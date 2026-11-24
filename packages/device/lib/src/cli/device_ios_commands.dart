part of 'device_cli.dart';

Future<void> _list(DeviceRuntime rt, DeviceOptions o) async {
  switch (o.platform) {
    case DevicePlatform.android:
      await _androidList(rt, o);
    case DevicePlatform.iosDevice:
      await _realList(rt, o);
    case DevicePlatform.iosSimulator:
      await _simList(rt, o);
  }
}

Future<void> _simList(DeviceRuntime rt, DeviceOptions o) async {
  final devices = await rt.simctl.devices();
  _emit(
    rt,
    o,
    {
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
    _simTable(devices),
  );
}

String _simTable(List<SimDevice> devices) {
  if (devices.isEmpty) return '（没有模拟器）';
  final b = StringBuffer('状态\t运行时\tUDID\t名称\n');
  for (final d in devices) {
    b.writeln('${d.state}\t${d.runtimeLabel}\t${d.udid}\t${d.name}');
  }
  return b.toString().trimRight();
}

Future<void> _realList(DeviceRuntime rt, DeviceOptions o) async {
  final devices = await rt.devicectl.devices();
  _emit(
    rt,
    o,
    {
      'devices': [for (final d in devices) d.toJson()]
    },
    _realTable(devices),
  );
}

String _realTable(List<RealDevice> devices) {
  if (devices.isEmpty) return '（没有物理设备；确认已用数据线连接并信任）';
  final b = StringBuffer('状态\t系统\t连接\tUDID\t名称\n');
  for (final d in devices) {
    b.writeln(
      '${RealDevice.stateLabel(d.state)}\t${d.osVersion}\t${d.transport ?? '-'}\t${d.udid}\t${d.name}',
    );
  }
  return b.toString().trimRight();
}

Future<void> _boot(DeviceRuntime rt, DeviceOptions o) async {
  final target = await _resolveSim(
    rt,
    o,
    bootedOnly: false,
    query: o.deviceQuery ?? o.positional.firstOrNull,
  );
  if (!target.isBooted) {
    if (!o.json) rt.write('启动 ${target.name} (${target.udid}) ...\n');
    await rt.simctl.boot(target.udid);
  }
  _emit(
    rt,
    o,
    {
      'udid': target.udid,
      'deviceId': target.udid,
      'name': target.name,
      'ready': true,
    },
    '已就绪：${target.name} (${target.udid})',
  );
}

Future<void> _shot(DeviceRuntime rt, DeviceOptions o) async {
  switch (o.platform) {
    case DevicePlatform.android:
      await _androidShot(rt, o);
    case DevicePlatform.iosDevice:
      await _realShot(rt, o);
    case DevicePlatform.iosSimulator:
      await _simShot(rt, o);
  }
}

Future<void> _simShot(DeviceRuntime rt, DeviceOptions o) async {
  final udid = (await _resolveSim(rt, o, bootedOnly: true)).udid;
  final out = o.out ?? tempPath('w_tools_device_shot', 'png');
  await rt.simctl.screenshot(udid, out);
  _emit(
    rt,
    o,
    {'path': out, 'deviceId': udid},
    out,
  );
}

Future<void> _realShot(DeviceRuntime rt, DeviceOptions o) async {
  final query = o.deviceQuery ?? o.positional.firstOrNull;
  final devices = await rt.devicectl.devices();
  final matches = Devicectl.matches(devices, query);
  if (matches.isEmpty) {
    throw const DeviceCliException(
      '找不到真机（先 device list --real；确认已连接并信任）',
      3,
    );
  }
  if (matches.length > 1) {
    final list = matches.map((d) => '  ${d.udid}  ${d.name}').join('\n');
    throw DeviceCliException('匹配到 ${matches.length} 台真机，请用 --device=<udid> 精确指定：\n$list', 2);
  }
  final target = matches.single;
  if (!target.isUsable) {
    throw DeviceCliException(
      '真机不可用（state=${target.state}）：请确认已连接、解锁并信任本机'
      '（${target.name} / ${target.udid}）',
      3,
    );
  }
  final out = o.out ?? tempPath('w_tools_device_real_shot', 'png');
  await rt.devicectl.screenshot(target.udid, out);
  // 锁屏/息屏时 devicectl 会返回全黑图 —— 明确提示，别让人以为截图坏了。
  // 只有真机需要这条：模拟器 / Android 的深色界面是正常内容。
  final dark = ScreenStats.isMostlyDark(File(out).readAsBytesSync());
  const warning = '截图几乎全黑：真机可能锁屏/息屏，请点亮并解锁后重试';
  _emit(
    rt,
    o,
    {
      'path': out,
      'deviceId': target.udid,
      if (dark) 'warning': warning,
    },
    dark ? '$out\n⚠️ $warning' : out,
  );
}

Future<void> _tap(DeviceRuntime rt, DeviceOptions o) async {
  await _requireCliclick(rt);
  final x = double.parse(o.positional[0]);
  final y = double.parse(o.positional[1]);
  final target = await _resolveSim(rt, o, bootedOnly: true);
  final cal = await _calibrate(rt, target);
  final screen = cal.toScreen(DPoint(x, y));
  await rt.input.tap(screen.x, screen.y, releaseFirst: !o.noReleaseMouse);
  _emit(
    rt,
    o,
    {
      'device': {'x': x, 'y': y},
      'screen': {'x': screen.x, 'y': screen.y},
      'deviceId': target.udid,
    },
    'tap device($x, $y) → screen(${screen.x.round()}, ${screen.y.round()})',
  );
}

Future<void> _drag(DeviceRuntime rt, DeviceOptions o) async {
  await _requireCliclick(rt);
  final target = await _resolveSim(rt, o, bootedOnly: true);
  final cal = await _calibrate(rt, target);
  final x1 = double.parse(o.positional[0]);
  final y1 = double.parse(o.positional[1]);
  final x2 = double.parse(o.positional[2]);
  final y2 = double.parse(o.positional[3]);
  final a = cal.toScreen(DPoint(x1, y1));
  final b = cal.toScreen(DPoint(x2, y2));
  await rt.input.drag(a.x, a.y, b.x, b.y, releaseFirst: !o.noReleaseMouse);
  _emit(
    rt,
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
      'deviceId': target.udid,
    },
    'drag screen(${a.x.round()},${a.y.round()}) → (${b.x.round()},${b.y.round()})',
  );
}

