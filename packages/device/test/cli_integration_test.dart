import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:test/test.dart';

/// 用 PATH 上的假 `xcrun` / `osascript` / `adb` / `screencapture` / `sips` /
/// `cliclick` 跑真实 CLI 进程，覆盖命令层行为（不碰真实设备）。
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
    File('${root.path}/adb.txt').writeAsStringSync(
        'List of devices attached\nSERIAL-1 device model:Pixel_5 transport_id:1\n');

    _exe(bin, 'osascript', r'''
#!/bin/sh
echo "osascript $*" >> "$W_TOOLS_FAKE_ROOT/calls.log"
case "$*" in
  *"System Events"*)
    [ "${FAKE_NO_WINDOW:-0}" = "1" ] && exit 1
    echo "100, 50, 872, 1084" ;;
esac
exit 0
''');
    _exe(bin, 'xcrun', r'''
#!/bin/sh
echo "xcrun $*" >> "$W_TOOLS_FAKE_ROOT/calls.log"
case "$1" in
  simctl)
    case "$2" in
      list) cat "$W_TOOLS_FAKE_ROOT/simctl.json" ;;
      io) cp "$W_TOOLS_FAKE_ROOT/screen.png" "$5" ;;
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
    _exe(bin, 'cliclick', '#!/bin/sh\nexit 0\n');
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

  void dispose() => root.deleteSync(recursive: true);
}

void main() {
  late _FakeEnv env;

  setUp(() async => env = await _FakeEnv.create());
  tearDown(() => env.dispose());

  test('list --json 带 schemaVersion / platform', () async {
    final r = await env.run(['list', '--json']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final json = jsonDecode('${r.stdout}'.trim()) as Map<String, dynamic>;
    expect(json['schemaVersion'], 1);
    expect(json['platform'], 'ios-simulator');
    expect(json['ok'], isTrue);
    expect((json['devices'] as List).length, 1);
  });

  test('shot --real 默认使用唯一临时文件', () async {
    final r = await env.run(['shot', '--real', '--device=PHONE', '--json']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final json = jsonDecode('${r.stdout}'.trim()) as Map<String, dynamic>;
    final path = json['path'] as String;
    expect(path, isNot('/tmp/device_real.png'));
    expect(path, contains('w_tools_device_real_shot'));
    expect(File(path).existsSync(), isTrue);
  });

  test('calibrate --json 明确坐标空间与两套 scale', () async {
    final r = await env.run(['calibrate', '--json']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final json = jsonDecode('${r.stdout}'.trim()) as Map<String, dynamic>;
    expect(json['coordinateSpace'], 'screen');
    expect(json['calibrationVersion'], 2);
    expect((json['window'] as Map)['scale'], 1);
    expect((json['screenshot'] as Map)['scale'], 3);
    expect((json['screenshot'] as Map)['windowScale'], 1);
  });

  test('缓存命中的 tap 不再激活 DeviceHub', () async {
    expect((await env.run(['calibrate'])).exitCode, 0);
    final before = 'activate'.allMatches(env.calls).length;
    expect((await env.run(['tap', '200', '840'])).exitCode, 0);
    expect((await env.run(['tap', '200', '840'])).exitCode, 0);
    expect('activate'.allMatches(env.calls).length, before);
  });

  test('wait --region 不需要 DeviceHub（osascript 窗口读取失败也能跑）', () async {
    final r = await env.run(
      ['wait', '--region=0,0,100,100', '--timeout-ms=3000', '--stable-ms=100'],
      extraEnv: {'FAKE_NO_WINDOW': '1'},
    );
    expect(r.exitCode, 0, reason: '${r.stderr}');
  });

  test('verify 画面不变 → exit 1', () async {
    expect((await env.run(['calibrate'])).exitCode, 0);
    final r = await env.run(
      ['verify', '200', '840', '--timeout-ms=3000', '--stable-ms=100', '--json'],
    );
    expect(r.exitCode, 1, reason: '${r.stderr}');
    final json = jsonDecode('${r.stdout}'.trim()) as Map<String, dynamic>;
    expect(json['changed'], isFalse);
    expect(json['platform'], 'ios-simulator');
  });

  test('drag 的 device 坐标是数字，且与 screen 分开', () async {
    expect((await env.run(['calibrate'])).exitCode, 0);
    final r = await env.run(['drag', '1', '2', '3', '4', '--json']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final json = jsonDecode('${r.stdout}'.trim()) as Map<String, dynamic>;
    final device = json['device'] as Map<String, dynamic>;
    expect((device['from'] as Map)['x'], 1);
    expect((device['to'] as Map)['y'], 4);
    expect(json['screen'], isNotNull);
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

  test('--device 型号子串命中多台 → exit 2', () async {
    File('${env.root.path}/adb.txt').writeAsStringSync(
      'List of devices attached\n'
      'SERIAL-A device model:Pixel_5 transport_id:1\n'
      'SERIAL-B device model:Pixel_5 transport_id:2\n',
    );

    final r = await env.run(['size', '--android', '--device=Pixel_5']);

    expect(r.exitCode, 2, reason: 'stdout=${r.stdout} stderr=${r.stderr}');
    expect('${r.stderr}', contains('SERIAL-A'));
    expect('${r.stderr}', contains('SERIAL-B'));
  });

  test('多台就绪 Android 时 --device 仍可精确选中', () async {
    File('${env.root.path}/adb.txt').writeAsStringSync(
      'List of devices attached\n'
      'SERIAL-A device model:Pixel_5 transport_id:1\n'
      'emulator-5554 device model:sdk_gphone64 transport_id:2\n',
    );

    final r = await env.run(['size', '--android', '--device=SERIAL-A', '--json']);

    expect(r.exitCode, 0, reason: 'stdout=${r.stdout} stderr=${r.stderr}');
    final json = jsonDecode('${r.stdout}'.trim()) as Map<String, dynamic>;
    expect(json['serial'], 'SERIAL-A');
  });

  test('size --android 优先 Override size', () async {
    final r = await env.run(['size', '--android', '--json']);
    expect(r.exitCode, 0, reason: 'stdout=${r.stdout} stderr=${r.stderr}');
    final json = jsonDecode('${r.stdout}'.trim()) as Map<String, dynamic>;
    expect(json['width'], 720);
    expect(json['height'], 1600);
  });
}
