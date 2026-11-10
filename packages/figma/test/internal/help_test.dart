import 'package:test/test.dart';
import 'package:w_tools_figma/src/cli/help.dart';

/// help 只有一份来源：顶层 usage 与每命令 help 必须在同一个文件里对齐。
void main() {
  test('顶层 usage 覆盖每个命令的 help 条目', () {
    for (final command in commandUsage.keys) {
      expect(usageText, contains(command), reason: 'usageText 漏了 $command');
    }
    expect(usageText, contains('--ignore-budget'));
    expect(usageText, contains('version'));
  });

  test('--no-markdown 在 help 里标了已弃用', () {
    expect(commandUsage['spec'], contains('已弃用'));
    expect(usageText, contains('已弃用'));
  });

  test('help init 点明与 w_tools_cli 的 init 不同', () {
    expect(commandUsage['init'], contains('w_tools_cli'));
  });

  test('help fetch 的 nodes 行不再漏 --depth', () {
    final fetch = commandUsage['fetch']!;
    final nodesLine = fetch.split('\n').firstWhere((line) => line.contains('fetch nodes'));
    expect(nodesLine, contains('--depth'));
    expect(fetch, contains('--scale'));
  });
}
