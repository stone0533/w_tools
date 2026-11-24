import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:test/test.dart';

/// 用 PATH 上的假 `xcrun` / `osascript` / `adb` / `screencapture` / `sips` /
/// `cliclick` / `plutil` 跑真实 CLI 进程，覆盖命令层行为（不碰真实设备）。
class _FakeEnv {
  _FakeEnv(this.root, this.home, this.bin);

  final Directory root;
  final Directory home;
  final Directory bin;

  static Future<_FakeEnv> create() async {
    final root = Directory.systemTemp.createTempSync('w_tools_device_fake_');
    final home = Directory('${root.path}/home')..createSync();
    final bin = Directory('${root.path}/bin')..createSync();

    final window = img.Image(width: 872, height: 1084);
    img.fill(window, color: img.ColorRgb8(250, 250, 250));
    img.fillRect(window, x1: 340, y1: 60, x2: 780, y2: 1030, color: img.ColorRgb8(8, 8, 8));
    img.fillRect(window, x1: 350, y1: 70, x2: 770, y2: 1020, color: img.ColorRgb8(235, 235, 235));
    File('${root.path}/window.png').writeAsBytesSync(img.encodePng(window));

    final screen = img.Image(width: 1206, height: 2622);
    img.fill(screen, color: img.ColorRgb8(210, 210, 210));
    File('${root.path}/screen.png').writeAsBytesSync(img.encodePng(screen));

    // 「tap 后换一帧」：只在截图像素 y=1000..1300 变化，用来验证 region 的 point→px 换算。
    final changed = img.Image(width: 1206, height: 2622);
    img.fill(changed, color: img.ColorRgb8(210, 210, 210));
    img.fillRect(
      changed,
      x1: 0,
      y1: 1000,
      x2: 1205,
      y2: 1300,
      color: img.ColorRgb8(40, 160, 80),
    );
    File('${root.path}/screen_before.png').writeAsBytesSync(img.encodePng(screen));
    File('${root.path}/screen_after.png').writeAsBytesSync(img.encodePng(changed));

    File('${root.path}/simctl.json').writeAsStringSync('''
{"devices":{"com.apple.CoreSimulator.SimRuntime.iOS-26-4":[
  {"udid":"UDID-1","name":"iPhone 17 Pro","state":"Booted"}
]}}
''');
    File('${root.path}/devicectl.json').writeAsStringSync('''
{"result":{"devices":[
  {"identifier":"PHONE","hardwareProperties":{"udid":"PHONE-1","platform":"iOS"},
   "deviceProperties":{"name":"My iPhone","osVersionNumber":"27.0","bootState":"booted"},
   "connectionProperties":{"transportType":"wired","pairingState":"paired"}}
]}}
''');
    File('${root.path}/devicetypes.json').writeAsStringSync('''
{"devicetypes":[
 {"identifier":"com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro","name":"iPhone 17 Pro",
  "bundlePath":"/Fake/DeviceTypes/iPhone 17 Pro.simdevicetype"},
 {"identifier":"com.apple.CoreSimulator.SimDeviceType.iPad-mini-A17-Pro","name":"iPad mini (A17 Pro)",
  "bundlePath":"/Fake/DeviceTypes/iPad mini (A17 Pro).simdevicetype"}
]}
''');
    File('${root.path}/adb.txt').writeAsStringSync(
        'List of devices attached\nSERIAL-1 device model:Pixel_5 transport_id:1\n');

    _exe(bin, 'osascript', r'''
#!/bin/sh
echo "osascript $*" >> "$W_TOOLS_FAKE_ROOT/calls.log"
case "$*" in
  *"get name of window 1"*)
    [ "${FAKE_NO_TITLE:-0}" = "1" ] && exit 1
    echo "${FAKE_WINDOW_TITLE:-iPhone 17 Pro – iOS 26.5}" ;;
  *"System Events"*)
    [ "${FAKE_NO_WINDOW:-0}" = "1" ] && exit 1
    echo "100, 50, 872, 1084" ;;
esac
exit 0
''');
    _exe(bin, 'plutil', r'''
#!/bin/sh
echo "plutil $*" >> "$W_TOOLS_FAKE_ROOT/calls.log"
[ "${FAKE_NO_PLIST:-0}" = "1" ] && exit 1
case "$*" in
  *"UDID-1/device.plist"*)
    echo 'com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro' ;;
  *"UDID-IPAD/device.plist"*)
    echo 'com.apple.CoreSimulator.SimDeviceType.iPad-mini-A17-Pro' ;;
  *"iPhone 17 Pro.simdevicetype"*"capabilities.plist"*)
    echo '{"capabilities":{"ScreenDimensionsCapability":{"main-screen-width":1206,"main-screen-height":2622,"main-screen-scale":3}}}' ;;
  *"iPad mini (A17 Pro).simdevicetype"*"capabilities.plist"*)
    echo '{"capabilities":{"ScreenDimensionsCapability":{"main-screen-width":1488,"main-screen-height":2266,"main-screen-scale":2}}}' ;;
  *) exit 1 ;;
esac
''');
    _exe(bin, 'xcrun', r'''
#!/bin/sh
echo "xcrun $*" >> "$W_TOOLS_FAKE_ROOT/calls.log"
case "$1" in
  simctl)
    case "$2" in
      list)
        case "$3" in
          devicetypes)
            [ "${FAKE_NO_DEVICETYPES:-0}" = "1" ] && exit 1
            cat "$W_TOOLS_FAKE_ROOT/devicetypes.json" ;;
          *) cat "$W_TOOLS_FAKE_ROOT/simctl.json" ;;
        esac ;;
      io)
        if [ "${FAKE_SCREEN_CHANGES:-0}" = "1" ]; then
          if [ -f "$W_TOOLS_FAKE_ROOT/tapped" ]; then
            cp "$W_TOOLS_FAKE_ROOT/screen_after.png" "$5"
          else
            cp "$W_TOOLS_FAKE_ROOT/screen_before.png" "$5"
          fi
        else
          cp "$W_TOOLS_FAKE_ROOT/screen.png" "$5"
        fi ;;
      *) exit 0 ;;
    esac ;;
  devicectl)
    case "$2" in
      list) cp "$W_TOOLS_FAKE_ROOT/devicectl.json" "$5" ;;
      device) cp "$W_TOOLS_FAKE_ROOT/screen.png" "$8" ;;
      *) exit 0 ;;
    esac ;;
esac
exit 0
''');
    _exe(bin, 'adb', r'''
#!/bin/sh
echo "adb $*" >> "$W_TOOLS_FAKE_ROOT/calls.log"
[ "$1" = "-s" ] && shift 2
case "$1" in
  devices) cat "$W_TOOLS_FAKE_ROOT/adb.txt" ;;
  exec-out) cat "$W_TOOLS_FAKE_ROOT/screen.png" ;;
  shell)
    case "$2 $3" in
      "wm size") printf 'Physical size: 1080x2400\nOverride size: 720x1600\n' ;;
      "dumpsys window") echo 'mCurrentFocus=Window{1 u0 com.example.app/.MainActivity}' ;;
      *) exit 0 ;;
    esac ;;
esac
exit 0
''');
    _exe(bin, 'screencapture', r'''
#!/bin/sh
echo "screencapture $*" >> "$W_TOOLS_FAKE_ROOT/calls.log"
cp "$W_TOOLS_FAKE_ROOT/window.png" "$4"
''');
    _exe(bin, 'sips', r'''
#!/bin/sh
for last; do :; done
python3 - "$last" <<'PY'
import struct, sys
with open(sys.argv[1], 'rb') as f:
    f.read(16)
    w, h = struct.unpack('>II', f.read(8))
print(f'pixelWidth: {w}')
print(f'pixelHeight: {h}')
PY
''');
    _exe(bin, 'cliclick', r'''#!/bin/sh
echo "cliclick $*" >> "$W_TOOLS_FAKE_ROOT/calls.log"
if [ "${FAKE_RELEASE_FAIL:-0}" = "1" ] && [ "$*" = "du:." ]; then
  exit 1
fi
touch "$W_TOOLS_FAKE_ROOT/tapped"
exit 0
''');
    _exe(bin, 'swift', r'''#!/bin/sh
if [ "${FAKE_SWIFT_FAIL:-0}" = "1" ]; then
  echo "no swift" >&2
  exit 1
fi
if [ "${FAKE_MOUSE_DOWN:-0}" = "1" ]; then echo true; else echo false; fi
exit 0
''');
    _exe(bin, 'which', r'''#!/bin/sh
echo "$W_TOOLS_FAKE_ROOT/bin/cliclick"
''');
    return _FakeEnv(root, home, bin);
  }

