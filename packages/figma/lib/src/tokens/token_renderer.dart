import 'token_collector.dart';

/// 颜色语义映射的 key：去掉 `#`、转大写（CLI 解析 YAML 与渲染共用）。
String colorKey(String value) => value.split('@').first.replaceAll('#', '').toUpperCase();

/// Markdown 样例的视觉截断：按 Unicode code point（runes）截 12 个，补 `…`。
///
/// 只用于人读表格；`tokens --json` 的 `samples` 保留完整 characters。
String shortenSample(String sample) {
  final start = sample.indexOf('「');
  final end = sample.indexOf('」', start + 1);
  if (start < 0 || end < 0) return sample;
  final text = sample.substring(start + 1, end);
  final runes = text.runes.toList();
  if (runes.length <= 12) return sample;
  final short = String.fromCharCodes(runes.take(12));
  return '${sample.substring(0, start)}「$short…」${sample.substring(end + 1)}';
}

/// 把统计结果渲染成 Markdown（与项目里的 `design-tokens.md` 结构对齐）。
class TokenRenderer {
  const TokenRenderer();

  String renderMarkdown({
    required TokenCollector tokens,
    required String source,
    required List<String> nodeIds,
    Map<String, String> colorNames = const <String, String>{},
  }) {
    String cell(Object? value) =>
        '$value'.replaceAll('\\', '\\\\').replaceAll('|', '\\|').replaceAll('\n', '<br>');
    final buf = StringBuffer()
      ..writeln('# 设计 token 汇总（Figma 节点统计）')
      ..writeln()
      ..writeln('> 数据源：`$source` · 节点 `${nodeIds.join(', ')}`')
      ..writeln('> 只统计 **SOLID** 填充与描边；带透明度的色值以 `@0.20` 形式单列。')
      ..writeln()
      ..writeln('## 颜色')
      ..writeln();
    if (colorNames.isNotEmpty) {
      buf
        ..writeln('| 值 | 语义名 | 次数 | 出现位置（示例） |')
        ..writeln('| --- | --- | --- | --- |');
    } else {
      buf
        ..writeln('| 值 | 次数 | 出现位置（示例） |')
        ..writeln('| --- | --- | --- |');
    }
    for (final c in tokens.colorsSorted()) {
      if (colorNames.isNotEmpty) {
        final name = colorNames[colorKey(c.value)] ?? '新增';
        buf.writeln(
            '| `${cell(c.value)}` | ${cell(name)} | ${c.count} | ${cell(c.samples.map(shortenSample).join(' / '))} |');
      } else {
        buf.writeln(
            '| `${cell(c.value)}` | ${c.count} | ${cell(c.samples.map(shortenSample).join(' / '))} |');
      }
    }

    buf
      ..writeln()
      ..writeln('## 文字')
      ..writeln()
      ..writeln('| 字体 | 字号 | 字重 | 样式 | 行高 | 字距 | 对齐 | 颜色 | 次数 | 示例 |')
      ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |');
    for (final t in tokens.textsSorted()) {
      final styles = <String>[
        if (t.fontStyle.isNotEmpty) t.fontStyle,
        if (t.textCase.isNotEmpty) 'case=${t.textCase}',
        if (t.textDecoration.isNotEmpty) 'deco=${t.textDecoration}',
      ];
      buf.writeln(
        '| ${t.family} | ${t.size} | ${t.weight} | ${styles.isEmpty ? '-' : styles.join(' ')} | '
        '${t.lineHeight} | '
        '${t.letterSpacing} | ${t.align} | `${t.color}` | ${t.count} | '
        '${cell(t.samples.map(shortenSample).join(' / '))} |',
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
      ..writeln('- 默认 `--min=1` 会列出全部值；只关心高频值时可加 `--min=3`。');
    return buf.toString();
  }
}
