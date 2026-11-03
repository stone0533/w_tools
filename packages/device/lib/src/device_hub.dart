import 'shell.dart';

/// DeviceHub 窗口在屏幕上的矩形（单位：屏幕 point）。
class HubWindow {
  const HubWindow(this.x, this.y, this.width, this.height);

  final double x;
  final double y;
  final double width;
  final double height;

  /// 判断两次读到的窗口是否一致（窗口被移动/缩放时标定要失效）。
  bool sameAs(HubWindow other, {double tolerance = 1}) =>
      (x - other.x).abs() <= tolerance &&
      (y - other.y).abs() <= tolerance &&
      (width - other.width).abs() <= tolerance &&
      (height - other.height).abs() <= tolerance;

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'w': width, 'h': height};

  static HubWindow? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    num? at(String k) => json[k] as num?;
    final x = at('x'), y = at('y'), w = at('w'), h = at('h');
    if (x == null || y == null || w == null || h == null) return null;
    return HubWindow(x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble());
  }
}

/// 通过 Accessibility 读 DeviceHub 窗口，并截图（需要「辅助功能」+「屏幕录制」）。
class DeviceHub {
  DeviceHub({Shell shell = const ProcessShell()}) : _shell = shell;

  final Shell _shell;

  /// 把 DeviceHub 放到最前（否则别的窗口会遮挡设备预览，标定会算错）。
  Future<void> activate() async {
    await _shell.run('osascript', [
      '-e',
      'tell application "DeviceHub" to activate',
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  /// 读窗口位置/大小；读不到（未运行 / 无权限）返回 null。
  Future<HubWindow?> window() async {
    final r = await _shell.run('osascript', [
      '-e',
      'tell application "System Events" to tell process "DeviceHub" to get {position, size} of window 1',
    ]);
    if (r.exitCode != 0) return null;
    return parseWindow('${r.stdout}');
  }

  /// 解析 osascript 的 `x, y, w, h` 输出（单独暴露便于单测）。
  static HubWindow? parseWindow(String text) {
    final nums =
        RegExp(r'-?\d+(?:\.\d+)?').allMatches(text).map((m) => double.parse(m.group(0)!)).toList();
    if (nums.length < 4) return null;
    return HubWindow(nums[0], nums[1], nums[2], nums[3]);
  }

  /// 截窗口到 [out]，返回「截图 px / point」的缩放比。
  Future<double> capture(HubWindow window, String out) async {
    await _shell.runOrThrow('screencapture', [
      '-x',
      '-R',
      '${window.x.round()},${window.y.round()},${window.width.round()},${window.height.round()}',
      out,
    ]);
    return scaleFor(window, out);
  }

  /// 截图的实际缩放比（Retina 上是 2）。
  Future<double> scaleFor(HubWindow window, String out) async {
    final r = await _shell.run('sips', ['-g', 'pixelWidth', out]);
    final m = RegExp(r'pixelWidth:\s*(\d+)').firstMatch('${r.stdout}');
    if (m == null) return 1;
    final px = int.parse(m.group(1)!);
    return window.width == 0 ? 1 : px / window.width;
  }
}
