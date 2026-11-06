import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

void main() {
  test('WColorExtension.fromHex', () {
    expect(WColorExtension.fromHex('#FF5733'), const Color(0xFFFF5733));
    expect('#FF5733'.toColor(), const Color(0xFFFF5733));
  });

  test('WImageStyleExtension 链式糖', () {
    final style = WImageStyleExtension(const WImageStyle()).square(40).rounded(20);
    expect(style.width, 40);
    expect(style.height, 40);
    expect(style.borderRadius, BorderRadius.circular(20));
  });

  test('WThemeDataExtension.withWTextStyles', () {
    final styles = WTextStyles.fromTextTheme(ThemeData.light().textTheme);
    final theme = WThemeDataExtension(ThemeData.light()).withWTextStyles(styles);
    expect(theme.extension<WTextStyles>(), styles);
  });
}
