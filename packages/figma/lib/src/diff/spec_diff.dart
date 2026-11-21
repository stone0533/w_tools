import '../spec/figma_node.dart';

/// 一处属性变化。
class SpecChange {
  SpecChange({
    required this.nodeId,
    required this.name,
    required this.field,
    required this.before,
    required this.after,
  });

  final String nodeId;
  final String name;
  final String field;
  final String before;
  final String after;

  @override
  String toString() => '「$name」 $field: $before → $after';
}

/// 新增 / 删除的节点。
class SpecNodeDelta {
  SpecNodeDelta({required this.nodeId, required this.name, required this.added});

  final String nodeId;
  final String name;

  /// true = 新增；false = 删除。
  final bool added;

  @override
  String toString() => '${added ? '+' : '-'} 「$name」 ($nodeId)';
}

/// 比较两棵节点树，输出「改了哪些属性」。
///
/// 只看设计稿还原关心的属性：几何、填充、描边（含虚线）、圆角、效果、文字样式、可见性。
class SpecDiff {
  const SpecDiff();

  List<SpecChange> changes(Map before, Map after) {
    final changes = <SpecChange>[];
    _compare(before, after, changes);
    return changes;
  }

  List<SpecNodeDelta> nodes(Map before, Map after) {
    final oldIds = <String, String>{};
    final newIds = <String, String>{};
    _collect(before, oldIds);
    _collect(after, newIds);
    final out = <SpecNodeDelta>[];
    for (final id in newIds.keys) {
      if (!oldIds.containsKey(id)) {
        out.add(SpecNodeDelta(nodeId: id, name: newIds[id]!, added: true));
      }
    }
    for (final id in oldIds.keys) {
      if (!newIds.containsKey(id)) {
        out.add(SpecNodeDelta(nodeId: id, name: oldIds[id]!, added: false));
      }
    }
    return out;
  }

  void _collect(Map node, Map<String, String> into) {
    final id = '${node['id'] ?? ''}';
    if (id.isNotEmpty) into[id] = '${node['name'] ?? ''}';
    for (final c in (node['children'] as List?) ?? const []) {
      if (c is Map) _collect(c, into);
    }
  }

  void _compare(
    Map before,
    Map after,
    List<SpecChange> out, {
    Map? beforeParent,
    Map? afterParent,
  }) {
    final id = '${after['id'] ?? before['id'] ?? ''}';
    final name = '${after['name'] ?? before['name'] ?? ''}';

    void add(String field, Object? a, Object? b) {
      final beforeText = _text(a);
      final afterText = _text(b);
      if (beforeText != afterText) {
        out.add(
          SpecChange(
            nodeId: id,
            name: name,
            field: field,
            before: beforeText,
            after: afterText,
          ),
        );
      }
    }

    add('size', _size(before), _size(after));
    add('position', _position(before, beforeParent), _position(after, afterParent));
    add('layout', _layout(before), _layout(after));
    add('visible', '${before['visible'] ?? true}', '${after['visible'] ?? true}');
    add('opacity', '${before['opacity'] ?? 1}', '${after['opacity'] ?? 1}');
    add('fills', _paintKey(before['fills']), _paintKey(after['fills']));
    add('strokes', _strokeKey(before), _strokeKey(after));
    add('effects', _effectKey(before['effects']), _effectKey(after['effects']));
    add('radius', _radius(before), _radius(after));
    add('rotation', '${before['rotation'] ?? 0}', '${after['rotation'] ?? 0}');
    add('isMask', '${before['isMask'] ?? false}', '${after['isMask'] ?? false}');
    add('clipsContent', '${before['clipsContent'] ?? false}', '${after['clipsContent'] ?? false}');
    add('blendMode', '${before['blendMode'] ?? ''}', '${after['blendMode'] ?? ''}');
    add('textDecoration', _styleText(before, 'textDecoration'),
        _styleText(after, 'textDecoration'));
    add('textCase', _styleText(before, 'textCase'), _styleText(after, 'textCase'));
    add('name', '${before['name'] ?? ''}', '${after['name'] ?? ''}');
    if ('${after['type']}' == 'TEXT' || '${before['type']}' == 'TEXT') {
      add('characters', '${before['characters'] ?? ''}', '${after['characters'] ?? ''}');
      add('text', _textForDiff(before), _textForDiff(after));
    }

    // 子节点按 id 配对后递归；顺序变化不计为改动。
    // 位置用相对父节点的坐标，整页平移不会刷出全量子节点改动。
    final beforeChildren = _childrenById(before);
    final afterChildren = _childrenById(after);
    final beforeOrder = beforeChildren.keys.toList();
    final afterOrder = afterChildren.keys.toList();
    final sameSet =
        beforeOrder.length == afterOrder.length && beforeOrder.every(afterChildren.containsKey);
    if (sameSet &&
        beforeOrder.length == afterOrder.length &&
        !List.generate(beforeOrder.length, (i) => beforeOrder[i] == afterOrder[i])
            .every((same) => same)) {
      add('order', beforeOrder.join(','), afterOrder.join(','));
    }
    for (final entry in afterChildren.entries) {
      final old = beforeChildren[entry.key];
      if (old != null) {
        _compare(
          old,
          entry.value,
          out,
          beforeParent: before,
          afterParent: after,
        );
      }
    }
  }

