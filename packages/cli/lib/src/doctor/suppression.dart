/// 解析 `// w_tools:ignore R9 reason: ...` / `// w_tools:ignore-file R9 reason: ...`。
///
/// 只有带非空 `reason:` 的标记才生效，避免无说明地屏蔽规则。
class Suppression {
  static final _marker = RegExp(
    r'w_tools:ignore(?:-file)?\s+([A-Za-z0-9_,\s]+?)(?:\s+reason:\s*(.+))?$',
  );

  static bool isIgnored(List<String> lines, int zeroBasedLine, String ruleId) {
    if (_isFileIgnored(lines, ruleId)) return true;
    return _isLineIgnored(lines, zeroBasedLine, ruleId) ||
        (zeroBasedLine > 0 && _isLineIgnored(lines, zeroBasedLine - 1, ruleId));
  }

  static bool _isFileIgnored(List<String> lines, String ruleId) {
    final end = lines.length < 20 ? lines.length : 20;
    for (var i = 0; i < end; i++) {
      if (_matches(lines[i], ruleId) && _isFileMarker(lines[i])) return true;
    }
    return false;
  }

  static bool _isLineIgnored(List<String> lines, int index, String ruleId) {
    if (index < 0 || index >= lines.length) return false;
    return _matches(lines[index], ruleId) && !_isFileMarker(lines[index]);
  }

  static bool _isFileMarker(String line) => line.contains('w_tools:ignore-file');

  static bool _matches(String line, String ruleId) {
    final match = _marker.firstMatch(line.trim());
    if (match == null) return false;
    final reason = match.group(2)?.trim();
    if (reason == null || reason.isEmpty) return false;
    final ids = match.group(1)!.split(',').map((e) => e.trim()).toSet();
    return ids.contains(ruleId);
  }
}
