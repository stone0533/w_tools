import 'dart:convert';
import 'dart:io';

import 'shell.dart';
import 'temp.dart';

/// 一台模拟器。
class SimDevice {
  const SimDevice({
    required this.udid,
    required this.name,
    required this.state,
    required this.runtime,
  });

  final String udid;
  final String name;

  /// Booted / Shutdown / ...
  final String state;
  final String runtime;

  bool get isBooted => state.toLowerCase() == 'booted';

  /// 展示用运行时名（`com.apple.CoreSimulator.SimRuntime.iOS-26-4` → `iOS 26.4`）。
  String get runtimeLabel {
    final raw = runtime.split('.').last;
    final m = RegExp(r'([A-Za-z]+)-(\d+)-(\d+)').firstMatch(raw);
    return m == null ? raw : '${m.group(1)} ${m.group(2)}.${m.group(3)}';
  }
}

/// 设备屏幕规格：像素尺寸 + 像素密度（px / point）。
class ScreenMetrics {
  const ScreenMetrics({
    required this.pixelWidth,
    required this.pixelHeight,
    required this.scale,
    required this.source,
    this.reason,
  });

  final int pixelWidth;
  final int pixelHeight;

  /// 截图 px / 设备 point（iPhone 常见 3，iPad 2）。
  final int scale;

  /// `deviceType` = 读自模拟器设备类型描述；`fallback` = 读不到时按截图尺寸估算。
  final String source;

  /// 仅在 [source] == `fallback` 时存在：说明卡在哪一步。
  ///
  /// `no-device-type` / `no-devicetypes` / `unknown-device-type` / `no-capabilities`。
  final String? reason;

  int get pointWidth => pixelWidth ~/ scale;
  int get pointHeight => pixelHeight ~/ scale;
}

/// `xcrun simctl list devices --json` 的解析与操作。
class Simctl {
  Simctl({Shell shell = const ProcessShell()}) : _shell = shell;

  final Shell _shell;

  /// 设备类型描述读不到时的经验密度。
  ///
  /// 竖屏：宽高比 >0.65 视为 iPad（1488×2266 ≈ 0.657、iPad 4:3 ≈ 0.75），
  /// 否则按宽度区分 iPhone（1206 → 3x、750/828 → 2x）。
  /// 横屏截图先按宽高比判断：>1.8 是 iPhone（2622×1206），否则是 iPad / SE
  /// （2732×2048、1334×750）—— 只看宽会把横屏 iPhone 误判成 2x。
  static int fallbackScale(int pixelWidth, int pixelHeight) {
    if (pixelWidth > 0 && pixelHeight > 0 && pixelWidth > pixelHeight) {
      return pixelWidth / pixelHeight > 1.8 ? 3 : 2;
    }
    if (pixelHeight > 0 && pixelWidth / pixelHeight > 0.65) return 2;
    if (pixelWidth >= 1536 || pixelWidth < 1080) return 2;
    return 3;
  }

  Future<List<SimDevice>> devices() async {
    final r = await _shell.runOrThrow('xcrun', ['simctl', 'list', 'devices', '--json']);
    return parseDevices('${r.stdout}');
  }

  /// 解析 simctl 的 JSON（单独暴露，方便单测）。
  static List<SimDevice> parseDevices(String jsonText) {
    final Object? root;
    try {
      root = jsonDecode(jsonText);
    } on FormatException {
      // simctl 输出异常（被截断 / 非 JSON）时不要炸，按「没有设备」处理
      return const [];
    }
    if (root is! Map) return const [];
    final devices = root['devices'];
    if (devices is! Map) return const [];
    final out = <SimDevice>[];
    devices.forEach((runtime, list) {
      if (list is! List) return;
      for (final d in list) {
        if (d is! Map) continue;
        final udid = '${d['udid'] ?? ''}';
        if (udid.isEmpty) continue;
        out.add(
          SimDevice(
            udid: udid,
            name: '${d['name'] ?? ''}',
            state: '${d['state'] ?? ''}',
            runtime: '$runtime',
          ),
        );
      }
    });
    return out;
  }

