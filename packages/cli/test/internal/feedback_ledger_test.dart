import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:w_tools_cli/src/feedback/feedback_ledger.dart';
import 'package:w_tools_cli/src/feedback/feedback_submit.dart';

const _body = '''- 包/版本：w_tools_ui 5.0.0
- 环境：Flutter 3.44 / macOS
- 命令 / 输入：WImage(...)
- 期望：显示
- 实际：空白
- 影响：页面不可用
- 建议：补提示
- 复现数据：见附件
''';

Directory _repo() {
  final root = Directory.systemTemp.createTempSync('wt_fb_ledger_');
  File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync('name: w_tools\n');
  Directory(p.join(root.path, 'packages', 'cli')).createSync(recursive: true);
  File(
    p.join(root.path, 'packages', 'cli', 'pubspec.yaml'),
  ).writeAsStringSync('name: w_tools_cli\n');
  final config = File(p.join(root.path, '.dart_tool', 'package_config.json'))
    ..createSync(recursive: true);
  config.writeAsStringSync(
    jsonEncode({
      'configVersion': 2,
      'packages': [
        {'name': 'w_tools_cli', 'rootUri': '../packages/cli'},
      ],
    }),
  );
  Directory(p.join(root.path, 'docs', 'feedback')).createSync(recursive: true);
  File(p.join(root.path, 'docs', 'feedback', 'README.md')).writeAsStringSync('''
# 反馈

| 包 | 待处理 | 最近更新 |
| --- | --- | --- |
| [api](api.md) | 0 | 2026-11-04 |
''');
  File(p.join(root.path, 'docs', 'feedback', 'api.md')).writeAsStringSync('''
# w_tools_api 反馈

## 待处理

（暂无）

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
''');
  return root;
}

void main() {
  test('CLI-020 索引表缺失时先失败，不留下半截台账', () {
    final root = _repo();
    addTearDown(() => root.deleteSync(recursive: true));
    File(
      p.join(root.path, 'docs', 'feedback', 'README.md'),
    ).writeAsStringSync('# 反馈\n\n没有索引表。\n');

    expect(
      () => addToLedger(root, FeedbackDraft(package: 'api', title: '新问题', body: _body)),
      throwsA(isA<FeedbackLedgerException>()),
    );
    expect(
      File(p.join(root.path, 'docs', 'feedback', 'api.md')).readAsStringSync(),
      isNot(contains('新问题')),
    );
  });

  test('追加到已有台账并更新索引', () {
    final root = _repo();
    addTearDown(() => root.deleteSync(recursive: true));
    final ledger = File(p.join(root.path, 'docs', 'feedback', 'api.md'));
    final result = addToLedger(
      root,
      FeedbackDraft(package: 'api', title: '超时', body: _body),
    );
    expect(result.pending, 1);
    expect(ledger.readAsStringSync(), contains('### [待处理] api: 超时'));
    final readme = File(p.join(root.path, 'docs', 'feedback', 'README.md')).readAsStringSync();
    expect(readme, contains('| [api](api.md) | 1 |'));

    addToLedger(root, FeedbackDraft(package: 'w_tools_api', title: '第二次', body: _body));
    expect(ledger.readAsStringSync(), contains('### [待处理] api: 第二次'));
    expect(
      File(p.join(root.path, 'docs', 'feedback', 'README.md')).readAsStringSync(),
      contains('| [api](api.md) | 2 |'),
    );
  });

  test('完全相同的反馈默认拒绝，--allow-duplicate 可覆盖', () {
    final root = _repo();
    addTearDown(() => root.deleteSync(recursive: true));
    final draft = FeedbackDraft(package: 'api', title: '超时', body: _body);
    addToLedger(root, draft);
    expect(
      () => addToLedger(root, draft),
      throwsA(isA<FeedbackLedgerException>()),
    );
    addToLedger(root, draft, allowDuplicate: true);
    expect(
      File(p.join(root.path, 'docs', 'feedback', 'api.md')).readAsStringSync(),
      contains('### [待处理] api: 超时'),
    );
  });

  test('linkedIssue 写入条目', () {
    final root = _repo();
    addTearDown(() => root.deleteSync(recursive: true));
    addToLedger(
      root,
      FeedbackDraft(package: 'api', title: '超时', body: _body),
      linkedIssue: 123,
    );
    expect(
      File(p.join(root.path, 'docs', 'feedback', 'api.md')).readAsStringSync(),
      contains('关联 issue：#123'),
    );
  });

  test('缺失包自动建档并补索引', () {
    final root = _repo();
    addTearDown(() => root.deleteSync(recursive: true));
    final result = addToLedger(
      root,
      FeedbackDraft(package: 'ui', title: '空白', body: _body),
    );
    expect(result.file.path, endsWith('docs/feedback/ui.md'));
    expect(result.pending, 1);
    expect(
      File(p.join(root.path, 'docs', 'feedback', 'README.md')).readAsStringSync(),
      contains('| [ui](ui.md) | 1 |'),
    );
  });

  test('非仓库检出拒绝写台账', () {
    final root = Directory.systemTemp.createTempSync('wt_fb_norepo_');
    addTearDown(() => root.deleteSync(recursive: true));
    expect(
      () => addToLedger(root, FeedbackDraft(package: 'ui', title: 'x', body: _body)),
      throwsA(isA<FeedbackLedgerException>()),
    );
  });
}
