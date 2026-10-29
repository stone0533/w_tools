import 'package:flutter/material.dart';

import 'button_motion.dart';
import 'button_semantics.dart';
import 'button_size.dart';

/// 不可变的按钮视觉样式。
///
/// 动效见 [WButtonMotion]，语义/loading 文案见 [WButtonSemantics]。
@immutable
class WButtonStyle {
  const WButtonStyle({
    this.motion = const WButtonMotion(),
    this.semantics = const WButtonSemantics(),
    this.backgroundColor,
    this.gradient,
    this.border,
    this.borderRadius,
    this.boxShadow,
    this.padding,
    this.clipBehavior = Clip.none,
    this.foregroundColor,
    this.textStyle,
    this.focusColor,
    this.hoverColor,
    this.disabledOpacity = 0.5,
    this.minWidth = 48,
    this.minHeight = 48,
    this.tapTargetSize = 48,
    this.iconSize = 18,
    this.gap = 8,
  });

  final WButtonMotion motion;
  final WButtonSemantics semantics;

  /// 纯色背景
  final Color? backgroundColor;

  /// 渐变背景
  final Gradient? gradient;

  /// 边框
  final BoxBorder? border;

  /// 圆角
  final BorderRadius? borderRadius;

  /// 阴影
  final List<BoxShadow>? boxShadow;

  /// 内容内边距
  final EdgeInsetsGeometry? padding;

  /// 背景裁剪行为；none 表示不裁剪
  final Clip clipBehavior;

  /// 文字/图标默认前景色
  final Color? foregroundColor;

  /// 文本样式
  final TextStyle? textStyle;

  /// 键盘焦点 overlay
  final Color? focusColor;

  /// hover overlay
  final Color? hoverColor;

  /// 禁用透明度
  final double disabledOpacity;

  final double minWidth;
  final double minHeight;
  final double tapTargetSize;
  final double iconSize;
  final double gap;

  /// 填充按钮的常用构造。
  factory WButtonStyle.filled({
    required Color backgroundColor,
    Color? foregroundColor,
    Color? borderColor,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    TextStyle? textStyle,
    WButtonMotion motion = const WButtonMotion(),
    WButtonSemantics semantics = const WButtonSemantics(),
  }) {
    return WButtonStyle(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      border: borderColor == null ? null : Border.all(color: borderColor),
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      padding: padding,
      textStyle: textStyle,
      motion: motion,
      semantics: semantics,
    );
  }

  /// 描边按钮的常用构造。
  factory WButtonStyle.outlined({
    Color? foregroundColor,
    Color? borderColor,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    TextStyle? textStyle,
    WButtonMotion motion = const WButtonMotion(),
    WButtonSemantics semantics = const WButtonSemantics(),
  }) {
    final color = borderColor ?? foregroundColor;
    return WButtonStyle(
      backgroundColor: Colors.transparent,
      foregroundColor: foregroundColor,
      border: color == null ? null : Border.all(color: color),
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      padding: padding,
      textStyle: textStyle,
      motion: motion,
      semantics: semantics,
    );
  }

  /// 文字按钮的常用构造。
  factory WButtonStyle.text({
    Color? foregroundColor,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    TextStyle? textStyle,
    WButtonMotion motion = const WButtonMotion(),
    WButtonSemantics semantics = const WButtonSemantics(),
  }) {
    return WButtonStyle(
      foregroundColor: foregroundColor,
      borderRadius: BorderRadius.circular(8),
      padding: padding,
      textStyle: textStyle,
      motion: motion,
      semantics: semantics,
    );
  }

  void validate() {
    motion.validate();
    assert(
      disabledOpacity >= 0 && disabledOpacity <= 1,
      'disabledOpacity 必须在 0..1',
    );
    assert(minWidth >= 0 && minHeight >= 0, 'minWidth/minHeight 不能为负');
    assert(minWidth.isFinite && minHeight.isFinite, 'minWidth/minHeight 必须有限');
    assert(tapTargetSize >= 0 && tapTargetSize.isFinite, 'tapTargetSize 非法');
    assert(iconSize >= 0 && gap >= 0, 'iconSize/gap 不能为负');
  }