Future<void> _simSize(DeviceRuntime rt, DeviceOptions o) async {
  final udid = (await _resolveSim(rt, o, bootedOnly: true)).udid;
  final metrics = await rt.simctl.metrics(udid);
  final fallback = metrics.source == 'fallback'
      ? '，回退估算${metrics.reason == null ? '' : '（${metrics.reason}）'}'
      : '';
  _emit(
    rt,
    o,
    {
      'width': metrics.pointWidth,
      'height': metrics.pointHeight,
      'pixelWidth': metrics.pixelWidth,
      'pixelHeight': metrics.pixelHeight,
      'scale': metrics.scale,
      'scaleSource': metrics.source,
      if (metrics.reason != null) 'scaleReason': metrics.reason,
      'deviceId': udid,
    },
    '${metrics.pointWidth} x ${metrics.pointHeight}（point；截图 '
    '${metrics.pixelWidth}×${metrics.pixelHeight} px，scale ${metrics.scale}$fallback）',
  );
}

Future<void> _wait(DeviceRuntime rt, DeviceOptions o) async {
  final target = await _resolveSim(rt, o, bootedOnly: true);
  final region = await _regionInPixels(rt, target, o.region);
  final ok = await _stability(rt, target.udid, region: region).waitStable(
    stableFor: o.stableFor,
    timeout: o.timeout,
  );
  _emit(
    rt,
    o,
    {
      'stable': ok,
      'deviceId': target.udid,
      'region': regionJson(o.region),
      'regionPixels': regionJson(region),
    },
    ok ? '画面已稳定' : '等待超时（画面仍在变化）',
    ok: ok,
  );
  if (!ok) exitCode = 3;
}

