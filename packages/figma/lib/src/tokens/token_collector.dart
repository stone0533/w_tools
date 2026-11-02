import '../spec/figma_node.dart';

/// 一处色值的统计项。
class ColorUsage {
  ColorUsage(this.value);

  /// `#RRGGBB`；带透明度时形如 `#RRGGBB@0.20`。
  final String value;

  /// 出现次数。
  int count = 0;

  /// 示例位置（最多 3 个）。
  final List<String> samples = [];
}

/// 一处文字样式的统计项。
class TextStyleUsage {
  TextStyleUsage({
    required this.family,
    required this.size,
    required this.weight,
    required this.lineHeight,
    required this.letterSpacing,
    required this.align,
    required this.color,
  });

  final String family;
  final String size;
  final String weight;
  final String lineHeight;
  final String letterSpacing;
  final String align;
  final String color;

  int count = 0;
  final List<String> samples = [];

  String get key => '$family|$size|$weight|$lineHeight|$letterSpacing|$align|$color';
}

/// 数值型统计（圆角 / 间距）。
class NumberUsage {
  NumberUsage(this.value);

  final String value;
  int count = 0;
}

/// 从一个或多个子树里汇总设计 token（颜色 / 文字 / 圆角 / 间距）。
///
/// 只读缓存，不联网；`minCount` 控制「出现次数低于阈值的值是否列出」。
class TokenCollector {
  TokenCollector({this.minCount = 1});

  /// 低于该次数的项不输出。
  final int minCount;

  final Map<String, ColorUsage> colors = {};
  final Map<String, TextStyleUsage> texts = {};
  final Map<String, NumberUsage> radii = {};
  final Map<String, NumberUsage> spacings = {};

  /// 统计 [document] 子树（可多次调用，累加）。
  void collect(Map document) => _walk(document);

  void _walk(Map node) {
    _collectFills(node);
    _collectStrokes(node);
    _collectText(node);
    _collectRadius(node);
    _collectSpacing(node);
    for (final c in (node['children'] as List?) ?? const []) {
      if (c is Map) _walk(c);
    }
  }

  void _collectFills(Map node) {
    for (final f in (node['fills'] as List?) ?? const []) {
      if (f is! Map || f['visible'] == false) continue;
      if ('${f['type']}' != 'SOLID') continue;
      _addColor(figmaHex(f['color']), _label(node));
    }
  }

  void _collectStrokes(Map node) {
    for (final s in (node['strokes'] as List?) ?? const []) {
      if (s is! Map || s['visible'] == false) continue;
      if ('${s['type']}' != 'SOLID') continue;
      _addColor(figmaHex(s['color']), _label(node));
    }
  }

  void _collectText(Map node) {
    if ('${node['type']}' != 'TEXT') return;
    final st = node['style'];
    if (st is! Map) return;
    final usage = TextStyleUsage(
      family: '${st['fontFamily'] ?? ''}',
      size: _fmtNum(st['fontSize']),
      weight: _numText(st['fontWeight']),
      lineHeight: _fmtNum(st['lineHeightPx']),
      letterSpacing: _fmtNum(st['letterSpacing']),
      align: '${st['textAlignHorizontal'] ?? '?'}',
      color: _firstFillColor(node),
    );
    final entry = texts.putIfAbsent(usage.key, () => usage);
    entry.count++;
    if (entry.samples.length < 3) entry.samples.add(_label(node));
  }

  void _collectRadius(Map node) {
    final corner = node['cornerRadius'];
    if (corner is num && corner > 0) {
      _addNumber(_numText(corner), radii);
    }
    final corners = node['rectangleCornerRadii'];
    if (corners is List) {
      for (final v in corners) {
        if (v is num && v > 0) _addNumber(_numText(v), radii);
      }
    }
  }

  void _collectSpacing(Map node) {
    for (final key in const [
      'itemSpacing',
      'paddingLeft',
      'paddingRight',
      'paddingTop',
      'paddingBottom',
    ]) {
      final v = node[key];
      if (v is num && v > 0) _addNumber(_numText(v), spacings);
    }
  }

  void _addColor(String value, String sample) {
    if (value.isEmpty) return;
    final entry = colors.putIfAbsent(value, () => ColorUsage(value));
    entry.count++;
    if (entry.samples.length < 3) entry.samples.add(sample);
  }

  void _addNumber(String value, Map<String, NumberUsage> target) {
    if (value.isEmpty || value == 'None') return;
    final entry = target.putIfAbsent(value, () => NumberUsage(value));
    entry.count++;
  }

  String _firstFillColor(Map node) {
    for (final f in (node['fills'] as List?) ?? const []) {
      if (f is! Map || f['visible'] == false) continue;
      if ('${f['type']}' == 'SOLID') return figmaHex(f['color']);
    }
    return '';
  }

  String _label(Map node) {
    final characters = '${node['characters'] ?? ''}';
    if (characters.isNotEmpty) {
      final short = characters.length > 12 ? characters.substring(0, 12) : characters;
      return '「$short」';
    }
    final name = '${node['name'] ?? ''}';
    return name.isEmpty ? '${node['id']}' : name;
  }

  String _numText(Object? v) {
    if (v == null) return '';
    return '$v';
  }

  /// 去掉浮点噪声：`19.200000762939453` → `19.2`，`16.0` → `16`，`0.0` → `0`。
  String _fmtNum(Object? v) {
    if (v is! num) return '';
    final s = double.parse(v.toStringAsFixed(2)).toString();
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  List<ColorUsage> colorsSorted() => _sorted(colors.values, (e) => e.value);

  List<TextStyleUsage> textsSorted() => _sorted(texts.values, (e) => e.key);

  List<NumberUsage> radiiSorted() => _sorted(radii.values, (e) => e.value);

  List<NumberUsage> spacingsSorted() => _sorted(spacings.values, (e) => e.value);

  List<T> _sorted<T extends Object>(Iterable<T> items, String Function(T) keyOf) {
    final filtered = items.where((e) => _countOf(e) >= minCount).toList();
    filtered.sort((a, b) {
      final byCount = _countOf(b).compareTo(_countOf(a));
      return byCount != 0 ? byCount : keyOf(a).compareTo(keyOf(b));
    });
    return filtered;
  }

  int _countOf(Object e) => switch (e) {
        ColorUsage(:final count) => count,
        TextStyleUsage(:final count) => count,
        NumberUsage(:final count) => count,
        _ => 0,
      };
}
