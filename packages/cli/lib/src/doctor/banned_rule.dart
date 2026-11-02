import 'rule.dart';

/// `banned` 配置里的匹配方式。
enum BannedPatternMode { literal, regex }

/// 一条项目级禁用规则。
///
/// 配置来自 `.w_tools_doctor.yaml` 的 `banned` 列表；doctor 只负责扫描文本，
/// 具体“为什么禁用 / 应该改用什么”由配置提供，避免把项目偏好写死在 CLI 里。
class BannedRule {
  const BannedRule({
    required this.id,
    required this.pattern,
    required this.mode,
    required this.use,
    required this.reason,
    required this.level,
    required this.paths,
    required this.ignore,
    this.error,
  });

  final String id;
  final String pattern;
  final BannedPatternMode mode;
  final String? use;
  final String? reason;
  final DoctorLevel level;
  final List<String> paths;
  final List<String> ignore;

  /// 配置错误（缺少 id / pattern、非法 regex 等）；有值时规则只报配置问题。
  final String? error;

  bool appliesTo(String relPath) {
    if (paths.isNotEmpty && !paths.any((pattern) => _globMatches(relPath, pattern))) {
      return false;
    }
    if (ignore.any((pattern) => _globMatches(relPath, pattern))) return false;
    return true;
  }

  bool matches(String sourceLine) {
    if (error != null || pattern.isEmpty) return false;
    if (mode == BannedPatternMode.literal) return sourceLine.contains(pattern);
    try {
      return RegExp(pattern).hasMatch(sourceLine);
    } on FormatException {
      return false;
    }
  }

  /// 配置校验：返回 null 表示可用。
  String? validate() {
    if (error != null) return error;
    if (id.trim().isEmpty) return 'banned 条目缺少 id';
    if (pattern.isEmpty) return 'banned 条目 `$id` 缺少 pattern';
    if (mode == BannedPatternMode.regex) {
      try {
        RegExp(pattern);
      } on FormatException catch (e) {
        return 'banned 条目 `$id` 的 regex 无效：${e.message}';
      }
    }
    return null;
  }
}

/// 轻量 glob：支持 `*`、`**`、`?`；不含通配符时按文件/目录前缀匹配。
bool _globMatches(String relPath, String rawPattern) {
  final pattern = rawPattern.replaceAll('\\', '/').replaceFirst(RegExp(r'/+$'), '');
  if (!pattern.contains('*') && !pattern.contains('?')) {
    return relPath == pattern || relPath.startsWith('$pattern/');
  }

  final buffer = StringBuffer('^');
  for (var i = 0; i < pattern.length; i++) {
    final char = pattern[i];
    if (char == '*') {
      if (i + 1 < pattern.length && pattern[i + 1] == '*') {
        buffer.write('.*');
        i++;
      } else {
        buffer.write('[^/]*');
      }
    } else if (char == '?') {
      buffer.write('.');
    } else {
      buffer.write(RegExp.escape(char));
    }
  }
  buffer.write(r'$');
  return RegExp(buffer.toString()).hasMatch(relPath);
}
