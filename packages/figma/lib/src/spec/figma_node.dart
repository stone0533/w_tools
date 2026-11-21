/// Figma 节点树的轻量读取工具（只依赖 `dart:convert` 解析出的 Map）。
///
/// 这里不做强类型建模：Figma 的 schema 会变，保持 Map 访问 + 防御式取值最稳。
library;

import 'dart:math' as math;

/// 把 Figma 的 `{r,g,b,a}` 颜色转成 `#RRGGBB`（带透明度时追加 `@0.20`）。
String figmaHex(Object? color) {
  if (color is! Map) return '';
  final r = _channel(color['r']);
  final g = _channel(color['g']);
  final b = _channel(color['b']);
  final a = color['a'] is num ? (color['a'] as num).toDouble() : 1;
  final hex = '#${_hex2(r)}${_hex2(g)}${_hex2(b)}';
  return a < 1 ? '$hex@${a.toStringAsFixed(2)}' : hex;
}

/// 填充 / 描边 paint 的 hex：把 paint 级 opacity 乘进 alpha。
String figmaPaintHex(Map paint) {
  final color = paint['color'];
  if (color is! Map) return '';
  final base = figmaHex(color);
  if (base.isEmpty) return base;
  final opacity = paint['opacity'] is num ? (paint['opacity'] as num).toDouble() : 1;
  if (opacity >= 1) return base;
  final alpha = (color['a'] is num ? (color['a'] as num).toDouble() : 1) * opacity;
  return '${base.split('@').first}@${alpha.toStringAsFixed(2)}';
}

String _opacitySuffix(Map paint) {
  final opacity = paint['opacity'] is num ? (paint['opacity'] as num).toDouble() : 1;
  return opacity < 1 ? '@${opacity.toStringAsFixed(2)}' : '';
}

int _channel(Object? v) => v is num ? (v * 255).round() : 0;

double _numValue(Object? v) => v is num ? v.toDouble() : 0;

String _hex2(int v) => v.toRadixString(16).toUpperCase().padLeft(2, '0');

/// 填充：纯色 / 图片 / 渐变（跳过隐藏层）。
String figmaFills(Map node) {
  final out = <String>[];
  for (final f in _list(node['fills'])) {
    if (f is! Map || f['visible'] == false) continue;
    final label = _paintLabel(f);
    if (label != null && label.isNotEmpty) out.add(label);
  }
  return out.isEmpty ? '-' : out.join(',');
}

/// paint 的人读标签；SOLID / IMAGE / GRADIENT 共用给填充和描边。
String? _paintLabel(Map paint) {
  final type = '${paint['type'] ?? ''}';
  if (type == 'SOLID') return figmaPaintHex(paint);
  if (type.startsWith('IMAGE')) return 'IMG${_opacitySuffix(paint)}';
  if (type.startsWith('GRADIENT')) return _gradientLabel(paint);
  return null;
}

String _gradientLabel(Map paint) {
  final stops = _list(paint['gradientStops']);
  final colors = <String>[];
  for (final stop in stops) {
    if (stop is Map) {
      final c = figmaHex(stop['color']);
      if (c.isNotEmpty) colors.add(c);
    }
  }
  var label = colors.isEmpty ? 'GRAD' : 'GRAD(${colors.join('→')})';
  final handles = paint['gradientHandlePositions'];
  if (handles is List && handles.length >= 2 && handles[0] is Map && handles[1] is Map) {
    final a = handles[0] as Map;
    final b = handles[1] as Map;
    final dx = _numValue(b['x']) - _numValue(a['x']);
    final dy = _numValue(b['y']) - _numValue(a['y']);
    if (dx != 0 || dy != 0) {
      label += '@${(math.atan2(dy, dx) * 180 / math.pi).toStringAsFixed(0)}°';
    }
  }
  final opacity = paint['opacity'] is num ? (paint['opacity'] as num).toDouble() : 1;
  if (opacity < 1) label += ', opacity=${opacity.toStringAsFixed(2)}';
  return label;
}

