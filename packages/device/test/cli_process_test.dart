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

  test('--version → exit 0，且与 pubspec 一致', () async {
    final r = await _run(<String>['--version']);
    expect(r.exitCode, 0);
    expect('${r.stdout}'.trim(), matches(RegExp(r'^w_tools_device \d+\.\d+\.\d+$')));
  });

  test('未知选项 / 已删除的选项 → exit 2', () async {
    expect((await _run(<String>['list', '--nope'])).exitCode, 2);
    expect((await _run(<String>['tap', '1', '2', '--scale=3'])).exitCode, 2);
    expect((await _run(<String>['tap', '1', '2', '--no-cache'])).exitCode, 2);
  });

  test('已删除的 type 命令 → exit 2（未知命令）', () async {
    final r = await _run(<String>['type', 'hi']);
    expect(r.exitCode, 2);
    expect('${r.stderr}', contains('未知命令'));
  });

  test('--json 在参数解析失败时也输出 JSON（含 platform）', () async {
    final r = await _run(<String>['tap', '1', '2', '--json', '--bogus']);
    expect(r.exitCode, 2);
    expect('${r.stdout}', contains('"ok":false'));
    expect('${r.stdout}', contains('"schemaVersion":2'));
    expect('${r.stdout}', contains('"platform":"ios-simulator"'));
    expect('${r.stderr}'.trim(), isEmpty);
  });

  test('未知命令的 JSON 错误不内嵌完整 usage', () async {
    final r = await _run(<String>['nope', '--json']);
    expect(r.exitCode, 2);
    expect('${r.stdout}', contains('"ok":false'));
    expect('${r.stdout}', isNot(contains('用法：')));
  });

  test('找不到指定模拟器 → exit 3（环境错误，不是参数错误）', () async {
    final r = await _run(<String>['tap', '1', '2', '--device=___no_such_device___']);
    expect(r.exitCode, 3);
  });

  test('位置参数数量不对 → exit 2', () async {
    expect((await _run(<String>['tap', '1', '2', '3'])).exitCode, 2);
    expect((await _run(<String>['list', 'x'])).exitCode, 2);
    expect((await _run(<String>['shot', 'x'])).exitCode, 2);
    expect((await _run(<String>['verify', '1'])).exitCode, 2);
  });

  test('非法平台组合 → exit 2（不会碰设备）', () async {
    expect((await _run(<String>['tap', '1', '2', '--real'])).exitCode, 2);
    expect((await _run(<String>['boot', '--android'])).exitCode, 2);
    expect((await _run(<String>['list', '--device=x'])).exitCode, 2);
    expect((await _run(<String>['foreground'])).exitCode, 2);
  });
}
