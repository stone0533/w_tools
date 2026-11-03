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

    test('非仓库检出 → 本项目收件箱', () {
      final project = _project(repoCheckout: false);
      final target = FeedbackTarget.resolve(projectRoot: project, package: 'figma');
      expect(target.kind, 'inbox');
      expect(target.path, endsWith('docs/agents/feedback.md'));
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
}
