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
    final rootExtras = <String>[
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

    void walk(Map n, int depth, bool inheritedVisible) {
      for (final c in (n['children'] as List?) ?? const []) {
        if (c is! Map) continue;
        final visible = inheritedVisible && c['visible'] != false;
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
          final opacity = (c['opacity'] as num?)?.toDouble();
          final opacityText = opacity != null && opacity < 1 ? pyFixed(opacity, 2) : '';
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
        walk(c, depth + 1, visible);
      }
    }

    walk(frame, 0, true);
    return buf.toString();
  }

  String _radiusText(Map node) {
    final radii = node['rectangleCornerRadii'];
    if (radii is List && radii.length >= 4) {
      return radii.take(4).map((v) => '${v ?? 0}').join(',');
    }
    final corner = node['cornerRadius'];
    return (corner is num && corner != 0) ? '$corner' : '';
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
    if (mode != 'HORIZONTAL' && mode != 'VERTICAL') return '';
    final parts = <String>['layoutMode=$mode'];
    final spacing = node['itemSpacing'];
    if (spacing != null) parts.add('itemSpacing=$spacing');
    final pads = <Object?>[
      node['paddingLeft'],
      node['paddingRight'],
      node['paddingTop'],
      node['paddingBottom'],
    ];
    if (pads.any((v) => v != null)) {
      parts.add('padding=${pads.map((v) => v ?? '-').join(',')}');
    }
    final primary = node['primaryAxisAlignItems'];
    final counter = node['counterAxisAlignItems'];
    if (primary != null || counter != null) {
      parts.add('align=${primary ?? '-'}/${counter ?? '-'}');
    }
    return parts.join(' ');
  }
}
