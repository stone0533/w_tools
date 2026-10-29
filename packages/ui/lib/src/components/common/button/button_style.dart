import 'package:flutter/material.dart';

import '../../layout/container.dart';
import '../text.dart';
import 'button_motion.dart';
import 'button_size.dart';
import 'button_semantics.dart';

/// 不可变的按钮视觉样式。
///
/// 动效见 [WButtonMotion]，语义/loading 文案见 [WButtonSemantics]。
@immutable
class WButtonStyle {
  WButtonStyle({
    this.motion = const WButtonMotion(),
    this.semantics = const WButtonSemantics(),
    WContainerConfig? container,
    this.padding,
    WTextConfig? textStyle,
    this.focusColor,
    this.hoverColor,
    this.overlayBorderRadius,
    this.disabledOpacity = 0.5,
    this.minWidth = 48,
    this.minHeight = 48,
    this.tapTargetSize = 48,
    this.iconSize = 18,
    this.gap = 8,
  })  : _container = container?.copy(),
        _textStyle = textStyle?.copy();

  final WButtonMotion motion;
  final WButtonSemantics semantics;

  final WContainerConfig? _container;

  /// 容器样式快照；每次读取返回副本
  WContainerConfig? get container => _container?.copy();

  /// 无 container 时的外层 padding；有 container 时由 container.padding 控制
  final EdgeInsetsGeometry? padding;

  final WTextConfig? _textStyle;

  /// 文本样式快照；每次读取返回副本
  WTextConfig? get textStyle => _textStyle?.copy();

  /// 键盘焦点 overlay
  final Color? focusColor;

  /// hover overlay
  final Color? hoverColor;

  /// focus/hover overlay 裁剪圆角
  final BorderRadiusGeometry? overlayBorderRadius;

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
    BorderRadiusGeometry? borderRadius,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    WTextConfig? textStyle,
    WButtonMotion motion = const WButtonMotion(),
    WButtonSemantics semantics = const WButtonSemantics(),
  }) {
    final container = WContainerConfig()
      ..color = backgroundColor
      ..padding = padding
      ..borderRadius = borderRadius ?? BorderRadius.circular(8);
    if (borderColor != null) container.border = Border.all(color: borderColor);
    final text = textStyle?.copy() ?? WTextConfig();
    if (foregroundColor != null) text.color = foregroundColor;
    return WButtonStyle(
      container: container,
      textStyle: text,
      motion: motion,
      semantics: semantics,
      overlayBorderRadius: borderRadius ?? BorderRadius.circular(8),
    );
  }

  /// 描边按钮的常用构造。
  factory WButtonStyle.outlined({
    Color? foregroundColor,
    Color? borderColor,
    BorderRadiusGeometry? borderRadius,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    WTextConfig? textStyle,
    WButtonMotion motion = const WButtonMotion(),
    WButtonSemantics semantics = const WButtonSemantics(),
  }) {
    final color = borderColor ?? foregroundColor;
    final container = WContainerConfig()
      ..color = Colors.transparent
      ..padding = padding
      ..borderRadius = borderRadius ?? BorderRadius.circular(8);
    if (color != null) container.border = Border.all(color: color);
    final text = textStyle?.copy() ?? WTextConfig();
    if (foregroundColor != null) text.color = foregroundColor;
    return WButtonStyle(
      container: container,
      textStyle: text,
      motion: motion,
      semantics: semantics,
      overlayBorderRadius: borderRadius ?? BorderRadius.circular(8),
    );
  }

  /// 文字按钮的常用构造。
  factory WButtonStyle.text({
    Color? foregroundColor,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    WTextConfig? textStyle,
    WButtonMotion motion = const WButtonMotion(),
    WButtonSemantics semantics = const WButtonSemantics(),
  }) {
    final container = WContainerConfig()
      ..color = Colors.transparent
      ..padding = padding;
    final text = textStyle?.copy() ?? WTextConfig();
    if (foregroundColor != null) text.color = foregroundColor;
    return WButtonStyle(
      container: container,
      textStyle: text,
      motion: motion,
      semantics: semantics,
      overlayBorderRadius: BorderRadius.circular(8),
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
    WContainerConfig? container,
    EdgeInsetsGeometry? padding,
    WTextConfig? textStyle,
    Color? focusColor,
    Color? hoverColor,
    BorderRadiusGeometry? overlayBorderRadius,
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
      container: container ?? this.container,
      padding: padding ?? this.padding,
      textStyle: textStyle ?? this.textStyle,
      focusColor: focusColor ?? this.focusColor,
      hoverColor: hoverColor ?? this.hoverColor,
      overlayBorderRadius: overlayBorderRadius ?? this.overlayBorderRadius,
      disabledOpacity: disabledOpacity ?? this.disabledOpacity,
      minWidth: minWidth ?? this.minWidth,
      minHeight: minHeight ?? this.minHeight,
      tapTargetSize: tapTargetSize ?? this.tapTargetSize,
      iconSize: iconSize ?? this.iconSize,
      gap: gap ?? this.gap,
    );
  }

  /// 清空 container（用于从有背景切换到纯文本）。
  WButtonStyle withoutContainer() {
    return WButtonStyle(
      motion: motion,
      semantics: semantics,
      padding: padding,
      textStyle: textStyle,
      focusColor: focusColor,
      hoverColor: hoverColor,
      overlayBorderRadius: overlayBorderRadius,
      disabledOpacity: disabledOpacity,
      minWidth: minWidth,
      minHeight: minHeight,
      tapTargetSize: tapTargetSize,
      iconSize: iconSize,
      gap: gap,
    );
  }

  /// 清空 textStyle。
  WButtonStyle withoutTextStyle() {
    return WButtonStyle(
      motion: motion,
      semantics: semantics,
      container: container,
      padding: padding,
      focusColor: focusColor,
      hoverColor: hoverColor,
      overlayBorderRadius: overlayBorderRadius,
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
    final nextContainer = container?.copy();
    if (size.padding != null && nextContainer != null) {
      nextContainer.padding = size.padding;
    }
    final nextTextStyle = textStyle?.copyWith(
      fontSize: size.fontSize,
      fontWeight: size.fontWeight,
      height: size.lineHeight,
      letterSpacing: size.letterSpacing,
    );
    return copyWith(
      container: nextContainer,
      padding: nextContainer == null ? (size.padding ?? padding) : null,
      minWidth: size.minWidth ?? minWidth,
      minHeight: size.minHeight ?? minHeight,
      tapTargetSize: size.tapTargetSize,
      textStyle: nextTextStyle,
      iconSize: size.iconSize ?? iconSize,
      gap: size.gap ?? gap,
    );
  }

  /// 深拷贝，避免共享可变的 container / textStyle。
  WButtonStyle copy() {
    return copyWith(
      container: container?.copy(),
      textStyle: textStyle?.copy(),
    );
  }
}
