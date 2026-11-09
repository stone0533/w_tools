import 'dart:io';

import 'package:test/test.dart';

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

  test('README 与 agents 覆盖全部 11 个命令', () {
    const commands = <String>[
      'list',
      'boot',
      'shot',
      'calibrate',
      'tap',
      'drag',
      'type',
      'size',
      'foreground',
      'wait',
      'verify',
    ];
    final readme = _read('README.md');
    final agents = _read('../../docs/agents/device-testing.md');
    for (final command in commands) {
      expect(readme, contains('device $command'));
      expect(agents, contains('device $command'), reason: 'agents 漏 device $command');
    }
  });

  test('README 与 --help 的退出码一致（含 4）', () async {
    final help = '${(await _help()).stdout}';
    final readme = _read('README.md');
    expect(help, contains('退出码：0 成功'));
    for (final code in <String>['1', '2', '3', '4']) {
      expect(help, contains('· $code '), reason: 'help 缺退出码 $code');
      expect(readme, contains('`$code`'), reason: 'README 缺退出码 $code');
    }
    expect(readme, contains('`0`'));
    expect(help, contains('1 verify'));
    expect(help, contains('2 参数'));
  });

  test('README 标注 type 实验 / boot 默认 / 库 API 边界 / 真机清单', () {
    final readme = _read('README.md');
    expect(readme, contains('实验'));
    expect(readme, contains('省略'));
    expect(readme, contains('不建议消费方依赖'));
    expect(readme, contains('API 快照'));
    expect(readme, contains('真机验证清单'));
  });

  test('CLI 版本常量与 pubspec 一致', () {
    final version =
        RegExp(r'^version:\s*(\S+)', multiLine: true).firstMatch(_read('pubspec.yaml'))!.group(1)!;
    expect(
      _read('lib/src/cli/device_cli.dart'),
      contains("deviceCliVersion = '$version'"),
    );
  });

  test('example 的 verify 无变化期望退出码是 1，不是旧的 2', () {
    final example = _read('example/tool/device_smoke.dart');
    expect(example, contains('expectExit: <int>[1]'));
    expect(example, isNot(contains('expectExit: <int>[2]')));
  });

  test('help 与 README 的 region / 超时限制一致', () async {
    final help = '${(await _help()).stdout}';
    final readme = _read('README.md');
    expect(help, contains('Android=截图像素'));
    expect(readme, contains('Android=截图像素'));
    expect(help, contains('仅 wait / verify'));
    expect(readme, contains('只用于 wait / verify'));
  });

  test('模块文档并入 packages/device/README.md', () {
    // 2026-11-06 docs 重构把 device_module.md 并入包 README；
    // 这里守住新的真源，避免再回头依赖已删除的 docs/modules 文件。
    expect(File('README.md').existsSync(), isTrue);
    expect(_read('README.md'), contains('w_tools_device'));
  });
}
