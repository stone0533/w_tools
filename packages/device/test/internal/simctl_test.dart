import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:w_tools_device/src/shell.dart';
import 'package:w_tools_device/src/simctl.dart';

/// 用假的 Shell 回答外部命令；不碰真实模拟器。
class _FakeShell extends Shell {
  _FakeShell(this.onRun);

  final ProcessResult Function(String exe, List<String> args) onRun;
  final calls = <String>[];

  @override
  Future<ProcessResult> run(String exe, List<String> args) async {
    calls.add('$exe ${args.join(' ')}');
    return onRun(exe, args);
  }

  @override
  Future<Uint8List> runBytes(String exe, List<String> args) async => Uint8List(0);
}

ProcessResult _ok(String out) => ProcessResult(0, 0, out, '');
ProcessResult _fail() => ProcessResult(0, 1, '', 'not found');

const _deviceType = 'com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro';

void main() {
  group('Simctl.parseDevices', () {
    test('解析 simctl --json', () {
      const json = '''
{"devices":{"com.apple.CoreSimulator.SimRuntime.iOS-26-4":[
  {"udid":"AAAA","name":"iPhone 17 Pro","state":"Booted"},
  {"udid":"BBBB","name":"iPhone 17","state":"Shutdown"}
]}}
''';
      final list = Simctl.parseDevices(json);
      expect(list.length, 2);
      expect(list.first.name, 'iPhone 17 Pro');
      expect(list.first.isBooted, isTrue);
      expect(list.first.runtimeLabel, 'iOS 26.4');
    });

    test('空 / 坏 JSON 返回空列表，不抛', () {
      expect(Simctl.parseDevices('{}'), isEmpty);
      expect(Simctl.parseDevices('{"devices":{}}'), isEmpty);
      expect(Simctl.parseDevices('not json'), isEmpty);
    });

    test('跳过没有 udid 的条目', () {
      final list = Simctl.parseDevices(
        '{"devices":{"x":[{"name":"A"},{"udid":"U","name":"B","state":"Booted"}]}}',
      );
      expect(list.length, 1);
      expect(list.single.udid, 'U');
    });
  });

  group('Simctl.matches（不静默取第一台）', () {
    const a = SimDevice(udid: 'AAAA', name: 'iPhone 17 Pro', state: 'Booted', runtime: 'x');
    const b = SimDevice(udid: 'BBBB', name: 'iPhone 17', state: 'Shutdown', runtime: 'x');
    const pad = SimDevice(udid: 'CCCC', name: 'iPad Air', state: 'Booted', runtime: 'x');

    test('udid / 名称精确匹配优先，其次子串', () {
      expect(Simctl.matches(const [a, b, pad], 'BBBB').single.udid, 'BBBB');
      expect(Simctl.matches(const [a, b, pad], 'iPhone 17 Pro').single.udid, 'AAAA');
      expect(Simctl.matches(const [a, b, pad], 'ipad').single.udid, 'CCCC');
    });

    test('子串命中多台时返回全部（由调用方报歧义）', () {
      expect(Simctl.matches(const [a, b, pad], 'iPhone').length, 2);
    });

    test('bootedOnly 只留已启动；空 query 返回全部就绪项', () {
      expect(Simctl.matches(const [a, b], null, bootedOnly: true).single.udid, 'AAAA');
      expect(Simctl.matches(const [], null), isEmpty);
      expect(Simctl.matches(const [a, b], 'nope'), isEmpty);
    });
  });

  group('Simctl.metrics（identifier → bundlePath，不猜密度）', () {
    const ipadType = 'com.apple.CoreSimulator.SimDeviceType.iPad-mini-A17-Pro';
    const devicetypes = '{"devicetypes":['
        '{"identifier":"$_deviceType","name":"iPhone 17 Pro",'
        '"bundlePath":"/Library/Developer/CoreSimulator/Profiles/DeviceTypes/iPhone 17 Pro.simdevicetype"},'
        '{"identifier":"$ipadType","name":"iPad mini (A17 Pro)",'
        '"bundlePath":"/Library/Developer/CoreSimulator/Profiles/DeviceTypes/iPad mini (A17 Pro).simdevicetype"}'
        ']}';

    test('identifier → bundlePath → capabilities（目录名含空格也命中）', () async {
      final shell = _FakeShell((exe, args) {
        if (exe == 'xcrun' && args.contains('devicetypes')) return _ok(devicetypes);
        if (exe == 'plutil') {
          final path = args.last;
          if (path.endsWith('device.plist')) {
            expect(args, containsAllInOrder(['-extract', 'deviceType', 'raw']));
            return _ok(_deviceType);
          }
          if (path.endsWith('iPhone 17 Pro.simdevicetype/Contents/Resources/capabilities.plist')) {
            return _ok(
              '{"capabilities":{"ScreenDimensionsCapability":'
              '{"main-screen-width":1206,"main-screen-height":2622,"main-screen-scale":3}}}',
            );
          }
        }
        return _fail();
      });
      final metrics = await Simctl(shell: shell).metrics('UDID-1');
      expect(metrics.source, 'deviceType');
      expect(metrics.pixelWidth, 1206);
      expect(metrics.pixelHeight, 2622);
      expect(metrics.scale, 3);
      expect(metrics.pointWidth, 402);
      expect(metrics.pointHeight, 874);
    });

    test('iPad mini：1488px / scale 2 → 744×1133（不套 iPhone 启发式）', () async {
      final shell = _FakeShell((exe, args) {
        if (exe == 'xcrun' && args.contains('devicetypes')) return _ok(devicetypes);
        if (exe == 'plutil') {
          final path = args.last;
          if (path.endsWith('device.plist')) return _ok(ipadType);
          if (path.endsWith(
              'iPad mini (A17 Pro).simdevicetype/Contents/Resources/capabilities.plist')) {
            return _ok(
              '{"capabilities":{"ScreenDimensionsCapability":'
              '{"main-screen-width":1488,"main-screen-height":2266,"main-screen-scale":2}}}',
            );
          }
        }
        return _fail();
      });
      final metrics = await Simctl(shell: shell).metrics('UDID-IPAD');
      expect(metrics.source, 'deviceType');
      expect(metrics.scale, 2);
      expect(metrics.pointWidth, 744);
      expect(metrics.pointHeight, 1133);
    });

    test('simctl devicetypes 不可用 → 截图 + 经验密度，并标成 fallback', () async {
      final shell = _FakeShell((exe, args) {
        if (exe == 'xcrun' && args.contains('devicetypes')) return _fail();
        if (exe == 'plutil') return _ok(_deviceType);
        if (args.contains('screenshot')) return _ok('');
        if (exe == 'sips') return _ok('pixelWidth: 1206\npixelHeight: 2622\n');
        return _fail();
      });
      final metrics = await Simctl(shell: shell).metrics('UDID-1');
      expect(metrics.source, 'fallback');
      expect(metrics.reason, 'no-devicetypes');
      expect(metrics.scale, 3);
      expect(metrics.pointWidth, 402);
      expect(metrics.pointHeight, 874);
    });

    test('device.plist 读不到 → reason=no-device-type', () async {
      final shell = _FakeShell((exe, args) {
        if (exe == 'plutil') return _fail();
        if (args.contains('screenshot')) return _ok('');
        if (exe == 'sips') return _ok('pixelWidth: 1206\npixelHeight: 2622\n');
        return _fail();
      });
      final metrics = await Simctl(shell: shell).metrics('UDID-1');
      expect(metrics.source, 'fallback');
      expect(metrics.reason, 'no-device-type');
    });

    test('标识符不在 devicetypes 表 → reason=unknown-device-type', () async {
      const other = '{"devicetypes":[{"identifier":"com.apple.Other","name":"Other",'
          '"bundlePath":"/Fake/Other.simdevicetype"}]}';
      final shell = _FakeShell((exe, args) {
        if (exe == 'xcrun' && args.contains('devicetypes')) return _ok(other);
        if (exe == 'plutil') return _ok(_deviceType);
        if (args.contains('screenshot')) return _ok('');
        if (exe == 'sips') return _ok('pixelWidth: 1206\npixelHeight: 2622\n');
        return _fail();
      });
      final metrics = await Simctl(shell: shell).metrics('UDID-1');
      expect(metrics.source, 'fallback');
      expect(metrics.reason, 'unknown-device-type');
    });

    test('capabilities 缺字段 → 回退', () async {
      final shell = _FakeShell((exe, args) {
        if (exe == 'xcrun' && args.contains('devicetypes')) return _ok(devicetypes);
        if (exe == 'plutil') {
          final path = args.last;
          if (path.endsWith('device.plist')) {
            expect(args, containsAllInOrder(['-extract', 'deviceType', 'raw']));
            return _ok(_deviceType);
          }
          if (path.endsWith('capabilities.plist')) return _ok('{"Other":{}}');
        }
        if (exe == 'sips') return _ok('pixelWidth: 750\npixelHeight: 1334\n');
        return _ok('');
      });
      final metrics = await Simctl(shell: shell).metrics('UDID-1');
      expect(metrics.source, 'fallback');
      expect(metrics.reason, 'no-capabilities');
      expect(metrics.scale, 2);
      expect(metrics.pointWidth, 375);
    });

    test('fallbackScale 规则：按宽高比识别 iPad，iPhone 仍 3x', () {
      expect(Simctl.fallbackScale(1206, 2622), 3);
      expect(Simctl.fallbackScale(1170, 2532), 3);
      expect(Simctl.fallbackScale(750, 1334), 2);
      expect(Simctl.fallbackScale(1620, 2160), 2);
      expect(Simctl.fallbackScale(2048, 2732), 2);
      // iPad mini 1488×2266：只看宽度会误判 3x，宽高比 0.657 → 2x。
      expect(Simctl.fallbackScale(1488, 2266), 2);
      // 横屏：iPhone 2622×1206 是 3x；iPad / SE 1334×750、2732×2048 是 2x。
      expect(Simctl.fallbackScale(2622, 1206), 3);
      expect(Simctl.fallbackScale(1334, 750), 2);
      expect(Simctl.fallbackScale(2732, 2048), 2);
      expect(Simctl.fallbackScale(2266, 1488), 2);
    });
  });
}
