import 'dart:io';

import 'package:test/test.dart';

Future<ProcessResult> _run(List<String> args) => Process.run(
      Platform.resolvedExecutable,
      <String>['run', 'bin/device.dart', ...args],
      workingDirectory: Directory.current.path,
    );

void main() {
  test('无参数 → exit 2 + usage', () async {
    final r = await _run(<String>[]);
    expect(r.exitCode, 2);
    expect('${r.stdout}', contains('w_tools_device'));
  });

  test('--help → exit 0 且含退出码 4', () async {
    final r = await _run(<String>['--help']);
    expect(r.exitCode, 0);
    expect('${r.stdout}', contains('退出码'));
    expect('${r.stdout}', contains('4'));
  });

  test('未知选项 → exit 2', () async {
    final r = await _run(<String>['list', '--nope']);
    expect(r.exitCode, 2);
  });

  test('未知命令 → exit 2', () async {
    final r = await _run(<String>['nope']);
    expect(r.exitCode, 2);
  });

  test('非法平台组合 → exit 2（不会碰设备）', () async {
    expect((await _run(<String>['tap', '--real'])).exitCode, 2);
    expect((await _run(<String>['boot', '--android'])).exitCode, 2);
    expect((await _run(<String>['list', '--device=x'])).exitCode, 2);
  });
}
