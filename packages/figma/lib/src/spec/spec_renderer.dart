import 'figma_node.dart';

/// 把一个画板节点渲染成 Markdown 规格表。
///
/// golden（`test/fixtures/spec-expected.md`）来自迁移期对齐好的 Python 输出；
/// 现在的守卫是 `test/spec_renderer_test.dart`。
class FigmaSpecRenderer {
  /// 名称命中任一前缀的节点会被跳过；默认不跳过，CLI 用 `--skip-name-prefix`。
  const FigmaSpecRenderer({
    this.skipNamePrefixes = const [],
    this.showNodeId = false,
    this.showLayout = false,
  });

  final List<String> skipNamePrefixes;

  /// markdown 表格是否加 `id` 列；默认关，避免表格变宽。
  final bool showNodeId;

  /// markdown 表格是否加 `布局` 列（layoutMode / itemSpacing / padding）。
  final bool showLayout;

  /// 从任意根节点开始查找 [targetId]。
  ///
  /// markdown 与 `spec --json` 的 `items[].node` 必须描述同一棵子树：CANVAS / DOCUMENT
  /// 没有 bbox 时按页面输出（子节点坐标相对页面原点），不要拿 `children.first` 顶替。
  String renderMarkdownFromRoot(Map root, String targetId) {
    final found = findFigmaNode(root, targetId);
    if (found == null) {
      throw StateError('在缓存里找不到节点 $targetId');
    }
    final type = '${found['type'] ?? ''}';
    final isPage = type == 'CANVAS' || type == 'DOCUMENT';
    final isText = type == 'TEXT';
    final bbox = found['absoluteBoundingBox'];
    if (!isPage && bbox is! Map) {
      throw StateError('节点 $targetId 缺少 absoluteBoundingBox，缓存可能已损坏');
    }
    final fb = bbox is Map ? bbox : const <Object?, Object?>{};
    if (!isPage && <Object?>[fb['x'], fb['y'], fb['width'], fb['height']].any((v) => v is! num)) {
      throw StateError(
        '节点 $targetId 的 absoluteBoundingBox 结构异常（需要 x/y/width/height），缓存可能已损坏',
      );
    }
    final ox = fb['x'] is num ? (fb['x'] as num).toDouble() : 0.0;
    final oy = fb['y'] is num ? (fb['y'] as num).toDouble() : 0.0;
    final children = _list(found['children']);
    final columns = <String>[
      if (showNodeId) 'id',
      'x,y',
      'w×h',
      '类型',
      '名称',
      '填充',
      '描边',
      '阴影',
      '圆角',
      '透明度',
      if (showLayout) '布局',
      '文字',
    ];
    final rootRadius = _radiusText(found);
    final rootOpacity = found['opacity'] is num ? (found['opacity'] as num).toDouble() : null;
    final rootExtras = <String>[
      if (rootRadius.isNotEmpty) '圆角 $rootRadius',
      if (rootOpacity != null && rootOpacity < 1) '透明度 ${pyFixed(rootOpacity, 2)}',
      if (found['isMask'] == true) 'mask',
      if (found['rotation'] is num && (found['rotation'] as num) != 0)
        '旋转 ${pyFixed(found['rotation'], 2)}°',
      if (found['clipsContent'] == true) '裁切',
    ];
    final summary = isPage
        ? '页面，${children.length} 个子节点'
        : (isText
            ? '文字 ${pyFixed(fb['width'], 0)}×${pyFixed(fb['height'], 0)}'
                '，文字色 ${figmaFills(found)}，描边 ${figmaStrokes(found)}，'
                '阴影 ${figmaEffects(found)}'
            : '画板 ${pyFixed(fb['width'], 0)}×${pyFixed(fb['height'], 0)}'
                '，背景 ${figmaFills(found)}，描边 ${figmaStrokes(found)}，'
                '阴影 ${figmaEffects(found)}');
    final buf = StringBuffer()
      ..writeln('# ${found['name']}  ($targetId)')
      ..writeln()
      ..writeln(
        '$summary${rootExtras.isEmpty ? '' : '，${rootExtras.join('，')}'}',
      )
      ..writeln();
    final rootLayout = showLayout ? _layoutSpec(found) : '';
    if (rootLayout.isNotEmpty) {
      buf
        ..writeln('根布局：$rootLayout')
        ..writeln();
    }
    buf
      ..writeln('| ${columns.join(' | ')} |')
      ..writeln('| ${columns.map((_) => '---').join(' | ')} |');

    void walk(Map n, int depth, bool inheritedVisible, double inheritedOpacity) {
      for (final c in _list(n['children'])) {
        if (c is! Map) continue;
        final childOpacity = c['opacity'] is num ? (c['opacity'] as num).toDouble() : 1.0;
        final effectiveOpacity = inheritedOpacity * childOpacity;
        final visible = inheritedVisible && c['visible'] != false && effectiveOpacity > 0;
        final name = '${c['name'] ?? ''}';
        // 前缀命中时仍保留目标节点及其祖先，否则 --skip-name-prefix 会把目标一起剪掉。
        if (skipNamePrefixes.any(name.startsWith) && !_containsId(c, targetId)) continue;
        final bb = c['absoluteBoundingBox'];
        final hidden = visible ? '' : '**隐藏** ';
        if (bb is Map && _num(bb['width']) > 0 && _num(bb['height']) > 0) {
          final x = _num(bb['x']) - ox;
          final y = _num(bb['y']) - oy;
          final w = pyFixed(bb['width'], 1);
          final h = pyFixed(bb['height'], 1);
          final radius = _radiusText(c);
          final opacityText = childOpacity < 1 ? pyFixed(childOpacity, 2) : '';
          final isTextNode = '${c['type']}' == 'TEXT';
          final text = isTextNode ? figmaTextSpec(c) : '';
          final characters = '${c['characters'] ?? ''}';
          final chars = characters.isEmpty ? '' : '“$characters” ';
          final indent = '  ' * depth;
          buf.writeln(
            '| ${showNodeId ? '${c['id']} | ' : ''}${pyFixed(x, 1)},${pyFixed(y, 1)} | $w×$h | '
            '${c['type']} | $hidden$indent${_visualPrefix(c)}${_cell(name)} | '
            '${figmaFills(c)} | ${figmaStrokes(c)} | ${figmaEffects(c)} | $radius | '
            '$opacityText | ${showLayout ? '${_layoutSpec(c)} | ' : ''}'
            '${_cell('$chars$text')} |',
          );
        }
        walk(c, depth + 1, visible, effectiveOpacity);
      }
    }

    if (isText) {
      final chars = '${found['characters'] ?? ''}';
      buf.writeln(
        '文字：${chars.isEmpty ? '' : '“$chars” '}${_cell(figmaTextSpec(found))}',
      );
      buf.writeln();
    }
    walk(found, 0, true, rootOpacity ?? 1);
    return buf.toString();
  }

