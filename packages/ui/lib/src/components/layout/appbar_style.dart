import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 标准顶部栏样式。
@immutable
class WAppBarStyle {
  const WAppBarStyle({
    this.backgroundColor,
    this.gradient,
    this.foregroundColor,
    this.titleStyle,
    this.height = 56,
    this.titleSpacing,
    this.systemOverlayStyle,
  });

  final Color? backgroundColor;
  final Gradient? gradient;
  final Color? foregroundColor;
  final TextStyle? titleStyle;
  final double height;
  final double? titleSpacing;
  final SystemUiOverlayStyle? systemOverlayStyle;

  /// 派生新样式；传 null 表示保留当前值（不能用 copyWith 清空字段）。
  WAppBarStyle copyWith({
    Color? backgroundColor,
    Gradient? gradient,
    Color? foregroundColor,
    TextStyle? titleStyle,
    double? height,
    double? titleSpacing,
    SystemUiOverlayStyle? systemOverlayStyle,
  }) {
    return WAppBarStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gradient: gradient ?? this.gradient,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      titleStyle: titleStyle ?? this.titleStyle,
      height: height ?? this.height,
      titleSpacing: titleSpacing ?? this.titleSpacing,
      systemOverlayStyle: systemOverlayStyle ?? this.systemOverlayStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WAppBarStyle &&
          other.backgroundColor == backgroundColor &&
          other.gradient == gradient &&
          other.foregroundColor == foregroundColor &&
          other.titleStyle == titleStyle &&
          other.height == height &&
          other.titleSpacing == titleSpacing &&
          other.systemOverlayStyle == systemOverlayStyle;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    gradient,
    foregroundColor,
    titleStyle,
    height,
    titleSpacing,
    systemOverlayStyle,
  );

  void validate() {
    assert(height >= 0 && height.isFinite, 'WAppBarStyle.height 非法');
    assert(
      titleSpacing == null || (titleSpacing!.isFinite && titleSpacing! >= 0),
      'WAppBarStyle.titleSpacing 必须非负',
    );
    assert(
      !(backgroundColor != null && gradient != null),
      'WAppBarStyle.backgroundColor 与 gradient 只能选一个',
    );
  }
}
