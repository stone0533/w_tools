import 'package:test/test.dart';
import 'package:w_tools_figma/src/tokens/token_renderer.dart';

void main() {
  test('透明色映射键忽略 @opacity', () {
    expect(colorKey('#757575@0.80'), '757575');
  });
}
