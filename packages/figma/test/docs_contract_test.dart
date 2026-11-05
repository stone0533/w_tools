import 'dart:io';

import 'package:test/test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  final readme = _read('README.md');
  final contract = _read('../../docs/figma-cli.md');
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

  test('README 注明当前 pub 0.11.2 / 0.11.3 待发布', () {
    expect(readme, contains('0.11.2'));
    expect(readme, contains('`0.11.3` 待发布'));
  });

  test('docs/figma-cli 不声称 token 相对 --root', () {
    expect(contract, isNot(contains('token / 缓存都相对它解析')));
    expect(contract, contains('token 固定在'));
  });

  test('docs/figma-cli diff 签名包含 fileKey', () {
    expect(contract, contains('`diff <fileKey> <nodeId>`'));
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
