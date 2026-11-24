part of 'device_cli.dart';

Future<String> _androidSerial(DeviceRuntime rt, DeviceOptions o) async {
  final devices = await rt.adb.devices();
  final matches = Adb.readyMatches(devices, o.deviceQuery);
  if (matches.isEmpty) {
    final query = o.deviceQuery ?? '';
    final suffix = query.isEmpty ? '' : '，未找到：$query';
    throw DeviceCliException(
      '没有就绪的 Android 设备（检查数据线 / 调试授权：adb devices -l）$suffix',
      3,
    );
  }
  if (matches.length > 1) {
    final list = matches.map((d) => '  ${d.serial}  ${d.model}').join('\n');
    final query = o.deviceQuery ?? '';
    final hint = query.isEmpty
        ? '检测到 ${matches.length} 台就绪的 Android 设备，请用 --device=<serial|model> 指定：'
        : '匹配到 ${matches.length} 台 Android 设备，请用 --device=<serial> 精确指定：';
    throw DeviceCliException('$hint\n$list', 2);
  }
  return matches.single.serial;
}

Future<void> _androidList(DeviceRuntime rt, DeviceOptions o) async {
  final devices = await rt.adb.devices();
  _emit(
    rt,
    o,
    {
      'devices': [for (final d in devices) d.toJson()],
    },
    _androidTable(devices),
  );
}

String _androidTable(List<AndroidDevice> devices) {
  if (devices.isEmpty) return '（没有 Android 设备）';
  final b = StringBuffer('状态\t型号\t序列号\n');
  for (final d in devices) {
    b.writeln('${d.state}\t${d.model}\t${d.serial}');
  }
  return b.toString().trimRight();
}

Future<void> _androidShot(DeviceRuntime rt, DeviceOptions o) async {
  final serial = await _androidSerial(rt, o);
  final out = o.out ?? tempPath('w_tools_device_android_shot', 'png');
  await rt.adb.screenshot(serial, out);
  _emit(rt, o, {'path': out, 'deviceId': serial}, out);
}

Future<void> _androidTap(DeviceRuntime rt, DeviceOptions o) async {
  final serial = await _androidSerial(rt, o);
  final x = int.parse(o.positional[0]);
  final y = int.parse(o.positional[1]);
  await rt.adb.tap(serial, x, y);
  _emit(
    rt,
    o,
    {
      'device': {'x': x, 'y': y},
      'deviceId': serial,
    },
    'tap $x, $y（像素）',
  );
}

Future<void> _androidDrag(DeviceRuntime rt, DeviceOptions o) async {
  final serial = await _androidSerial(rt, o);
  final v = o.positional.map(int.parse).toList();
  await rt.adb.swipe(serial, v[0], v[1], v[2], v[3]);
  _emit(
    rt,
    o,
    {
      'device': {
        'from': {'x': v[0], 'y': v[1]},
        'to': {'x': v[2], 'y': v[3]},
      },
      'deviceId': serial,
    },
    'swipe ${v[0]},${v[1]} → ${v[2]},${v[3]}（像素）',
  );
}

Future<void> _androidSize(DeviceRuntime rt, DeviceOptions o) async {
  final serial = await _androidSerial(rt, o);
  final (width, height) = await rt.adb.screenSize(serial);
  _emit(
    rt,
    o,
    {
      'width': width,
      'height': height,
      'deviceId': serial,
    },
    '$width x $height（像素）',
  );
}

Future<void> _androidForeground(DeviceRuntime rt, DeviceOptions o) async {
  final serial = await _androidSerial(rt, o);
  final pkg = await rt.adb.currentPackage(serial);
  if (pkg.isEmpty) {
    throw const DeviceCliException('取不到 Android 前台包名（设备可能锁屏 / 无 Activity）', 3);
  }
  _emit(
    rt,
    o,
    {'package': pkg, 'deviceId': serial},
    pkg,
  );
}

Stability _androidStability(DeviceRuntime rt, String serial, {DRect? region}) => Stability(
      grab: () => _androidFingerprint(rt, serial, region: region),
    );

/// 直接在内存里对截图像素做指纹：不落盘（一次 wait 可能采样几十帧）。
Future<String> _androidFingerprint(
  DeviceRuntime rt,
  String serial, {
  DRect? region,
}) async {
  final bytes = await rt.adb.screenshotBytes(serial);
  return region == null
      ? ScreenFingerprint.of(bytes)
      : ScreenFingerprint.ofRegion(bytes, region: region);
}

Future<void> _androidWait(DeviceRuntime rt, DeviceOptions o) async {
  final serial = await _androidSerial(rt, o);
  final ok = await _androidStability(rt, serial, region: o.region).waitStable(
    stableFor: o.stableFor,
    timeout: o.timeout,
  );
  _emit(
    rt,
    o,
    {'stable': ok, 'deviceId': serial},
    ok ? '画面已稳定' : '等待超时（画面仍在变化）',
    ok: ok,
  );
  if (!ok) exitCode = 3;
}

Future<void> _androidVerify(DeviceRuntime rt, DeviceOptions o) async {
  final serial = await _androidSerial(rt, o);
  final x = int.parse(o.positional[0]);
  final y = int.parse(o.positional[1]);
  final changed = await TapVerifier.verify(
    stability: _androidStability(rt, serial, region: o.region),
    fingerprint: () => _androidFingerprint(rt, serial, region: o.region),
    tap: () => rt.adb.tap(serial, x, y),
    stableFor: o.stableFor,
    timeout: o.timeout,
  );
  _emit(
    rt,
    o,
    {
      'changed': changed,
      'device': {'x': x, 'y': y},
      'deviceId': serial,
      'region': regionJson(o.region),
    },
    'tap $x, $y（像素）：${changed ? '画面有变化 ✅' : '画面无变化 ⚠️（坐标可能失效）'}',
  );
  if (!changed) exitCode = 1;
}
