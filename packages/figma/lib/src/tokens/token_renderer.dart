import 'token_collector.dart';

/// 把统计结果渲染成 Markdown（与项目里的 `design-tokens.md` 结构对齐）。
class TokenRenderer {
  const TokenRenderer();

  String renderMarkdown({
    required TokenCollector tokens,
    required String source,
    required List<String> nodeIds,
    Map<String, String> colorNames = const <String, String>{},
  }) {
    final buf = StringBuffer()
      ..writeln('# 设计 token 汇总（Figma 节点统计）')
      ..writeln()
      ..writeln('> 数据源：`$source` · 节点 `${nodeIds.join(', ')}`')
      ..writeln('> 只统计 **SOLID** 填充与描边；带透明度的色值以 `@0.20` 形式单列。')
      ..writeln()
      ..writeln('## 颜色')
      ..writeln()
      ..writeln('| 值 | 次数 | 出现位置（示例） |')
      ..writeln('| --- | --- | --- |');
    for (final c in tokens.colorsSorted()) {
      buf.writeln('| `${c.value}` | ${c.count} | ${c.samples.join(' / ')} |');
    }

    if (colorNames.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('## 语义色映射')
        ..writeln();
      for (final c in tokens.colorsSorted()) {
        final name = colorNames[c.value.replaceAll('#', '').toUpperCase()];
        buf.writeln('- `${c.value}` → ${name ?? '未映射'}');
      }
    }

    buf
      ..writeln()
      ..writeln('## 文字')
      ..writeln()
      ..writeln('| 字体 | 字号 | 字重 | 行高 | 字距 | 对齐 | 颜色 | 次数 | 示例 |')
      ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- | --- |');
    for (final t in tokens.textsSorted()) {
      buf.writeln(
        '| ${t.family} | ${t.size} | ${t.weight} | ${t.lineHeight} | '
        '${t.letterSpacing} | ${t.align} | `${t.color}` | ${t.count} | '
        '${t.samples.join(' / ')} |',
      );
    }

    buf
      ..writeln()
      ..writeln('## 圆角')
      ..writeln()
      ..writeln('| 值 | 次数 |')
      ..writeln('| --- | --- |');
    for (final r in tokens.radiiSorted()) {
      buf.writeln('| ${r.value} | ${r.count} |');
    }

    buf
      ..writeln()
      ..writeln('## 间距（auto-layout）')
      ..writeln()
      ..writeln('| 值 | 次数 |')
      ..writeln('| --- | --- |');
    for (final s in tokens.spacingsSorted()) {
      buf.writeln('| ${s.value} | ${s.count} |');
    }

    buf
      ..writeln()
      ..writeln('## 下一步')
      ..writeln()
      ..writeln('- 把上表的色值/文字对到项目 `AppColors` / `WTextStyles` 的语义名；')
      ..writeln('- 只有设计稿出现、代码里没有的值，补进「待确认」再决定是否新增 token；')
      ..writeln('- 出现 1 次的值可以用 `--min=1` 查看全部（默认也会列出）。');
    return buf.toString();
  }
}
