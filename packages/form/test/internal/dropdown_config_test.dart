import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/src/components/fields/dropdown.dart';
import 'package:w_tools_form/src/components/fields/multi_dropdown.dart';

/// `WFormDropdownConfig` / `WFormMultiDropdownConfig` 是包内实现（barrel 里 hide），
/// 白盒测试只能放在 `test/internal/`；根 `test/` 不允许 import src。
void main() {
  group('WFormDropdownConfig', () {
    test('所有 setter 可调用', () {
      final c = WFormDropdownConfig()
        ..height = 48
        ..hint = const Text('请选择')
        ..icon = const Icon(Icons.arrow_downward)
        ..dropdownColor = Colors.white
        ..style = const TextStyle(fontSize: 16);
      expect(c, isNotNull);
    });
  });

  group('WFormMultiDropdownConfig', () {
    test('所有 setter 可调用', () {
      final c = WFormMultiDropdownConfig()
        ..height = 48
        ..enabled = true
        ..icon = const Icon(Icons.arrow_drop_down)
        ..itemPadding = const EdgeInsets.symmetric(vertical: 8);
      expect(c, isNotNull);
    });
  });
}