Future<void> _verify(DeviceRuntime rt, DeviceOptions o) async {
  await _requireCliclick(rt);
  final x = double.parse(o.positional[0]);
  final y = double.parse(o.positional[1]);
  final target = await _resolveSim(rt, o, bootedOnly: true);
  final cal = await _calibrate(rt, target);
  final screen = cal.toScreen(DPoint(x, y));
  // `--region` 与 tap 同坐标系（point）；指纹按截图 px 取，这里换算一次。
  final region = o.region?.scaled(cal.screenshotScale);
  final changed = await TapVerifier.verify(
    stability: _stability(rt, target.udid, region: region),
    fingerprint: () => _fingerprint(rt, target.udid, region: region),
    tap: () => rt.input.tap(
      screen.x,
      screen.y,
      releaseFirst: !o.noReleaseMouse,
    ),
    stableFor: o.stableFor,
    timeout: o.timeout,
  );
  // 没变化时探一下宿主左键：它是「所有点击都静默失效」最常见、也最难猜的原因。
  bool? mouseDown;
  var released = false;
  if (!changed) {
    mouseDown = await rt.input.mouseButtonDown();
    if (mouseDown == true && !o.noReleaseMouse) {
      released = await rt.input.release();
    }
  }
  final hint = !changed
      ? released
          ? _mouseReleasedHint
          : mouseDown == true
              ? o.noReleaseMouse
                  ? _mouseNoReleaseHint
                  : _mouseReleaseFailedHint
              : _mouseStuckHint
      : null;
  _emit(
    rt,
    o,
    {
      'changed': changed,
      'device': {'x': x, 'y': y},
      'screen': {'x': screen.x, 'y': screen.y},
      'deviceId': target.udid,
      'region': regionJson(o.region),
      'regionPixels': regionJson(region),
      if (mouseDown != null) 'mouseButtonDown': mouseDown,
      if (released) 'releasedMouse': true,
      if (hint != null) 'hint': hint,
    },
    'tap device($x, $y) → screen(${screen.x.round()}, ${screen.y.round()})：'
    '${changed ? '画面有变化 ✅' : '画面无变化 ⚠️（坐标可能失效）\n$hint'}',
  );
  if (!changed) exitCode = 1;
}

/// `verify` 没变化时给一条成本最低的排查项：宿主左键卡住时所有点击都会静默失效。
const _mouseStuckHint = '若所有点击都无效，先检查宿主左键是否卡在按下状态（模拟器可能表现为长按/抖动）：'
    '执行 `cliclick du:.` 释放后重试。';

const _mouseReleasedHint = '检测到宿主左键处于按下状态，已在当前位置释放；请重试本次点击。';

const _mouseReleaseFailedHint = '检测到宿主左键处于按下状态，但自动释放失败；请手动执行 `cliclick du:.` 后重试。';

const _mouseNoReleaseHint = '检测到宿主左键处于按下状态；--no-release-mouse 已禁用自动释放，'
    '请手动执行 `cliclick du:.` 后重试。';

/// `--region` 与 tap 同坐标系（iOS = point）；`wait` 不需要标定，但仍需要密度换算。
Future<DRect?> _regionInPixels(
  DeviceRuntime rt,
  SimDevice target,
  DRect? region,
) async {
  if (region == null) return null;
  final metrics = await rt.simctl.metrics(target.udid);
  return region.scaled(metrics.scale.toDouble());
}

String _calibrationText(Calibration c) =>
    '窗口：(${c.window.x}, ${c.window.y}) ${c.window.width}×${c.window.height}\n'
    '${c.windowTitle == null ? '' : '窗口标题：${c.windowTitle}\n'}'
    '设备屏幕（屏幕坐标）：(${c.deviceRect.left.toStringAsFixed(1)}, '
    '${c.deviceRect.top.toStringAsFixed(1)}) '
    '${c.deviceRect.width.toStringAsFixed(1)}×${c.deviceRect.height.toStringAsFixed(1)}\n'
    '设备分辨率：${c.deviceWidth}×${c.deviceHeight}';

/// 设备截图指纹（用于判断画面是否变化）。
///
/// [region] 已在调用处换算成**截图像素**（`--region` 对外与 tap 同坐标系）。
Future<String> _fingerprint(DeviceRuntime rt, String udid, {DRect? region}) =>
    withTempFile('w_tools_device_fp', 'png', (path) async {
      await rt.simctl.screenshot(udid, path);
      final bytes = File(path).readAsBytesSync();
      return region == null
          ? ScreenFingerprint.of(bytes)
          : ScreenFingerprint.ofRegion(bytes, region: region);
    });

Stability _stability(DeviceRuntime rt, String udid, {DRect? region}) => Stability(
      grab: () => _fingerprint(rt, udid, region: region),
    );

