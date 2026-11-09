part of 'device_cli.dart';

Future<String> _androidSerial(DeviceOptions o) async {
  final devices = await _deps.adb().devices();
  final query = o.deviceQuery;
  final target = Adb.resolve(devices, query);
  if (target == null) {
    final suffix = query == null || query.isEmpty ? '' : '，未找到：$query';
    throw DeviceCliException(
      '没有就绪的 Android 设备（检查数据线 / 调试授权：adb devices -l）$suffix',
      3,
    );
  }
  return target.serial;
}

Future<void> _androidList(DeviceOptions o) async {
  final devices = await _deps.adb().devices();
  if (o.json) {
    _emit(
        o,
        {
          'android': true,
          'devices': [for (final d in devices) d.toJson()],
        },
        '');
    return;
  }
  if (devices.isEmpty) {
    _deps.write('（没有 Android 设备）\n');
    return;
  }
  final b = StringBuffer('状态\t型号\t序列号\n');
  for (final d in devices) {
    b.writeln('${d.state}\t${d.model}\t${d.serial}');
  }
  _deps.write('${b.toString().trimRight()}\n');
}

Future<void> _androidShot(DeviceOptions o) async {
  final serial = await _androidSerial(o);
  final out = o.out ?? _tempFile('w_tools_device_android_shot', 'png');
  await _deps.adb().screenshot(serial, out);
  final dark = ScreenStats.isMostlyDark(File(out).readAsBytesSync());
  _emit(
    o,
    {
      'path': out,
      'serial': serial,
      'deviceId': serial,
      'android': true,
      if (dark) 'warning': '截图几乎全黑：设备可能息屏/锁屏，请点亮解锁后重试',
    },
    dark ? '$out\n⚠️ 截图几乎全黑：设备可能息屏/锁屏' : out,
  );
}

Future<void> _androidTap(DeviceOptions o) async {
  final serial = await _androidSerial(o);
  final x = int.parse(o.positional[0]);
  final y = int.parse(o.positional[1]);
  await _deps.adb().tap(serial, x, y);
  _emit(
      o,
      {
        'device': {'x': x, 'y': y},
        'serial': serial,
        'deviceId': serial,
      },
      'tap $x, $y（像素）');
}

Future<void> _androidDrag(DeviceOptions o) async {
  final serial = await _androidSerial(o);
  final v = o.positional.map(int.parse).toList();
  await _deps.adb().swipe(serial, v[0], v[1], v[2], v[3]);
  final coords = {
    'from': {'x': v[0], 'y': v[1]},
    'to': {'x': v[2], 'y': v[3]},
  };
  _emit(
      o,
      {
        // 兼容旧 key；新脚本用 device/screen（Android 两者都是截图像素）。
        ...coords,
        'device': coords,
        'screen': coords,
        'serial': serial,
        'deviceId': serial,
      },
      'swipe ${v[0]},${v[1]} → ${v[2]},${v[3]}（像素）');
}

Stability _androidStability(Adb adb, String serial, {DRect? region}) => Stability(
      grab: () => _androidFingerprint(adb, serial, region: region),
    );

Future<String> _androidFingerprint(Adb adb, String serial, {DRect? region}) async {
  final out = _tempFile('w_tools_device_fp_android', 'png');
  try {
    await adb.screenshot(serial, out);
    final bytes = File(out).readAsBytesSync();
    return region == null
        ? ScreenFingerprint.of(bytes)
        : ScreenFingerprint.ofRegion(bytes, region: region);
  } finally {
    final file = File(out);
    if (file.existsSync()) file.deleteSync();
  }
}

Future<void> _androidWait(DeviceOptions o) async {
  final serial = await _androidSerial(o);
  final adb = _deps.adb();
  final ok = await _androidStability(adb, serial, region: o.region).waitStable(
    stableFor: o.stableFor,
    timeout: o.timeout,
  );
  _emit(o, {'stable': ok, 'serial': serial, 'deviceId': serial}, ok ? '画面已稳定' : '等待超时（画面仍在变化）');
  if (!ok) exitCode = 3;
}

Future<void> _androidVerify(DeviceOptions o) async {
  final serial = await _androidSerial(o);
  final adb = _deps.adb();
  final x = int.parse(o.positional[0]);
  final y = int.parse(o.positional[1]);
  final changed = await TapVerifier.verify(
    stability: _androidStability(adb, serial, region: o.region),
    fingerprint: () => _androidFingerprint(adb, serial, region: o.region),
    tap: () => adb.tap(serial, x, y),
    stableFor: o.stableFor,
    timeout: o.timeout,
  );
  _emit(
      o,
      {
        'changed': changed,
        'device': {'x': x, 'y': y},
        'serial': serial,
        'deviceId': serial,
        'region': o.region == null
            ? null
            : {
                'x': o.region!.left,
                'y': o.region!.top,
                'w': o.region!.width,
                'h': o.region!.height,
              },
      },
      'tap $x, $y（像素）：${changed ? '画面有变化 ✅' : '画面无变化 ⚠️（坐标可能失效）'}');
  if (!changed) exitCode = 1;
}
