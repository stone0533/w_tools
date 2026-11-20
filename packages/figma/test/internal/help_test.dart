import 'package:test/test.dart';
import 'package:w_tools_figma/src/cli/help.dart';

/// help 只有一份来源：顶层 usage 与每命令 help 必须在同一个文件里对齐。
void main() {
  test('顶层 usage 覆盖每个命令的 help 条目', () {
    for (final command in commandUsage.keys) {
      expect(usageText, contains(command), reason: 'usageText 漏了 $command');
    }
    expect(usageText, isNot(contains('--ignore-budget')));
    expect(usageText, contains('version'));
  });

  test('help 不再包含 budget 命令', () {
    expect(commandUsage.containsKey('budget'), isFalse);
  });

  test('help 不再为 url / get 推荐 --root', () {
    expect(commandUsage['url'], isNot(contains('--root')));
    expect(commandUsage['get'], isNot(contains('--root')));
    expect(commandUsage['url'], isNot(contains('1862:9222')));
  });

  test('help 不再推荐已删除的 --no-markdown', () {
    expect(usageText, isNot(contains('no-markdown')));
    expect(commandUsage['spec'], isNot(contains('no-markdown')));
  });

  test('help init 点明与 w_tools_cli 的 init 不同', () {
    expect(commandUsage['init'], contains('w_tools_cli'));
  });

  test('help 选项保留取值占位符', () {
    expect(commandUsage['fetch'], contains('--root=<dir>'));
    expect(commandUsage['fetch'], contains('--depth=<n>'));
    expect(commandUsage['spec'], contains('--skip-name-prefix=<s>'));
    expect(commandUsage['tokens'], contains('--map=<path>'));
    expect(commandUsage['usage'], contains('--set=<n>'));
  });

  test('help fetch 的 nodes 行不再漏 --depth', () {
    final fetch = commandUsage['fetch']!;
    final nodesLine = fetch.split('\n').firstWhere((line) => line.contains('fetch nodes'));
    expect(nodesLine, contains('--depth'));
    expect(fetch, contains('--scale'));
  });
}
