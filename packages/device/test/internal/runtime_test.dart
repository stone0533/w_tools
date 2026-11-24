import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_device/src/cli/device_cli.dart';
import 'package:w_tools_device/src/input.dart';
import 'package:w_tools_device/src/simctl.dart';

void main() {
  tearDown(() => exitCode = 0);

  test('runDeviceCli 注入依赖并捕获输出', () async {
    final out = StringBuffer();
    exitCode = 0;
    await runDeviceCli(
      <String>['list', '--json'],
      runtime: DeviceRuntime(
        simctl: _FakeSimctl(),
        write: out.write,
      ),
    );
    expect(exitCode, 0);
    expect(out.toString(), contains('"schemaVersion":2'));
    expect(out.toString(), contains('"platform":"ios-simulator"'));
    expect(out.toString(), contains('UDID-1'));
    expect(out.toString(), isNot(contains('"real"')));
  });

  test('注入空设备 → exit 3，错误可捕获', () async {
    final err = StringBuffer();
    exitCode = 0;
    await runDeviceCli(
      <String>['tap', '1', '2', '--device=nope'],
      runtime: DeviceRuntime(
        simctl: _EmptySimctl(),
        input: _FakeInput(),
        write: (_) {},
        writeError: err.write,
      ),
    );
    expect(exitCode, 3);
    expect(err.toString(), contains('nope'));
  });

  test('参数解析失败时 JSON 也带 platform', () async {
    final out = StringBuffer();
    exitCode = 0;
    await runDeviceCli(
      <String>['tap', '1', '2', '--json', '--bogus'],
      runtime: DeviceRuntime(write: out.write),
    );
    expect(exitCode, 2);
    expect(out.toString(), contains('"ok":false'));
    expect(out.toString(), contains('"platform":"ios-simulator"'));
  });

  test('--android 的失败 JSON 带 platform=android', () async {
    final out = StringBuffer();
    exitCode = 0;
    await runDeviceCli(
      <String>['size', '--android', '--json', '--bogus'],
      runtime: DeviceRuntime(write: out.write),
    );
    expect(exitCode, 2);
    expect(out.toString(), contains('"platform":"android"'));
  });

  test('未知命令 exit 2 且带 usage', () async {
    final err = StringBuffer();
    exitCode = 0;
    await runDeviceCli(
      <String>['type', 'hi'],
      runtime: DeviceRuntime(write: (_) {}, writeError: err.write),
    );
    expect(exitCode, 2);
    expect(err.toString(), contains('未知命令'));
    expect(err.toString(), contains('用法'));
  });

  test('同一进程连续两次运行不残留依赖（无全局状态）', () async {
    final first = StringBuffer();
    await runDeviceCli(<String>['list', '--json'],
        runtime: DeviceRuntime(simctl: _FakeSimctl(), write: first.write));
    expect(first.toString(), contains('UDID-1'));

    final second = StringBuffer();
    await runDeviceCli(<String>['list', '--json'],
        runtime: DeviceRuntime(simctl: _EmptySimctl(), write: second.write));
    expect(second.toString(), contains('"devices":[]'));
    expect(second.toString(), isNot(contains('UDID-1')));
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
