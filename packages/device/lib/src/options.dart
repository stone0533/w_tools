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
    required this.android,
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

  /// 走 Android（adb）：坐标是**截图像素**，不需要标定。
  final bool android;

  String? get deviceOrFirst => device;

  static DeviceOptions parse(List<String> args) {
    String? device, out;
    var noCache = false;
    var json = false;
    var real = false;
    var android = false;
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
      } else if (a == '--android') {
        android = true;
      } else if (a.startsWith('--device=')) {
        device = a.substring('--device='.length);
      } else if (a.startsWith('--out=')) {
        out = a.substring('--out='.length);
      } else if (a == '--no-cache') {
        noCache = true;
      } else if (a.startsWith('--scale=')) {
        scale = _positiveInt('--scale', a.substring('--scale='.length));
      } else if (a.startsWith('--timeout-ms=')) {
        timeout = Duration(
          milliseconds: _positiveInt(
            '--timeout-ms',
            a.substring('--timeout-ms='.length),
          ),
        );
      } else if (a.startsWith('--stable-ms=')) {
        stableFor = Duration(
          milliseconds: _positiveInt(
            '--stable-ms',
            a.substring('--stable-ms='.length),
          ),
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
      android: android,
    );
  }

  /// 校验平台 / 命令组合，避免 `tap --real` 仍然点模拟器。
  void validate() {
    if (real && android) {
      throw StateError('--real 与 --android 不能同时使用');
    }
    const simOnly = <String>{'boot', 'calibrate'};
    const noReal = <String>{
      'boot',
      'calibrate',
      'tap',
      'drag',
      'type',
      'size',
      'wait',
      'verify',
    };
    const androidOnly = <String>{'foreground'};
    const androidCommands = <String>{
      'list',
      'shot',
      'tap',
      'drag',
      'type',
      'size',
      'wait',
      'verify',
      'foreground',
    };
    const realCommands = <String>{'list', 'shot'};
    if (simOnly.contains(command) && (real || android)) {
      throw StateError('$command 只支持 iOS 模拟器');
    }
    if (real && !realCommands.contains(command)) {
      throw StateError('--real 只支持 list / shot');
    }
    if (real && noReal.contains(command)) {
      throw StateError('$command 不支持真机');
    }
    if (android && !androidCommands.contains(command)) {
      throw StateError('--android 不支持 $command');
    }
    if (androidOnly.contains(command) && !android) {
      throw StateError('$command 需要 --android');
    }
    if (region != null && command != 'wait' && command != 'verify') {
      throw StateError('--region 只支持 wait / verify');
    }
    if (out != null && command != 'shot') {
      throw StateError('--out 只支持 shot');
    }
    if (scale != null && !android && !real && command == 'list') {
      throw StateError('--scale 只用于模拟器截图 / 标定');
    }
    if (scale != null && (android || real)) {
      throw StateError('--scale 只用于 iOS 模拟器');
    }
    if (noCache &&
        command != 'tap' &&
        command != 'drag' &&
        command != 'wait' &&
        command != 'verify') {
      throw StateError('--no-cache 只用于 tap / drag / wait / verify');
    }
    if (timeout != const Duration(seconds: 15) && command != 'wait' && command != 'verify') {
      throw StateError('--timeout-ms 只用于 wait / verify');
    }
    if (stableFor != const Duration(milliseconds: 600) &&
        command != 'wait' &&
        command != 'verify') {
      throw StateError('--stable-ms 只用于 wait / verify');
    }
  }

  static int _positiveInt(String option, String value) {
    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= 0) {
      throw StateError('$option 需要正整数：$value');
    }
    return parsed;
  }

  static DRect _parseRegion(String arg) {
    final parts = arg.substring('--region='.length).split(',');
    if (parts.length != 4) {
      throw StateError('--region 需要 x,y,w,h（设备坐标，例如 --region=0,0,402,120）');
    }
    final v = parts.map((e) => double.tryParse(e.trim())).toList();
    if (v.any((e) => e == null || !e.isFinite)) {
      throw StateError('--region 的四个值都要是有限数字：$arg');
    }
    if (v[2]! <= 0 || v[3]! <= 0) {
      throw StateError('--region 的宽高需要大于 0：$arg');
    }
    return DRect(v[0]!, v[1]!, v[2]!, v[3]!);
  }
}
