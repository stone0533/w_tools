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

/// 本项目收件箱：`docs/agents/feedback.md`（无论是否检出仓库，都可能存在）。
File inboxFile(Directory projectRoot) =>
    File(p.join(projectRoot.path, 'docs', 'agents', 'feedback.md'));

/// 反馈该写到哪个文件（或目录）。
class FeedbackTarget {
  const FeedbackTarget({
    required this.path,
    required this.kind,
    required this.exists,
  });

  /// 库侧单包文件，或消费方收件箱文件，或库侧反馈目录。
  final String path;

  /// `library-package` / `inbox` / `library-dir`
  final String kind;
  final bool exists;

  bool get isLibrary => kind != 'inbox';

  Map<String, Object?> toJson() => <String, Object?>{
    'path': path,
    'kind': kind,
    'exists': exists,
  };

  /// - 有库仓库时：`<repo>/docs/feedback/<包>.md`（不给 `--package` 则是目录）
  /// - 否则：项目里的收件箱 `docs/agents/feedback.md`
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
    final inbox = p.join(projectRoot.path, 'docs', 'agents', 'feedback.md');
    return FeedbackTarget(
      path: inbox,
      kind: 'inbox',
      exists: File(inbox).existsSync(),
    );
  }
}
