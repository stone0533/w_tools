/// `<!-- @if:feature -->` / `<!-- @endif -->` 的唯一处理器。
///
/// 模板渲染（`templates.dart`）和生成器校验（`tool/gen_templates.dart`）必须用
/// 同一套语义；marker 只允许独立成行，避免行内 marker 被漏进生成物。
class ConditionalTemplate {
  const ConditionalTemplate._();

  static String render(String content, Set<String> enabled) {
    final out = <String>[];
    var include = true;
    for (final line in content.split('\n')) {
      final start = RegExp(r'^<!-- @if:([a-z]+) -->$').firstMatch(line);
      if (start != null) {
        include = enabled.contains(start.group(1));
        continue;
      }
      if (line == '<!-- @endif -->') {
        include = true;
        continue;
      }
      if (include) out.add(line);
    }
    return out.join('\n');
  }

  static void validate(String content, {String? name}) {
    final label = name == null ? '' : '模板 $name: ';
    var depth = 0;
    for (final line in content.split('\n')) {
      final isIf = RegExp(r'^<!-- @if:[a-z]+ -->$').hasMatch(line);
      final isEnd = line == '<!-- @endif -->';
      if ((line.contains('@if:') || line.contains('@endif')) && !isIf && !isEnd) {
        throw StateError('$label@if / @endif 必须单独成行，不能写在其他内容里：$line');
      }
      if (isIf) {
        if (depth != 0) throw StateError('$label@if 不支持嵌套');
        depth++;
      } else if (isEnd) {
        if (depth == 0) throw StateError('$label多余的 @endif');
        depth--;
      }
    }
    if (depth != 0) throw StateError('$label@if 未闭合');
  }
}
