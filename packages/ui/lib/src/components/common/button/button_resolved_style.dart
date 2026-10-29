import 'package:flutter/material.dart';

/// 当前 WidgetState 下解析后的按钮视觉值。
@immutable
class WButtonResolvedStyle {
  const WButtonResolvedStyle({
    this.backgroundColor,
    this.gradient,
    this.border,
    this.boxShadow,
    this.textStyle,
    this.foregroundColor,
    this.iconSize = 18,
    this.gap = 8,
  });

  final Color? backgroundColor;
  final Gradient? gradient;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final TextStyle? textStyle;
  final Color? foregroundColor;
  final double iconSize;
  final double gap;
}
