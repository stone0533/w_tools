/// Figma 节点树的轻量读取工具（只依赖 `dart:convert` 解析出的 Map）。
///
/// 这里不做强类型建模：Figma 的 schema 会变，保持 Map 访问 + 防御式取值最稳。
library;

/// 把 Figma 的 `{r,g,b,a}` 颜色转成 `#RRGGBB`（带透明度时追加 `@0.20`）。
String figmaHex(Object? color) {
  if (color is! Map) return '';
  final r = _channel(color['r']);
  final g = _channel(color['g']);
  final b = _channel(color['b']);
  final a = (color['a'] as num?)?.toDouble() ?? 1;
  final hex = '#${_hex2(r)}${_hex2(g)}${_hex2(b)}';
  return a < 1 ? '$hex@${a.toStringAsFixed(2)}' : hex;
}

int _channel(Object? v) => (((v as num?) ?? 0) * 255).round();

String _hex2(int v) => v.toRadixString(16).toUpperCase().padLeft(2, '0');

/// 填充：纯色 / 图片 / 渐变（跳过隐藏层）。
String figmaFills(Map node) {
  final out = <String>[];
  for (final f in (node['fills'] as List?) ?? const []) {
    if (f is! Map || f['visible'] == false) continue;
    final type = '${f['type'] ?? ''}';
    if (type == 'SOLID') {
      out.add(figmaHex(f['color']));
    } else if (type.startsWith('IMAGE')) {
      out.add('IMG');
    } else if (type.startsWith('GRADIENT')) {
      out.add('GRAD');
    }
  }
  return out.isEmpty ? '-' : out.join(',');
}

/// 描边：颜色 / 宽度 / 单边标记 / **虚线**（`strokeDashes` 是最常被漏掉的属性）。
String figmaStrokes(Map node) {
  final out = <String>[];
  for (final s in (node['strokes'] as List?) ?? const []) {
    if (s is! Map || s['visible'] == false) continue;
    var desc = figmaHex(s['color']);
    if ('${s['type'] ?? ''}' != 'SOLID') desc = '${s['type'] ?? '?'}';
    desc += ' ${_numText(node['strokeWeight'])}px';
    final sides = node['individualStrokeWeights'];
    if (sides is Map && sides.isNotEmpty) {
      final marks = <String>[];
      for (final entry in sides.entries) {
        if ((entry.value as num?) != null && (entry.value as num) != 0) {
          marks.add('${entry.key}'[0].toUpperCase());
        }
      }
      desc += ' [${marks.join(',')}]';
    }
    final dashes = node['strokeDashes'];
    if (dashes is List && dashes.isNotEmpty) desc += ' dash$dashes';
    out.add(desc);
  }
  return out.isEmpty ? '-' : out.join('; ');
}

/// 效果（阴影 / 模糊）：类型 + 半径 + 透明度 + 偏移。
String figmaEffects(Map node) {
  final out = <String>[];
  for (final e in (node['effects'] as List?) ?? const []) {
    if (e is! Map || e['visible'] == false) continue;
    var desc = '${e['type'] ?? '?'}';
    final radius = e['radius'];
    if (radius is num && radius != 0) desc += ' r=$radius';
    final color = e['color'];
    if (color is Map && color['a'] != null) {
      desc += ' a=${(color['a'] as num).toDouble().toStringAsFixed(2)}';
    }
    final offset = e['offset'];
    if (offset is Map) {
      desc += ' off=(${_fmt1(offset['x'])},${_fmt1(offset['y'])})';
    }
    out.add(desc);
  }
  return out.isEmpty ? '-' : out.join(',');
}

/// 文字规格：字体 / 字重 / 字号 / 行高 / 字距 / 对齐 / 颜色 / 富文本分段。
String figmaTextSpec(Map node) {
  final st = (node['style'] as Map?) ?? const {};
  final parts = <String>[
    '${st['fontFamily'] ?? ''}',
    '${st['fontWeight'] ?? ''}',
    '${st['fontSize'] ?? ''}px',
    'lh=${_pyRound(st['lineHeightPx'], 1)}',
    'ls=${_pyRound(st['letterSpacing'], 2)}',
    'align=${st['textAlignHorizontal'] ?? '?'}',
  ];
  final color = figmaFills(node);
  if (color != '-') parts.add(color);

  // 富文本：一段文字里多种样式（颜色/字重）是最容易漏的
  final overrides = (node['characterStyleOverrides'] as List?) ?? const [];
  final table = (node['styleOverrideTable'] as Map?) ?? const {};
  if (overrides.any((v) => v != 0) && table.isNotEmpty) {
    final chars = '${node['characters'] ?? ''}';
    final runs = <String>[];
    for (var i = 0; i < overrides.length; i++) {
      final style = table['${overrides[i]}'];
      if (style is! Map) continue;
      var runColor = '';
      final fs = (style['fills'] as List?) ?? const [];
      if (fs.isNotEmpty && fs.first is Map) {
        runColor = figmaHex((fs.first as Map)['color']);
      }
      final ch = i < chars.length ? chars[i] : '';
      runs.add("[$i]='$ch' ${style['fontWeight'] ?? ''} $runColor");
    }
    if (runs.isNotEmpty) parts.add('runs: ${runs.take(8).join(' ')}');
  }
  return parts.where((p) => p.isNotEmpty).join(' | ');
}

/// 在节点树里按 id 查节点（深度优先）。
Map? findFigmaNode(Map node, String id) {
  if (node['id'] == id) return node;
  for (final c in (node['children'] as List?) ?? const []) {
    if (c is Map) {
      final hit = findFigmaNode(c, id);
      if (hit != null) return hit;
    }
  }
  return null;
}

String _fmt1(Object? v) => ((v as num?) ?? 0).toDouble().toStringAsFixed(1);

/// 模拟 Python `round(v, digits)` + `str()`：整数输入原样、浮点保留小数位。
String _pyRound(Object? v, int digits) {
  // Python 侧写的是 `round(x or 0, digits)`：0 / 0.0 / null 都会变成 int 0 → "0"
  if (v is! num) return '0';
  if (v == 0) return '0';
  if (v is int) return '$v';
  return double.parse(v.toStringAsFixed(digits)).toString();
}

/// 与 Python 的 f-string 对齐：缺值打印 `None`，整数不带小数点。
String _numText(Object? v) => v == null ? 'None' : '$v';
