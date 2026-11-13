import 'package:flutter/material.dart';

/// 步骤条按主题解析后的三种颜色。
@immutable
class WStepColors {
  const WStepColors({
    required this.completed,
    required this.current,
    required this.upcoming,
  });

  final Color completed;
  final Color current;
  final Color upcoming;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WStepColors &&
          other.completed == completed &&
          other.current == current &&
          other.upcoming == upcoming;

  @override
  int get hashCode => Object.hash(completed, current, upcoming);
}

/// 步骤条样式。
@immutable
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
  WStepColors resolve(ColorScheme scheme) {
    return WStepColors(
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
    TextStyle? labelStyle,
    TextStyle? completedLabelStyle,
    TextStyle? currentLabelStyle,
    TextStyle? upcomingLabelStyle,
  }) {
    return WStepStyle(
      completedColor: completedColor ?? this.completedColor,
      currentColor: currentColor ?? this.currentColor,
      upcomingColor: upcomingColor ?? this.upcomingColor,
      itemSize: itemSize ?? this.itemSize,
      labelSpacing: labelSpacing ?? this.labelSpacing,
      separatorHeight: separatorHeight ?? this.separatorHeight,
      separatorIndent: separatorIndent ?? this.separatorIndent,
      labelStyle: labelStyle ?? this.labelStyle,
      completedLabelStyle: completedLabelStyle ?? this.completedLabelStyle,
      currentLabelStyle: currentLabelStyle ?? this.currentLabelStyle,
      upcomingLabelStyle: upcomingLabelStyle ?? this.upcomingLabelStyle,
    );
  }
}
