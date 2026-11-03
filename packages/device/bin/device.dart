import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:w_tools_device/w_tools_device.dart';

const _usage = '''
w_tools_device —— 设备验证小工具（模拟器为主 + 真机截图，读数 + 点击）

用法：
  dart run w_tools_device:device list                 # 列出模拟器（udid / 名称 / 状态）
  dart run w_tools_device:device list --real          # 列出物理真机（devicectl）
  dart run w_tools_device:device boot <名称|udid>      # 启动并等待可用
  dart run w_tools_device:device shot --out=<path>    # 截设备屏（--real 走 devicectl）
  dart run w_tools_device:device calibrate            # 标定 DeviceHub 里设备屏幕的坐标
  dart run w_tools_device:device tap <x> <y>          # 用设备坐标点（自动换算成屏幕坐标）
  dart run w_tools_device:device drag <x1> <y1> <x2> <y2>
  dart run w_tools_device:device type <text>          # 输入文本（先点中输入框）
  dart run w_tools_device:device wait                 # 等画面稳定
  dart run w_tools_device:device verify <x> <y>       # 点一下并确认画面有变化（坐标自检）

可选：
  --device=<udid|名称>   指定设备（默认用已启动的 / 第一台）
  --no-cache            忽略标定缓存，强制重算
  --scale=3             设备像素密度（默认按截图宽度猜 3x/2x）
  --timeout-ms=15000    等待超时
  --stable-ms=600       画面稳定判定窗口
  --region=x,y,w,h      只看这块区域（设备坐标）；verify/wait 用
  --real                操作物理真机（仅 list / shot；点击需要 idb，本工具不支持）
  --json                输出 JSON（给脚本 / CI 用）

退出码：0 成功 · 1 参数/执行错误 · 2 verify 画面没变化（坐标可能失效）

依赖：macOS + Xcode；`brew install cliclick`；给宿主 App 开「辅助功能」+「屏幕录制」。
''';

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.contains('-h') || args.contains('--help')) {
    stdout.write(_usage);
    exitCode = args.isEmpty ? 2 : 0;
    return;
  }

  DeviceOptions? options;
  final simctl = Simctl();
  try {
    options = DeviceOptions.parse(args);
    final o = options;
    switch (o.command) {
      case 'list':
        await _list(o, simctl);
      case 'boot':
        await _boot(simctl, o);
      case 'shot':
        await _shot(simctl, o);
      case 'calibrate':
        _emitCalibration(o, await _calibrate(simctl, o, force: true));
      case 'tap':
        await _tap(simctl, o);
      case 'drag':
        await _drag(simctl, o);
      case 'type':
        await Input().type(o.positional.join(' '));
        _emit(o, {'text': o.positional.join(' ')}, '已输入：${o.positional.join(' ')}');
      case 'wait':
        await _wait(simctl, o);
      case 'verify':
        await _verify(simctl, o);
      default:
        throw StateError('未知命令：${o.command}\n\n$_usage');
    }
  } on ProcessException catch (e) {
    _fail(options, '命令执行失败：${e.message}', 1);
  } on StateError catch (e) {
    _fail(options, e.message, 1);
  }
}

/// 输出：`--json` 打 JSON，否则打人类可读文本。
void _emit(DeviceOptions o, Map<String, Object?> data, String human) {
  if (o.json) {
    stdout.writeln(jsonEncode({'ok': true, 'command': o.command, ...data}));
  } else {
    stdout.writeln(human);
  }
}

void _fail(DeviceOptions? o, String message, int code) {
  if (o?.json ?? false) {
    stdout.writeln(jsonEncode({'ok': false, 'command': o?.command, 'error': message}));
  } else {
    stderr.writeln(message);
  }
  exitCode = code;
}

Future<void> _list(DeviceOptions o, Simctl simctl) async {
  if (o.real) {
    final devices = await Devicectl().devices();
    _emit(
        o,
        {
          'real': true,
          'devices': [for (final d in devices) d.toJson()],
        },
        _realTable(devices));
    return;
  }
  final devices = await simctl.devices();
  _emit(
      o,
      {
        'real': false,
        'devices': [
          for (final d in devices)
            {
              'udid': d.udid,
              'name': d.name,
              'state': d.state,
              'runtime': d.runtimeLabel,
              'booted': d.isBooted,
            },
        ],
      },
      _simTable(devices));
}

String _simTable(List<SimDevice> devices) {
  if (devices.isEmpty) return '（没有模拟器）';
  final b = StringBuffer('状态\t运行时\tUDID\t名称\n');
  for (final d in devices) {
    b.writeln('${d.state}\t${d.runtimeLabel}\t${d.udid}\t${d.name}');
  }
  return b.toString().trimRight();
}

