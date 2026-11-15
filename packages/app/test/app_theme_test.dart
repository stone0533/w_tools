// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_app/w_tools_app.dart';

void main() {
  test('值相等 / hashCode', () {
    final light = ThemeData.light();
    final dark = ThemeData.dark();
    final a = WAppTheme(light: light, dark: dark, mode: ThemeMode.dark);
    final b = WAppTheme(light: light, dark: dark, mode: ThemeMode.dark);

    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('默认不干预系统栏', () {
    expect(const WAppTheme().systemUiOverlayStyle, isNull);
  });

  test('显式样式原样保留', () {
    const style = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
    );

    expect(
      const WAppTheme(systemUiOverlayStyle: style).systemUiOverlayStyle,
      same(style),
    );
  });
}