  String _radiusText(Map node) {
    final radii = node['rectangleCornerRadii'];
    final smoothing =
        node['cornerSmoothing'] is num ? (node['cornerSmoothing'] as num).toDouble() : 0.0;
    final smooth = smoothing > 0 ? ' smooth=${pyFixed(smoothing, 2)}' : '';
    if (radii is List && radii.length >= 4) {
      return '${radii.take(4).map((v) => '${v ?? 0}').join(',')}$smooth';
    }
    final corner = node['cornerRadius'];
    return corner is num
        ? '$corner$smooth'
        : (smoothing > 0 ? 'smooth=${pyFixed(smoothing, 2)}' : '');
  }

  String _visualPrefix(Map node) {
    final flags = <String>[
      if (node['isMask'] == true) '[mask]',
      if (node['clipsContent'] == true) '[clip]',
      if (node['rotation'] is num && (node['rotation'] as num) != 0)
        '[rot=${pyFixed(node['rotation'], 2)}°]',
    ];
    return flags.isEmpty ? '' : '${flags.join(' ')} ';
  }

  String _cell(Object? value) =>
      '$value'.replaceAll('\\', '\\\\').replaceAll('|', '\\|').replaceAll('\n', '<br>');

  bool _containsId(Map node, String id) {
    if ('${node['id'] ?? ''}' == id) return true;
    for (final child in _list(node['children'])) {
      if (child is Map && _containsId(child, id)) return true;
    }
    return false;
  }

  num _num(Object? value) => value is num ? value : 0;

  List<Object?> _list(Object? value) => value is List ? value : const <Object?>[];

  String _layoutSpec(Map node) {
    final mode = '${node['layoutMode'] ?? ''}';
    final parts = <String>[];
    if (mode == 'HORIZONTAL' || mode == 'VERTICAL') {
      parts.add('layoutMode=$mode');
      final spacing = node['itemSpacing'];
      if (spacing != null) parts.add('itemSpacing=$spacing');
    }
    final left = node['paddingLeft'];
    final right = node['paddingRight'];
    final top = node['paddingTop'];
    final bottom = node['paddingBottom'];
    if (<Object?>[left, right, top, bottom].any((v) => v != null)) {
      parts.add('padding=(l:${left ?? '-'},r:${right ?? '-'},t:${top ?? '-'},b:${bottom ?? '-'})');
    }
    final primary = node['primaryAxisAlignItems'];
    final counter = node['counterAxisAlignItems'];
    if (primary != null || counter != null) {
      parts.add('align=${primary ?? '-'}/${counter ?? '-'}');
    }
    final hs = node['layoutSizingHorizontal'];
    final vs = node['layoutSizingVertical'];
    if (hs != null || vs != null) parts.add('sizing=${hs ?? '-'}/${vs ?? '-'}');
    final grow = node['layoutGrow'];
    if (grow is num && grow != 0) parts.add('grow=$grow');
    if (node['layoutPositioning'] == 'ABSOLUTE') parts.add('position=ABSOLUTE');
    final constraints = node['constraints'];
    if (constraints is Map) {
      parts
          .add('constraints=${constraints['horizontal'] ?? '-'}/${constraints['vertical'] ?? '-'}');
    }
    final wrap = node['layoutWrap'];
    if (wrap != null) parts.add('wrap=$wrap');
    final counterSpacing = node['counterAxisSpacing'];
    if (counterSpacing != null) parts.add('counterSpacing=$counterSpacing');
    return parts.join(' ');
  }
}
