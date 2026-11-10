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
