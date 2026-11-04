/// 轻量 glob：支持 `*`、`**`、`?`；不含通配符时按文件/目录前缀匹配。
final Map<String, RegExp> _globCache = <String, RegExp>{};

bool globMatches(String relPath, String rawPattern) {
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
  final regex = _globCache.putIfAbsent(pattern, () => RegExp(buffer.toString()));
  return regex.hasMatch(relPath);
}
