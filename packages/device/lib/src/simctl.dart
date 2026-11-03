import 'dart:convert';
import 'dart:io';

import 'shell.dart';

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

/// `xcrun simctl list devices --json` 的解析与操作。
class Simctl {
  Simctl({Shell shell = const ProcessShell()}) : _shell = shell;

  final Shell _shell;

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

  /// 按 udid 或名称（可模糊）找设备；`booted` 表示只找已启动的。
  static SimDevice? resolve(
    List<SimDevice> all,
    String? query, {
    bool bootedOnly = false,
  }) {
    Iterable<SimDevice> pool = all;
    if (bootedOnly) pool = pool.where((d) => d.isBooted);
    if (query == null || query.isEmpty) return pool.firstOrNull;
    return pool.where((d) => d.udid == query).firstOrNull ??
        pool.where((d) => d.name == query).firstOrNull ??
        pool.where((d) => d.name.toLowerCase().contains(query.toLowerCase())).firstOrNull;
  }

  Future<void> boot(String udid) async {
    await _shell.runOrThrow('xcrun', ['simctl', 'boot', udid]);
    // bootstatus 会等设备真正可用（-b = booted）
    await _shell.runOrThrow('xcrun', ['simctl', 'bootstatus', udid, '-b']);
  }

  /// 截设备屏（px），返回文件路径。
  Future<String> screenshot(String udid, String out) async {
    await _shell.runOrThrow('xcrun', ['simctl', 'io', udid, 'screenshot', out]);
    return out;
  }

  /// 设备逻辑尺寸（point）。iPhone 常见 3x，其余按 2x 粗略判断；
  /// 需要精确时用 `--scale=` 覆盖。
  static int guessScale(int pixelWidth) => pixelWidth >= 1080 ? 3 : 2;

  /// 读取截图尺寸（px），用于标定时确定设备宽高比。
  Future<(int width, int height)> screenshotSize(String udid) async {
    final tmp = '${Directory.systemTemp.path}/w_tools_device_size.png';
    await screenshot(udid, tmp);
    final size = await _imageSize(tmp);
    File(tmp).deleteSync();
    return size;
  }

  static Future<(int, int)> _imageSize(String path) async {
    final r =
        await const ProcessShell().run('sips', ['-g', 'pixelWidth', '-g', 'pixelHeight', path]);
    final text = '${r.stdout}';
    final w = RegExp(r'pixelWidth:\s*(\d+)').firstMatch(text);
    final h = RegExp(r'pixelHeight:\s*(\d+)').firstMatch(text);
    if (w == null || h == null) {
      throw StateError('读不到图片尺寸: $path');
    }
    return (int.parse(w.group(1)!), int.parse(h.group(1)!));
  }
}
