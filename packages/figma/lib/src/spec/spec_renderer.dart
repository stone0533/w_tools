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
  String renderMarkdownFromRoot(Map root, String targetId) {
    final found = findFigmaNode(root, targetId);
    if (found == null) {
      throw StateError('在缓存里找不到节点 $targetId');
    }
    var frame = found;
    final bbox = frame['absoluteBoundingBox'];
    if (bbox is! Map) {
      // 传入的是 CANVAS/页面时没有 bbox，用第一个子节点兜底
      final children = (frame['children'] as List?) ?? const [];
      if (children.isEmpty || children.first is! Map) {
        throw StateError('节点 $targetId 没有 absoluteBoundingBox，也没有子节点');
      }
      frame = children.first as Map;
    }

    final fb = frame['absoluteBoundingBox'] as Map;
    final ox = (fb['x'] as num).toDouble();
    final oy = (fb['y'] as num).toDouble();
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
    final rootRadius = _radiusText(frame);
    final rootOpacity = (frame['opacity'] as num?)?.toDouble();
    final rootExtras = <String>[
      if (rootRadius.isNotEmpty) '圆角 $rootRadius',
      if (rootOpacity != null && rootOpacity < 1) '透明度 ${pyFixed(rootOpacity, 2)}',
      if (frame['isMask'] == true) 'mask',
      if ((frame['rotation'] as num?) != null && (frame['rotation'] as num) != 0)
        '旋转 ${pyFixed(frame['rotation'], 2)}°',
      if (frame['clipsContent'] == true) '裁切',
    ];
    final buf = StringBuffer()
      ..writeln('# ${frame['name']}  ($targetId)')
      ..writeln()
      ..writeln(
        '画板 ${pyFixed(fb['width'], 0)}×${pyFixed(fb['height'], 0)}'
        '，背景 ${figmaFills(frame)}，描边 ${figmaStrokes(frame)}，'
        '阴影 ${figmaEffects(frame)}'
        '${rootExtras.isEmpty ? '' : '，${rootExtras.join('，')}'}',
      )
      ..writeln();
    final rootLayout = showLayout ? _layoutSpec(frame) : '';
    if (rootLayout.isNotEmpty) {
      buf
        ..writeln('根布局：$rootLayout')
        ..writeln();
    }
    buf
      ..writeln('| ${columns.join(' | ')} |')
      ..writeln('| ${columns.map((_) => '---').join(' | ')} |');

    void walk(Map n, int depth, bool inheritedVisible, double inheritedOpacity) {
      for (final c in (n['children'] as List?) ?? const []) {
        if (c is! Map) continue;
        final childOpacity = (c['opacity'] as num?)?.toDouble() ?? 1;
        final effectiveOpacity = inheritedOpacity * childOpacity;
        final visible = inheritedVisible && c['visible'] != false && effectiveOpacity > 0;
        final name = '${c['name'] ?? ''}';
        if (skipNamePrefixes.any(name.startsWith)) continue;
        final bb = c['absoluteBoundingBox'];
        final hidden = visible ? '' : '**隐藏** ';
        if (bb is Map && ((bb['width'] as num?) ?? 0) > 0 && ((bb['height'] as num?) ?? 0) > 0) {
          final x = (bb['x'] as num).toDouble() - ox;
          final y = (bb['y'] as num).toDouble() - oy;
          final w = pyFixed(bb['width'], 1);
          final h = pyFixed(bb['height'], 1);
          final radius = _radiusText(c);
          final opacityText = childOpacity < 1 ? pyFixed(childOpacity, 2) : '';
          final isText = '${c['type']}' == 'TEXT';
          final text = isText ? figmaTextSpec(c) : '';
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

    if ('${frame['type']}' == 'TEXT') {
      final chars = '${frame['characters'] ?? ''}';
      buf.writeln(
        '文字：${chars.isEmpty ? '' : '“$chars” '}${_cell(figmaTextSpec(frame))}',
      );
      buf.writeln();
    }
    walk(frame, 0, true, rootOpacity ?? 1);
    return buf.toString();
  }

  String _radiusText(Map node) {
    final radii = node['rectangleCornerRadii'];
    final smoothing = (node['cornerSmoothing'] as num?)?.toDouble() ?? 0;
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
      if ((node['rotation'] as num?) != null && (node['rotation'] as num) != 0)
        '[rot=${pyFixed(node['rotation'], 2)}°]',
    ];
    return flags.isEmpty ? '' : '${flags.join(' ')} ';
  }

  String _cell(Object? value) =>
      '$value'.replaceAll('\\', '\\\\').replaceAll('|', '\\|').replaceAll('\n', '<br>');

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
