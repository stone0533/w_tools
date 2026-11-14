// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

void main() {
  test('WAppBarStyle 值相等', () {
    final a = WAppBarStyle(height: 60);
    final b = WAppBarStyle(height: 60);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('WStepStyle 值相等', () {
    final a = WStepStyle(itemSize: 32);
    final b = WStepStyle(itemSize: 32);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });
}
