import 'geometry.dart';

/// CLI 参数（可单测；`bin/device.dart` 只负责分发）。
class DeviceOptions {
  const DeviceOptions({
    required this.command,
    required this.positional,
    required this.device,
    required this.out,
    required this.noCache,
    required this.scale,
    required this.timeout,
    required this.stableFor,
    required this.region,
    required this.json,
    required this.real,
  });

  final String command;
  final List<String> positional;
  final String? device;
  final String? out;
  final bool noCache;

  /// 设备像素密度（3 = iPhone 常见，2 = SE/iPad）。
  final int? scale;

  final Duration timeout;
  final Duration stableFor;

  /// 只看这块区域（设备坐标，point）；null = 整屏。
  final DRect? region;

  /// 输出 JSON（给脚本 / CI 用）。
  final bool json;

  /// 操作物理真机（需要 devicectl；点击不支持）。
  final bool real;

  String? get deviceOrFirst => device;

  static DeviceOptions parse(List<String> args) {
    String? device, out;
    var noCache = false;
    var json = false;
    var real = false;
    int? scale;
    var timeout = const Duration(seconds: 15);
    var stableFor = const Duration(milliseconds: 600);
    DRect? region;
    final rest = <String>[];
    for (final a in args) {
      if (a == '--json') {
        json = true;
      } else if (a == '--real') {
        real = true;
      } else if (a.startsWith('--device=')) {
        device = a.substring('--device='.length);
      } else if (a.startsWith('--out=')) {
        out = a.substring('--out='.length);
      } else if (a == '--no-cache') {
        noCache = true;
      } else if (a.startsWith('--scale=')) {
        scale = int.tryParse(a.substring('--scale='.length));
      } else if (a.startsWith('--timeout-ms=')) {
        timeout = Duration(
          milliseconds: int.tryParse(a.substring('--timeout-ms='.length)) ?? 15000,
        );
      } else if (a.startsWith('--stable-ms=')) {
        stableFor = Duration(
          milliseconds: int.tryParse(a.substring('--stable-ms='.length)) ?? 600,
        );
      } else if (a.startsWith('--region=')) {
        region = _parseRegion(a);
      } else if (a.startsWith('--')) {
        throw StateError('未知选项：$a');
      } else {
        rest.add(a);
      }
    }
    return DeviceOptions(
      command: rest.isEmpty ? 'list' : rest.first,
      positional: rest.skip(1).toList(),
      device: device,
      out: out,
      noCache: noCache,
      scale: scale,
      timeout: timeout,
      stableFor: stableFor,
      region: region,
      json: json,
      real: real,
    );
  }

  static DRect _parseRegion(String arg) {
    final parts = arg.substring('--region='.length).split(',');
    if (parts.length != 4) {
      throw StateError('--region 需要 x,y,w,h（设备坐标，例如 --region=0,0,402,120）');
    }
    final v = parts.map((e) => double.tryParse(e.trim())).toList();
    if (v.any((e) => e == null)) {
      throw StateError('--region 的四个值都要是数字：$arg');
    }
    return DRect(v[0]!, v[1]!, v[2]!, v[3]!);
  }
}
