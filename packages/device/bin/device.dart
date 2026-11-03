import 'dart:io';
import 'package:image/image.dart' as img;

import 'package:w_tools_device/w_tools_device.dart';

const _usage = '''
w_tools_device —— 设备验证小工具（模拟器为主，读数 + 点击）

用法：
  dart run w_tools_device:device list                 # 列出模拟器（udid / 名称 / 状态）
  dart run w_tools_device:device boot <名称|udid>      # 启动并等待可用
  dart run w_tools_device:device shot --out=<path>    # 截设备屏
  dart run w_tools_device:device calibrate            # 标定 DeviceHub 里设备屏幕的坐标
  dart run w_tools_device:device tap <x> <y>          # 用设备坐标点（自动换算成屏幕坐标）
  dart run w_tools_device:device drag <x1> <y1> <x2> <y2>
  dart run w_tools_device:device type <text>          # 输入文本（先点中输入框）

可选：
  --device=<udid|名称>   指定设备（默认用已启动的 / 第一台）
  --no-cache            忽略标定缓存，强制重算

依赖：macOS + Xcode；`brew install cliclick`；给宿主 App 开「辅助功能」+「屏幕录制」。
''';

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.contains('-h') || args.contains('--help')) {
    stdout.write(_usage);
    exitCode = args.isEmpty ? 2 : 0;
    return;
  }

  final options = _Options.parse(args);
  final simctl = Simctl();
  try {
    switch (options.command) {
      case 'list':
        _list(await simctl.devices());
      case 'boot':
        await _boot(simctl, options);
      case 'shot':
        await _shot(simctl, options);
      case 'calibrate':
        final cal = await _calibrate(simctl, options, force: true);
        _printCalibration(cal);
      case 'tap':
        await _tap(simctl, options);
      case 'drag':
        await _drag(simctl, options);
      case 'type':
        await Input().type(options.positional.join(' '));
      default:
        stderr.writeln('未知命令：${options.command}');
        stdout.write(_usage);
        exitCode = 2;
    }
  } on ProcessException catch (e) {
    stderr.writeln('命令执行失败：${e.message}');
    exitCode = 1;
  } on StateError catch (e) {
    stderr.writeln(e.message);
    exitCode = 1;
  }
}

void _list(List<SimDevice> devices) {
  if (devices.isEmpty) {
    stdout.writeln('（没有模拟器）');
    return;
  }
  stdout.writeln('状态\t运行时\tUDID\t名称');
  for (final d in devices) {
    stdout.writeln('${d.state}\t${d.runtimeLabel}\t${d.udid}\t${d.name}');
  }
}

Future<void> _boot(Simctl simctl, _Options o) async {
  final devices = await simctl.devices();
  final target = Simctl.resolve(devices, o.deviceOrFirst ?? o.positional.firstOrNull);
  if (target == null) {
    throw StateError('找不到模拟器：${o.deviceOrFirst ?? o.positional.firstOrNull}');
  }
  if (!target.isBooted) {
    stdout.writeln('启动 ${target.name} (${target.udid}) ...');
    await simctl.boot(target.udid);
  }
  stdout.writeln('已就绪：${target.name} (${target.udid})');
}

Future<void> _shot(Simctl simctl, _Options o) async {
  final udid = await _resolveUdid(simctl, o, bootedOnly: true);
  final out = o.out ?? '${Directory.systemTemp.path}/device_shot.png';
  await simctl.screenshot(udid, out);
  stdout.writeln(out);
}

Future<void> _tap(Simctl simctl, _Options o) async {
  if (o.positional.length < 2) {
    throw StateError('tap 需要 <x> <y>（设备坐标）');
  }
  final x = double.parse(o.positional[0]);
  final y = double.parse(o.positional[1]);
  final cal = await _calibrate(simctl, o, force: o.noCache);
  final screen = cal.toScreen(DPoint(x, y));
  await Input().tap(screen.x, screen.y);
  stdout.writeln(
    'tap device($x, $y) → screen(${screen.x.round()}, ${screen.y.round()})',
  );
}