  /// 填充的稳定结构 key：区分图片 / 渐变的具体内容，而不是只看 `IMG` / `GRAD`。
  String _paintKey(Object? paints) {
    if (paints is! List) return '';
    final parts = <String>[];
    for (final paint in paints) {
      if (paint is! Map || paint['visible'] == false) continue;
      final type = '${paint['type'] ?? ''}';
      if (type.startsWith('IMAGE')) {
        parts.add('$type:${paint['imageRef'] ?? paint['imageHash'] ?? ''}:'
            'opacity=${paint['opacity'] ?? 1}');
      } else if (type.startsWith('GRADIENT')) {
        parts.add('$type:${_gradientStops(paint['gradientStops'])}:'
            '${_gradientHandles(paint['gradientHandlePositions'])}:${paint['gradientTransform'] ?? ''}:'
            'opacity=${paint['opacity'] ?? 1}');
      } else {
        parts.add('$type:${figmaPaintHex(paint)}:opacity=${paint['opacity'] ?? 1}');
      }
    }
    return parts.join(';');
  }

  String _gradientHandles(Object? handles) {
    if (handles is! List) return '';
    return handles.map((point) => point is Map ? '${point['x']},${point['y']}' : '').join(';');
  }

  String _gradientStops(Object? stops) {
    if (stops is! List) return '';
    return stops.map((stop) {
      if (stop is! Map) return '';
      return '${stop['position']}:${figmaHex(stop['color'])}';
    }).join(',');
  }

  String _strokeKey(Map node) {
    // 颜色 / 虚线 / 单边宽度都在描述里；图片 / 渐变描边由结构 key 区分。
    return '${_paintKey(node['strokes'])}|${figmaStrokes(node)}';
  }

  String _effectKey(Object? effects) {
    if (effects is! List) return '';
    final parts = <String>[];
    for (final effect in effects) {
      if (effect is! Map || effect['visible'] == false) continue;
      parts.add(
        '${effect['type']}:${effect['radius']}:${effect['spread']}:'
        '${figmaHex(effect['color'])}:${effect['offset']}',
      );
    }
    return parts.join(';');
  }

  Map<String, Map> _childrenById(Map node) {
    final out = <String, Map>{};
    for (final c in (node['children'] as List?) ?? const []) {
      if (c is Map) out['${c['id']}'] = c;
    }
    return out;
  }

  String _size(Map node) {
    final bb = node['absoluteBoundingBox'];
    if (bb is! Map) return '';
    final w = (bb['width'] as num?)?.toDouble() ?? 0;
    final h = (bb['height'] as num?)?.toDouble() ?? 0;
    return '${w.toStringAsFixed(1)}×${h.toStringAsFixed(1)}';
  }

  String _radius(Map node) {
    final r = node['cornerRadius'];
    final radii = node['rectangleCornerRadii'];
    return '${r ?? ''}|${radii is List ? radii.join(',') : ''}|'
        '${node['cornerSmoothing'] ?? 0}';
  }

  String _position(Map node, Map? parent) {
    final bb = node['absoluteBoundingBox'];
    if (bb is! Map) return '';
    final parentBox = parent?['absoluteBoundingBox'];
    final originX = parentBox is Map ? (parentBox['x'] as num?)?.toDouble() ?? 0 : 0;
    final originY = parentBox is Map ? (parentBox['y'] as num?)?.toDouble() ?? 0 : 0;
    final x = ((bb['x'] as num?)?.toDouble() ?? 0) - originX;
    final y = ((bb['y'] as num?)?.toDouble() ?? 0) - originY;
    return '${x.toStringAsFixed(1)},${y.toStringAsFixed(1)}';
  }

  String _layout(Map node) {
    final spacing = node['itemSpacing'];
    final left = node['paddingLeft'];
    final right = node['paddingRight'];
    final top = node['paddingTop'];
    final bottom = node['paddingBottom'];
    final constraints = node['constraints'];
    return 'layoutMode=${node['layoutMode']} itemSpacing=$spacing '
        'padding=l:$left,r:$right,t:$top,b:$bottom '
        'primary=${node['primaryAxisAlignItems']} counter=${node['counterAxisAlignItems']} '
        'sizing=${node['layoutSizingHorizontal']}/${node['layoutSizingVertical']} '
        'grow=${node['layoutGrow']} positioning=${node['layoutPositioning']} '
        'wrap=${node['layoutWrap']} counterSpacing=${node['counterAxisSpacing']} '
        'constraints=${constraints is Map ? '${constraints['horizontal']}/${constraints['vertical']}' : '-'}';
  }

  String _textForDiff(Map node) {
    final style = node['style'];
    if (style is! Map) return figmaTextSpec(node);
    final copy = Map<String, dynamic>.from(node);
    final cleanStyle = Map<String, dynamic>.from(style)
      ..remove('textDecoration')
      ..remove('textCase');
    copy['style'] = cleanStyle;
    return figmaTextSpec(copy);
  }

  String _styleText(Map node, String key) {
    final style = node['style'];
    return style is Map ? '${style[key] ?? ''}' : '';
  }

  String _text(Object? v) {
    if (v == null) return '';
    return '$v';
  }
}
