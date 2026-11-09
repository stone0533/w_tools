import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_device/src/cli/device_cli.dart';
import 'package:w_tools_device/w_tools_device.dart';

void main() {
  tearDown(() => exitCode = 0);

  test('runDeviceCli 可注入依赖并捕获输出', () async {
    final out = StringBuffer();
    exitCode = 0;
    await runDeviceCli(
      <String>['list', '--json'],
      deps: DeviceCliDeps(
        simctl: () => _FakeSimctl(),
        write: out.write,
      ),
    );
    expect(exitCode, 0);
    expect(out.toString(), contains('"schemaVersion":1'));
    expect(out.toString(), contains('"platform":"ios-simulator"'));
    expect(out.toString(), contains('UDID-1'));
  });

  test('注入空设备 → exit 3，错误可捕获', () async {
    final err = StringBuffer();
    exitCode = 0;
    await runDeviceCli(
      <String>['tap', '1', '2', '--device=nope'],
      deps: DeviceCliDeps(
        simctl: () => _EmptySimctl(),
        input: () => _FakeInput(),
        write: (_) {},
        writeError: err.write,
      ),
    );
    expect(exitCode, 3);
    expect(err.toString(), contains('nope'));
  });
}

class _FakeSimctl extends Simctl {
  @override
  Future<List<SimDevice>> devices() async => const <SimDevice>[
        SimDevice(
          udid: 'UDID-1',
          name: 'iPhone 17 Pro',
          state: 'Booted',
          runtime: 'com.apple.CoreSimulator.SimRuntime.iOS-26-4',
        ),
      ];
}

class _EmptySimctl extends Simctl {
  @override
  Future<List<SimDevice>> devices() async => const <SimDevice>[];
}

class _FakeInput extends Input {
  @override
  Future<bool> available() async => true;
}
