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

  static const Object _unset = Object();

  WAppBarStyle copyWith({
    Object? backgroundColor = _unset,
    Object? gradient = _unset,
    Object? foregroundColor = _unset,
    Object? titleStyle = _unset,
    double? height,
    Object? titleSpacing = _unset,
    Object? systemOverlayStyle = _unset,
  }) {
    return WAppBarStyle(
      backgroundColor: identical(backgroundColor, _unset)
          ? this.backgroundColor
          : backgroundColor as Color?,
      gradient: identical(gradient, _unset) ? this.gradient : gradient as Gradient?,
      foregroundColor: identical(foregroundColor, _unset)
          ? this.foregroundColor
          : foregroundColor as Color?,
      titleStyle: identical(titleStyle, _unset) ? this.titleStyle : titleStyle as TextStyle?,
      height: height ?? this.height,
      titleSpacing: identical(titleSpacing, _unset) ? this.titleSpacing : titleSpacing as double?,
      systemOverlayStyle: identical(systemOverlayStyle, _unset)
          ? this.systemOverlayStyle
          : systemOverlayStyle as SystemUiOverlayStyle?,
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

/// 标准顶部导航栏。
///
/// 只提供 leading / title / actions / bottom 的标准布局；
/// 任意叠放请在页面层自己用 Container/Stack。
///
/// 默认包含状态栏背景；嵌套在 SafeArea 中时可传 `includeStatusBar: false`。
