import 'package:test/test.dart';
import 'package:w_tools_device/src/options.dart';

void main() {
  group('DeviceOptions.parse（CLI 参数）', () {
    test('默认值', () {
      final o = DeviceOptions.parse([]);
      expect(o.command, 'list');
      expect(o.json, isFalse);
      expect(o.platform, DevicePlatform.iosSimulator);
      expect(o.region, isNull);
      expect(o.timeout, const Duration(seconds: 15));
      expect(o.stableFor, const Duration(milliseconds: 600));
    });

    test('命令与位置参数', () {
      final o = DeviceOptions.parse(['tap', '121', '821']);
      expect(o.command, 'tap');
      expect(o.positional, ['121', '821']);
    });

    test('--real / --android 推导三态平台，且互斥', () {
      expect(DeviceOptions.parse(['shot', '--real']).platform, DevicePlatform.iosDevice);
      expect(DeviceOptions.parse(['size', '--android']).platform, DevicePlatform.android);
      expect(DeviceOptions.parse(['list']).platform, DevicePlatform.iosSimulator);
      expect(
        () => DeviceOptions.parse(['shot', '--real', '--android']),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('不能同时'))),
      );
    });

    test('--json / --device / --out', () {
      final o = DeviceOptions.parse(
        ['shot', '--json', '--real', '--device=ABC', '--out=/tmp/a.png'],
      );
      expect(o.json, isTrue);
      expect(o.real, isTrue);
      expect(o.deviceQuery, 'ABC');
      expect(o.out, '/tmp/a.png');
    });

    test('值选项统一支持空格与等号写法', () {
      final o = DeviceOptions.parse(<String>[
        'verify',
        '1',
        '2',
        '--device',
        'iPhone 17 Pro',
        '--region',
        '0,0,10,10',
        '--timeout-ms',
        '5000',
        '--stable-ms',
        '200',
      ]);
      expect(o.deviceQuery, 'iPhone 17 Pro');
      expect(o.region!.width, 10);
      expect(o.timeout, const Duration(seconds: 5));
      expect(o.stableFor, const Duration(milliseconds: 200));
    });

    test('--region 是截图像素矩形', () {
      final o = DeviceOptions.parse(['verify', '1', '2', '--region=0,40,402,80']);
      expect(o.region!.left, 0);
      expect(o.region!.top, 40);
      expect(o.region!.width, 402);
      expect(o.region!.height, 80);
    });

    test('--region 缺参数 / 非数字 / 零宽 → 明确报错', () {
      expect(
        () => DeviceOptions.parse(['verify', '1', '2', '--region=1,2,3']),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('x,y,w,h'))),
      );
      expect(
        () => DeviceOptions.parse(['verify', '1', '2', '--region=a,b,c,d']),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('数字'))),
      );
      expect(() => DeviceOptions.parse(['verify', '1', '2', '--region=1,2,0,3']), throwsStateError);
    });

    test('空值 / 缺值 / flag 带值 → 明确报错', () {
      expect(() => DeviceOptions.parse(['tap', '1', '2', '--device=']), throwsStateError);
      expect(() => DeviceOptions.parse(['shot', '--out=']), throwsStateError);
      expect(() => DeviceOptions.parse(['shot', '--device']), throwsStateError);
      expect(() => DeviceOptions.parse(['wait', '--timeout-ms']), throwsStateError);
      expect(() => DeviceOptions.parse(['list', '--json=1']), throwsStateError);
    });

    test('已删除的选项（--scale / --no-cache）现在是未知选项', () {
      expect(
        () => DeviceOptions.parse(['tap', '1', '2', '--bogus']),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('--bogus'))),
      );
      expect(() => DeviceOptions.parse(['tap', '1', '2', '--scale=3']), throwsStateError);
      expect(() => DeviceOptions.parse(['tap', '1', '2', '--no-cache']), throwsStateError);
    });

    test('--no-release-mouse：默认 false，只用于 iOS 的 tap / drag / verify', () {
      expect(DeviceOptions.parse(['tap', '1', '2']).noReleaseMouse, isFalse);
      final o = DeviceOptions.parse(['tap', '1', '2', '--no-release-mouse']);
      expect(o.noReleaseMouse, isTrue);
      expect(() => o.validate(), returnsNormally);
      expect(
        () => DeviceOptions.parse(['drag', '1', '2', '3', '4', '--no-release-mouse']).validate(),
        returnsNormally,
      );
      expect(
        () => DeviceOptions.parse(['verify', '1', '2', '--no-release-mouse']).validate(),
        returnsNormally,
      );
      // 平台 / 命令亲和性
      expect(
        () => DeviceOptions.parse(['tap', '1', '2', '--android', '--no-release-mouse']).validate(),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('iOS 模拟器'))),
      );
      expect(
          () => DeviceOptions.parse(['wait', '--no-release-mouse']).validate(), throwsStateError);
      expect(
          () => DeviceOptions.parse(['size', '--no-release-mouse']).validate(), throwsStateError);
    });
  });

  group('DeviceOptions.validate（命令表驱动）', () {
    test('平台表：只支持模拟器 / Android 的命令拒绝真机', () {
      expect(
        () => DeviceOptions.parse(['boot', '--real']).validate(),
        throwsA(
          isA<StateError>()
              .having((e) => e.message, 'message', contains('boot'))
              .having((e) => e.message, 'message', contains('iOS 真机')),
        ),
      );
      expect(() => DeviceOptions.parse(['tap', '1', '2', '--real']).validate(), throwsStateError);
      expect(() => DeviceOptions.parse(['size', '--real']).validate(), throwsStateError);
      expect(() => DeviceOptions.parse(['wait', '--real']).validate(), throwsStateError);
      expect(() => DeviceOptions.parse(['foreground']).validate(), throwsStateError);
      expect(() => DeviceOptions.parse(['foreground', '--android']).validate(), returnsNormally);
      expect(() => DeviceOptions.parse(['list', '--real']).validate(), returnsNormally);
      expect(() => DeviceOptions.parse(['shot', '--android']).validate(), returnsNormally);
    });

    test('位置参数个数：多传 / 少传都报错', () {
      expect(
        () => DeviceOptions.parse(['tap', '1']).validate(),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('<x> <y>'))),
      );
      expect(() => DeviceOptions.parse(['tap', '1', '2', '3']).validate(), throwsStateError);
      expect(() => DeviceOptions.parse(['list', 'x']).validate(), throwsStateError);
      expect(() => DeviceOptions.parse(['verify']).validate(), throwsStateError);
      expect(() => DeviceOptions.parse(['shot', 'x']).validate(), throwsStateError);
      expect(() => DeviceOptions.parse(['shot', '--real', 'device']).validate(), returnsNormally);
      expect(() => DeviceOptions.parse(['boot', 'iPhone']).validate(), returnsNormally);
    });

    test('选项亲和性来自同一张命令表', () {
      expect(
        () => DeviceOptions.parse(['tap', '1', '2', '--timeout-ms=100']).validate(),
        throwsA(
          isA<StateError>()
              .having((e) => e.message, 'message', contains('--timeout-ms'))
              .having((e) => e.message, 'message', contains('wait')),
        ),
      );
      expect(() => DeviceOptions.parse(['tap', '1', '2', '--region=0,0,1,1']).validate(),
          throwsStateError);
      expect(() => DeviceOptions.parse(['shot', '--region=0,0,1,1']).validate(), throwsStateError);
      expect(() => DeviceOptions.parse(['size', '--out=/tmp/a.png']).validate(), throwsStateError);
      expect(
        () => DeviceOptions.parse(['list', '--device=ABC']).validate(),
        throwsA(
            isA<StateError>().having((e) => e.message, 'message', contains('list 不支持 --device'))),
      );
    });

    test('wait / verify 允许 region 与超时选项', () {
      expect(
        () => DeviceOptions.parse(
          ['wait', '--region=0,0,10,10', '--timeout-ms=500', '--stable-ms=100'],
        ).validate(),
        returnsNormally,
      );
      expect(
        () => DeviceOptions.parse(['verify', '1', '2', '--region=0,0,10,10']).validate(),
        returnsNormally,
      );
    });

    test('未知命令不在这里报错（交给 CLI 带 usage）', () {
      DeviceOptions.parse(['nope']).validate();
      DeviceOptions.parse(['type', 'hi']).validate();
    });

    test('commandNames 与命令表一致，且不含已删除的 type', () {
      expect(commandNames, isNot(contains('type')));
      expect(commandNames.length, 10);
      expect(
        commandNames,
        containsAll(<String>[
          'list',
          'boot',
          'shot',
          'calibrate',
          'tap',
          'drag',
          'size',
          'foreground',
          'wait',
          'verify',
        ]),
      );
    });
  });
}
