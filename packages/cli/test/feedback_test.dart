import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:w_tools_cli/src/feedback/feedback_lint.dart';
import 'package:w_tools_cli/src/feedback/feedback_path.dart';

Directory _tmp(String prefix) => Directory.systemTemp.createTempSync(prefix);

/// 造一个「项目 → 指向 packages/cli 的 package_config」，可控制是否为仓库检出。
Directory _project({required bool repoCheckout}) {
  final root = _tmp('wt_fb_');
  final repo = p.join(root.path, 'repo');
  final pkg = Directory(p.join(repo, 'packages', 'cli'))..createSync(recursive: true);
  File(p.join(pkg.path, 'pubspec.yaml')).writeAsStringSync('name: w_tools_cli\n');
  if (repoCheckout) {
    Directory(p.join(repo, 'docs', 'feedback')).createSync(recursive: true);
  }
  final project = Directory(p.join(root.path, 'app'))..createSync(recursive: true);
  final config = File(p.join(project.path, '.dart_tool', 'package_config.json'))
    ..createSync(recursive: true);
  config.writeAsStringSync(
    '{"configVersion":2,"packages":[{"name":"w_tools_cli","rootUri":"${pkg.uri}"}]}',
  );
  return project;
}

void main() {
  group('feedback path', () {
    test('仓库检出 → 库侧单包文件', () {
      final project = _project(repoCheckout: true);
      final target = FeedbackTarget.resolve(projectRoot: project, package: 'figma');
      expect(target.kind, 'library-package');
      expect(target.path, endsWith('docs/feedback/figma.md'));
      expect(target.exists, isFalse);
    });

    test('仓库检出、不给包 → 库侧目录', () {
      final project = _project(repoCheckout: true);
      final target = FeedbackTarget.resolve(projectRoot: project);
      expect(target.kind, 'library-dir');
    });

    test('非仓库检出 → disabled，不返回本地收件箱', () {
      final project = _project(repoCheckout: false);
      final target = FeedbackTarget.resolve(projectRoot: project, package: 'figma');
      expect(target.kind, 'disabled');
      expect(target.path, isNull);
      expect(target.exists, isFalse);
    });
  });

  group('feedback path 的入参校验', () {
    test('合法包名原样返回；空 / null 视为不指定', () {
      expect(validatePackageName('figma'), 'figma');
      expect(validatePackageName('e2e'), 'e2e');
      expect(validatePackageName(null), isNull);
      expect(validatePackageName(''), isNull);
    });

    test('带 .. 或大小写的包名抛 FormatException', () {
      expect(() => validatePackageName('../evil'), throwsFormatException);
      expect(() => validatePackageName('Fig'), throwsFormatException);
      expect(() => validatePackageName('a/b'), throwsFormatException);
    });

    test('收件箱路径固定为 docs/agents/feedback.md', () {
      final root = Directory.systemTemp.createTempSync('wt_fb_inbox_');
      addTearDown(() => root.deleteSync(recursive: true));
      expect(inboxFile(root).path, endsWith('docs/agents/feedback.md'));
    });
  });

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
