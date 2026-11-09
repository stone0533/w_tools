import 'dart:io';

import 'shell.dart';

/// 一台 Android 设备（真机或模拟器）。
class AndroidDevice {
  const AndroidDevice({
    required this.serial,
    required this.state,
    required this.model,
    required this.product,
    required this.transport,
  });

  final String serial;

  /// `device` / `offline` / `unauthorized`
  final String state;
  final String model;
  final String product;
  final String transport;

  bool get isReady => state == 'device';

  Map<String, Object?> toJson() => {
        'serial': serial,
        'state': state,
        'model': model,
        'product': product,
        'transport': transport,
      };
}

/// `adb`：Android 的「simctl + devicectl + 输入注入」三合一。
///
/// 相比 iOS 的一大优势：**坐标就是截图像素**，不需要 DeviceHub 窗口标定，
/// 也不需要 cliclick / 屏幕录制权限。
class Adb {
  Adb({Shell shell = const ProcessShell()}) : _shell = shell;

  final Shell _shell;

  List<String> _args(String? serial, List<String> rest) => [
        if (serial != null) ...['-s', serial],
        ...rest,
      ];

  Future<List<AndroidDevice>> devices() async {
    final r = await _shell.runOrThrow('adb', ['devices', '-l']);
    return parseDevices('${r.stdout}');
  }

  /// 解析 `adb devices -l`（单独暴露便于单测）。
  static List<AndroidDevice> parseDevices(String text) {
    final out = <AndroidDevice>[];
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('List of devices')) continue;
      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length < 2) continue;
      final serial = parts[0];
      final state = parts[1];
      String field(String key) {
        for (final p in parts.skip(2)) {
          if (p.startsWith('$key:')) return p.substring(key.length + 1);
        }
        return '';
      }

      out.add(
        AndroidDevice(
          serial: serial,
          state: state,
          model: field('model'),
          product: field('product'),
          transport: field('transport_id'),
        ),
      );
    }
    return out;
  }

  static AndroidDevice? resolve(List<AndroidDevice> all, String? query) {
    // 只从就绪设备里挑：显式指定 offline / unauthorized 设备时返回 null，
    // 由调用方给出“没有就绪设备”的明确错误，而不是继续执行再报 adb 错误。
    final ready = all.where((d) => d.isReady).toList();
    if (query == null || query.isEmpty) return ready.firstOrNull;
    return ready.where((d) => d.serial == query).firstOrNull ??
        ready.where((d) => d.model.toLowerCase().contains(query.toLowerCase())).firstOrNull;
  }

  /// 设备分辨率（px）。有 `Override size` 时优先用它，因为 `input tap/swipe`
  /// 使用的就是 override 后的显示坐标空间。
  Future<(int, int)> screenSize(String serial) async {
    final r = await _shell.runOrThrow('adb', _args(serial, ['shell', 'wm', 'size']));
    final text = '${r.stdout}';
    final m = RegExp(r'Override size:\s*(\d+)x(\d+)').firstMatch(text) ??
        RegExp(r'(\d+)x(\d+)').firstMatch(text);
    if (m == null) {
      throw ProcessException(
        'adb',
        _args(serial, ['shell', 'wm', 'size']),
        '读不到 Android 分辨率：$text',
        1,
      );
    }
    return (int.parse(m.group(1)!), int.parse(m.group(2)!));
  }

  /// 截图（PNG）。二进制必须走 `runBytes`（`Process.run` 默认按 UTF-8 解码会毁掉 PNG）。
  Future<String> screenshot(String serial, String out) async {
    final bytes = await _shell.runBytes('adb', _args(serial, ['exec-out', 'screencap', '-p']));
    File(out).parent.createSync(recursive: true);
    File(out).writeAsBytesSync(bytes);
    return out;
  }

  /// 点击：**截图像素坐标**。
  Future<void> tap(String serial, int x, int y) async {
    await _shell.runOrThrow('adb', _args(serial, ['shell', 'input', 'tap', '$x', '$y']));
  }

  /// 滑动（毫秒时长越短越像甩动）。
  Future<void> swipe(
    String serial,
    int x1,
    int y1,
    int x2,
    int y2, {
    int durationMs = 300,
  }) async {
    await _shell.runOrThrow(
      'adb',
      _args(serial, ['shell', 'input', 'swipe', '$x1', '$y1', '$x2', '$y2', '$durationMs']),
    );
  }

  /// 输入文本（先点中输入框）。
  ///
  /// Android 的 `input text` 用 `%s` 表示空格；这里用单引号包住整段，
  /// 避免 `& | ; ( ) < >` 被远端 shell 解释。换行/控制字符无法可靠输入，直接报错。
  /// 中文/emoji 取决于设备输入法，不保证可用。
  Future<void> text(String serial, String text) async {
    await _shell.runOrThrow(
      'adb',
      _args(serial, ['shell', 'input', 'text', escapeTextArgument(text)]),
    );
  }

  /// 供单测：把文本转成传给 `adb shell input text` 的单个参数。
  static String escapeTextArgument(String text) {
    if (RegExp(r'[\x00-\x1F\x7F]').hasMatch(text)) {
      throw StateError('type 不支持换行/控制字符；换行请用 keyevent');
    }
    final escaped = text.replaceAll(' ', '%s').replaceAll("'", "'\\''");
    return "'$escaped'";
  }

  /// 前台 App 的包名（空 = 取不到）。
  ///
  /// 注意：`dumpsys window mCurrentFocus` **不是合法子命令**（会报 Bad window command），
  /// 必须跑整个 `dumpsys window` 再按 `mCurrentFocus=` 解析。
  Future<String> currentPackage(String serial) async {
    final r = await _shell.run('adb', _args(serial, ['shell', 'dumpsys', 'window']));
    return parseCurrentPackage('${r.stdout}');
  }

  /// 前台包名必须非空；供 CLI 把“取不到”转成明确失败。
  static String requirePackage(String pkg) {
    if (pkg.isEmpty) {
      throw StateError('取不到 Android 前台包名（设备可能锁屏 / 无 Activity）');
    }
    return pkg;
  }

  /// 从 `dumpsys window` 输出里取前台包名；取不到回落到 `topResumedActivity`。
  static String parseCurrentPackage(String dumpsys) {
    final focus = RegExp(r'mCurrentFocus=Window\{[^}]*?\s([a-zA-Z0-9_.]+)/').firstMatch(dumpsys);
    if (focus != null) return focus.group(1)!;
    final resumed =
        RegExp(r'topResumedActivity=ActivityRecord\{[^}]*?\s([a-zA-Z0-9_.]+)/').firstMatch(dumpsys);
    if (resumed != null) return resumed.group(1)!;
    return '';
  }
}
