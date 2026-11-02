import 'figma_node.dart';

/// 实现时不需要还原的子树（iOS 状态栏 mock）。
const _skipNamePrefixes = ['Left Side', 'Right Side', 'Island'];

/// 把一个画板节点渲染成 Markdown 规格表。
///
/// 与 `scripts/figma_spec.py` 输出逐字节一致（迁移期用 golden 对比校验）。
class FigmaSpecRenderer {
  const FigmaSpecRenderer({this.skipNamePrefixes = _skipNamePrefixes});

  final List<String> skipNamePrefixes;

  /// [node] 是目标画板；找不到时抛 [StateError]。
  String renderMarkdown(Map node, String targetId) {
    return renderMarkdownFromRoot(node, targetId);
  }

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
    final buf = StringBuffer()
      ..writeln('# ${frame['name']}  ($targetId)')
      ..writeln()
      ..writeln(
        '画板 ${(fb['width'] as num).toDouble().toStringAsFixed(0)}'
        '×${(fb['height'] as num).toDouble().toStringAsFixed(0)}'
        '，背景 ${figmaFills(frame)}，描边 ${figmaStrokes(frame)}，'
        '阴影 ${figmaEffects(frame)}',
      )
      ..writeln()
      ..writeln('| x,y | w×h | 类型 | 名称 | 填充 | 描边 | 阴影 | 圆角 | 文字 |')
      ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- | --- |');

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
          final w = (bb['width'] as num).toDouble().toStringAsFixed(1);
          final h = (bb['height'] as num).toDouble().toStringAsFixed(1);
          // Python 里 `c.get('cornerRadius') or ''`：0 也当空
          final corner = c['cornerRadius'];
          final radius = (corner is num && corner != 0) ? '$corner' : '';
          final isText = '${c['type']}' == 'TEXT';
          final text = isText ? figmaTextSpec(c) : '';
          final characters = '${c['characters'] ?? ''}';
          final chars = characters.isEmpty
              ? ''
              : '“${characters.length > 40 ? characters.substring(0, 40) : characters}” ';
          final indent = '  ' * depth;
          final shortName = name.length > 26 ? name.substring(0, 26) : name;
          buf.writeln(
            '| ${x.toStringAsFixed(1)},${y.toStringAsFixed(1)} | $w×$h | '
            '${c['type']} | $hidden$indent$shortName | ${figmaFills(c)} | '
            '${figmaStrokes(c)} | ${figmaEffects(c)} | $radius | $chars$text |',
          );
        }
        walk(c, depth + 1, visible);
      }
    }

    walk(frame, 0, true);
    return buf.toString();
  }
}