/// 描边：颜色 / 宽度 / 单边标记 / **虚线**（`strokeDashes` 是最常被漏掉的属性）。
String figmaStrokes(Map node) {
  final out = <String>[];
  for (final s in _list(node['strokes'])) {
    if (s is! Map || s['visible'] == false) continue;
    var desc = figmaPaintHex(s);
    final type = '${s['type'] ?? ''}';
    if (type != 'SOLID') {
      desc = _paintLabel(s) ?? '$type${_opacitySuffix(s)}';
    }
    final weight = _numText(node['strokeWeight']);
    if (weight.isNotEmpty) desc += ' ${weight}px';
    final align = node['strokeAlign'];
    if (align is String && align.isNotEmpty) desc += ' align=$align';
    final sides = node['individualStrokeWeights'];
    if (sides is Map && sides.isNotEmpty) {
      final marks = <String>[];
      for (final entry in sides.entries) {
        if (entry.value is! num || (entry.value as num) == 0) continue;
        final key = '${entry.key}';
        if (key.isEmpty) continue;
        final side = key.substring(0, 1).toUpperCase();
        marks.add('$side=${_numText(entry.value)}');
      }
      desc += ' [${marks.join(',')}]';
    }
    final dashes = node['strokeDashes'];
    if (dashes is List && dashes.isNotEmpty) desc += ' dash$dashes';
    final cap = node['strokeCap'];
    if (cap is String && cap != 'NONE' && cap != 'BUTT') desc += ' cap=$cap';
    final join = node['strokeJoin'];
    if (join is String && join != 'MITER') desc += ' join=$join';
    out.add(desc);
  }
  return out.isEmpty ? '-' : out.join('; ');
}

