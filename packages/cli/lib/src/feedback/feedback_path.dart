import 'dart:io';

import 'package:path/path.dart' as p;

import '../context/install_info.dart';

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
