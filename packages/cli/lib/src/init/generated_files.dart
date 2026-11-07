import 'targets.dart';

/// `init` 生成物里带版本标记的文件清单。
///
/// `init` 的写入、`--check-drift`、doctor R8 必须使用同一份清单，
/// 否则会出现「init 会生成、doctor 不检查」的漂移。
class GeneratedFiles {
  const GeneratedFiles._();

  static const aiPrompts = '.w_tools/AI_PROMPTS.md';

  static List<String> versioned({
    required String toolkitEntry,
    required Iterable<String> targets,
  }) {
    final files = <String>{toolkitEntry, aiPrompts};
    for (final target in targets) {
      final path = targetFiles[target];
      if (path != null) files.add(path);
    }
    return files.toList();
  }
}
