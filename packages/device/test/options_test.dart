import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:test/test.dart';
import 'package:w_tools_device/w_tools_device.dart';

void main() {
  group('DeviceOptions.parse（CLI 参数）', () {
    test('默认值', () {
      final o = DeviceOptions.parse([]);
      expect(o.command, 'list');
      expect(o.json, isFalse);
      expect(o.real, isFalse);
      expect(o.region, isNull);
      expect(o.timeout, const Duration(seconds: 15));
      expect(o.stableFor, const Duration(milliseconds: 600));
    });

    test('命令与位置参数', () {
      final o = DeviceOptions.parse(['tap', '121', '821']);
      expect(o.command, 'tap');
      expect(o.positional, ['121', '821']);
    });

    test('--json / --real / --device / --out', () {
      final o = DeviceOptions.parse(
        ['shot', '--json', '--real', '--device=ABC', '--out=/tmp/a.png'],
      );
      expect(o.json, isTrue);
      expect(o.real, isTrue);
      expect(o.device, 'ABC');
      expect(o.out, '/tmp/a.png');
    });

    test('--region 解析成矩形（设备坐标）', () {
      final o = DeviceOptions.parse(['verify', '1', '2', '--region=0,40,402,80']);
      expect(o.region!.left, 0);
      expect(o.region!.top, 40);
      expect(o.region!.width, 402);
      expect(o.region!.height, 80);
    });

    test('--region 缺参数 / 非数字 → 明确报错', () {
      expect(
        () => DeviceOptions.parse(['verify', '1', '2', '--region=1,2,3']),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('x,y,w,h'))),
      );
      expect(
        () => DeviceOptions.parse(['verify', '1', '2', '--region=a,b,c,d']),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('数字'))),
      );
    });

    test('未知选项 → StateError（CLI 里转成友好提示 + exit 1）', () {
      expect(
        () => DeviceOptions.parse(['tap', '1', '2', '--bogus']),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('--bogus'))),
      );
    });

    test('--timeout-ms / --stable-ms / --scale', () {
      final o = DeviceOptions.parse(
        ['wait', '--timeout-ms=5000', '--stable-ms=200', '--scale=2'],
      );
      expect(o.timeout, const Duration(seconds: 5));
      expect(o.stableFor, const Duration(milliseconds: 200));
      expect(o.scale, 2);
    });
  });

  group('Devicectl.parseDevices（真机列表）', () {
    // devicectl 会把模拟器也列出来（transportType=sameMachine），必须过滤掉
    const json = '''
{"result":{"devices":[
 {"identifier":"PHONE","hardwareProperties":{"udid":"00008101-AAA","platform":"iOS"},
  "deviceProperties":{"name":"My iPhone","osVersionNumber":"27.0","bootState":"booted"},
  "connectionProperties":{"transportType":"wired","pairingState":"paired"}},
 {"identifier":"SIM","hardwareProperties":{"udid":"SIM-1","platform":"iOS"},
  "deviceProperties":{"name":"iPhone 17 Pro","osVersionNumber":"26.4","bootState":"booted"},
  "connectionProperties":{"transportType":"sameMachine","pairingState":"paired"}},
 {"identifier":"SIM2","hardwareProperties":{"udid":"SIM-2","platform":"simulator"},
  "deviceProperties":{"name":"iPad","osVersionNumber":"17.5","bootState":"shutdown"},
  "connectionProperties":{"transportType":"localNetwork","pairingState":"paired"}}
]}}
''';

    test('过滤掉模拟器（sameMachine / platform=simulator）', () {
      final list = Devicectl.parseDevices(json);
      expect(list.length, 1);
      expect(list.single.udid, '00008101-AAA');
      expect(list.single.name, 'My iPhone');
      expect(list.single.transport, 'wired');
      expect(list.single.paired, isTrue);
    });

    test('坏 JSON / 缺字段不抛', () {
      expect(Devicectl.parseDevices('nope'), isEmpty);
      expect(Devicectl.parseDevices('{}'), isEmpty);
      expect(Devicectl.parseDevices('{"result":{"devices":[{"foo":1}]}}'), isEmpty);
    });

    test('按 udid / 名称 / 子串挑设备', () {
      final list = Devicectl.parseDevices(json);
      expect(Devicectl.resolve(list, '00008101-AAA')!.name, 'My iPhone');
      expect(Devicectl.resolve(list, 'my iphone')!.udid, '00008101-AAA');
      expect(Devicectl.resolve(list, null)!.udid, '00008101-AAA');
      expect(Devicectl.resolve(list, 'nope'), isNull);
      expect(Devicectl.resolve(const [], null), isNull);
    });
  });

  group('Adb（Android）', () {
    test('解析 adb devices -l', () {
      const text = '''List of devices attached
0B241FDD4008T1         device usb:1179648X product:redfin model:Pixel_5 device:redfin transport_id:7
emulator-5554          offline transport_id:3

''';
      final list = Adb.parseDevices(text);
      expect(list.length, 2);
      expect(list.first.serial, '0B241FDD4008T1');
      expect(list.first.model, 'Pixel_5');
      expect(list.first.isReady, isTrue);
      expect(list.last.isReady, isFalse);
    });

    test('resolve 只挑就绪设备', () {
      const text = 'List of devices attached\nAAA offline\nBBB device model:Pixel_5\n';
      final list = Adb.parseDevices(text);
      expect(Adb.resolve(list, null)!.serial, 'BBB');
      expect(Adb.resolve(list, 'AAA')!.serial, 'AAA');
      expect(Adb.resolve(list, 'pixel')!.serial, 'BBB');
      expect(Adb.resolve(const [], null), isNull);
    });

    test('前台包名：优先 mCurrentFocus，回落 topResumedActivity', () {
      const withFocus = '''
  mCurrentFocus=Window{46d41f6 u0 com.android.settings/com.android.settings.SubSettings}
  mFocusedApp=ActivityRecord{5700d8b u0 com.android.settings/.SubSettings t2099}
''';
      expect(Adb.parseCurrentPackage(withFocus), 'com.android.settings');

      const onlyResumed = '''
  topResumedActivity=ActivityRecord{5700d8b u0 hk.ureward.app/.MainActivity t1}
''';
      expect(Adb.parseCurrentPackage(onlyResumed), 'hk.ureward.app');
      expect(Adb.parseCurrentPackage(''), isEmpty);
    });
  });

  group('ScreenStats（真机锁屏会返回全黑图）', () {
    Uint8List solid(int r, int g, int b) {
      final image = img.Image(width: 40, height: 40);
      img.fill(image, color: img.ColorRgb8(r, g, b));
      return Uint8List.fromList(img.encodePng(image));
    }

    test('全黑 → true；普通内容 → false', () {
      expect(ScreenStats.isMostlyDark(solid(0, 0, 0)), isTrue);
      expect(ScreenStats.isMostlyDark(solid(250, 250, 250)), isFalse);
      expect(ScreenStats.isMostlyDark(solid(120, 30, 200)), isFalse);
    });
  });
}
