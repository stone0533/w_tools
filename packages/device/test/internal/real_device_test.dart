import 'package:test/test.dart';
import 'package:w_tools_device/src/real_device.dart';

const _devices = '''
{"result":{"devices":[
 {"identifier":"PHONE","hardwareProperties":{"udid":"00008101-AAA","platform":"iOS"},
  "deviceProperties":{"name":"My iPhone","osVersionNumber":"27.0","bootState":"booted"},
  "connectionProperties":{"transportType":"wired","pairingState":"paired","tunnelState":"connected"}},
 {"identifier":"SIM","hardwareProperties":{"udid":"SIM-1","platform":"iOS"},
  "deviceProperties":{"name":"iPhone 17 Pro","osVersionNumber":"26.4","bootState":"booted"},
  "connectionProperties":{"transportType":"sameMachine","pairingState":"paired"}},
 {"identifier":"SIM2","hardwareProperties":{"udid":"SIM-2","platform":"simulator"},
  "deviceProperties":{"name":"iPad","osVersionNumber":"17.5","bootState":"shutdown"},
  "connectionProperties":{"transportType":"localNetwork","pairingState":"paired"}}
]}}
''';

void main() {
  group('Devicectl.parseDevices', () {
    test('过滤模拟器（sameMachine / platform=simulator），保留 state / transport', () {
      final list = Devicectl.parseDevices(_devices);
      expect(list.length, 1);
      final d = list.single;
      expect(d.udid, '00008101-AAA');
      expect(d.state, 'booted');
      expect(d.transport, 'wired');
      expect(d.paired, isTrue);
      expect(d.isUsable, isTrue);
    });

    test('缺 transportType / bootState → transport 省略，state 回落 tunnelState', () {
      const json = '''
{"result":{"devices":[
 {"hardwareProperties":{"udid":"U-1","platform":"iOS"},
  "deviceProperties":{"name":"Lei 的 iPhone","osVersionNumber":"27.0"},
  "connectionProperties":{"pairingState":"paired","tunnelState":"unavailable"}}
]}}
''';
      final d = Devicectl.parseDevices(json).single;
      expect(d.transport, isNull);
      expect(d.state, 'unavailable');
      expect(d.isUsable, isFalse);
      expect(d.toJson().containsKey('transport'), isFalse);
      expect(d.toJson()['state'], 'unavailable');
    });

    test('完全没有状态字段 → state=unknown', () {
      const json = '''
{"result":{"devices":[
 {"hardwareProperties":{"udid":"U-2","platform":"iOS"},
  "deviceProperties":{"name":"X"},
  "connectionProperties":{}}
]}}
''';
      final d = Devicectl.parseDevices(json).single;
      expect(d.state, 'unknown');
      expect(d.transport, isNull);
    });

    test('坏 JSON / 缺字段不抛', () {
      expect(Devicectl.parseDevices('nope'), isEmpty);
      expect(Devicectl.parseDevices('{}'), isEmpty);
      expect(Devicectl.parseDevices('{"result":{"devices":[{"foo":1}]}}'), isEmpty);
    });

    test('按 udid / 名称 / 子串挑设备；空 query 返回全部', () {
      final list = Devicectl.parseDevices(_devices);
      expect(Devicectl.matches(list, '00008101-AAA').single.name, 'My iPhone');
      expect(Devicectl.matches(list, 'my iphone').single.udid, '00008101-AAA');
      expect(Devicectl.matches(list, null).single.udid, '00008101-AAA');
      expect(Devicectl.matches(list, 'nope'), isEmpty);
      expect(Devicectl.matches(const [], null), isEmpty);
    });
  });

  group('RealDevice 状态', () {
    test('只有 tunnelState=connected 时 isUsable 为 true', () {
      const connected = RealDevice(
        udid: 'U',
        name: 'iPad',
        osVersion: '18.6',
        state: 'connected',
        transport: 'wired',
        paired: true,
      );
      expect(connected.isUsable, isTrue);

      const unavailable = RealDevice(
        udid: 'U2',
        name: 'iPhone',
        osVersion: '27.0',
        state: 'unavailable',
        transport: null,
        paired: true,
      );
      expect(unavailable.isUsable, isFalse);
    });

    test('stateLabel：常见状态转中文，未知值原样返回', () {
      expect(RealDevice.stateLabel('booted'), '已启动');
      expect(RealDevice.stateLabel('connected'), '已连接');
      expect(RealDevice.stateLabel('unavailable'), '不可用');
      expect(RealDevice.stateLabel('disconnected'), '已断开');
      expect(RealDevice.stateLabel('shutdown'), '已关机');
      expect(RealDevice.stateLabel('weird'), 'weird');
    });
  });
}