  WButtonStyle copyWith({
    WButtonMotion? motion,
    WButtonSemantics? semantics,
    Color? backgroundColor,
    Gradient? gradient,
    BoxBorder? border,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
    EdgeInsetsGeometry? padding,
    Clip? clipBehavior,
    Color? foregroundColor,
    TextStyle? textStyle,
    Color? focusColor,
    Color? hoverColor,
    double? disabledOpacity,
    double? minWidth,
    double? minHeight,
    double? tapTargetSize,
    double? iconSize,
    double? gap,
  }) {
    return WButtonStyle(
      motion: motion ?? this.motion,
      semantics: semantics ?? this.semantics,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gradient: gradient ?? this.gradient,
      border: border ?? this.border,
      borderRadius: borderRadius ?? this.borderRadius,
      boxShadow: boxShadow ?? this.boxShadow,
      padding: padding ?? this.padding,
      clipBehavior: clipBehavior ?? this.clipBehavior,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      textStyle: textStyle ?? this.textStyle,
      focusColor: focusColor ?? this.focusColor,
      hoverColor: hoverColor ?? this.hoverColor,
      disabledOpacity: disabledOpacity ?? this.disabledOpacity,
      minWidth: minWidth ?? this.minWidth,
      minHeight: minHeight ?? this.minHeight,
      tapTargetSize: tapTargetSize ?? this.tapTargetSize,
      iconSize: iconSize ?? this.iconSize,
      gap: gap ?? this.gap,
    );
  }

  /// 清空背景相关字段。
  WButtonStyle withoutBackground() {
    return WButtonStyle(
      motion: motion,
      semantics: semantics,
      padding: padding,
      clipBehavior: clipBehavior,
      foregroundColor: foregroundColor,
      textStyle: textStyle,
      focusColor: focusColor,
      hoverColor: hoverColor,
      disabledOpacity: disabledOpacity,
      minWidth: minWidth,
      minHeight: minHeight,
      tapTargetSize: tapTargetSize,
      iconSize: iconSize,
      gap: gap,
    );
  }

  /// 清空文本样式与前景色。
  WButtonStyle withoutTextStyle() {
    return WButtonStyle(
      motion: motion,
      semantics: semantics,
      backgroundColor: backgroundColor,
      gradient: gradient,
      border: border,
      borderRadius: borderRadius,
      boxShadow: boxShadow,
      padding: padding,
      clipBehavior: clipBehavior,
      focusColor: focusColor,
      hoverColor: hoverColor,
      disabledOpacity: disabledOpacity,
      minWidth: minWidth,
      minHeight: minHeight,
      tapTargetSize: tapTargetSize,
      iconSize: iconSize,
      gap: gap,
    );
  }

  /// 把尺寸令牌叠加到当前样式；只覆盖布局/文字/图标字段。
  WButtonStyle applySize(WButtonSize? size) {
    if (size == null) return this;
    size.validate();
    TextStyle? nextTextStyle = textStyle;
    if (size.fontSize != null ||
        size.fontWeight != null ||
        size.lineHeight != null ||
        size.letterSpacing != null) {
      nextTextStyle = (textStyle ?? const TextStyle()).copyWith(
        fontSize: size.fontSize,
        fontWeight: size.fontWeight,
        height: size.lineHeight,
        letterSpacing: size.letterSpacing,
      );
    }
    return copyWith(
      padding: size.padding ?? padding,
      minWidth: size.minWidth ?? minWidth,
      minHeight: size.minHeight ?? minHeight,
      tapTargetSize: size.tapTargetSize,
      textStyle: nextTextStyle,
      iconSize: size.iconSize ?? iconSize,
      gap: size.gap ?? gap,
    );
  }
}
