import 'package:test/test.dart';
import 'package:w_tools_figma/src/spec/figma_node.dart';

void main() {
  test('描边缺 strokeWeight 时不打印 Python 的 None', () {
    final text = figmaStrokes({
      'strokes': [
        {
          'type': 'SOLID',
          'color': {'r': 0, 'g': 0, 'b': 0},
        },
      ],
    });

    expect(text, contains('#000000'));
    expect(text, isNot(contains('None')));
    expect(text, isNot(contains(' px')));
  });

  test('individualStrokeWeights 输出边和宽度', () {
    final text = figmaStrokes({
      'individualStrokeWeights': {'left': 2, 'right': 1, 'top': 0, 'bottom': 0},
      'strokes': [
        {
          'type': 'SOLID',
          'color': {'r': 0, 'g': 0, 'b': 0}
        },
      ],
    });

    expect(text, contains('L=2'));
    expect(text, contains('R=1'));
    expect(text, isNot(contains('T=')));
  });

  test('非默认 strokeCap / strokeJoin 输出短标记', () {
    final text = figmaStrokes({
      'strokeCap': 'ROUND',
      'strokeJoin': 'ROUND',
      'strokes': [
        {
          'type': 'SOLID',
          'color': {'r': 0, 'g': 0, 'b': 0},
        },
      ],
    });

    expect(text, contains('cap=ROUND'));
    expect(text, contains('join=ROUND'));
  });

  test('有 strokeWeight 时照常带 px', () {
    final text = figmaStrokes({
      'strokeWeight': 2,
      'strokes': [
        {
          'type': 'SOLID',
          'color': {'r': 1, 'g': 1, 'b': 1},
        },
      ],
    });

    expect(text, contains('2px'));
  });
}
