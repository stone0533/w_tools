import 'package:flutter/material.dart';

/// 表单字段共用的外框配置。
///
/// 字段 Config 继承本类，避免 height / width / leading / actions /
/// containerPadding 等字段在六个字段中重复声明。
class WFormFieldChrome {
  bool enabled = true;
  double? height;
  double? width;
  double? yOffset;
  Widget? leading;
  List<Widget>? actions;
  Decoration? containerDecoration;
  EdgeInsetsGeometry? containerMargin;
  EdgeInsetsGeometry? containerPadding;
}