/// 效果（阴影 / 模糊）：类型 + 半径 + 透明度 + 偏移。
String figmaEffects(Map node) {
  final out = <String>[];
  for (final e in _list(node['effects'])) {
    if (e is! Map || e['visible'] == false) continue;
    var desc = '${e['type'] ?? '?'}';
    final effectColor = figmaPaintHex(e);
    if (effectColor.isNotEmpty) desc += ' $effectColor';
    final radius = e['radius'];
    if (radius is num && radius != 0) desc += ' r=$radius';
    final color = e['color'];
    if (color is Map && !effectColor.contains('@') && color['a'] is num) {
      final alpha = (color['a'] as num).toDouble();
      if (alpha < 1) desc += ' a=${alpha.toStringAsFixed(2)}';
    }
    final spread = e['spread'];
    if (spread is num && spread != 0) desc += ' spread=$spread';
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
  final style = node['style'];
  if (style != null && style is! Map) {
    throw StateError('节点 ${node['id']} 的 style 不是对象，缓存可能已损坏');
  }
  final st = style is Map ? style : const <String, dynamic>{};
  final parts = <String>[
    '${st['fontFamily'] ?? ''}',
    '${st['fontWeight'] ?? ''}',
    if (st['fontSize'] != null && '${st['fontSize']}'.isNotEmpty) '${st['fontSize']}px',
    'lh=${_pyRound(st['lineHeightPx'], 1)}',
    'ls=${_pyRound(st['letterSpacing'], 2)}',
    'align=${st['textAlignHorizontal'] ?? '?'}',
    if (st['textAlignVertical'] != null && st['textAlignVertical'] != 'TOP')
      'valign=${st['textAlignVertical']}',
    if (st['fontStyle'] != null && st['fontStyle'] != 'Regular') 'style=${st['fontStyle']}',
    if (st['textAutoResize'] != null && st['textAutoResize'] != 'NONE')
      'resize=${st['textAutoResize']}',
    if (st['paragraphSpacing'] is num && (st['paragraphSpacing'] as num) != 0)
      'para=${_pyRound(st['paragraphSpacing'], 1)}',
    if (st['textDecoration'] != null) 'deco=${st['textDecoration']}',
    if (st['textCase'] != null) 'case=${st['textCase']}',
  ];
  final color = figmaFills(node);
  if (color != '-') parts.add(color);

  // 富文本：一段文字里多种样式（颜色/字重）是最容易漏的
  final overrides = _list(node['characterStyleOverrides']);
  final rawTable = node['styleOverrideTable'];
  final table = rawTable is Map ? rawTable : const <String, dynamic>{};
  if (overrides.any((v) => v != 0) && table.isNotEmpty) {
    final chars = '${node['characters'] ?? ''}';
    Map? styleAt(int i) {
      if (i >= overrides.length) return null;
      final style = table['${overrides[i]}'];
      return style is Map ? style : null;
    }

    String styleText(Map? style) {
      if (style == null) return '';
      final fills = _list(style['fills']);
      final color =
          fills.isNotEmpty && fills.first is Map ? figmaHex((fills.first as Map)['color']) : '';
      // override 只写了 decoration 时，family / fontSize / weight 回退到 base style，
      // 不要输出孤立的 `px`。
      final family = style['fontFamily'] ?? st['fontFamily'];
      final fontSize = style['fontSize'] ?? st['fontSize'];
      final fontWeight = style['fontWeight'] ?? st['fontWeight'];
      return <String>[
        if (family != null && '$family'.isNotEmpty) '$family',
        if (fontSize != null && '$fontSize'.isNotEmpty) '${fontSize}px',
        if (fontWeight != null && '$fontWeight'.isNotEmpty) '$fontWeight',
        if (style['fontStyle'] != null && style['fontStyle'] != 'Regular') '${style['fontStyle']}',
        if (style['letterSpacing'] != null) 'ls=${_pyRound(style['letterSpacing'], 2)}',
        if (style['textCase'] != null) 'case=${style['textCase']}',
        if (style['textDecoration'] != null) 'deco=${style['textDecoration']}',
        color,
      ].where((e) => e.trim().isNotEmpty).join(' ');
    }

    String styleKey(Map? style) => styleText(style);

    final runs = <String>[];
    var start = 0;
    Map? currentStyle = styleAt(0);
    for (var i = 1; i <= chars.length; i++) {
      final style = i < chars.length ? styleAt(i) : null;
      if (i < chars.length && styleKey(style) == styleKey(currentStyle)) continue;
      final end = i - 1;
      final text = chars.substring(start, i);
      runs.add("[$start..$end]='$text' ${styleText(currentStyle)}".trim());
      start = i;
      currentStyle = style;
    }
    if (runs.isNotEmpty) parts.add('runs: ${runs.join(' ')}');
  }
  return parts.where((p) => p.isNotEmpty).join(' · ');
}

/// 在节点树里按 id 查节点（深度优先）。
Map? findFigmaNode(Map node, String id) {
  if (node['id'] == id) return node;
  for (final c in _list(node['children'])) {
    if (c is Map) {
      final hit = findFigmaNode(c, id);
      if (hit != null) return hit;
    }
  }
  return null;
}

List<Object?> _list(Object? value) => value is List ? value : const <Object?>[];

String _fmt1(Object? v) => pyFixed(v, 1);

/// 与 Python `f'{x:.1f}'` 一致：**四舍六入五成双**（round-half-even）。
///
/// Dart 的 `toStringAsFixed` 是「五一律进」，在 920.25 这种值上会与 Python 差 0.1；
/// 规格表的 golden（`test/fixtures/spec-expected.md`）来自迁移期对齐好的 Python 输出，
/// 所以这里保留同一取整规则，由 `test/spec_renderer_test.dart` 的 golden 与单测守住。
String pyFixed(Object? value, int digits) {
  final v = value is num ? value.toDouble() : 0;
  final factor = _pow10(digits);
  final scaled = v * factor;
  final sign = scaled < 0 ? -1.0 : 1.0;
  final abs = scaled.abs();
  final floor = abs.floorToDouble();
  final diff = abs - floor;
  double rounded;
  if (diff > 0.5 - 1e-9 && diff < 0.5 + 1e-9) {
    rounded = (floor % 2 == 0) ? floor : floor + 1;
  } else if (diff > 0.5) {
    rounded = floor + 1;
  } else {
    rounded = floor;
  }
  return (sign * rounded / factor).toStringAsFixed(digits);
}

double _pow10(int digits) {
  var f = 1.0;
  for (var i = 0; i < digits; i++) {
    f *= 10;
  }
  return f;
}

/// 模拟 Python `round(v, digits)` + `str()`：整数输入原样、浮点保留小数位。
String _pyRound(Object? v, int digits) {
  // Python 侧写的是 `round(x or 0, digits)`：0 / 0.0 / null 都会变成 int 0 → "0"
  if (v is! num) return '0';
  if (v == 0) return '0';
  if (v is int) return '$v';
  return double.parse(pyFixed(v, digits)).toString();
}

/// 与 Python 的 f-string 对齐：缺值打印 `None`，整数不带小数点。
String _numText(Object? v) => v == null ? '' : '$v';