  /// 按 udid / 名称精确匹配，其次按名称子串；返回**全部**命中项。
  ///
  /// 调用方必须在命中多台时报歧义（exit 2），不能静默取第一台 ——
  /// 否则点击 / 截图会打到另一台设备上。
  static List<SimDevice> matches(
    List<SimDevice> all,
    String? query, {
    bool bootedOnly = false,
  }) {
    final pool = bootedOnly ? all.where((d) => d.isBooted) : all;
    if (query == null || query.isEmpty) return pool.toList();
    final exact = pool.where((d) => d.udid == query || d.name == query).toList();
    if (exact.isNotEmpty) return exact;
    final lower = query.toLowerCase();
    return pool.where((d) => d.name.toLowerCase().contains(lower)).toList();
  }

  Future<void> boot(String udid) async {
    await _shell.runOrThrow('xcrun', ['simctl', 'boot', udid]);
    // bootstatus 会等设备真正可用（-b = booted）
    await _shell.runOrThrow('xcrun', ['simctl', 'bootstatus', udid, '-b']);
  }

  /// 截设备屏（px），返回文件路径。
  Future<String> screenshot(String udid, String out) async {
    File(out).parent.createSync(recursive: true);
    await _shell.runOrThrow('xcrun', ['simctl', 'io', udid, 'screenshot', out]);
    return out;
  }

  /// 设备屏幕规格（px + 密度 + 点数）。
  ///
  /// `device.plist` 里的 `deviceType` 是**标识符**
  /// （`com.apple.CoreSimulator.SimDeviceType.iPhone-17`），而 DeviceTypes 目录名是
  /// 人类可读名（`iPhone 17.simdevicetype`）—— 所以先用
  /// `simctl list devicetypes --json` 把它映射到 `bundlePath`，再读
  /// `capabilities.plist` 的 `ScreenDimensionsCapability`。
  ///
  /// 都读不到（旧版 Xcode / simctl 异常）才回退到「截图宽度 + 经验密度」，
  /// 并在 [ScreenMetrics.source] 里标成 `fallback`，让 `--json` 能看出来。
  Future<ScreenMetrics> metrics(String udid) async {
    final (fromDeviceType, reason) = await _metricsFromDeviceType(udid);
    if (fromDeviceType != null) return fromDeviceType;
    final (width, height) = await screenshotSize(udid);
    return ScreenMetrics(
      pixelWidth: width,
      pixelHeight: height,
      scale: fallbackScale(width, height),
      source: 'fallback',
      reason: reason,
    );
  }

  /// 从设备类型描述取指标；失败时第二个返回值是走向 fallback 的原因。
  Future<(ScreenMetrics?, String?)> _metricsFromDeviceType(String udid) async {
    final type = await _deviceType(udid);
    if (type == null) return (null, 'no-device-type');
    final table = await _deviceTypes();
    if (table == null) return (null, 'no-devicetypes');
    final info = table[type];
    if (info == null) return (null, 'unknown-device-type');
    final metrics = await _metricsFromBundle(info.bundlePath) ?? await _metricsFromName(info.name);
    return (metrics, metrics == null ? 'no-capabilities' : null);
  }

  Map<String, ({String? bundlePath, String? name})>? _typeInfoCache;

  Future<String?> _deviceType(String udid) async {
    final home = Platform.environment['HOME'];
    if (home == null) return null;
    // 不能把 device.plist 转成 JSON：里面含 Date（lastUsedAt），JSON 无法表示。
    // `plutil -extract <key> raw` 只取字符串值，正好够用。
    final ProcessResult result;
    try {
      result = await _shell.run('plutil', [
        '-extract',
        'deviceType',
        'raw',
        '-o',
        '-',
        '$home/Library/Developer/CoreSimulator/Devices/$udid/device.plist',
      ]);
    } on ProcessException {
      return null;
    }
    if (result.exitCode != 0) return null;
    final type = '${result.stdout}'.trim();
    return type.isEmpty ? null : type;
  }