  static void _exe(Directory bin, String name, String source) {
    final f = File('${bin.path}/$name')..writeAsStringSync(source);
    Process.runSync('chmod', ['+x', f.path]);
  }

  Map<String, String> get env => {
        ...Platform.environment,
        'PATH': '${bin.path}:${Platform.environment['PATH'] ?? ''}',
        'HOME': home.path,
        'W_TOOLS_FAKE_ROOT': root.path,
        'FAKE_NO_WINDOW': '0',
      };

  Future<ProcessResult> run(List<String> args, {Map<String, String>? extraEnv}) => Process.run(
        Platform.resolvedExecutable,
        <String>['run', 'bin/device.dart', ...args],
        workingDirectory: Directory.current.path,
        environment: {...env, ...?extraEnv},
      );

  String get calls => File('${root.path}/calls.log').existsSync()
      ? File('${root.path}/calls.log').readAsStringSync()
      : '';

  int countCalls(String needle) => needle.allMatches(calls).length;

  Map<String, dynamic> json(ProcessResult r) =>
      jsonDecode('${r.stdout}'.trim()) as Map<String, dynamic>;

  void dispose() => root.deleteSync(recursive: true);
}

void main() {
  late _FakeEnv env;

  setUp(() async => env = await _FakeEnv.create());
  tearDown(() => env.dispose());

  test('list --json 带 schemaVersion 2 / platform，且不再有 real 字段', () async {
    final r = await env.run(['list', '--json']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final json = env.json(r);
    expect(json['schemaVersion'], 2);
    expect(json['platform'], 'ios-simulator');
    expect(json['ok'], isTrue);
    expect(json.containsKey('real'), isFalse);
    expect((json['devices'] as List).length, 1);
  });

  test('list --android --json', () async {
    final r = await env.run(['list', '--android', '--json']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final json = env.json(r);
    expect(json['platform'], 'android');
    expect(((json['devices'] as List).single as Map)['serial'], 'SERIAL-1');
  });

  test('list 文本表：模拟器 / Android 都有表头与设备', () async {
    final sim = await env.run(['list']);
    expect('${sim.stdout}', contains('名称'));
    expect('${sim.stdout}', contains('UDID-1'));

    final android = await env.run(['list', '--android']);
    expect('${android.stdout}', contains('序列号'));
    expect('${android.stdout}', contains('SERIAL-1'));
  });

  test('boot：未启动设备调用 simctl boot / bootstatus', () async {
    File('${env.root.path}/simctl.json').writeAsStringSync('''
{"devices":{"R":[{"udid":"UDID-1","name":"iPhone 17 Pro","state":"Shutdown"}]}}
''');
    final r = await env.run(['boot', 'UDID-1', '--json']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect(env.calls, contains('simctl boot UDID-1'));
    expect(env.calls, contains('simctl bootstatus UDID-1 -b'));
    expect(env.json(r)['ready'], isTrue);
  });

  test('shot（模拟器）写唯一临时文件', () async {
    final r = await env.run(['shot', '--json']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final path = env.json(r)['path'] as String;
    expect(path, contains('w_tools_device_shot'));
    expect(File(path).existsSync(), isTrue);
  });

  test('shot --android 写 PNG', () async {
    final r = await env.run(['shot', '--android', '--json']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final path = env.json(r)['path'] as String;
    expect(path, contains('w_tools_device_android_shot'));
    expect(File(path).existsSync(), isTrue);
  });

  test('shot --real 默认使用唯一临时文件', () async {
    final r = await env.run(['shot', '--real', '--device=PHONE', '--json']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final json = env.json(r);
    final path = json['path'] as String;
    expect(path, contains('w_tools_device_real_shot'));
    expect(File(path).existsSync(), isTrue);
    expect(json['deviceId'], 'PHONE-1');
  });

  test('list --real --json：缺 transport 时不输出 "null"，state 回落 tunnelState', () async {
    File('${env.root.path}/devicectl.json').writeAsStringSync('''
{"result":{"devices":[
 {"hardwareProperties":{"udid":"PHONE-2","platform":"iOS"},
  "deviceProperties":{"name":"Lei 的 iPhone","osVersionNumber":"27.0"},
  "connectionProperties":{"pairingState":"paired","tunnelState":"unavailable"}}
]}}
''');
    final r = await env.run(['list', '--real', '--json']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final d = (env.json(r)['devices'] as List).single as Map<String, dynamic>;
    expect(d.containsKey('transport'), isFalse);
    expect(d['state'], 'unavailable');
    expect('${r.stdout}', isNot(contains('"null"')));
  });

  test('list --real 文本表用中文状态，JSON 保留 raw state', () async {
    final text = await env.run(['list', '--real']);
    expect('${text.stdout}', contains('已启动'));
    expect('${text.stdout}', isNot(contains('booted')));
    final json = env.json(await env.run(['list', '--real', '--json']));
    expect(((json['devices'] as List).single as Map)['state'], 'booted');
  });

  test('shot --real：只有 tunnelState=connected 时也算可用', () async {
    File('${env.root.path}/devicectl.json').writeAsStringSync('''
{"result":{"devices":[
 {"hardwareProperties":{"udid":"PHONE-3","platform":"iOS"},
  "deviceProperties":{"name":"Lei 的 iPad","osVersionNumber":"18.6"},
  "connectionProperties":{"transportType":"wired","pairingState":"paired","tunnelState":"connected"}}
]}}
''');
    final r = await env.run(['shot', '--real', '--device=PHONE-3', '--json']);
    expect(r.exitCode, 0, reason: 'stdout=${r.stdout} stderr=${r.stderr}');
  });

  test('shot --real 不可用设备：文案带 state，不出现空括号', () async {
    File('${env.root.path}/devicectl.json').writeAsStringSync('''
{"result":{"devices":[
 {"hardwareProperties":{"udid":"PHONE-2","platform":"iOS"},
  "deviceProperties":{"name":"Lei 的 iPhone","osVersionNumber":"27.0"},
  "connectionProperties":{"pairingState":"paired","tunnelState":"unavailable"}}
]}}
''');
    final r = await env.run(['shot', '--real', '--device=PHONE-2', '--json']);
    expect(r.exitCode, 3, reason: 'stdout=${r.stdout} stderr=${r.stderr}');
    final json = env.json(r);
    expect(json['error'], contains('state=unavailable'));
    expect(json['error'], isNot(contains('()')));
  });

  test('calibrate --json 用设备类型密度，坐标空间 / 两套 scale 分开', () async {
    final r = await env.run(['calibrate', '--json']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final json = env.json(r);
    expect(json['coordinateSpace'], 'screen');
    expect(json['calibrationVersion'], 2);
    expect((json['window'] as Map)['scale'], 1);
    expect((json['screenshot'] as Map)['scale'], 3);
    expect((json['screenshot'] as Map)['windowScale'], 1);
    expect((json['device'] as Map)['width'], 402);
    expect((json['device'] as Map)['height'], 874);
    expect(json['deviceId'], 'UDID-1');
    expect(json['windowTitle'], 'iPhone 17 Pro – iOS 26.5');
    // deviceRect 是屏幕坐标：必须落在窗口矩形内（窗口在 (100,50)）。
    final window = json['window'] as Map<String, dynamic>;
    final rect = json['deviceRect'] as Map<String, dynamic>;
    expect(rect['x'] as num, greaterThanOrEqualTo(window['x'] as num));
    expect(rect['y'] as num, greaterThanOrEqualTo(window['y'] as num));
    expect(
      (rect['x'] as num) + (rect['w'] as num),
      lessThanOrEqualTo((window['x'] as num) + (window['w'] as num)),
    );
    // 绝对值约束：fake 窗口里机身 bbox 从窗口内 x≈340 起，加上窗口原点应 ≈454；
    // 若 detect 漏掉窗口原点，这里只有 ≈354 —— 只断言「在 deviceRect 内」是自洽的、抓不到。
    expect(rect['x'] as num, greaterThan((window['x'] as num) + 300));
    expect(rect['x'] as num, lessThan((window['x'] as num) + 500));
  });

  test('tap 的 screen 坐标落在 deviceRect 内（窗口原点只加一次）', () async {
    final cal = env.json(await env.run(['calibrate', '--json']));
    final tap = env.json(await env.run(['tap', '201', '803', '--json']));
    final rect = cal['deviceRect'] as Map<String, dynamic>;
    final screen = tap['screen'] as Map<String, dynamic>;
    expect(
      screen['x'] as num,
      inInclusiveRange(rect['x'] as num, (rect['x'] as num) + (rect['w'] as num)),
    );
    expect(
      screen['y'] as num,
      inInclusiveRange(rect['y'] as num, (rect['y'] as num) + (rect['h'] as num)),
    );
  });

  test('Device Hub 显示的不是目标设备 → exit 3（不静默点错）', () async {
    final r = await env.run(
      ['calibrate', '--json'],
      extraEnv: {'FAKE_WINDOW_TITLE': 'iPhone 17 – iOS 26.2'},
    );
    expect(r.exitCode, 3, reason: 'stdout=${r.stdout} stderr=${r.stderr}');
    final json = env.json(r);
    expect(json['ok'], isFalse);
    expect(json['error'], contains('iPhone 17 Pro'));
    expect(json['error'], contains('iPhone 17 – iOS 26.2'));
  });

  test('窗口标题带 Simulator 后缀仍视为同一台设备', () async {
    final r = await env.run(
      ['calibrate', '--json'],
      extraEnv: {'FAKE_WINDOW_TITLE': 'iPhone 17 Pro Simulator – iOS 26.5'},
    );
    expect(r.exitCode, 0, reason: '${r.stderr}');
  });

  test('窗口标题是「更长的同名前缀」也算不一致（iPhone 17 Pro / Pro Max）', () async {
    final r = await env.run(
      ['calibrate', '--json'],
      extraEnv: {'FAKE_WINDOW_TITLE': 'iPhone 17 Pro Max – iOS 26.5'},
    );
    expect(r.exitCode, 3, reason: 'stdout=${r.stdout} stderr=${r.stderr}');
    expect(env.json(r)['error'], contains('iPhone 17 Pro Max'));
  });

  test('窗口标题读不到时跳过校验（兼容未来 Xcode）', () async {
    final r = await env.run(['calibrate', '--json'], extraEnv: {'FAKE_NO_TITLE': '1'});
    expect(r.exitCode, 0, reason: '${r.stderr}');
  });

  test('每次 tap 都重新标定（没有缓存，不会静默点偏）', () async {
    expect((await env.run(['calibrate'])).exitCode, 0);
    final before = env.countCalls('screencapture');
    expect((await env.run(['tap', '200', '840'])).exitCode, 0);
    expect((await env.run(['tap', '200', '840'])).exitCode, 0);
    expect(env.countCalls('screencapture'), before + 2);
  });

  test('tap 默认先释放宿主左键（du:.）再点', () async {
    final r = await env.run(['tap', '200', '840']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect(env.calls, contains('cliclick du:. c:'));
  });

  test('--no-release-mouse 关闭 tap 的预释放', () async {
    final r = await env.run(['tap', '200', '840', '--no-release-mouse']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect(env.calls, contains('cliclick c:'));
    expect(env.calls, isNot(contains('cliclick du:. c:')));
  });

  test('verify：point region 覆盖变化带 → changed:true，regionPixels 已换算', () async {
    final r = await env.run(
      [
        'verify',
        '200',
        '840',
        '--region=0,333,402,100',
        '--timeout-ms=3000',
        '--stable-ms=100',
        '--json',
      ],
      extraEnv: {'FAKE_SCREEN_CHANGES': '1'},
    );
    expect(r.exitCode, 0, reason: 'stdout=${r.stdout} stderr=${r.stderr}');
    final json = env.json(r);
    expect(json['changed'], isTrue);
    // 有变化时不带排查提示。
    expect(json.containsKey('hint'), isFalse);
    expect((json['region'] as Map)['y'], 333.0);
    final px = json['regionPixels'] as Map<String, dynamic>;
    expect(px['y'], 999.0);
    expect(px['w'], 1206.0);
    expect(px['h'], 300.0);
  });

  test('verify：point region 未覆盖变化带 → changed:false（换算丢失会判反）', () async {
    final r = await env.run(
      [
        'verify',
        '200',
        '840',
        '--region=0,700,402,100',
        '--timeout-ms=3000',
        '--stable-ms=100',
        '--json',
      ],
      extraEnv: {'FAKE_SCREEN_CHANGES': '1'},
    );
    expect(r.exitCode, 1, reason: 'stdout=${r.stdout} stderr=${r.stderr}');
    final json = env.json(r);
    expect(json['changed'], isFalse);
    final px = json['regionPixels'] as Map<String, dynamic>;
    expect(px['y'], 2100.0);
  });

  test('wait --region 不需要 DeviceHub，JSON 给出换算后的 regionPixels', () async {
    final r = await env.run(
      [
        'wait',
        '--region=0,100,402,240',
        '--timeout-ms=3000',
        '--stable-ms=100',
        '--json',
      ],
      extraEnv: {'FAKE_NO_WINDOW': '1'},
    );
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final json = env.json(r);
    expect(json['stable'], isTrue);
    expect((json['region'] as Map)['y'], 100.0);
    final px = json['regionPixels'] as Map<String, dynamic>;
    expect(px['x'], 0.0);
    expect(px['y'], 300.0);
    expect(px['w'], 1206.0);
    expect(px['h'], 720.0);
  });

  test('wait 超时 → exit 3 且 ok:false（不是成功）', () async {
    final r = await env.run(
      ['wait', '--timeout-ms=300', '--stable-ms=600', '--json'],
    );
    expect(r.exitCode, 3, reason: 'stdout=${r.stdout} stderr=${r.stderr}');
    final json = env.json(r);
    expect(json['ok'], isFalse);
    expect(json['stable'], isFalse);
  });

  test('verify 画面不变 → exit 1，但 ok 仍是 true（findings）', () async {
    expect((await env.run(['calibrate'])).exitCode, 0);
    final r = await env.run(
      ['verify', '200', '840', '--timeout-ms=3000', '--stable-ms=100', '--json'],
    );
    expect(r.exitCode, 1, reason: '${r.stderr}');
    final json = env.json(r);
    expect(json['changed'], isFalse);
    expect(json['ok'], isTrue);
    expect(json['platform'], 'ios-simulator');
    // 没变化时给出「宿主左键可能卡住」的排查项；探针结果 false 时不会尝试释放。
    expect(json['hint'], contains('左键'));
    expect(json['mouseButtonDown'], isFalse);
    expect(json.containsKey('releasedMouse'), isFalse);
  });

  test('verify 没变化 + 左键卡住 → 探针命中并尝试释放', () async {
    expect((await env.run(['calibrate'])).exitCode, 0);
    final r = await env.run(
      ['verify', '200', '840', '--timeout-ms=3000', '--stable-ms=100', '--json'],
      extraEnv: {'FAKE_MOUSE_DOWN': '1'},
    );
    expect(r.exitCode, 1, reason: '${r.stderr}');
    final json = env.json(r);
    expect(json['changed'], isFalse);
    expect(json['mouseButtonDown'], isTrue);
    expect(json['releasedMouse'], isTrue);
    expect(json['hint'], contains('已在当前位置释放'));
    expect(env.calls, contains('cliclick du:.'));
  });

  test('verify 左键卡住且释放失败 → 报释放失败，不假装已释放', () async {
    expect((await env.run(['calibrate'])).exitCode, 0);
    final r = await env.run(
      ['verify', '200', '840', '--timeout-ms=3000', '--stable-ms=100', '--json'],
      extraEnv: {'FAKE_MOUSE_DOWN': '1', 'FAKE_RELEASE_FAIL': '1'},
    );
    expect(r.exitCode, 1, reason: '${r.stderr}');
    final json = env.json(r);
    expect(json['mouseButtonDown'], isTrue);
    expect(json.containsKey('releasedMouse'), isFalse);
    expect(json['hint'], contains('自动释放失败'));
  });

  test('--no-release-mouse：verify 失败也不自动释放', () async {
    expect((await env.run(['calibrate'])).exitCode, 0);
    final r = await env.run(
      [
        'verify',
        '200',
        '840',
        '--no-release-mouse',
        '--timeout-ms=3000',
        '--stable-ms=100',
        '--json',
      ],
      extraEnv: {'FAKE_MOUSE_DOWN': '1'},
    );
    expect(r.exitCode, 1, reason: '${r.stderr}');
    final json = env.json(r);
    expect(json['mouseButtonDown'], isTrue);
    expect(json.containsKey('releasedMouse'), isFalse);
    expect(json['hint'], contains('已禁用自动释放'));
    expect(env.calls, isNot(contains('cliclick du:.')));
  });

  test('swift 不可用 → 探针字段省略，仍给 hint', () async {
    expect((await env.run(['calibrate'])).exitCode, 0);
    final r = await env.run(
      ['verify', '200', '840', '--timeout-ms=3000', '--stable-ms=100', '--json'],
      extraEnv: {'FAKE_SWIFT_FAIL': '1'},
    );
    expect(r.exitCode, 1, reason: '${r.stderr}');
    final json = env.json(r);
    expect(json.containsKey('mouseButtonDown'), isFalse);
    expect(json.containsKey('releasedMouse'), isFalse);
    expect(json['hint'], contains('左键'));
  });

  test('drag 默认先释放（du:. 与 dd: 同一次调用）', () async {
    final r = await env.run(['drag', '1', '2', '3', '4']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect(env.calls, contains('cliclick du:. dd:'));
  });

  test('drag 的 device 坐标是数字，且与 screen 分开', () async {
    expect((await env.run(['calibrate'])).exitCode, 0);
    final r = await env.run(['drag', '1', '2', '3', '4', '--json']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final json = env.json(r);
    final device = json['device'] as Map<String, dynamic>;
    expect((device['from'] as Map)['x'], 1);
    expect((device['to'] as Map)['y'], 4);
    expect(json['screen'], isNotNull);
  });

  test('size --json 使用设备类型密度，不猜', () async {
    final r = await env.run(['size', '--json']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final json = env.json(r);
    expect(json['width'], 402);
    expect(json['height'], 874);
    expect(json['pixelWidth'], 1206);
    expect(json['scale'], 3);
    expect(json['scaleSource'], 'deviceType');
  });

  test('iPad mini：identifier → bundlePath 映射得到真实 scale 2 / 744×1133', () async {
    File('${env.root.path}/simctl.json').writeAsStringSync('''
{"devices":{"R":[{"udid":"UDID-IPAD","name":"iPad mini (A17 Pro)","state":"Booted"}]}}
''');
    final r = await env.run(['size', '--json']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final json = env.json(r);
    expect(json['scaleSource'], 'deviceType');
    expect(json['scale'], 2);
    expect(json['pixelWidth'], 1488);
    expect(json['width'], 744);
    expect(json['height'], 1133);
  });

  test('plist 不可用时 size 回退，并标明 scaleSource / scaleReason', () async {
    final r = await env.run(
      ['size', '--json'],
      extraEnv: {'FAKE_NO_PLIST': '1'},
    );
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final json = env.json(r);
    expect(json['scaleSource'], 'fallback');
    expect(json['scaleReason'], 'no-device-type');
    expect(json['scale'], 3);
    expect(json['width'], 402);
  });

  test('devicetypes 不可用时 size 回退，scaleReason=no-devicetypes', () async {
    final r = await env.run(
      ['size', '--json'],
      extraEnv: {'FAKE_NO_DEVICETYPES': '1'},
    );
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final json = env.json(r);
    expect(json['scaleSource'], 'fallback');
    expect(json['scaleReason'], 'no-devicetypes');
  });

  test('iOS 子串命中多台 → exit 2 并列出候选（不静默取第一台）', () async {
    File('${env.root.path}/simctl.json').writeAsStringSync('''
{"devices":{"R":[
  {"udid":"UDID-1","name":"iPhone 17 Pro","state":"Booted"},
  {"udid":"UDID-2","name":"iPhone 17","state":"Booted"}
]}}
''');
    final r = await env.run(['size', '--device=iPhone']);
    expect(r.exitCode, 2, reason: 'stdout=${r.stdout} stderr=${r.stderr}');
    expect('${r.stderr}', contains('UDID-1'));
    expect('${r.stderr}', contains('UDID-2'));
  });

  test('指定未启动的模拟器 → exit 3 且明确说「未启动」', () async {
    File('${env.root.path}/simctl.json').writeAsStringSync('''
{"devices":{"R":[
  {"udid":"UDID-1","name":"iPhone 17 Pro","state":"Booted"},
  {"udid":"UDID-2","name":"iPhone 17","state":"Shutdown"}
]}}
''');
    final r = await env.run(['tap', '1', '2', '--device=UDID-2']);
    expect(r.exitCode, 3, reason: 'stdout=${r.stdout} stderr=${r.stderr}');
    expect('${r.stderr}', contains('未启动'));
    expect('${r.stderr}', contains('UDID-2'));
  });

  test('多台就绪 Android 且未指定 --device → exit 2 并列出设备', () async {
    File('${env.root.path}/adb.txt').writeAsStringSync(
      'List of devices attached\n'
      'SERIAL-A device model:Pixel_5 transport_id:1\n'
      'emulator-5554 device model:sdk_gphone64 transport_id:2\n',
    );

    final r = await env.run(['size', '--android']);

    expect(r.exitCode, 2, reason: 'stdout=${r.stdout} stderr=${r.stderr}');
    expect('${r.stderr}', contains('SERIAL-A'));
    expect('${r.stderr}', contains('emulator-5554'));
    expect('${r.stderr}', contains('--device'));
  });

  test('多台就绪 Android 时 --device 仍可精确选中', () async {
    File('${env.root.path}/adb.txt').writeAsStringSync(
      'List of devices attached\n'
      'SERIAL-A device model:Pixel_5 transport_id:1\n'
      'emulator-5554 device model:sdk_gphone64 transport_id:2\n',
    );

    final r = await env.run(['size', '--android', '--device=SERIAL-A', '--json']);

    expect(r.exitCode, 0, reason: 'stdout=${r.stdout} stderr=${r.stderr}');
    expect(env.json(r)['deviceId'], 'SERIAL-A');
  });

  test('size --android 优先 Override size', () async {
    final r = await env.run(['size', '--android', '--json']);
    expect(r.exitCode, 0, reason: 'stdout=${r.stdout} stderr=${r.stderr}');
    final json = env.json(r);
    expect(json['width'], 720);
    expect(json['height'], 1600);
  });

  test('Android drag 不再发 legacy from/to / screen / serial', () async {
    final r = await env.run(['drag', '--android', '1', '2', '3', '4', '--json']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final json = env.json(r);
    expect(json.containsKey('from'), isFalse);
    expect(json['screen'], isNull);
    expect(json['serial'], isNull);
    expect(json['deviceId'], 'SERIAL-1');
    expect((json['device'] as Map)['from'], isNotNull);
  });

  test('foreground --android', () async {
    final r = await env.run(['foreground', '--android', '--json']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect(env.json(r)['package'], 'com.example.app');
  });

  test('参数错误的 JSON 也带 platform（--android 时为 android）', () async {
    final r = await env.run(['size', '--android', '--json', '--bogus']);
    expect(r.exitCode, 2);
    expect(env.json(r)['platform'], 'android');
  });
}
