import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_device/src/options.dart';

String _read(String path) => File(path).readAsStringSync();

Future<ProcessResult> _help() => Process.run(
      Platform.resolvedExecutable,
      <String>['run', 'bin/device.dart', '--help'],
      workingDirectory: Directory.current.path,
    );

void main() {
  test('README 安装版本与 pubspec 一致', () {
    final version =
        RegExp(r'^version:\s*(\S+)', multiLine: true).firstMatch(_read('pubspec.yaml'))!.group(1)!;
    expect(_read('README.md'), contains('w_tools_device: ^$version'));
  });

  test('README / agents / --help 覆盖命令表里的全部命令', () async {
    final help = '${(await _help()).stdout}';
    final readme = _read('README.md');
    final agents = _read('../../docs/agents/device-testing.md');
    for (final command in commandNames) {
      expect(help, contains('device $command'), reason: 'help 漏 device $command');
      expect(readme, contains('device $command'), reason: 'README 漏 device $command');
      expect(agents, contains('device $command'), reason: 'agents 漏 device $command');
    }
    // 已删除的命令不能再出现在帮助 / README 的用法里。
    expect(help, isNot(contains('device type')));
    expect(readme, isNot(contains('device type')));
  });

  test('已删除的选项不再出现在 --help', () async {
    final help = '${(await _help()).stdout}';
    expect(help, isNot(contains('--scale')));
    expect(help, isNot(contains('--no-cache')));
  });

  test('--no-release-mouse 在 README / help 都有说明', () async {
    final help = '${(await _help()).stdout}';
    final readme = _read('README.md');
    expect(help, contains('--no-release-mouse'));
    expect(readme, contains('--no-release-mouse'));
  });

  test('README 与 --help 的退出码一致（含 4）', () async {
    final help = '${(await _help()).stdout}';
    final readme = _read('README.md');
    expect(help, contains('退出码：0 成功'));
    for (final code in <String>['1', '2', '3', '4']) {
      expect(help, contains('· $code '), reason: 'help 缺退出码 $code');
      expect(readme, contains('`$code`'), reason: 'README 缺退出码 $code');
    }
    expect(help, contains('1 verify'));
    expect(help, contains('2 参数'));
  });

  test('CLI 版本常量与 pubspec 一致', () {
    final version =
        RegExp(r'^version:\s*(\S+)', multiLine: true).firstMatch(_read('pubspec.yaml'))!.group(1)!;
    expect(
      _read('lib/src/cli/device_cli.dart'),
      contains("deviceCliVersion = '$version'"),
    );
  });

  test('JSON schemaVersion 在 README / 代码中一致', () async {
    final help = '${(await _help()).stdout}';
    final code = _read('lib/src/cli/device_cli.dart');
    final version = RegExp(r'deviceJsonSchemaVersion = (\d+)').firstMatch(code)!.group(1)!;
    expect(_read('README.md'), contains('schemaVersion: $version'));
    expect(help, contains('schemaVersion=$version'));
  });

  test('--region 单位在 README / help 一致（与 tap 同坐标系）', () async {
    final help = '${(await _help()).stdout}';
    final readme = _read('README.md');
    expect(help, contains('与 tap 同坐标系'));
    expect(readme, contains('与 tap 同坐标系'));
    expect(help, contains('仅 wait / verify'));
  });

  test('README 说明本包没有公开 barrel（不再有库 API 快照）', () {
    final readme = _read('README.md');
    expect(readme, contains('没有公开 barrel'));
    expect(readme, contains('CLI 工具'));
    expect(readme, isNot(contains('API 快照（`scripts/api_snapshots/`）')));
  });

  test('README 说明 ok 语义与 wait 超时', () {
    final readme = _read('README.md');
    expect(readme, contains('wait` 超时是 `ok:false'));
    expect(readme, contains('verify` 画面没变化仍是 `ok:true'));
  });

  test('README 说明 regionPixels / scaleReason', () {
    final readme = _read('README.md');
    expect(readme, contains('regionPixels'));
    expect(readme, contains('scaleReason'));
  });

  test('example 不再指向已删除的 device_smoke', () {
    final example = _read('example/README.md');
    expect(example, isNot(contains('device_smoke.dart --tabs')));
    expect(example, contains('device verify'));
    expect(File('example/tool/device_smoke.dart').existsSync(), isFalse);
  });
}