Future<void> _drag(Simctl simctl, _Options o) async {
  if (o.positional.length < 4) {
    throw StateError('drag 需要 <x1> <y1> <x2> <y2>（设备坐标）');
  }
  final cal = await _calibrate(simctl, o, force: o.noCache);
  final a = cal.toScreen(
    DPoint(double.parse(o.positional[0]), double.parse(o.positional[1])),
  );
  final b = cal.toScreen(
    DPoint(double.parse(o.positional[2]), double.parse(o.positional[3])),
  );
  await Input().drag(a.x, a.y, b.x, b.y);
  stdout.writeln('drag screen(${a.x.round()},${a.y.round()}) → (${b.x.round()},${b.y.round()})');
}

/// 拿标定（缓存命中且窗口没变就复用）。
Future<Calibration> _calibrate(
  Simctl simctl,
  _Options o, {
  bool force = false,
}) async {
  final udid = await _resolveUdid(simctl, o, bootedOnly: true);
  final store = CalibrationStore();
  final hub = DeviceHub();
  // 先把 DeviceHub 置前：别的窗口（有时是活动监视器）会盖住设备预览
  await hub.activate();
  final window = await hub.window();
  if (window == null) {
    throw StateError(
      '读不到 DeviceHub 窗口：确认 DeviceHub 已打开，且宿主 App 有「辅助功能」权限',
    );
  }
  if (!force) {
    final cached = store.load(udid);
    if (cached != null && cached.matches(window)) return cached;
  }

  final size = await simctl.screenshotSize(udid);
  final deviceScale = o.scale ?? Simctl.guessScale(size.$1);
  final points = (size.$1 ~/ deviceScale, size.$2 ~/ deviceScale);
  final shot = '${Directory.systemTemp.path}/w_tools_device_hub.png';
  final scale = await hub.capture(window, shot);
  final image = img.decodePng(File(shot).readAsBytesSync());
  if (image == null) throw StateError('窗口截图解码失败：$shot');
  final cal = const CalibrationDetector().detect(
    image: image,
    window: window,
    scale: scale,
    deviceWidth: points.$1,
    deviceHeight: points.$2,
  );
  store.save(udid, cal);
  return cal;
}

Future<String> _resolveUdid(
  Simctl simctl,
  _Options o, {
  bool bootedOnly = false,
}) async {
  final devices = await simctl.devices();
  final target = Simctl.resolve(devices, o.deviceOrFirst, bootedOnly: bootedOnly);
  if (target == null) {
    throw StateError(bootedOnly ? '没有已启动的模拟器（先 device boot）' : '找不到模拟器');
  }
  return target.udid;
}

void _printCalibration(Calibration c) {
  stdout.writeln('窗口：(${c.window.x}, ${c.window.y}) ${c.window.width}×${c.window.height}');
  stdout.writeln(
    '设备屏幕（窗口内）：(${c.deviceRect.left.toStringAsFixed(1)}, '
    '${c.deviceRect.top.toStringAsFixed(1)}) '
    '${c.deviceRect.width.toStringAsFixed(1)}×${c.deviceRect.height.toStringAsFixed(1)}',
  );
  stdout.writeln('设备分辨率：${c.deviceWidth}×${c.deviceHeight}');
}

class _Options {
  _Options({
    required this.command,
    required this.positional,
    required this.device,
    required this.out,
    required this.noCache,
    required this.scale,
  });

  final String command;
  final List<String> positional;
  final String? device;
  final String? out;
  final bool noCache;

  /// 设备像素密度（3 = iPhone 常见，2 = SE/iPad）。
  final int? scale;

  String? get deviceOrFirst => device;

  static _Options parse(List<String> args) {
    String? device, out;
    var noCache = false;
    int? scale;
    final rest = <String>[];
    for (final a in args) {
      if (a.startsWith('--device=')) {
        device = a.substring('--device='.length);
      } else if (a.startsWith('--out=')) {
        out = a.substring('--out='.length);
      } else if (a == '--no-cache') {
        noCache = true;
      } else if (a.startsWith('--scale=')) {
        scale = int.tryParse(a.substring('--scale='.length));
      } else if (a.startsWith('--')) {
        throw StateError('未知选项：$a');
      } else {
        rest.add(a);
      }
    }
    return _Options(
      command: rest.isEmpty ? 'list' : rest.first,
      positional: rest.skip(1).toList(),
      device: device,
      out: out,
      noCache: noCache,
      scale: scale,
    );
  }
}
