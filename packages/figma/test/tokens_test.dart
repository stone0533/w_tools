import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_figma/w_tools_figma.dart';

/// `tokens` 的统计与渲染测试：全部读本地 fixture，不联网、不消耗额度。
void main() {
  final fixture = File('test/fixtures/nodes-frame.json');
  const nodeId = '1915:58517';

  Map<String, dynamic> document() {
    final raw = jsonDecode(fixture.readAsStringSync()) as Map<String, dynamic>;
    final nodes = raw['nodes'] as Map<String, dynamic>;
    return (nodes.values.first as Map<String, dynamic>)['document'] as Map<String, dynamic>;
  }

  TokenCollector collect({int minCount = 1}) {
    final c = TokenCollector(minCount: minCount);
    c.collect(findFigmaNode(document(), nodeId)!);
    return c;
  }

  test('颜色按出现次数降序，颜色值归一化为 #RRGGBB', () {
    final colors = collect().colorsSorted();
    expect(colors.first.value, '#3F3F3F');
    expect(colors.first.count, 14);
    expect(colors.any((c) => c.value == '#3F3F3F'), isTrue);
    // 出现两次以上的色值按次数降序
    for (var i = 1; i < colors.length; i++) {
      expect(colors[i - 1].count >= colors[i].count, isTrue);
    }
  });

  test('文字样式把浮点噪声收敛（16 而不是 16.0，行高 25.6）', () {
    final texts = collect().textsSorted();
    final body16 = texts.firstWhere((t) => t.size == '16' && t.weight == '700');
    expect(body16.family, 'Noto Sans');
    expect(body16.lineHeight, '25.6');
    expect(body16.color, '#3F3F3F');
    expect(body16.count, 6);
  });

  test('minCount 过滤掉低频项', () {
    final all = collect().colorsSorted();
    final filtered = collect(minCount: 6).colorsSorted();
    expect(all.length > filtered.length, isTrue);
    expect(filtered.every((c) => c.count >= 6), isTrue);
  });

  test('Markdown 渲染包含四个小节', () {
    final md = const TokenRenderer().renderMarkdown(
      tokens: collect(),
      source: 'test/fixtures/nodes-frame.json',
      nodeIds: [nodeId],
    );
    expect(md, contains('# 设计 token 汇总'));
    expect(md, contains('## 颜色'));
    expect(md, contains('## 文字'));
    expect(md, contains('## 圆角'));
    expect(md, contains('## 间距（auto-layout）'));
    expect(md, contains('| `#3F3F3F` | 14 |'));
  });

  test('颜色语义映射命中与未映射', () {
    final md = const TokenRenderer().renderMarkdown(
      tokens: collect(),
      source: 'test/fixtures/nodes-frame.json',
      nodeIds: [nodeId],
      colorNames: <String, String>{'3F3F3F': 'textPrimary'},
    );
    expect(md, contains('| 值 | 语义名 | 次数 | 出现位置（示例） |'));
    expect(md, contains('| `#3F3F3F` | textPrimary | 14 |'));
    expect(md, contains('| 新增 |'));
  });

  test('找不到节点时 CLI 报错（collect 前先确认存在）', () {
    expect(findFigmaNode(document(), '999:999'), isNull);
  });
}
