import 'package:flutter/material.dart';
import 'package:w_tools_form/w_tools_form.dart';

/// 边框配置不可变，可以安全地跨字段、跨页面共享。
final WFormBorderConfig exampleBorderConfig = WFormBorderConfig.standard(
  radius: 12,
);

/// 每次调用都创建新的字段 Config，避免可变配置跨字段共享。
WFormTextFieldConfig exampleTextConfig() {
  return WFormTextFieldConfig()
    ..height = 52
    ..containerPadding = const EdgeInsets.symmetric(horizontal: 16)
    ..style = const TextStyle(fontSize: 16, color: Color(0xFF111827))
    ..hintStyle = const TextStyle(fontSize: 16, color: Color(0xFF9CA3AF));
}

WFormDropdownConfig exampleDropdownConfig() {
  return WFormDropdownConfig()
    ..height = 52
    ..containerPadding = const EdgeInsets.symmetric(horizontal: 16)
    ..style = const TextStyle(fontSize: 16, color: Color(0xFF111827))
    ..hintStyle = const TextStyle(fontSize: 16, color: Color(0xFF9CA3AF));
}

WFormDatePickerConfig exampleDateConfig({String? hintText}) {
  return WFormDatePickerConfig()
    ..height = 52
    ..containerPadding = const EdgeInsets.symmetric(horizontal: 16)
    ..displayFormat = 'yyyy-MM-dd'
    ..style = const TextStyle(fontSize: 16, color: Color(0xFF111827))
    ..decoration = InputDecoration(
      hintText: hintText,
      border: InputBorder.none,
    );
}

WFormMultiDropdownConfig exampleMultiConfig() {
  return WFormMultiDropdownConfig()
    ..height = 52
    ..containerPadding = const EdgeInsets.symmetric(horizontal: 16)
    ..hintText = '请选择';
}

/// 页面级表单主题：边框和图标由 WFormTheme 统一提供。
Widget exampleFormTheme({required Widget child}) {
  return WFormTheme(
    borderConfig: exampleBorderConfig,
    dropdownIcon: const Icon(Icons.keyboard_arrow_down_rounded),
    checkboxSelectedIcon: const Icon(
      Icons.check_circle_rounded,
      color: Color(0xFF10B981),
    ),
    child: child,
  );
}