String _realTable(List<RealDevice> devices) {
  if (devices.isEmpty) return '（没有物理设备；确认已用数据线连接并信任）';
  final b = StringBuffer('状态\t系统\t连接\tUDID\t名称\n');
  for (final d in devices) {
    b.writeln('${d.bootState}\t${d.osVersion}\t${d.transport}\t${d.udid}\t${d.name}');
  }
  return b.toString().trimRight();
}

Future<void> _boot(Simctl simctl, DeviceOptions o) async {
  final devices = await simctl.devices();
  final target = Simctl.resolve(devices, o.deviceOrFirst ?? o.positional.firstOrNull);
  if (target == null) {
    throw StateError('找不到模拟器：${o.deviceOrFirst ?? o.positional.firstOrNull}');
  }
  if (!target.isBooted) {
    if (!o.json) stdout.writeln('启动 ${target.name} (${target.udid}) ...');
    await simctl.boot(target.udid);
  }
  _emit(
      o,
      {
        'udid': target.udid,
        'name': target.name,
        'ready': true,
      },
      '已就绪：${target.name} (${target.udid})');
}

Future<void> _shot(Simctl simctl, DeviceOptions o) async {
  if (o.real) {
    final devices = await Devicectl().devices();
    final target = Devicectl.resolve(devices, o.deviceOrFirst);
    if (target == null) {
      throw StateError('找不到真机（先 device list --real；确认已连接并信任）');
    }
    if (!target.isBooted) {
      throw StateError('真机未启动/未解锁：${target.name} (${target.bootState})');
    }
    final out = o.out ?? '${Directory.systemTemp.path}/device_real.png';
    await Devicectl().screenshot(target.udid, out);
    // 锁屏/息屏时 devicectl 会返回全黑图 —— 明确提示，别让人以为截图坏了
    final dark = ScreenStats.isMostlyDark(File(out).readAsBytesSync());
    _emit(
      o,
      {
        'path': out,
        'udid': target.udid,
        'real': true,
        if (dark) 'warning': '截图几乎全黑：真机可能锁屏/息屏，请点亮并解锁后重试',
      },
      dark ? '$out\n⚠️ 截图几乎全黑：真机可能锁屏/息屏，请点亮并解锁后重试' : out,
    );
    return;
  }
  final udid = await _resolveUdid(simctl, o, bootedOnly: true);
  final out = o.out ?? '${Directory.systemTemp.path}/device_shot.png';
  await simctl.screenshot(udid, out);
  _emit(o, {'path': out, 'udid': udid, 'real': false}, out);
}

Future<void> _tap(Simctl simctl, DeviceOptions o) async {
  _requireArgs(o, 2, 'tap 需要 <x> <y>（设备坐标）');
  final x = double.parse(o.positional[0]);
  final y = double.parse(o.positional[1]);
  final cal = await _calibrate(simctl, o, force: o.noCache);
  final screen = cal.toScreen(DPoint(x, y));
  await Input().tap(screen.x, screen.y);
  _emit(
      o,
      {
        'device': {'x': x, 'y': y},
        'screen': {'x': screen.x, 'y': screen.y},
      },
      'tap device($x, $y) → screen(${screen.x.round()}, ${screen.y.round()})');
}

Future<void> _drag(Simctl simctl, DeviceOptions o) async {
  _requireArgs(o, 4, 'drag 需要 <x1> <y1> <x2> <y2>（设备坐标）');
  final cal = await _calibrate(simctl, o, force: o.noCache);
  final a = cal.toScreen(
    DPoint(double.parse(o.positional[0]), double.parse(o.positional[1])),
  );
  final b = cal.toScreen(
    DPoint(double.parse(o.positional[2]), double.parse(o.positional[3])),
  );
  await Input().drag(a.x, a.y, b.x, b.y);
  _emit(
      o,
      {
        'from': {'x': a.x, 'y': a.y},
        'to': {'x': b.x, 'y': b.y},
      },
      'drag screen(${a.x.round()},${a.y.round()}) → (${b.x.round()},${b.y.round()})');
}

Future<void> _wait(Simctl simctl, DeviceOptions o) async {
  final udid = await _resolveUdid(simctl, o, bootedOnly: true);
  final ok = await _stability(simctl, udid).waitStable(
    stableFor: o.stableFor,
    timeout: o.timeout,
  );
  _emit(o, {'stable': ok}, ok ? '画面已稳定' : '等待超时（画面仍在变化）');
  if (!ok) exitCode = 3;
}

