import 'dart:io';

import 'package:path/path.dart' as p;

import '../context/install_info.dart';

/// 校验 `--package`：只允许小写字母/数字/下划线，防止 `../` 穿越到反馈目录之外。
///
/// 返回规范化后的包名；`null` / 空串视为「不指定包」，返回 null。
String? validatePackageName(String? package) {
  if (package == null || package.isEmpty) return null;
  if (!RegExp(r'^[a-z0-9_]+$').hasMatch(package)) {
    throw FormatException('--package 只允许小写字母/数字/下划线：$package');
  }
  return package;
}

/// 旧版本地收件箱：`docs/agents/feedback.md`。仅用于 lint/search 的只读兼容，不再作为提交目标。
File inboxFile(Directory projectRoot) =>
    File(p.join(projectRoot.path, 'docs', 'agents', 'feedback.md'));

/// 反馈该写到哪个文件（或目录）。
class FeedbackTarget {
  const FeedbackTarget({
    required this.path,
    required this.kind,
    required this.exists,
  });

  /// 库侧单包文件 / 目录；消费方禁用时为 null。
  final String? path;

  /// `library-package` / `library-dir` / `disabled`
  final String kind;
  final bool exists;

  bool get isLibrary => kind == 'library-package' || kind == 'library-dir';

  Map<String, Object?> toJson() => <String, Object?>{
    'path': path,
    'kind': kind,
    'exists': exists,
  };

  /// - 有库仓库时：`<repo>/docs/feedback/<包>.md`（不给 `--package` 则是目录）
  /// - 否则：disabled，不返回本地收件箱路径
  static FeedbackTarget resolve({
    required Directory projectRoot,
    String? package,
  }) {
    final install = InstallInfo.detect(projectRoot: projectRoot);
    final dir = install.feedbackDir;
    if (dir != null) {
      if (package != null && package.isNotEmpty) {
        final file = p.join(dir, '$package.md');
        return FeedbackTarget(
          path: file,
          kind: 'library-package',
          exists: File(file).existsSync(),
        );
      }
      return FeedbackTarget(
        path: dir,
        kind: 'library-dir',
        exists: Directory(dir).existsSync(),
      );
    }
    return const FeedbackTarget(
      path: null,
      kind: 'disabled',
      exists: false,
    );
  }
}
