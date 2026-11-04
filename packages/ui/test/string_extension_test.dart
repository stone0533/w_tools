import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

void main() {
  group('WImageStyle.copyWith', () {
    test('复制字段，不可变', () {
      const style = WImageStyle(
        width: 10,
        height: 20,
        fit: BoxFit.contain,
        aspectRatio: 1.5,
        semanticLabel: '头像',
        excludeFromSemantics: true,
        filterQuality: FilterQuality.high,
        alignment: Alignment.topCenter,
      );

      final copy = style.copyWith(width: 99);
      expect(copy.width, 99);
      expect(style.width, 10);
      expect(copy.height, 20);
      expect(copy.fit, BoxFit.contain);
      expect(copy.semanticLabel, '头像');
      expect(copy.filterQuality, FilterQuality.high);
      expect(copy.alignment, Alignment.topCenter);
    });
  });
}