Future<void> _verify(Simctl simctl, DeviceOptions o) async {
  _requireArgs(o, 2, 'verify 需要 <x> <y>（设备坐标）');
  final x = double.parse(o.positional[0]);
  final y = double.parse(o.positional[1]);
  final udid = await _resolveUdid(simctl, o, bootedOnly: true);
  final cal = await _calibrate(simctl, o, force: o.noCache);
  final screen = cal.toScreen(DPoint(x, y));
  final pixelWidth = (await simctl.screenshotSize(udid)).$1;
  final changed = await TapVerifier.verify(
    stability: _stability(
      simctl,
      udid,
      region: o.region,
      calibration: cal,
      pixelWidth: pixelWidth,
    ),
    fingerprint: () => _fingerprint(
      simctl,
      udid,
      region: o.region,
      calibration: cal,
      pixelWidth: pixelWidth,
    ),
    tap: () => Input().tap(screen.x, screen.y),
    stableFor: o.stableFor,
    timeout: o.timeout,
  );
  _emit(
      o,
      {
        'changed': changed,
        'device': {'x': x, 'y': y},
        'screen': {'x': screen.x, 'y': screen.y},
        'region': o.region == null
            ? null
            : {
                'x': o.region!.left,
                'y': o.region!.top,
                'w': o.region!.width,
                'h': o.region!.height,
              },
      },
      'tap device($x, $y) → screen(${screen.x.round()}, ${screen.y.round()})：'
      '${changed ? '画面有变化 ✅' : '画面无变化 ⚠️（坐标可能失效）'}');
  if (!changed) exitCode = 2;
}

void _requireArgs(DeviceOptions o, int count, String message) {
  if (o.positional.length < count) throw StateError(message);
}

void _emitCalibration(DeviceOptions o, Calibration c) {
  _emit(
      o,
      {
        'window': c.window.toJson(),
        'deviceRect': {
          'x': c.deviceRect.left,
          'y': c.deviceRect.top,
          'w': c.deviceRect.width,
          'h': c.deviceRect.height,
        },
        'device': {'width': c.deviceWidth, 'height': c.deviceHeight},
      },
      '窗口：(${c.window.x}, ${c.window.y}) ${c.window.width}×${c.window.height}\n'
      '设备屏幕（窗口内）：(${c.deviceRect.left.toStringAsFixed(1)}, '
      '${c.deviceRect.top.toStringAsFixed(1)}) '
      '${c.deviceRect.width.toStringAsFixed(1)}×${c.deviceRect.height.toStringAsFixed(1)}\n'
      '设备分辨率：${c.deviceWidth}×${c.deviceHeight}');
}

/// 设备截图指纹（用于判断画面是否变化）。
///
/// [region] 是设备坐标（point）；内部换算成截图像素再裁剪。
Future<String> _fingerprint(
  Simctl simctl,
  String udid, {
  DRect? region,
  Calibration? calibration,
  int? pixelWidth,
}) async {
  final out = '${Directory.systemTemp.path}/w_tools_device_fp.png';
  await simctl.screenshot(udid, out);
  final bytes = File(out).readAsBytesSync();
  if (region == null || calibration == null || pixelWidth == null) {
    return ScreenFingerprint.of(bytes);
  }
  final scale = pixelWidth / calibration.deviceWidth; // 截图 px / 设备 point
  final px = DRect(
    region.left * scale,
    region.top * scale,
    region.width * scale,
    region.height * scale,
  );
  return ScreenFingerprint.ofRegion(bytes, region: px);
}

Stability _stability(
  Simctl simctl,
  String udid, {
  DRect? region,
  Calibration? calibration,
  int? pixelWidth,
}) =>
    Stability(
      grab: () => _fingerprint(
        simctl,
        udid,
        region: region,
        calibration: calibration,
        pixelWidth: pixelWidth,
      ),
    );

/// 拿标定（缓存命中且窗口没变就复用）。
Future<Calibration> _calibrate(
  Simctl simctl,
  DeviceOptions o, {
  bool force = false,
}) async {
  final udid = await _resolveUdid(simctl, o, bootedOnly: true);
  final store = CalibrationStore();
  final hub = DeviceHub();
  // 先把 DeviceHub 置前：别的窗口（有时是活动监视器）会盖住设备预览
  await hub.activate();
  final window = await hub.window();
  if (window == null) {
    throw StateError('读不到 DeviceHub 窗口：确认 DeviceHub 已打开，且宿主 App 有「辅助功能」权限');
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
  DeviceOptions o, {
  bool bootedOnly = false,
}) async {
  final devices = await simctl.devices();
  final target = Simctl.resolve(devices, o.deviceOrFirst, bootedOnly: bootedOnly);
  if (target == null) {
    throw StateError(bootedOnly ? '没有已启动的模拟器（先 device boot）' : '找不到模拟器');
  }
  return target.udid;
}
