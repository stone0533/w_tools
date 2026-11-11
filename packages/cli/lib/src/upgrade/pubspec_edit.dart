// 只改 `dependencies:` / `dev_dependencies:` 里指名包的**版本 token**。
//
// 为什么不整份 YAML 往返：消费方 pubspec 里的注释是事实源（为什么钉死某个版本、
// 哪个 major 有语义变化）。`pub upgrade --major-versions --tighten` 自己也是
// 只改 token 的写法；这里用同样的策略，其余字节一律不动。

const _sections = <String>{'dependencies', 'dev_dependencies'};

class PubspecEdit {
  const PubspecEdit({required this.text, required this.applied, required this.missed});

  final String text;

  /// 实际写掉的包 → 新约束。
  final Map<String, String> applied;

  /// 传进来但没在对应 section 里找到约束行的包。
  final List<String> missed;
}

/// 把 [updates]（包 → 新约束）写进 [text]；找不到的包记到 [PubspecEdit.missed]。
PubspecEdit raiseConstraints(String text, Map<String, String> updates) {
  final eol = text.contains('\r\n') ? '\r\n' : '\n';
  final lines = text.split(eol);
  final pending = Map<String, String>.of(updates);
  final applied = <String, String>{};

  void scan(int start, int end) {
    for (var i = start; i < end; i++) {
      final entry = _parseEntry(lines[i]);
      if (entry == null) continue;
      final newValue = pending.remove(entry.key);
      if (newValue == null) continue;
      lines[i] = '${entry.prefix}${entry.quotes}$newValue${entry.quotes}${entry.suffix}';
      applied[entry.key] = newValue;
    }
  }

  var i = 0;
  while (i < lines.length) {
    final section = _sectionHeader(lines[i]);
    if (section == null) {
      i++;
      continue;
    }
    final start = i + 1;
    var end = start;
    while (end < lines.length && !_isTopLevelKey(lines[end])) {
      end++;
    }
    scan(start, end);
    i = end;
  }

  return PubspecEdit(
    text: lines.join(eol),
    applied: applied,
    missed: pending.keys.toList()..sort(),
  );
}

String? _sectionHeader(String line) {
  final match = RegExp(r'^([A-Za-z_][A-Za-z0-9_]*):\s*(?:#.*)?$').firstMatch(line);
  if (match == null) return null;
  final name = match.group(1)!;
  return _sections.contains(name) ? name : null;
}

/// 顶格、非空、非注释 → 下一个顶层键，section 到这里结束。
bool _isTopLevelKey(String line) {
  if (line.trim().isEmpty) return false;
  if (line.startsWith('#')) return false;
  return !line.startsWith(' ') && !line.startsWith('\t');
}

class _Entry {
  const _Entry({
    required this.key,
    required this.prefix,
    required this.suffix,
    required this.quotes,
  });

  final String key;
  final String prefix;

  /// 原来的引号（`"` / `'` / 空），写回时保持同样的写法。
  final String quotes;

  /// 值后面的行尾注释（含它前面的空格），原样保留。
  final String suffix;
}

_Entry? _parseEntry(String line) {
  final match = RegExp(r'^(\s+)([A-Za-z_][A-Za-z0-9_]*):(\s*)(.*)$').firstMatch(line);
  if (match == null) return null;
  final rest = match.group(4)!;
  final trimmed = rest.trim();
  // `name:` 后面跟缩进块 = path / git 依赖；计划阶段已经跳过，这里也不动。
  if (trimmed.isEmpty || trimmed.startsWith('#')) return null;

  final String value;
  final String suffix;
  if (trimmed.startsWith('"') || trimmed.startsWith("'")) {
    final quote = trimmed[0];
    final close = trimmed.indexOf(quote, 1);
    if (close < 0) return null;
    value = trimmed.substring(0, close + 1);
    suffix = rest.substring(rest.indexOf(trimmed) + value.length);
  } else {
    final comment = RegExp(r'\s+#').firstMatch(rest);
    if (comment == null) {
      value = rest;
      suffix = '';
    } else {
      value = rest.substring(0, comment.start);
      suffix = rest.substring(comment.start);
    }
  }
  // 纯版本 token 才改：`^1.2.3` / `"^1.2.3"` / `1.2.3`。
  if (!RegExp(r'''^["']?\^?\d+\.\d+\.\d+["']?$''').hasMatch(value.trim())) return null;

  final quotes = value.startsWith('"') ? '"' : (value.startsWith("'") ? "'" : '');
  return _Entry(
    key: match.group(2)!,
    prefix: '${match.group(1)}${match.group(2)}:${match.group(3)}',
    suffix: suffix,
    quotes: quotes,
  );
}
