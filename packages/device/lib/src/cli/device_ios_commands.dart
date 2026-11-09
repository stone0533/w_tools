part of 'device_cli.dart';

Future<void> _list(DeviceOptions o, Simctl simctl) async {
  if (o.real) {
    final devices = await _deps.devicectl().devices();
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
  final query = o.deviceQuery ?? o.positional.firstOrNull;
  final target = Simctl.resolve(devices, query);
  if (target == null) {
    throw DeviceCliException('找不到模拟器：${query ?? '（没有可用模拟器）'}', 3);
  }
  if (!target.isBooted) {
    if (!o.json) _deps.write('启动 ${target.name} (${target.udid}) ...\n');
    await simctl.boot(target.udid);
  }
  _emit(
      o,
      {
        'udid': target.udid,
        'deviceId': target.udid,
        'name': target.name,
        'ready': true,
      },
      '已就绪：${target.name} (${target.udid})');
}

Future<void> _shot(Simctl simctl, DeviceOptions o) async {
  if (o.real) {
    final devices = await _deps.devicectl().devices();
    final query = o.deviceQuery ?? o.positional.firstOrNull;
    final target = Devicectl.resolve(devices, query);
    if (target == null) {
      throw const DeviceCliException(
        '找不到真机（先 device list --real；确认已连接并信任）',
        3,
      );
    }
    if (!target.isBooted) {
      throw DeviceCliException('真机未启动/未解锁：${target.name} (${target.bootState})', 3);
    }
    final out = o.out ?? _tempFile('w_tools_device_real_shot', 'png');
    await _deps.devicectl().screenshot(target.udid, out);
    // 锁屏/息屏时 devicectl 会返回全黑图 —— 明确提示，别让人以为截图坏了
    final dark = ScreenStats.isMostlyDark(File(out).readAsBytesSync());
    _emit(
      o,
      {
        'path': out,
        'udid': target.udid,
        'deviceId': target.udid,
        'real': true,
        if (dark) 'warning': '截图几乎全黑：真机可能锁屏/息屏，请点亮并解锁后重试',
      },
      dark ? '$out\n⚠️ 截图几乎全黑：真机可能锁屏/息屏，请点亮并解锁后重试' : out,
    );
    return;
  }
  final udid = await _resolveUdid(simctl, o, bootedOnly: true);
  final out = o.out ?? _tempFile('w_tools_device_shot', 'png');
  await simctl.screenshot(udid, out);
  final dark = ScreenStats.isMostlyDark(File(out).readAsBytesSync());
  _emit(
    o,
    {
      'path': out,
      'udid': udid,
      'deviceId': udid,
      'real': false,
      if (dark) 'warning': '截图几乎全黑：模拟器可能未显示内容',
    },
    dark ? '$out\n⚠️ 截图几乎全黑：模拟器可能未显示内容' : out,
  );
}

Future<void> _tap(Simctl simctl, DeviceOptions o) async {
  await _requireCliclick();
  final x = double.parse(o.positional[0]);
  final y = double.parse(o.positional[1]);
  final udid = await _resolveUdid(simctl, o, bootedOnly: true);
  final cal = await _calibrate(simctl, o, udid, force: o.noCache);
  final screen = cal.toScreen(DPoint(x, y));
  await _deps.input().tap(screen.x, screen.y);
  _emit(
      o,
      {
        'device': {'x': x, 'y': y},
        'screen': {'x': screen.x, 'y': screen.y},
        'deviceId': udid,
      },
      'tap device($x, $y) → screen(${screen.x.round()}, ${screen.y.round()})');
}

Future<void> _drag(Simctl simctl, DeviceOptions o) async {
  await _requireCliclick();
  final udid = await _resolveUdid(simctl, o, bootedOnly: true);
  final cal = await _calibrate(simctl, o, udid, force: o.noCache);
  final x1 = double.parse(o.positional[0]);
  final y1 = double.parse(o.positional[1]);
  final x2 = double.parse(o.positional[2]);
  final y2 = double.parse(o.positional[3]);
  final a = cal.toScreen(DPoint(x1, y1));
  final b = cal.toScreen(DPoint(x2, y2));
  await _deps.input().drag(a.x, a.y, b.x, b.y);
  _emit(
      o,
      {
        'device': {
          'from': {'x': x1, 'y': y1},
          'to': {'x': x2, 'y': y2},
        },
        'screen': {
          'from': {'x': a.x, 'y': a.y},
          'to': {'x': b.x, 'y': b.y},
        },
        'deviceId': udid,
      },
      'drag screen(${a.x.round()},${a.y.round()}) → (${b.x.round()},${b.y.round()})');
}

Future<void> _wait(Simctl simctl, DeviceOptions o) async {
  final udid = await _resolveUdid(simctl, o, bootedOnly: true);
  int? deviceWidth;
  int? pixelWidth;
  if (o.region != null) {
    // wait 只需要「截图 px / 设备 point」的比例；不需要 DeviceHub 标定。
    final size = await simctl.screenshotSize(udid);
    pixelWidth = size.$1;
    final deviceScale = o.scale ?? Simctl.guessScale(size.$1);
    deviceWidth = size.$1 ~/ deviceScale;
  }
  final ok = await _stability(
    simctl,
    udid,
    region: o.region,
    deviceWidth: deviceWidth,
    pixelWidth: pixelWidth,
  ).waitStable(
    stableFor: o.stableFor,
    timeout: o.timeout,
  );
  _emit(o, {'stable': ok, 'deviceId': udid}, ok ? '画面已稳定' : '等待超时（画面仍在变化）');
  if (!ok) exitCode = 3;
}

Future<void> _verify(Simctl simctl, DeviceOptions o) async {
  await _requireCliclick();
  final x = double.parse(o.positional[0]);
  final y = double.parse(o.positional[1]);
  final udid = await _resolveUdid(simctl, o, bootedOnly: true);
  final cal = await _calibrate(simctl, o, udid, force: o.noCache);
  final screen = cal.toScreen(DPoint(x, y));
  final pixelWidth =
      cal.screenshotWidth > 0 ? cal.screenshotWidth : (await simctl.screenshotSize(udid)).$1;
  final changed = await TapVerifier.verify(
    stability: _stability(
      simctl,
      udid,
      region: o.region,
      deviceWidth: cal.deviceWidth,
      pixelWidth: pixelWidth,
    ),
    fingerprint: () => _fingerprint(
      simctl,
      udid,
      region: o.region,
      deviceWidth: cal.deviceWidth,
      pixelWidth: pixelWidth,
    ),
    tap: () => _deps.input().tap(screen.x, screen.y),
    stableFor: o.stableFor,
    timeout: o.timeout,
  );
  _emit(
      o,
      {
        'changed': changed,
        'device': {'x': x, 'y': y},
        'screen': {'x': screen.x, 'y': screen.y},
        'deviceId': udid,
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
  if (!changed) exitCode = 1;
}

void _emitCalibration(DeviceOptions o, Calibration c, {String? deviceId}) {
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
        'screenshot': {
          'width': c.screenshotWidth,
          'height': c.screenshotHeight,
          'scale': c.scale,
        },
        if (deviceId != null) 'deviceId': deviceId,
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
  int? deviceWidth,
  int? pixelWidth,
}) async {
  final out = _tempFile('w_tools_device_fp', 'png');
  try {
    await simctl.screenshot(udid, out);
    final bytes = File(out).readAsBytesSync();
    if (region == null || deviceWidth == null || pixelWidth == null) {
      return ScreenFingerprint.of(bytes);
    }
    final scale = pixelWidth / deviceWidth; // 截图 px / 设备 point
    final px = DRect(
      region.left * scale,
      region.top * scale,
      region.width * scale,
      region.height * scale,
    );
    return ScreenFingerprint.ofRegion(bytes, region: px);
  } finally {
    final file = File(out);
    if (file.existsSync()) file.deleteSync();
  }
}

Stability _stability(
  Simctl simctl,
  String udid, {
  DRect? region,
  int? deviceWidth,
  int? pixelWidth,
}) =>
    Stability(
      grab: () => _fingerprint(
        simctl,
        udid,
        region: region,
        deviceWidth: deviceWidth,
        pixelWidth: pixelWidth,
      ),
    );

/// 拿标定（缓存命中且窗口没变就复用）。
///
/// 缓存命中路径不激活 DeviceHub、不截图：只有真正需要重算时才 capture（内部会 activate）。
Future<Calibration> _calibrate(
  Simctl simctl,
  DeviceOptions o,
  String udid, {
  bool force = false,
}) async {
  final store = _deps.calibrationStore();
  final hub = _deps.deviceHub();
  final window = await hub.window();
  if (window == null) {
    throw const DeviceCliException(
      '读不到 DeviceHub 窗口：确认 DeviceHub 已打开，且宿主 App 有「辅助功能」权限',
      3,
    );
  }
  // 先取当前设备分辨率：尺寸 / 方向 / --scale 变化时旧标定必须失效，
  // 否则 deviceRect 会把点击换算到错误位置（旧实现只比对窗口，查不出旋转）。
  final size = await simctl.screenshotSize(udid);
  final deviceScale = o.scale ?? Simctl.guessScale(size.$1);
  final points = (size.$1 ~/ deviceScale, size.$2 ~/ deviceScale);

  if (!force) {
    final cached = store.load(udid);
    if (CalibrationStore.isFreshCalibration(
      cached,
      window,
      deviceWidth: points.$1,
      deviceHeight: points.$2,
    )) {
      return cached!;
    }
  }

  final shot = _tempFile('w_tools_device_hub', 'png');
  try {
    final scale = await hub.capture(window, shot);
    final image = img.decodePng(File(shot).readAsBytesSync());
    if (image == null) {
      throw DeviceCliException('窗口截图解码失败：$shot', 3);
    }
    final Calibration cal;
    try {
      cal = const CalibrationDetector().detect(
        image: image,
        window: window,
        scale: scale,
        deviceWidth: points.$1,
        deviceHeight: points.$2,
        screenshotWidth: size.$1,
        screenshotHeight: size.$2,
      );
    } on StateError catch (e) {
      throw DeviceCliException(e.message, 3);
    }
    store.save(udid, cal);
    return cal;
  } finally {
    final file = File(shot);
    if (file.existsSync()) file.deleteSync();
  }
}

Future<String> _resolveUdid(
  Simctl simctl,
  DeviceOptions o, {
  bool bootedOnly = false,
}) async {
  final devices = await simctl.devices();
  final query = o.deviceQuery;
  final target = Simctl.resolve(devices, query, bootedOnly: bootedOnly);
  if (target == null) {
    if (query != null && query.isNotEmpty) {
      throw DeviceCliException('找不到匹配的模拟器：$query（先 device list 确认）', 3);
    }
    throw DeviceCliException(
      bootedOnly ? '没有已启动的模拟器（先 device boot）' : '找不到模拟器',
      3,
    );
  }
  return target.udid;
}
