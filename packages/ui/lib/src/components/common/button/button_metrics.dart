import 'package:flutter/material.dart';

import 'button_style.dart';

/// WButtonStyle 的布局 / 尺寸部分；用于把布局从样式里逐步拆出。
@immutable
class WButtonMetrics {
  const WButtonMetrics({
    required this.padding,
    required this.alignment,
    required this.minWidth,
    required this.minHeight,
    required this.tapTargetSize,
    required this.iconSize,
    required this.gap,
  });

  factory WButtonMetrics.fromStyle(WButtonStyle style) {
    return WButtonMetrics(
      padding: style.padding,
      alignment: style.alignment,
      minWidth: style.minWidth,
      minHeight: style.minHeight,
      tapTargetSize: style.tapTargetSize,
      iconSize: style.iconSize,
      gap: style.gap,
    );
  }

  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;
  final double minWidth;
  final double minHeight;
  final double tapTargetSize;
  final double iconSize;
  final double gap;

  /// 把这些布局字段写回一个 WButtonStyle。
  WButtonStyle applyTo(WButtonStyle style) {
    return style.copyWith(
      padding: padding,
      alignment: alignment,
      minWidth: minWidth,
      minHeight: minHeight,
      tapTargetSize: tapTargetSize,
      iconSize: iconSize,
      gap: gap,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WButtonMetrics &&
          other.padding == padding &&
          other.alignment == alignment &&
          other.minWidth == minWidth &&
          other.minHeight == minHeight &&
          other.tapTargetSize == tapTargetSize &&
          other.iconSize == iconSize &&
          other.gap == gap;

  @override
  int get hashCode => Object.hash(
    padding,
    alignment,
    minWidth,
    minHeight,
    tapTargetSize,
    iconSize,
    gap,
  );
}
