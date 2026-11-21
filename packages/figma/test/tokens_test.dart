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

  test('run 的 textCase 不同不会合并', () {
    final c = TokenCollector();
    c.collect({
      'id': '1:1',
      'type': 'TEXT',
      'characters': 'AB',
      'style': {
        'fontFamily': 'Inter',
        'fontSize': 14,
        'textAlignHorizontal': 'LEFT',
      },
      'characterStyleOverrides': [1, 2],
      'styleOverrideTable': {
        '1': {'fontSize': 14, 'textCase': 'UPPER'},
        '2': {'fontSize': 14, 'textCase': 'LOWER'},
      },
      'children': <Object?>[],
    });
    expect(c.texts.length, 3, reason: 'base + UPPER + LOWER');
  });

  test('textCase / textDecoration 是公开字段，markdown 样式列能看到', () {
    final c = TokenCollector();
    c.collect({
      'id': '1:1',
      'type': 'TEXT',
      'characters': 'abcdef',
      'style': {
        'fontFamily': 'Inter',
        'fontSize': 16,
        'textAlignHorizontal': 'LEFT',
      },
      'characterStyleOverrides': <int>[0, 0, 0, 0, 3, 3],
      'styleOverrideTable': {
        '3': {'textDecoration': 'UNDERLINE'},
      },
      'children': <Object?>[],
    });
    final texts = c.textsSorted();
    expect(texts, hasLength(2), reason: 'base 与链接 run 是两条不同样式');
    final run = texts.firstWhere((t) => t.textDecoration == 'UNDERLINE');
    expect(run.textDecoration, 'UNDERLINE');
    expect(run.textCase, '');
    final md = const TokenRenderer().renderMarkdown(
      tokens: c,
      source: 'test',
      nodeIds: const ['1:1'],
    );
    expect(md, contains('deco=UNDERLINE'));
  });

  test('skipNamePrefixes 跳过指定名称前缀的子树', () {
    final c = TokenCollector(skipNamePrefixes: const ['標題']);
    c.collect({
      'id': '1:1',
      'type': 'FRAME',
      'children': [
        {
          'id': '1:2',
          'type': 'TEXT',
          'name': '標題 mock',
          'characters': 'Title',
          'style': {'fontFamily': 'Inter', 'fontSize': 20},
          'fills': [
            {
              'type': 'SOLID',
              'color': {'r': 0, 'g': 0, 'b': 0},
            },
          ],
        },
        {
          'id': '1:3',
          'type': 'TEXT',
          'name': 'Body',
          'characters': 'Body',
          'style': {'fontFamily': 'Inter', 'fontSize': 14},
          'fills': [
            {
              'type': 'SOLID',
              'color': {'r': 1, 'g': 0, 'b': 0},
            },
          ],
        },
      ],
    });
    expect(c.colors.keys, <String>['#FF0000']);
    expect(c.texts.length, 1);
  });

  test('samples 保留完整 emoji，Markdown 按 runes 截断', () {
    final chars = '😀' * 14;
    final c = TokenCollector();
    c.collect({
      'id': '1:1',
      'type': 'TEXT',
      'characters': chars,
      'style': {
        'fontFamily': 'Noto Sans',
        'fontSize': 14,
        'textAlignHorizontal': 'LEFT',
      },
      'fills': [
        {
          'type': 'SOLID',
          'color': {'r': 0.2, 'g': 0.2, 'b': 0.2},
        },
      ],
      'children': <Object?>[],
    });

    final sample = c.colorsSorted().single.samples.single;
    expect(sample, contains(chars));
    // 完整 sample 不能含孤立代理项
    expect(sample.codeUnits.where((unit) => unit >= 0xD800 && unit <= 0xDFFF), hasLength(28));

    final md = const TokenRenderer().renderMarkdown(
      tokens: c,
      source: 'test',
      nodeIds: const ['1:1'],
    );
    expect(md, contains('…'));
    expect(md, isNot(contains('😀' * 14)));
  });

  test('长文本 Markdown 加省略号；JSON samples 是完整 characters', () {
    final c = TokenCollector();
    c.collect({
      'id': '1:1',
      'type': 'TEXT',
      'characters': '2025/10/03 20:00 到期',
      'style': {
        'fontFamily': 'Noto Sans',
        'fontSize': 14,
        'textAlignHorizontal': 'LEFT',
      },
      'fills': [
        {
          'type': 'SOLID',
          'color': {'r': 0.2, 'g': 0.2, 'b': 0.2},
        },
      ],
      'children': <Object?>[],
    });
    final sample = c.colorsSorted().single.samples.single;
    expect(sample, contains('2025/10/03 20:00 到期'));
    final md = const TokenRenderer().renderMarkdown(
      tokens: c,
      source: 'test',
      nodeIds: const ['1:1'],
    );
    expect(md, contains('2025/10/03 2…'));
  });

  test('样例内部的 」 不会被当成外层结束符', () {
    final c = TokenCollector();
    c.collect({
      'id': '1:1',
      'type': 'TEXT',
      'characters': '1234567890123「引號」後續',
      'style': {
        'fontFamily': 'Noto Sans',
        'fontSize': 14,
        'textAlignHorizontal': 'LEFT',
      },
      'fills': [
        {
          'type': 'SOLID',
          'color': {'r': 0.2, 'g': 0.2, 'b': 0.2},
        },
      ],
      'children': <Object?>[],
    });
    final md = const TokenRenderer().renderMarkdown(
      tokens: c,
      source: 'test',
      nodeIds: const ['1:1'],
    );
    expect(md, contains('「123456789012…」'));
    expect(md, isNot(contains('…」後續」')));
  });

  test('ZWJ emoji 按 grapheme cluster 截断，不切开家庭 emoji', () {
    final c = TokenCollector();
    c.collect({
      'id': '1:1',
      'type': 'TEXT',
      'characters': '👨‍👩‍👧‍👦👨‍👩‍👧‍👦👨‍👩‍👧‍👦👨‍👩‍👧‍👦ABCDEFGHIJ',
      'style': {
        'fontFamily': 'Noto Sans',
        'fontSize': 14,
        'textAlignHorizontal': 'LEFT',
      },
      'fills': [
        {
          'type': 'SOLID',
          'color': {'r': 0.2, 'g': 0.2, 'b': 0.2},
        },
      ],
      'children': <Object?>[],
    });
    final md = const TokenRenderer().renderMarkdown(
      tokens: c,
      source: 'test',
      nodeIds: const ['1:1'],
    );
    expect(md, contains('👨‍👩‍👧‍👦👨‍👩‍👧‍👦👨‍👩‍👧‍👦👨‍👩‍👧‍👦'));
    expect(md, isNot(contains('👨‍👩‍👧…')));
  });

  test('opacity=0 的节点及其子树不计入 token', () {
    final c = TokenCollector();
    c.collect({
      'id': '1:1',
      'type': 'FRAME',
      'opacity': 0,
      'fills': [
        {
          'type': 'SOLID',
          'color': {'r': 1, 'g': 0, 'b': 0, 'a': 1},
        },
      ],
      'children': <Object?>[],
    });
    expect(c.colors, isEmpty);
  });

  test('rich text run 的颜色进入 token', () {
    final c = TokenCollector();
    c.collect({
      'id': '1:1',
      'type': 'TEXT',
      'characters': 'AB',
      'style': {
        'fontFamily': 'Inter',
        'fontSize': 14,
        'textAlignHorizontal': 'LEFT',
      },
      'fills': [
        {
          'type': 'SOLID',
          'color': {'r': 0.1, 'g': 0.2, 'b': 0.3, 'a': 1},
        },
      ],
      'characterStyleOverrides': [1, 1],
      'styleOverrideTable': {
        '1': {
          'fills': [
            {
              'type': 'SOLID',
              'color': {'r': 1, 'g': 0, 'b': 0, 'a': 1},
            },
          ],
        },
      },
      'children': <Object?>[],
    });
    expect(c.colors.values.map((e) => e.value), contains('#FF0000'));
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

  test('隐藏节点及其子树不进入 token', () {
    final c = TokenCollector();
    c.collect({
      'id': 'root',
      'type': 'FRAME',
      'visible': true,
      'children': [
        {
          'id': 'hidden',
          'type': 'FRAME',
          'visible': false,
          'fills': [
            {
              'type': 'SOLID',
              'visible': true,
              'color': {'r': 1, 'g': 0, 'b': 0}
            },
          ],
          'children': [
            {
              'id': 'hidden-child',
              'type': 'TEXT',
              'style': {'fontSize': 99},
            },
          ],
        },
      ],
    });
    expect(c.colors, isEmpty);
    expect(c.texts, isEmpty);
  });

  test('找不到节点时 CLI 报错（collect 前先确认存在）', () {
    expect(findFigmaNode(document(), '999:999'), isNull);
  });
}
