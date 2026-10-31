import 'package:flutter/material.dart';
import 'package:w_tools_form/w_tools_form.dart';

/// 边框配置不可变，可以安全地跨字段、跨页面共享。
final WFormBorderConfig exampleBorderConfig = WFormBorderConfig.standard(
  radius: 12,
);

/// 高级样式覆盖示例：普通页面直接使用 WFormTextField 的 label 即可。
WFormTextFieldConfig exampleTextConfig() {
  return WFormTextFieldConfig()
    ..height = 52
    ..containerPadding = const EdgeInsets.symmetric(horizontal: 16)
    ..style = const TextStyle(fontSize: 16, color: Color(0xFF111827))
    ..hintStyle = const TextStyle(fontSize: 16, color: Color(0xFF9CA3AF));
}
