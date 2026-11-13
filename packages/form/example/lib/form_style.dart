import 'package:flutter/material.dart';
import 'package:w_tools_form/w_tools_form.dart';

// 页面级边框直接用 WForm 的默认值（跟随主题）。这里只保留「自定义边框」示例，
// 见 exampleCompactBorderConfig。

/// 页面默认字段样式：高度 / 内边距 / 正文 / hint。
const exampleFieldStyle = WFormFieldStyle(
  height: 52,
  containerPadding: EdgeInsets.symmetric(horizontal: 16),
  textStyle: TextStyle(fontSize: 16, color: Color(0xFF111827)),
  hintStyle: TextStyle(fontSize: 16, color: Color(0xFF9CA3AF)),
);

/// 自定义边框：灰底 + 聚焦绿边 + 错误红边，消息使用自定义前缀。
final exampleCompactBorderConfig = WFormBorderStyle(
  defaultDecoration: BoxDecoration(
    color: const Color(0xFFF9FAFB),
    border: Border.all(color: const Color(0xFFE5E7EB)),
    borderRadius: BorderRadius.circular(8),
  ),
  focusedDecoration: BoxDecoration(
    color: Colors.white,
    border: Border.all(color: const Color(0xFF059669), width: 1.5),
    borderRadius: BorderRadius.circular(8),
  ),
  errorDecoration: BoxDecoration(
    color: const Color(0xFFFFF1F2),
    border: Border.all(color: const Color(0xFFDC2626)),
    borderRadius: BorderRadius.circular(8),
  ),
  hintBuilder: _buildHint,
  errorBuilder: _buildError,
);

Widget _buildHint(List<String>? list) {
  if (list == null || list.isEmpty) return const SizedBox.shrink();
  return Text(
    '提示：${list.join('；')}',
    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
  );
}

Widget _buildError(List<String>? list) {
  if (list == null || list.isEmpty) return const SizedBox.shrink();
  return Text(
    '错误：${list.join('；')}',
    style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
  );
}
