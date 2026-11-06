import 'package:flutter/material.dart';

const Object _unset = Object();

class WStepStyle {
  const WStepStyle({
    this.completedColor,
    this.currentColor,
    this.upcomingColor,
    this.itemSize = 28,
    this.labelSpacing = 8,
    this.separatorHeight = 2,
    this.separatorIndent = 8,
    this.labelStyle,
    this.completedLabelStyle,
    this.currentLabelStyle,
    this.upcomingLabelStyle,
  });

  /// 为 null 时分别取 `ColorScheme.primary` / `primary` / `outline`。
  final Color? completedColor;
  final Color? currentColor;
  final Color? upcomingColor;
  final double itemSize;
  final double labelSpacing;
  final double separatorHeight;
  final double separatorIndent;
  final TextStyle? labelStyle;
  final TextStyle? completedLabelStyle;
  final TextStyle? currentLabelStyle;
  final TextStyle? upcomingLabelStyle;

  /// 按 ColorScheme 解析实际颜色；未显式设置的颜色取主题色。
  ({Color completed, Color current, Color upcoming}) resolve(ColorScheme scheme) {
    return (
      completed: completedColor ?? scheme.primary,
      current: currentColor ?? scheme.primary,
      upcoming: upcomingColor ?? scheme.outline,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WStepStyle &&
          other.completedColor == completedColor &&
          other.currentColor == currentColor &&
          other.upcomingColor == upcomingColor &&
          other.itemSize == itemSize &&
          other.labelSpacing == labelSpacing &&
          other.separatorHeight == separatorHeight &&
          other.separatorIndent == separatorIndent &&
          other.labelStyle == labelStyle &&
          other.completedLabelStyle == completedLabelStyle &&
          other.currentLabelStyle == currentLabelStyle &&
          other.upcomingLabelStyle == upcomingLabelStyle;

  @override
  int get hashCode => Object.hash(
    completedColor,
    currentColor,
    upcomingColor,
    itemSize,
    labelSpacing,
    separatorHeight,
    separatorIndent,
    labelStyle,
    completedLabelStyle,
    currentLabelStyle,
    upcomingLabelStyle,
  );

  WStepStyle copyWith({
    Color? completedColor,
    Color? currentColor,
    Color? upcomingColor,
    double? itemSize,
    double? labelSpacing,
    double? separatorHeight,
    double? separatorIndent,
    Object? labelStyle = _unset,
    Object? completedLabelStyle = _unset,
    Object? currentLabelStyle = _unset,
    Object? upcomingLabelStyle = _unset,
  }) {
    return WStepStyle(
      completedColor: completedColor ?? this.completedColor,
      currentColor: currentColor ?? this.currentColor,
      upcomingColor: upcomingColor ?? this.upcomingColor,
      itemSize: itemSize ?? this.itemSize,
      labelSpacing: labelSpacing ?? this.labelSpacing,
      separatorHeight: separatorHeight ?? this.separatorHeight,
      separatorIndent: separatorIndent ?? this.separatorIndent,
      labelStyle: identical(labelStyle, _unset) ? this.labelStyle : labelStyle as TextStyle?,
      completedLabelStyle: identical(completedLabelStyle, _unset)
          ? this.completedLabelStyle
          : completedLabelStyle as TextStyle?,
      currentLabelStyle: identical(currentLabelStyle, _unset)
          ? this.currentLabelStyle
          : currentLabelStyle as TextStyle?,
      upcomingLabelStyle: identical(upcomingLabelStyle, _unset)
          ? this.upcomingLabelStyle
          : upcomingLabelStyle as TextStyle?,
    );
  }
}

/// 一组步骤的不可变定义，可在多个页面复用。
///
/// 页面只需要传 [current]：
///
/// ```dart
/// AppSteps.register.build(current: step)
/// ```
