// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package
import 'package:flutter/material.dart';

/// 表单字段共用的外框配置。
///
/// 字段 Config 继承本类，避免 height / width / leading / actions /
/// containerPadding 等字段在七个字段中重复声明。
///
/// 本类是可变的：建议每个字段独立创建一份配置；需要跨字段复用时使用
/// `copy()/copyWith()`，不要直接共享同一个实例。
abstract class WFormFieldBaseConfig {
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
