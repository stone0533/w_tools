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
  String _fontStyle = '';
  String _textCase = '';
  String _textDecoration = '';

  /// 字体样式：Regular / Italic / ...
  String get fontStyle => _fontStyle;

  /// 大小写变换（UPPER / LOWER / TITLE ...）；空串表示未设置。
  String get textCase => _textCase;

  /// 文字装饰（UNDERLINE / STRIKETHROUGH ...）；空串表示未设置。
  String get textDecoration => _textDecoration;

  int count = 0;
  final List<String> samples = [];

  String get key =>
      '$family|$size|$weight|$lineHeight|$letterSpacing|$align|$color|$_fontStyle|$_textCase|$_textDecoration';
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
  TokenCollector({this.minCount = 1, this.skipNamePrefixes = const <String>[]});

  /// 低于该次数的项不输出。
  final int minCount;

  /// 名称命中任一前缀的子树不统计（与 `spec --skip-name-prefix` 同语义）。
  final List<String> skipNamePrefixes;

  final Map<String, ColorUsage> colors = {};
  final Map<String, TextStyleUsage> texts = {};
  final Map<String, NumberUsage> radii = {};
  final Map<String, NumberUsage> spacings = {};

  /// 统计 [document] 子树（可多次调用，累加）。
  void collect(Map document) => _walk(document, inheritedVisible: true, inheritedOpacity: 1);

  void _walk(
    Map node, {
    required bool inheritedVisible,
    required double inheritedOpacity,
  }) {
    final opacity = (node['opacity'] as num?)?.toDouble() ?? 1;
    final effectiveOpacity = inheritedOpacity * opacity;
    final visible = inheritedVisible && node['visible'] != false && effectiveOpacity > 0;
    if (!visible) return;
    _collectFills(node);
    _collectStrokes(node);
    _collectText(node);
    _collectRadius(node);
    _collectSpacing(node);
    for (final c in _list(node['children'])) {
      if (c is! Map) continue;
      if (skipNamePrefixes.any('${c['name'] ?? ''}'.startsWith)) continue;
      _walk(c, inheritedVisible: visible, inheritedOpacity: effectiveOpacity);
    }
  }

  void _collectFills(Map node) {
    for (final f in _list(node['fills'])) {
      if (f is! Map || f['visible'] == false) continue;
      if ('${f['type']}' != 'SOLID') continue;
      _addColor(figmaPaintHex(f), _label(node));
    }
  }

  void _collectStrokes(Map node) {
    for (final s in _list(node['strokes'])) {
      if (s is! Map || s['visible'] == false) continue;
      if ('${s['type']}' != 'SOLID') continue;
      _addColor(figmaPaintHex(s), _label(node));
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
    usage._fontStyle = '${st['fontStyle'] ?? ''}';
    usage._textCase = '${st['textCase'] ?? ''}';
    usage._textDecoration = '${st['textDecoration'] ?? ''}';
    final entry = texts.putIfAbsent(usage.key, () => usage);
    entry.count++;
    if (entry.samples.length < 3) entry.samples.add(_label(node));

    // rich text 的 run 样式也要进 token；颜色之外还要区分斜体 / 字号 / 字重。
    final overrides = _list(node['characterStyleOverrides']);
    final rawTable = node['styleOverrideTable'];
    final table = rawTable is Map ? rawTable : const <String, dynamic>{};
    final seenRuns = <String>{};
    for (final id in overrides) {
      final style = table['$id'];
      if (style is! Map) continue;
      final runFamily = '${style['fontFamily'] ?? st['fontFamily'] ?? ''}';
      final runSize = _fmtNum(style['fontSize'] ?? st['fontSize']);
      final runWeight = _numText(style['fontWeight'] ?? st['fontWeight']);
      final runStyle = '${style['fontStyle'] ?? st['fontStyle'] ?? ''}';
      final runCase = '${style['textCase'] ?? st['textCase'] ?? ''}';
      final runDecoration = '${style['textDecoration'] ?? st['textDecoration'] ?? ''}';
      final runAlign = '${st['textAlignHorizontal'] ?? '?'}';
      final runColor = _firstFillColor({'fills': style['fills'] ?? node['fills']});
      final runKey =
          '$runFamily|$runSize|$runWeight|${_fmtNum(style['lineHeightPx'] ?? st['lineHeightPx'])}|'
          '${_fmtNum(style['letterSpacing'] ?? st['letterSpacing'])}|$runAlign|$runColor|$runStyle|$runCase|$runDecoration';
      if (!seenRuns.add(runKey)) continue;
      final run = TextStyleUsage(
        family: runFamily,
        size: runSize,
        weight: runWeight,
        lineHeight: _fmtNum(style['lineHeightPx'] ?? st['lineHeightPx']),
        letterSpacing: _fmtNum(style['letterSpacing'] ?? st['letterSpacing']),
        align: runAlign,
        color: runColor,
      );
      run._fontStyle = runStyle;
      run._textCase = runCase;
      run._textDecoration = runDecoration;
      final runEntry = texts.putIfAbsent(run.key, () => run);
      runEntry.count++;
      if (runEntry.samples.length < 3) runEntry.samples.add('${_label(node)} [run]');
      final fills = _list(style['fills']);
      for (final fill in fills) {
        if (fill is! Map || fill['visible'] == false || '${fill['type']}' != 'SOLID') continue;
        final color = figmaPaintHex(fill);
        if (color.isNotEmpty) _addColor(color, _label(node));
      }
    }
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
    for (final f in _list(node['fills'])) {
      if (f is! Map || f['visible'] == false) continue;
      if ('${f['type']}' == 'SOLID') return figmaHex(f['color']);
    }
    return '';
  }

  List<Object?> _list(Object? value) => value is List ? value : const <Object?>[];

  String _label(Map node) {
    final characters = '${node['characters'] ?? ''}';
    final id = '${node['id'] ?? ''}';
    if (characters.isNotEmpty) {
      // JSON samples 保留全文；视觉截断只在 Markdown 渲染层做，避免 UTF-16 切断代理项。
      return '「$characters」${id.isEmpty ? '' : ' ($id)'}';
    }
    final name = '${node['name'] ?? ''}';
    if (name.isEmpty) return id;
    return id.isEmpty ? name : '$name ($id)';
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
