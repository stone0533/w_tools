import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_app/w_tools_app.dart';

void main() {
  test('值相等 / hashCode / copyWith', () {
    final light = ThemeData.light();
    final dark = ThemeData.dark();
    final a = WAppTheme(light: light, dark: dark, mode: ThemeMode.dark);
    final b = WAppTheme(light: light, dark: dark, mode: ThemeMode.dark);

    expect(a, b);
    expect(a.hashCode, b.hashCode);

    final copy = a.copyWith(mode: ThemeMode.light);
    expect(copy.mode, ThemeMode.light);
    expect(copy.light, same(light));
    expect(copy.dark, same(dark));
  });

  test('默认系统栏为透明状态栏 + 黑色导航栏', () {
    final style = const WAppTheme().systemUiOverlayStyle;

    expect(style, isNotNull);
    expect(style!.statusBarColor, Colors.transparent);
    expect(style.statusBarBrightness, Brightness.dark);
    expect(style.systemNavigationBarColor, Colors.black);
    expect(style.systemNavigationBarIconBrightness, Brightness.light);
  });

  test('显式 null 可关闭系统栏干预', () {
    expect(const WAppTheme(systemUiOverlayStyle: null).systemUiOverlayStyle, isNull);
  });
}