/// 现场标定（不缓存）：缓存会在 DeviceHub 缩放 / 侧栏布局变化后静默点偏，
/// 而省下的那一步还不如一次坐标错误的代价大。
///
/// 标定前核对窗口标题：Device Hub 只显示一台设备，窗口里选错设备时
/// `--device` 会被静默忽略（后续点击落到另一台）。
Future<Calibration> _calibrate(DeviceRuntime rt, SimDevice target) async {
  final window = await rt.deviceHub.window();
  if (window == null) {
    throw const DeviceCliException(
      '读不到 DeviceHub 窗口：确认 DeviceHub 已打开，且宿主 App 有「辅助功能」权限',
      3,
    );
  }
  final title = await rt.deviceHub.title();
  if (title != null && !_windowTitleMatches(title, target.name)) {
    throw DeviceCliException(
      'Device Hub 当前显示的是「$title」，与 --device 指定的「${target.name}」不一致；'
      '请先在 Device Hub 里选中目标设备后重试。',
      3,
    );
  }
  final metrics = await rt.simctl.metrics(target.udid);
  return withTempFile('w_tools_device_hub', 'png', (path) async {
    final scale = await rt.deviceHub.capture(window, path);
    final image = img.decodePng(File(path).readAsBytesSync());
    if (image == null) {
      throw DeviceCliException('窗口截图解码失败：$path', 3);
    }
    try {
      return const CalibrationDetector().detect(
        image: image,
        window: window,
        scale: scale,
        deviceWidth: metrics.pointWidth,
        deviceHeight: metrics.pointHeight,
        screenshotWidth: metrics.pixelWidth,
        screenshotHeight: metrics.pixelHeight,
        deviceScale: metrics.scale,
        windowTitle: title,
      );
    } on StateError catch (e) {
      throw DeviceCliException(e.message, 3);
    }
  });
}

/// 窗口标题形如 `iPhone 17 Pro – iOS 26.5`（部分 Xcode 会写成
/// `iPhone 17 Pro Simulator – iOS 26.5`）。
///
/// 要求名称后面是分隔符、`Simulator` / `模拟器` 后缀或结尾，避免
/// `iPhone 17 Pro` 误配 `iPhone 17 Pro Max` 这种「更长的同名前缀」。
bool _windowTitleMatches(String title, String name) {
  final index = title.indexOf(name);
  if (index < 0) return false;
  var rest = title.substring(index + name.length);
  if (rest.isEmpty) return true;
  final separator = RegExp(r'^\s*[–\-—(（]');
  if (separator.hasMatch(rest)) return true;
  rest = rest.trimLeft();
  for (final suffix in const <String>['Simulator', '模拟器']) {
    if (rest.toLowerCase().startsWith(suffix.toLowerCase())) {
      final after = rest.substring(suffix.length).trimLeft();
      return after.isEmpty || separator.hasMatch(after);
    }
  }
  return false;
}

/// 解析唯一模拟器；多台命中直接报歧义，不静默取第一台。
Future<SimDevice> _resolveSim(
  DeviceRuntime rt,
  DeviceOptions o, {
  required bool bootedOnly,
  String? query,
}) async {
  final q = query ?? o.deviceQuery;
  final devices = await rt.simctl.devices();
  final matches = Simctl.matches(devices, q, bootedOnly: bootedOnly);
  if (matches.isEmpty) {
    // 设备存在但没启动时，不要报「找不到」把排障引到名字写错上。
    if (bootedOnly) {
      final existing = Simctl.matches(devices, q);
      if (existing.isNotEmpty) {
        final list = existing.map((d) => '${d.name} (${d.udid}, ${d.state})').join('；');
        throw DeviceCliException('模拟器存在但未启动：$list（先 device boot）', 3);
      }
    }
    if (q != null && q.isNotEmpty) {
      throw DeviceCliException('找不到匹配的模拟器：$q（先 device list 确认）', 3);
    }
    throw DeviceCliException(
      bootedOnly ? '没有已启动的模拟器（先 device boot）' : '找不到模拟器',
      3,
    );
  }
  if (matches.length > 1) {
    final list = matches.map((d) => '  ${d.udid}  ${d.name}').join('\n');
    throw DeviceCliException('匹配到 ${matches.length} 台模拟器，请用 --device=<udid|名称> 精确指定：\n$list', 2);
  }
  return matches.single;
}

Future<void> _requireCliclick(DeviceRuntime rt) async {
  if (!await rt.input.available()) {
    throw const DeviceCliException('找不到 cliclick；先 brew install cliclick（iOS 模拟器点击依赖它）', 3);
  }
}
