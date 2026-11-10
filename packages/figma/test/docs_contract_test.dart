import 'dart:io';

import 'package:test/test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  final readme = _read('README.md');
  final agents = _read('../../docs/agents/figma.md');

  test('README 命令表覆盖全部公开命令', () {
    const commands = <String>[
      'init',
      'frames',
      'fetch file',
      'fetch nodes',
      'fetch images',
      'get',
      'me',
      'spec',
      'tokens',
      'url',
      'diff',
      'usage',
      'cache',
      'budget',
      'help',
      'version',
    ];
    for (final command in commands) {
      expect(readme, contains('`$command`'), reason: 'README 缺 $command');
    }
  });

  test('README 不再把 .gitignore 说成 init 的产物', () {
    expect(readme, isNot(contains('token 模板 / `.gitignore`')));
  });

  test('README 安装示例只用当前版本，不写死发布状态', () {
    final version =
        RegExp(r'^version:\s*(\S+)', multiLine: true).firstMatch(_read('pubspec.yaml'))!.group(1)!;
    expect(readme, contains('w_tools_figma: ^$version'));
    expect(readme, isNot(contains('待发布')));
  });

  test('README 不声称 token 相对 --root', () {
    expect(readme, isNot(contains('token / 缓存都相对它解析')));
    expect(readme, contains('环境变量优先于文件'));
  });

  test('README 的 diff 用法包含 fileKey', () {
    expect(readme, contains('diff <fileKey>'));
  });

  test('README 有库 API 章节', () {
    expect(readme, contains('## 库 API'));
    expect(readme, contains('HttpFigmaClient'));
  });

  test('docs/agents 覆盖缓存 / 额度 / 版本命令', () {
    for (final command in <String>['cache stats', 'budget', 'usage', 'version']) {
      expect(agents, contains(command), reason: 'agents 缺 $command');
    }
  });
}
