import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../tool/feedback_lint.dart';

Directory _tmp(String prefix) => Directory.systemTemp.createTempSync(prefix);

void main() {
  group('feedback lint', () {
    test('字段齐全的待处理条目通过', () {
      final root = _tmp('wt_fbl_');
      addTearDown(() => root.deleteSync(recursive: true));
      final file = File(p.join(root.path, 'figma.md'))
        ..writeAsStringSync('''
## 待处理

### [待处理] figma: 示例
- 包/版本：w_tools_figma 0.10.0
- 环境：macOS
- 命令 / 输入：figma fetch nodes
- 期望：快
- 实际：慢
- 影响：多等 10 分钟
- 建议：加缓存
- 复现数据：129 MB
''');
      final result = const FeedbackLinter().lintFiles([file.path]);
      expect(result.ok, isTrue);
      expect(result.pending, 1);
    });

    test('缺字段 / 未知状态 / 已闭环缺版本号都会报错', () {
      final root = _tmp('wt_fbl2_');
      addTearDown(() => root.deleteSync(recursive: true));
      final file = File(p.join(root.path, 'cli.md'))
        ..writeAsStringSync('''
### [待处理] cli: 缺字段
- 包/版本：w_tools_cli 1.9.4

### [瞎写] cli: 状态非法
- 包/版本：x

## 已闭环

| 日期 | 问题 | 结果 |
| 2026-11-03 | 没写版本 | ✅ 修好了 |
''');
      final result = const FeedbackLinter().lintFiles([file.path]);
      expect(result.ok, isFalse);
      expect(result.issues.any((i) => i.message.contains('缺字段')), isTrue);
      expect(result.issues.any((i) => i.message.contains('未知状态')), isTrue);
      expect(result.issues.any((i) => i.message.contains('版本号')), isTrue);
    });

    test('字段只在正文出现、没有「- 字段：」行 → 报缺字段', () {
      final root = _tmp('wt_fbl4_');
      addTearDown(() => root.deleteSync(recursive: true));
      final file = File(p.join(root.path, 'cli.md'))
        ..writeAsStringSync('''
### [待处理] cli: 只有正文提到环境
这条里提到了环境和命令，但没有字段行。
''');
      final result = const FeedbackLinter().lintFiles([file.path]);
      expect(result.issues.where((i) => i.message.contains('缺字段')).length, 8);
    });

    test('多行命令 / 复现数据（代码块 + 缩进列表）不算占位', () {
      final root = _tmp('wt_fbl_multiline_');
      addTearDown(() => root.deleteSync(recursive: true));
      final file = File(p.join(root.path, 'app.md'))
        ..writeAsStringSync('''
### [待处理] app: 多行字段
- 包/版本：w_tools_app 4.0.1
- 环境：macOS
- 命令 / 输入：
  ```dart
  await app.start();
  ```
- 期望：有日志
- 实际：没有日志
- 影响：排查靠猜
- 建议：加日志
- 复现数据：
   - `packages/app/lib/src/app.dart:1-2`
   - 现象：没有任何输出
''');
      final result = const FeedbackLinter().lintFiles([file.path]);
      expect(
        result.issues.where((i) => i.message.contains('占位内容')),
        isEmpty,
        reason: '字段值写在下一行的代码块 / 列表里是合法内容',
      );
      expect(result.ok, isTrue);
    });

    test('缩进子项不会被当成字段（字段必须从行首 - 开始）', () {
      final root = _tmp('wt_fbl_nested_');
      addTearDown(() => root.deleteSync(recursive: true));
      final file = File(p.join(root.path, 'app.md'))
        ..writeAsStringSync('''
### [待处理] app: 子项冒充字段
- 包/版本：w_tools_app 4.0.1
- 环境：macOS
- 期望：有日志
- 实际：没有日志
- 影响：排查靠猜
- 建议：加日志
- 复现数据：
  - 命令：这不是字段
  - 复现数据：这也不是字段
''');
      final result = const FeedbackLinter().lintFiles([file.path]);
      final missing = result.issues.where((i) => i.message.contains('缺字段'));
      expect(missing.map((i) => i.message), contains('待处理条目缺字段「命令」'));
    });

    test('代码块 / 行内代码里的 ... 不算占位，裸 ... 仍算', () {
      final root = _tmp('wt_fbl_ellipsis_');
      addTearDown(() => root.deleteSync(recursive: true));
      final file = File(p.join(root.path, 'e2e.md'))
        ..writeAsStringSync('''
### [待处理] e2e: 代码里的省略号
- 包/版本：w_tools_e2e 0.2.0
- 环境：macOS
- 命令 / 输入：
  ```bash
  flutter run -d <udid> --dart-define=E2E_EMAIL=... --dart-define=E2E_PASSWORD=...
  ```
- 期望：能跑
- 实际：不能跑
- 影响：多花时间
- 建议：补文档
- 复现数据：`debugPrint('[E2E] ...')`

### [待处理] e2e: 裸省略号
- 包/版本：w_tools_e2e 0.2.0
- 环境：macOS
- 命令 / 输入：...
- 期望：能跑
- 实际：不能跑
- 影响：多花时间
- 建议：补文档
- 复现数据：日志
''');
      final result = const FeedbackLinter().lintFiles([file.path]);
      final placeholderIssues = result.issues.where((i) => i.message.contains('占位内容')).toList();
      expect(placeholderIssues, hasLength(1));
      expect(placeholderIssues.single.message, contains('命令'));
    });

    test('字段值是空的仍算占位', () {
      final root = _tmp('wt_fbl_empty_');
      addTearDown(() => root.deleteSync(recursive: true));
      final file = File(p.join(root.path, 'ui.md'))
        ..writeAsStringSync('''
### [待处理] ui: 空字段
- 包/版本：w_tools_ui 14.1.0
- 环境：macOS
- 命令 / 输入：flutter test
- 期望：通过
- 实际：失败
- 影响：挡 CI
- 建议：补断言
- 复现数据：

### [待处理] ui: 空字段 2
- 包/版本：w_tools_ui 14.1.0
- 环境：macOS
- 命令 / 输入：flutter test
- 期望：通过
- 实际：失败
- 影响：挡 CI
- 建议：补断言
- 复现数据：
''');
      final result = const FeedbackLinter().lintFiles([file.path]);
      expect(result.issues.where((i) => i.message.contains('占位内容')), hasLength(2));
    });

    test('待处理超过 stale-days 给警告，不影响 ok', () {
      final root = _tmp('wt_fbl5_');
      addTearDown(() => root.deleteSync(recursive: true));
      final file = File(p.join(root.path, 'cli.md'))
        ..writeAsStringSync('''
### [待处理] cli: 挂了很久
- 包/版本：w_tools_cli 1.9.5
- 环境：macOS
- 命令 / 输入：flutter test
- 期望：快
- 实际：慢
- 影响：等 10 分钟
- 建议：加缓存
- 复现数据：日志片段
- 状态变更：2026-01-01 待处理
''');
      final result = const FeedbackLinter(
        staleDays: 30,
      ).lintFiles([file.path], now: DateTime(2026, 3, 1));
      expect(result.ok, isTrue);
      expect(result.warnings.single.message, contains('没动'));
    });

    test('stale-days=0 关闭 stale 检查（与 --help 一致）', () {
      final root = _tmp('wt_fbl5b_');
      addTearDown(() => root.deleteSync(recursive: true));
      final file = File(p.join(root.path, 'cli.md'))
        ..writeAsStringSync('''
### [待处理] cli: 挂了很久
- 包/版本：w_tools_cli 1.9.5
- 环境：macOS
- 命令 / 输入：flutter test
- 期望：快
- 实际：慢
- 影响：等 10 分钟
- 建议：加缓存
- 复现数据：日志片段
- 状态变更：2026-01-01 待处理
''');
      final result = const FeedbackLinter(
        staleDays: 0,
      ).lintFiles([file.path], now: DateTime(2026, 3, 1));
      expect(result.ok, isTrue);
      expect(result.warnings, isEmpty);
    });

    test('已确认条目必须链 issue', () {
      final root = _tmp('wt_fbl7_');
      addTearDown(() => root.deleteSync(recursive: true));
      final file = File(p.join(root.path, 'cli.md'))
        ..writeAsStringSync('''
### [已确认] cli: 没链 issue
- 包/版本：w_tools_cli 1.9.6
- 状态变更：2026-11-03 已确认

### [已确认] cli: 链了 issue
- 包/版本：w_tools_cli 1.9.6
- 状态变更：2026-11-03 已确认 → #42
''');
      final result = const FeedbackLinter().lintFiles([file.path]);
      expect(result.issues, hasLength(1));
      expect(result.issues.single.line, 1);
      expect(result.issues.single.message, contains('issue'));
    });

    test('重复反馈与占位内容会报错', () {
      final root = _tmp('wt_fbl_quality_');
      addTearDown(() => root.deleteSync(recursive: true));
      final file = File(p.join(root.path, 'ui.md'))
        ..writeAsStringSync('''
### [待处理] ui: x
- 包/版本：w_tools_ui 6.0.0
- 环境：macOS
- 命令 / 输入：WImage(...)
- 期望：显示
- 实际：空白
- 影响：页面不可用
- 建议：补提示
- 复现数据：见附件

### [待处理] ui: x
- 包/版本：w_tools_ui 6.0.0
- 环境：macOS
- 命令 / 输入：WImage(...)
- 期望：显示
- 实际：空白
- 影响：页面不可用
- 建议：补提示
- 复现数据：见附件
''');
      final result = const FeedbackLinter().lintFiles([file.path]);
      expect(result.issues.any((i) => i.message.contains('重复反馈')), isTrue);
      expect(result.issues.any((i) => i.message.contains('标题不能是占位内容')), isTrue);
      expect(result.issues.any((i) => i.message.contains('不能是占位内容')), isTrue);
    });

    test('索引列了不存在的文件 → 报错', () {
      final root = _tmp('wt_fbl6_');
      addTearDown(() => root.deleteSync(recursive: true));
      final dir = p.join(root.path, 'feedback');
      Directory(dir).createSync();
      File(p.join(dir, 'README.md')).writeAsStringSync('''
| 包 | 待处理 |
| --- | --- |
| [map](map.md) | 0 |
''');
      final result = const FeedbackLinter().lintLibrary(Directory(dir));
      expect(result.issues.any((i) => i.message.contains('没有 map.md')), isTrue);
    });

    test('索引数量不一致会报错', () {
      final root = _tmp('wt_fbl3_');
      addTearDown(() => root.deleteSync(recursive: true));
      final dir = p.join(root.path, 'feedback');
      Directory(dir).createSync();
      File(p.join(dir, 'figma.md')).writeAsStringSync('''
### [待处理] figma: a
- 包/版本：x
''');
      File(p.join(dir, 'README.md')).writeAsStringSync('''
| 包 | 待处理 |
| --- | --- |
| [figma](figma.md) | 0 |
''');
      final result = const FeedbackLinter().lintLibrary(Directory(dir));
      expect(result.issues.any((i) => i.message.contains('索引')), isTrue);
    });
  });

  group('feedback 状态机', () {
    test('已修复必须带版本，不修必须带理由', () {
      final dir = _tmp('wt_fb_state_');
      final file = File(p.join(dir.path, 'cli.md'))
        ..writeAsStringSync('''
### [已修复] cli: 缺版本
- 影响：用户看不到修复版本

### [不修] cli: 缺理由
- 包/版本：w_tools_cli 1.9.5
''');
      addTearDown(() => dir.deleteSync(recursive: true));
      final result = const FeedbackLinter().lintFiles([file.path]);
      expect(result.ok, isFalse);
      expect(result.issues.any((i) => i.message.contains('已修复条目缺少版本号')), isTrue);
      expect(result.issues.any((i) => i.message.contains('不修条目缺少理由')), isTrue);
    });

    test('已修复带版本、不修带理由时通过', () {
      final dir = _tmp('wt_fb_state_ok_');
      final file = File(p.join(dir.path, 'cli.md'))
        ..writeAsStringSync('''
### [已修复] cli: 有版本
- 版本：1.9.5

### [不修] cli: 有理由
- 理由：与 5.0 设计冲突
''');
      addTearDown(() => dir.deleteSync(recursive: true));
      expect(const FeedbackLinter().lintFiles([file.path]).ok, isTrue);
    });
  });
}
