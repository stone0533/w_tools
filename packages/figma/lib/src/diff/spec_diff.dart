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

  void _compare(Map before, Map after, List<SpecChange> out) {
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
    add('visible', '${before['visible'] ?? true}', '${after['visible'] ?? true}');
    add('fills', figmaFills(before), figmaFills(after));
    add('strokes', figmaStrokes(before), figmaStrokes(after));
    add('effects', figmaEffects(before), figmaEffects(after));
    add('radius', _radius(before), _radius(after));
    add('name', '${before['name'] ?? ''}', '${after['name'] ?? ''}');
    if ('${after['type']}' == 'TEXT' || '${before['type']}' == 'TEXT') {
      add('characters', '${before['characters'] ?? ''}', '${after['characters'] ?? ''}');
      add('text', figmaTextSpec(before), figmaTextSpec(after));
    }

    // 子节点按 id 配对后递归；顺序变化不计为改动
    final beforeChildren = _childrenById(before);
    final afterChildren = _childrenById(after);
    for (final entry in afterChildren.entries) {
      final old = beforeChildren[entry.key];
      if (old != null) _compare(old, entry.value, out);
    }
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
    return r == null ? '' : '$r';
  }

  String _text(Object? v) {
    if (v == null) return '';
    return '$v';
  }
}
