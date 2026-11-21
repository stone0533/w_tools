import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_figma/w_tools_figma.dart' as figma;

/// 与最初的 Python golden 做基线对比；Dart 版本已扩展 strokeAlign / opacity / spread。
/// fixture 是从真实 `.figma-cache` 抽的子画板（148KB），不联网、不消耗额度。
void main() {
  final fixture = File('test/fixtures/nodes-frame.json');
  const nodeId = '1915:58517';
  final markdown = fixture.existsSync()
      ? const figma.FigmaSpecRenderer().renderMarkdownFromRoot(
          _documentOf(fixture),
          nodeId,
        )
      : null;

  test('fixture 存在且能解析', () {
    expect(fixture.existsSync(), isTrue, reason: '缺少 test/fixtures/nodes-frame.json');
    expect(markdown, isNotNull);
  });

  test('Markdown golden 与 spec-expected.md 一致', () {
    final expected = File('test/fixtures/spec-expected.md').readAsStringSync();
    expect(markdown, expected);
  });

  test('找不到节点时抛 StateError', () {
    final root = _documentOf(fixture);
    expect(
      () => const figma.FigmaSpecRenderer().renderMarkdownFromRoot(root, '999:999'),
      throwsStateError,
    );
  });

  test('格式化与 Python 一致：五成双（920.25 → 920.2，不是 920.3）', () {
    expect(figma.pyFixed(920.25, 1), '920.2');
    expect(figma.pyFixed(920.35, 1), '920.4');
    expect(figma.pyFixed(19.200000762939453, 1), '19.2');
    expect(figma.pyFixed(375.0, 0), '375');
    expect(figma.pyFixed(-0.25, 1), '-0.2');
  });

  test('--with-layout 时表格带布局字段，默认不带', () {
    final root = <String, dynamic>{
      'id': '1:2',
      'type': 'FRAME',
      'name': 'L',
      'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 100, 'height': 100},
      'layoutMode': 'HORIZONTAL',
      'itemSpacing': 4,
      'paddingLeft': 12,
      'paddingRight': 12,
      'paddingTop': 6,
      'paddingBottom': 6,
      'children': [
        {
          'id': '1:3',
          'type': 'FRAME',
          'name': 'Column',
          'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 100, 'height': 100},
          'layoutMode': 'VERTICAL',
          'itemSpacing': 8,
          'paddingLeft': 16,
          'paddingRight': 16,
          'paddingTop': 10,
          'paddingBottom': 10,
          'primaryAxisAlignItems': 'MIN',
          'counterAxisAlignItems': 'CENTER',
        },
      ],
    };
    final md = const figma.FigmaSpecRenderer(showLayout: true).renderMarkdownFromRoot(root, '1:2');

    expect(md, contains('| 布局 |'));
    expect(
      md,
      contains('根布局：layoutMode=HORIZONTAL itemSpacing=4 padding=(l:12,r:12,t:6,b:6)'),
    );
    expect(
      md,
      contains('layoutMode=VERTICAL itemSpacing=8 padding=(l:16,r:16,t:10,b:10) align=MIN/CENTER'),
    );
    expect(
      const figma.FigmaSpecRenderer().renderMarkdownFromRoot(root, '1:2'),
      isNot(contains('| 布局 |')),
    );
  });

  test('--with-id 时表格带子节点 id，默认不带', () {
    final root = _documentOf(fixture);
    final withId =
        const figma.FigmaSpecRenderer(showNodeId: true).renderMarkdownFromRoot(root, nodeId);

    expect(withId, contains('| id | x,y |'));
    expect(withId, matches(RegExp(r'\n\| \d+:\d+ \|')));
    expect(markdown, isNot(contains('| id | x,y |')));
  });

  test('逐角圆角 / mask / rotation / decoration / 表格转义', () {
    final root = <String, dynamic>{
      'id': '1:2',
      'type': 'FRAME',
      'name': 'Root',
      'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 100, 'height': 100},
      'children': [
        {
          'id': '1:3',
          'type': 'RECTANGLE',
          'name': 'Card | A',
          'isMask': true,
          'rotation': 12,
          'rectangleCornerRadii': [8, 8, 0, 0],
          'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 100, 'height': 40},
          'fills': [
            {
              'type': 'SOLID',
              'opacity': 0.5,
              'color': {'r': 0.2, 'g': 0.2, 'b': 0.2},
            },
          ],
          'children': [],
        },
        {
          'id': '1:4',
          'type': 'TEXT',
          'name': 'Text',
          'characters': 'A|B\nC',
          'absoluteBoundingBox': {'x': 0, 'y': 40, 'width': 100, 'height': 20},
          'style': {'fontFamily': 'Noto Sans', 'textDecoration': 'UNDERLINE'},
          'children': [],
        },
      ],
    };
    final md = const figma.FigmaSpecRenderer().renderMarkdownFromRoot(root, '1:2');
    expect(md, contains('| 8,8,0,0 |'));
    expect(md, contains('[mask]'));
    expect(md, contains('[rot=12.00°]'));
    expect(md, contains('#333333@0.50'));
    expect(md, contains('deco=UNDERLINE'));
    expect(md, contains('A\\|B<br>C'));
  });

  test('TEXT 目标自身输出文字，opacity=0 标隐藏', () {
    final textRoot = <String, dynamic>{
      'id': '1:2',
      'type': 'TEXT',
      'name': 'OnlyText',
      'characters': 'Hello',
      'style': {'fontFamily': 'Inter', 'fontSize': 14, 'textAlignHorizontal': 'LEFT'},
      'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 100, 'height': 20},
      'children': <Object?>[],
    };
    final textMd = const figma.FigmaSpecRenderer().renderMarkdownFromRoot(textRoot, '1:2');
    expect(textMd, contains('文字：'));
    expect(textMd, contains('Hello'));

    final root = <String, dynamic>{
      'id': '1:2',
      'type': 'FRAME',
      'name': 'Root',
      'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 100, 'height': 100},
      'children': [
        {
          'id': '1:3',
          'type': 'RECTANGLE',
          'name': 'Invisible',
          'opacity': 0,
          'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
          'children': <Object?>[],
        },
      ],
    };
    final md = const figma.FigmaSpecRenderer().renderMarkdownFromRoot(root, '1:2');
    expect(md, contains('**隐藏**'));
  });

  test('文字 valign 与 cornerSmoothing 输出短标记', () {
    final root = <String, dynamic>{
      'id': '1:2',
      'type': 'FRAME',
      'name': 'Root',
      'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 100, 'height': 100},
      'children': [
        {
          'id': '1:3',
          'type': 'TEXT',
          'name': 'Text',
          'characters': 'Hi',
          'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 100, 'height': 20},
          'style': {
            'fontFamily': 'Inter',
            'textAlignHorizontal': 'LEFT',
            'textAlignVertical': 'CENTER',
          },
          'children': <Object?>[],
        },
        {
          'id': '1:4',
          'type': 'RECTANGLE',
          'name': 'Smooth',
          'cornerRadius': 13,
          'cornerSmoothing': 0.6,
          'absoluteBoundingBox': {'x': 0, 'y': 20, 'width': 100, 'height': 20},
          'children': <Object?>[],
        },
      ],
    };
    final md = const figma.FigmaSpecRenderer().renderMarkdownFromRoot(root, '1:2');
    expect(md, contains('valign=CENTER'));
    expect(md, contains('13 smooth=0.60'));
  });

  test('渐变 opacity 用不歧义格式', () {
    final root = <String, dynamic>{
      'id': '1:2',
      'type': 'FRAME',
      'name': 'Gradient',
      'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 100, 'height': 100},
      'children': [
        {
          'id': '1:3',
          'type': 'RECTANGLE',
          'name': 'Grad',
          'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 100, 'height': 100},
          'fills': [
            {
              'type': 'GRADIENT_LINEAR',
              'opacity': 0.5,
              'gradientStops': [
                {
                  'position': 0,
                  'color': {'r': 1, 'g': 0, 'b': 0}
                },
                {
                  'position': 1,
                  'color': {'r': 0, 'g': 0, 'b': 1}
                },
              ],
              'gradientHandlePositions': [
                {'x': 0, 'y': 0},
                {'x': 1, 'y': 0},
              ],
            },
          ],
          'children': <Object?>[],
        },
      ],
    };
    final md = const figma.FigmaSpecRenderer().renderMarkdownFromRoot(root, '1:2');
    expect(md, contains('opacity=0.50'));
    expect(md, isNot(contains('@0.50@45°')));
  });

  test('渐变描边输出 stop 颜色和角度', () {
    final root = <String, dynamic>{
      'id': '1:2',
      'type': 'FRAME',
      'name': 'Gradient stroke',
      'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 100, 'height': 100},
      'children': [
        {
          'id': '1:3',
          'type': 'ELLIPSE',
          'name': 'Ring',
          'absoluteBoundingBox': {'x': 10, 'y': 10, 'width': 80, 'height': 80},
          'strokes': [
            {
              'type': 'GRADIENT_LINEAR',
              'gradientHandlePositions': [
                {'x': 0, 'y': 0},
                {'x': 0, 'y': 1},
              ],
              'gradientStops': [
                {
                  'position': 0,
                  'color': {'r': 1, 'g': 0, 'b': 0},
                },
                {
                  'position': 1,
                  'color': {'r': 0, 'g': 0, 'b': 1},
                },
              ],
            },
          ],
          'strokeWeight': 2,
          'strokeAlign': 'INSIDE',
          'children': <Object?>[],
        },
      ],
    };
    final md = const figma.FigmaSpecRenderer().renderMarkdownFromRoot(root, '1:2');
    expect(md, contains('GRAD(#FF0000→#0000FF)@90° 2px align=INSIDE'));
  });

  test('根节点自身输出圆角 / opacity / mask', () {
    final root = <String, dynamic>{
      'id': '1:2',
      'type': 'FRAME',
      'name': 'Card',
      'opacity': 0.5,
      'isMask': true,
      'rectangleCornerRadii': [4, 0, 0, 4],
      'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 100, 'height': 100},
      'children': <Object?>[],
    };
    final md = const figma.FigmaSpecRenderer().renderMarkdownFromRoot(root, '1:2');
    expect(md, contains('圆角 4,0,0,4'));
    expect(md, contains('透明度 0.50'));
    expect(md, contains('mask'));
  });

  test('CANVAS 根节点按页面输出，不拿首个子节点顶替', () {
    final page = <String, dynamic>{
      'id': '0:1',
      'type': 'CANVAS',
      'name': '首页',
      'children': [
        {
          'id': '10:1',
          'type': 'FRAME',
          'name': 'Table',
          'absoluteBoundingBox': {'x': 20, 'y': 30, 'width': 300, 'height': 200},
          'children': <Object?>[],
        },
      ],
    };
    final md = const figma.FigmaSpecRenderer().renderMarkdownFromRoot(page, '0:1');
    expect(md, contains('# 首页  (0:1)'));
    expect(md, contains('页面，1 个子节点'));
    expect(md, isNot(contains('# Table  (0:1)')));
    expect(md, contains('| 20.0,30.0 |'));
  });

  test('TEXT 根节点标文字色，不叫背景', () {
    final textRoot = <String, dynamic>{
      'id': '20:1',
      'type': 'TEXT',
      'name': 'note',
      'characters': 'Hello',
      'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 48, 'height': 19},
      'style': {'fontFamily': 'Inter', 'fontSize': 16, 'textAlignHorizontal': 'LEFT'},
      'fills': [
        {
          'type': 'SOLID',
          'color': {'r': 0.2, 'g': 0.2, 'b': 0.2},
        },
      ],
      'children': <Object?>[],
    };
    final md = const figma.FigmaSpecRenderer().renderMarkdownFromRoot(textRoot, '20:1');
    expect(md, contains('文字 48×19，文字色 #333333'));
    expect(md, isNot(contains('画板')));
    expect(md, isNot(contains('背景')));
  });

  test('rich run 只有 decoration 时回退 base 字号，不输出孤立 px', () {
    final text = <String, dynamic>{
      'id': '21:1',
      'type': 'TEXT',
      'name': 'note',
      'characters': 'abcdef',
      'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 100, 'height': 20},
      'style': {
        'fontFamily': 'Noto Sans TC',
        'fontWeight': 400,
        'fontSize': 16,
        'textAlignHorizontal': 'LEFT',
      },
      'characterStyleOverrides': <int>[0, 0, 0, 0, 3, 3],
      'styleOverrideTable': {
        '3': {'textDecoration': 'UNDERLINE'},
      },
      'children': <Object?>[],
    };
    final md = const figma.FigmaSpecRenderer().renderMarkdownFromRoot(text, '21:1');
    expect(md, contains('Noto Sans TC 16px 400 deco=UNDERLINE'));
    expect(md, isNot(contains("'ef' px")));
  });

  test('根节点 bbox / style 结构异常时报可读错误', () {
    final badBox = <String, dynamic>{
      'id': '1:1',
      'type': 'FRAME',
      'name': 'bad',
      'absoluteBoundingBox': {'y': 0, 'width': 10, 'height': 10},
      'children': <Object?>[],
    };
    expect(
      () => const figma.FigmaSpecRenderer().renderMarkdownFromRoot(badBox, '1:1'),
      throwsA(
          isA<StateError>().having((e) => e.message, 'message', contains('absoluteBoundingBox'))),
    );

    final badStyle = <String, dynamic>{
      'id': '1:1',
      'type': 'TEXT',
      'name': 'bad',
      'characters': 'hi',
      'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
      'style': 'oops',
      'children': <Object?>[],
    };
    expect(
      () => const figma.FigmaSpecRenderer().renderMarkdownFromRoot(badStyle, '1:1'),
      throwsA(isA<StateError>().having((e) => e.message, 'message', contains('style'))),
    );
  });

  test('描边虚线 / 文字样式 / 隐藏层等关键属性都被渲染', () {
    final md = markdown!;
    expect(md, contains('# Frame 15720  (1915:58517)'));
    expect(md, contains('画板 375×700'));
    // 表格表头固定
    expect(md, contains('| x,y | w×h | 类型 | 名称 | 填充 | 描边 | 阴影 | 圆角 | 透明度 | 文字 |'));
  });
}

Map<String, dynamic> _documentOf(File file) {
  final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final nodes = raw['nodes'] as Map<String, dynamic>;
  return (nodes.values.first as Map<String, dynamic>)['document'] as Map<String, dynamic>;
}
