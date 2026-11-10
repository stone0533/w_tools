import 'dart:io';

import 'package:test/test.dart';

/// 文档口径漂移守卫：同一个事实只允许有一份来源。
///
/// 这些断言读的是文件文本，不需要网络、不需要缓存，跟着 `dart test` 一起跑。
void main() {
  final readme = File('README.md').readAsStringSync();
  final schemaReadme = File('schema/README.md').readAsStringSync();
  final agentsDoc = File('../../docs/agents/figma.md').readAsStringSync();
  final version = RegExp(r'^version:\s*(\S+)', multiLine: true)
      .firstMatch(File('pubspec.yaml').readAsStringSync())!
      .group(1)!;

  test('README 里所有 w_tools_figma 的 caret 约束都等于当前版本', () {
    final matches = RegExp(r'w_tools_figma\s*:?\s*\^(\d+\.\d+\.\d+)').allMatches(readme);
    expect(matches, isNotEmpty, reason: 'README 至少要留一个可复制的 yaml 安装约束');
    for (final match in matches) {
      expect(
        match.group(1),
        version,
        reason: 'README 的安装约束与 pubspec 不一致：${match.group(0)}（当前 $version）',
      );
    }
    expect(readme, isNot(contains('待发布')), reason: '发布状态不该写死在 README 里');
  });

  test('README 的 _budget.json 描述与代码一致（只有 limit）', () {
    // 只认"给出格式"的那一行（含 `{`），文件清单里的说明行不算。
    final formatLines = readme
        .split('\n')
        .where((line) => line.contains('_budget.json') && line.contains('{'))
        .toList();
    expect(formatLines, hasLength(1), reason: 'README 应只有一处给出 _budget.json 的格式');
    expect(formatLines.single, contains('limit'));
    expect(
      formatLines.single,
      isNot(contains('used')),
      reason: '代码从不写 used（用量在 _usage.log）',
    );
  });

  test('schema/README.md 的清单与 schema/ 目录一致', () {
    final listed = RegExp(r'\|\s*`([a-z0-9_]+\.v1\.json)`\s*\|')
        .allMatches(schemaReadme)
        .map((m) => m.group(1)!)
        .toSet();
    final onDisk = Directory('schema')
        .listSync()
        .whereType<File>()
        .map((file) => file.uri.pathSegments.last)
        .where((name) => name.endsWith('.json'))
        .toSet();
    expect(
      listed,
      onDisk,
      reason: 'schema/README.md 的表格是唯一清单：加 / 删 schema 文件必须同步它',
    );
  });

  test('工具包 CLI 约定写在 docs/agents/cli.md', () {
    final cliDoc = File('../../docs/agents/cli.md').readAsStringSync();
    expect(cliDoc, contains('工具包 CLI 约定'), reason: '四个工具 CLI 的约定没落文档');
    expect(cliDoc, contains('退出码'), reason: '约定里必须写退出码');
    expect(cliDoc, contains('flag 弃用'), reason: 'flag 弃用的流程要落在约定里');
  });

  test('figma 的 init 与 w_tools_cli 的 init 已区分', () {
    expect(
      agentsDoc,
      contains('**不是** `w_tools_cli` 的 init'),
      reason: '同名命令不同义，文档要写清',
    );
  });

  test('docs/agents 不再把 cacheFile 说成相对 --root', () {
    expect(agentsDoc, contains('通常是绝对路径'));
    expect(agentsDoc, isNot(contains('相对 `--root`')));
  });

  test('消费方 AGENTS 教了 tokens 的结构化数组', () {
    final agents = File('AGENTS.md').readAsStringSync();
    expect(agents, contains('tokens --json'), reason: 'AGENTS.md 没提 tokens 的 JSON 形态');
    for (final key in <String>['colors', 'texts', 'radii', 'spacings']) {
      expect(
        agents,
        contains(key),
        reason: 'AGENTS.md 漏教 $key：AI 会退回解析 markdown',
      );
    }
  });

  test('docs/agents 教了 tokens 数组与 url/me 的 schema', () {
    expect(agentsDoc, contains('colors'), reason: 'docs/agents 没教 tokens 结构化数组');
    expect(agentsDoc, contains('w_tools_figma.url/1'), reason: '缺 url 的 schema 名');
    expect(agentsDoc, contains('w_tools_figma.me/1'), reason: '缺 me 的 schema 名');
  });

  test('README 说明了 tokens --json 的结构化数组', () {
    expect(readme, contains('结构化数组'), reason: 'README 的 tokens 数组说明被删了');
  });

  test('docs/agents 不再用裸 figma 命令 / 历史能力段', () {
    expect(agentsDoc, isNot(contains('0.4.0')), reason: '版本前缀的历史能力段已删，别再加回来');
    expect(
      agentsDoc,
      isNot(contains('\nfigma ')),
      reason: '命令要写全 dart run w_tools_figma:figma，裸 figma 在消费方跑不起来',
    );
  });

  test('README 说明了索引 / 迁移标记的统计口径', () {
    expect(readme, contains('_nodes-index.json'), reason: 'cache stats 会把它算进文件数');
    expect(readme, contains('_migrated-v1'), reason: '迁移标记的存在与删除方式要写清');
  });

  test('README 说明了 tokens 的 source / sources', () {
    expect(readme, contains('`sources`'), reason: '多缓存时看 sources，别只看 source');
  });
}
