import 'package:flutter/foundation.dart';
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
    this.leadingWidth,
    this.actionsPadding,
    this.boxShadow,
    this.systemOverlayStyle,
  });

  final Color? backgroundColor;
  final Gradient? gradient;
  final Color? foregroundColor;
  final TextStyle? titleStyle;
  final double height;
  final double? titleSpacing;

  /// leading 区域的宽度；null 时由 [NavigationToolbar] 决定。
  final double? leadingWidth;

  /// actions 区域的内边距；null 时不额外加 padding。
  final EdgeInsetsGeometry? actionsPadding;

  /// 顶栏阴影；自绘顶栏没有 Material elevation，需要阴影时显式传。
  final List<BoxShadow>? boxShadow;
  final SystemUiOverlayStyle? systemOverlayStyle;

  /// 派生新样式；传 null 表示保留当前值（不能用 copyWith 清空字段）。
  ///
  /// 需要在纯色与渐变之间切换时用 [withBackground]；清空背景用
  /// [withoutBackground]。
  WAppBarStyle copyWith({
    Color? backgroundColor,
    Gradient? gradient,
    Color? foregroundColor,
    TextStyle? titleStyle,
    double? height,
    double? titleSpacing,
    double? leadingWidth,
    EdgeInsetsGeometry? actionsPadding,
    List<BoxShadow>? boxShadow,
    SystemUiOverlayStyle? systemOverlayStyle,
  }) {
    return WAppBarStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gradient: gradient ?? this.gradient,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      titleStyle: titleStyle ?? this.titleStyle,
      height: height ?? this.height,
      titleSpacing: titleSpacing ?? this.titleSpacing,
      leadingWidth: leadingWidth ?? this.leadingWidth,
      actionsPadding: actionsPadding ?? this.actionsPadding,
      boxShadow: boxShadow ?? this.boxShadow,
      systemOverlayStyle: systemOverlayStyle ?? this.systemOverlayStyle,
    );
  }

  /// 设置唯一背景：color / gradient 必须且只能传一个，并清空另一个。
  ///
  /// [copyWith] 的 null 表示保留，无法清空另一项；渐变 ↔ 纯色切换用这里，
  /// 否则 `copyWith(backgroundColor: c)` 会同时保留 gradient，触发 validate 断言。
  WAppBarStyle withBackground({Color? color, Gradient? gradient}) {
    assert(
      (color == null) != (gradient == null),
      'WAppBarStyle.withBackground: color 与 gradient 必须且只能传一个',
    );
    return WAppBarStyle(
      backgroundColor: color,
      gradient: gradient,
      foregroundColor: foregroundColor,
      titleStyle: titleStyle,
      height: height,
      titleSpacing: titleSpacing,
      leadingWidth: leadingWidth,
      actionsPadding: actionsPadding,
      boxShadow: boxShadow,
      systemOverlayStyle: systemOverlayStyle,
    );
  }

  /// 清空背景（backgroundColor 与 gradient）。
  WAppBarStyle withoutBackground() {
    return WAppBarStyle(
      foregroundColor: foregroundColor,
      titleStyle: titleStyle,
      height: height,
      titleSpacing: titleSpacing,
      leadingWidth: leadingWidth,
      actionsPadding: actionsPadding,
      boxShadow: boxShadow,
      systemOverlayStyle: systemOverlayStyle,
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
          other.leadingWidth == leadingWidth &&
          other.actionsPadding == actionsPadding &&
          listEquals(other.boxShadow, boxShadow) &&
          other.systemOverlayStyle == systemOverlayStyle;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    gradient,
    foregroundColor,
    titleStyle,
    height,
    titleSpacing,
    leadingWidth,
    actionsPadding,
    boxShadow == null ? null : Object.hashAll(boxShadow!),
    systemOverlayStyle,
  );

  void validate() {
    assert(height >= 0 && height.isFinite, 'WAppBarStyle.height 非法');
    assert(
      titleSpacing == null || (titleSpacing!.isFinite && titleSpacing! >= 0),
      'WAppBarStyle.titleSpacing 必须非负',
    );
    assert(
      leadingWidth == null || (leadingWidth!.isFinite && leadingWidth! >= 0),
      'WAppBarStyle.leadingWidth 必须非负',
    );
    assert(
      !(backgroundColor != null && gradient != null),
      'WAppBarStyle.backgroundColor 与 gradient 只能选一个',
    );
  }
}
