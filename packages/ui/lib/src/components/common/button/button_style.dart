import 'package:flutter/material.dart';

import 'button_motion.dart';
import 'button_resolved_style.dart';
import 'button_semantics.dart';
import 'button_size.dart';

/// 不可变的按钮视觉样式。
///
/// 颜色/边框/阴影/文字使用 [WidgetStateProperty]，由 WButton 按当前
/// `WidgetState` 解析成 [WButtonResolvedStyle]。
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

  final WidgetStateProperty<Color?>? backgroundColor;
  final WidgetStateProperty<Gradient?>? gradient;
  final WidgetStateProperty<BoxBorder?>? border;
  final BorderRadius? borderRadius;
  final WidgetStateProperty<List<BoxShadow>?>? boxShadow;
  final EdgeInsetsGeometry? padding;
  final Clip clipBehavior;
  final WidgetStateProperty<Color?>? foregroundColor;
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// hover/focus overlay 颜色（非状态属性，overlay 只在这些状态出现）
  final Color? focusColor;
  final Color? hoverColor;

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
      backgroundColor: WidgetStatePropertyAll(backgroundColor),
      foregroundColor: foregroundColor == null ? null : WidgetStatePropertyAll(foregroundColor),
      border: borderColor == null ? null : WidgetStatePropertyAll(Border.all(color: borderColor)),
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      padding: padding,
      textStyle: textStyle == null ? null : WidgetStatePropertyAll(textStyle),
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
      backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
      foregroundColor: foregroundColor == null ? null : WidgetStatePropertyAll(foregroundColor),
      border: color == null ? null : WidgetStatePropertyAll(Border.all(color: color)),
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      padding: padding,
      textStyle: textStyle == null ? null : WidgetStatePropertyAll(textStyle),
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
      foregroundColor: foregroundColor == null ? null : WidgetStatePropertyAll(foregroundColor),
      borderRadius: BorderRadius.circular(8),
      padding: padding,
      textStyle: textStyle == null ? null : WidgetStatePropertyAll(textStyle),
      motion: motion,
      semantics: semantics,
    );
  }

  /// 根据当前 WidgetState 解析出可直接渲染的视觉值。
  WButtonResolvedStyle resolve(Set<WidgetState> states) {
    final shadows = boxShadow?.resolve(states);
    final foreground = foregroundColor?.resolve(states);
    final resolvedTextStyle = textStyle?.resolve(states);
    final effectiveTextStyle = foreground == null
        ? resolvedTextStyle
        : (resolvedTextStyle ?? const TextStyle()).copyWith(color: foreground);
    return WButtonResolvedStyle(
      states: Set<WidgetState>.unmodifiable(states),
      backgroundColor: backgroundColor?.resolve(states),
      gradient: gradient?.resolve(states),
      border: border?.resolve(states),
      boxShadow: shadows == null ? null : List<BoxShadow>.unmodifiable(shadows),
      textStyle: effectiveTextStyle,
      foregroundColor: foreground,
      iconSize: iconSize,
      gap: gap,
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
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Gradient?>? gradient,
    WidgetStateProperty<BoxBorder?>? border,
    BorderRadius? borderRadius,
    WidgetStateProperty<List<BoxShadow>?>? boxShadow,
    EdgeInsetsGeometry? padding,
    Clip? clipBehavior,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<TextStyle?>? textStyle,
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

  /// 静态改背景色，内部包装为 WidgetStatePropertyAll。
  WButtonStyle withBackgroundColor(Color color) =>
      copyWith(backgroundColor: WidgetStatePropertyAll(color));

  /// 静态改前景色，内部包装为 WidgetStatePropertyAll。
  WButtonStyle withForegroundColor(Color color) =>
      copyWith(foregroundColor: WidgetStatePropertyAll(color));

  static const Object _unset = Object();

  WButtonStyle _copyNullable({
    Object? backgroundColor = _unset,
    Object? gradient = _unset,
    Object? border = _unset,
    Object? boxShadow = _unset,
    Object? borderRadius = _unset,
    Object? textStyle = _unset,
    Object? foregroundColor = _unset,
    Object? focusColor = _unset,
    Object? hoverColor = _unset,
  }) {
    return WButtonStyle(
      motion: motion,
      semantics: semantics,
      backgroundColor: identical(backgroundColor, _unset)
          ? this.backgroundColor
          : backgroundColor as WidgetStateProperty<Color?>?,
      gradient:
          identical(gradient, _unset) ? this.gradient : gradient as WidgetStateProperty<Gradient?>?,
      border: identical(border, _unset) ? this.border : border as WidgetStateProperty<BoxBorder?>?,
      borderRadius:
          identical(borderRadius, _unset) ? this.borderRadius : borderRadius as BorderRadius?,
      boxShadow: identical(boxShadow, _unset)
          ? this.boxShadow
          : boxShadow as WidgetStateProperty<List<BoxShadow>?>?,
      padding: padding,
      clipBehavior: clipBehavior,
      foregroundColor: identical(foregroundColor, _unset)
          ? this.foregroundColor
          : foregroundColor as WidgetStateProperty<Color?>?,
      textStyle: identical(textStyle, _unset)
          ? this.textStyle
          : textStyle as WidgetStateProperty<TextStyle?>?,
      focusColor: identical(focusColor, _unset) ? this.focusColor : focusColor as Color?,
      hoverColor: identical(hoverColor, _unset) ? this.hoverColor : hoverColor as Color?,
      disabledOpacity: disabledOpacity,
      minWidth: minWidth,
      minHeight: minHeight,
      tapTargetSize: tapTargetSize,
      iconSize: iconSize,
      gap: gap,
    );
  }

  WButtonStyle withoutBackground() => _copyNullable(
        backgroundColor: null,
        gradient: null,
      );

  WButtonStyle withoutDecoration() => _copyNullable(
        backgroundColor: null,
        gradient: null,
        border: null,
        borderRadius: null,
        boxShadow: null,
      );

  WButtonStyle withoutBorder() => _copyNullable(border: null);

  WButtonStyle withoutBoxShadow() => _copyNullable(boxShadow: null);

  WButtonStyle withoutTextStyle() => _copyNullable(
        textStyle: null,
        foregroundColor: null,
      );

  WButtonStyle withoutForegroundColor() => _copyNullable(foregroundColor: null);

  WButtonStyle withoutFocusColor() => _copyNullable(focusColor: null);

  WButtonStyle withoutHoverColor() => _copyNullable(hoverColor: null);

  /// 把尺寸令牌叠加到当前样式；只覆盖布局/文字/图标字段。
  WButtonStyle applySize(WButtonSize? size) {
    if (size == null) return this;
    size.validate();
    WidgetStateProperty<TextStyle?>? nextTextStyle = textStyle;
    if (size.fontSize != null ||
        size.fontWeight != null ||
        size.lineHeight != null ||
        size.letterSpacing != null) {
      final base = textStyle;
      nextTextStyle = WidgetStateProperty.resolveWith((states) {
        final text = base?.resolve(states);
        return (text ?? const TextStyle()).copyWith(
          fontSize: size.fontSize,
          fontWeight: size.fontWeight,
          height: size.lineHeight,
          letterSpacing: size.letterSpacing,
        );
      });
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