  /// `identifier → (bundlePath, name)`；一次进程内最多读一次。
  Future<Map<String, ({String? bundlePath, String? name})>?> _deviceTypes() async {
    final cached = _typeInfoCache;
    if (cached != null) return cached;
    final ProcessResult result;
    try {
      result = await _shell.run('xcrun', ['simctl', 'list', 'devicetypes', '--json']);
    } on ProcessException {
      return null;
    }
    if (result.exitCode != 0) return null;
    try {
      final root = jsonDecode('${result.stdout}');
      if (root is! Map || root['devicetypes'] is! List) return null;
      final table = <String, ({String? bundlePath, String? name})>{};
      for (final entry in root['devicetypes'] as List) {
        if (entry is! Map) continue;
        final identifier = entry['identifier'];
        if (identifier is! String || identifier.isEmpty) continue;
        final bundlePath = entry['bundlePath'];
        final name = entry['name'];
        table[identifier] = (
          bundlePath: bundlePath is String && bundlePath.isNotEmpty ? bundlePath : null,
          name: name is String && name.isNotEmpty ? name : null,
        );
      }
      return _typeInfoCache = table;
    } on FormatException {
      return null;
    }
  }

  Future<ScreenMetrics?> _metricsFromBundle(String? bundlePath) async {
    if (bundlePath == null) return null;
    return _metricsFromPlist('$bundlePath/Contents/Resources/capabilities.plist');
  }

  Future<ScreenMetrics?> _metricsFromName(String? name) async {
    if (name == null) return null;
    final home = Platform.environment['HOME'];
    final dirs = <String>[
      if (home != null) '$home/Library/Developer/CoreSimulator/Profiles/DeviceTypes',
      '/Library/Developer/CoreSimulator/Profiles/DeviceTypes',
    ];
    for (final dir in dirs) {
      final metrics =
          await _metricsFromPlist('$dir/$name.simdevicetype/Contents/Resources/capabilities.plist');
      if (metrics != null) return metrics;
    }
    return null;
  }

  Future<ScreenMetrics?> _metricsFromPlist(String path) async {
    final data = await _readPlist(path);
    if (data == null) return null;
    // 真实文件是 `{"capabilities": {"ScreenDimensionsCapability": {...}}}`；
    // 顶层也接受，避免旧版 / 裁剪过的 plist 直接判失败。
    final capabilities = data['capabilities'];
    final dimensions = capabilities is Map
        ? capabilities['ScreenDimensionsCapability']
        : data['ScreenDimensionsCapability'];
    if (dimensions is! Map) return null;
    final width = dimensions['main-screen-width'];
    final height = dimensions['main-screen-height'];
    final scale = dimensions['main-screen-scale'];
    if (width is! num || height is! num || scale is! num) return null;
    if (width <= 0 || height <= 0 || scale <= 0) return null;
    return ScreenMetrics(
      pixelWidth: width.toInt(),
      pixelHeight: height.toInt(),
      scale: scale.toInt(),
      source: 'deviceType',
    );
  }

  /// `plutil -convert json -o -`：把 plist 读成 JSON，失败返回 null（不抛）。
  ///
  /// `plutil` 缺失 / 不可执行也按「读不到」处理：密度回退总比整个命令失败好。
  Future<Map<String, dynamic>?> _readPlist(String path) async {
    final ProcessResult r;
    try {
      r = await _shell.run('plutil', ['-convert', 'json', '-o', '-', path]);
    } on ProcessException {
      return null;
    }
    if (r.exitCode != 0) return null;
    try {
      final decoded = jsonDecode('${r.stdout}');
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  /// 读取截图尺寸（px）；只在拿不到设备类型描述时兜底使用。
  Future<(int width, int height)> screenshotSize(String udid) async =>
      withTempFile('w_tools_device_size', 'png', (path) async {
        await screenshot(udid, path);
        return _imageSize(path);
      });

  Future<(int, int)> _imageSize(String path) async {
    final r = await _shell.run('sips', ['-g', 'pixelWidth', '-g', 'pixelHeight', path]);
    final text = '${r.stdout}';
    final w = RegExp(r'pixelWidth:\s*(\d+)').firstMatch(text);
    final h = RegExp(r'pixelHeight:\s*(\d+)').firstMatch(text);
    if (w == null || h == null) {
      throw ProcessException(
        'sips',
        ['-g', 'pixelWidth', '-g', 'pixelHeight', path],
        '读不到图片尺寸: $path',
        1,
      );
    }
    return (int.parse(w.group(1)!), int.parse(h.group(1)!));
  }
}
