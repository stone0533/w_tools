import 'package:flutter/material.dart';

import 'button_resolved_style.dart';
import 'button_size.dart';

/// 不可变的按钮视觉样式。
///
/// 颜色/边框/阴影/文字使用 [WidgetStateProperty]，由 WButton 按当前
/// `WidgetState` 解析成 [WButtonResolvedStyle]。
@immutable
class WButtonStyle {
  const WButtonStyle({
    this.backgroundColor,
    this.gradient,
    this.border,
    this.borderRadius,
    this.boxShadow,
    this.padding,
    this.alignment = Alignment.center,
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

  final WidgetStateProperty<Color?>? backgroundColor;
  final WidgetStateProperty<Gradient?>? gradient;
  final WidgetStateProperty<BoxBorder?>? border;
  final BorderRadius? borderRadius;
  final WidgetStateProperty<List<BoxShadow>?>? boxShadow;
  final EdgeInsetsGeometry? padding;

  /// 内容在按钮内的对齐方式；全宽按钮默认居中。
  final AlignmentGeometry alignment;

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
  ///
  /// 未传 [foregroundColor] 时按背景亮度自动选黑 / 白，避免深色背景上
  /// 文字沿用环境默认色而不可读；要固定品牌前景色时显式传。
  factory WButtonStyle.filled({
    required Color backgroundColor,
    Color? foregroundColor,
    Color? borderColor,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    TextStyle? textStyle,
  }) {
    final onColor =
        foregroundColor ??
        (ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.dark
            ? Colors.white
            : Colors.black);
    return WButtonStyle(
      backgroundColor: WidgetStatePropertyAll(backgroundColor),
      foregroundColor: WidgetStatePropertyAll(onColor),
      border: borderColor == null ? null : WidgetStatePropertyAll(Border.all(color: borderColor)),
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      padding: padding,
      textStyle: textStyle == null ? null : WidgetStatePropertyAll(textStyle),
    );
  }

  /// 描边按钮的常用构造。
  factory WButtonStyle.outlined({
    Color? foregroundColor,
    Color? borderColor,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    TextStyle? textStyle,
  }) {
    final color = borderColor ?? foregroundColor;
    return WButtonStyle(
      backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
      foregroundColor: foregroundColor == null ? null : WidgetStatePropertyAll(foregroundColor),
      border: color == null ? null : WidgetStatePropertyAll(Border.all(color: color)),
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      padding: padding,
      textStyle: textStyle == null ? null : WidgetStatePropertyAll(textStyle),
    );
  }

  /// 文字按钮的常用构造。
  factory WButtonStyle.text({
    Color? foregroundColor,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    TextStyle? textStyle,
  }) {
    return WButtonStyle(
      foregroundColor: foregroundColor == null ? null : WidgetStatePropertyAll(foregroundColor),
      borderRadius: BorderRadius.circular(8),
      padding: padding,
      textStyle: textStyle == null ? null : WidgetStatePropertyAll(textStyle),
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WButtonStyle &&
          other.backgroundColor == backgroundColor &&
          other.gradient == gradient &&
          other.border == border &&
          other.borderRadius == borderRadius &&
          other.boxShadow == boxShadow &&
          other.padding == padding &&
          other.alignment == alignment &&
          other.clipBehavior == clipBehavior &&
          other.foregroundColor == foregroundColor &&
          other.textStyle == textStyle &&
          other.focusColor == focusColor &&
          other.hoverColor == hoverColor &&
          other.disabledOpacity == disabledOpacity &&
          other.minWidth == minWidth &&
          other.minHeight == minHeight &&
          other.tapTargetSize == tapTargetSize &&
          other.iconSize == iconSize &&
          other.gap == gap;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    gradient,
    border,
    borderRadius,
    boxShadow,
    padding,
    alignment,
    clipBehavior,
    foregroundColor,
    textStyle,
    focusColor,
    hoverColor,
    disabledOpacity,
    minWidth,
    minHeight,
    tapTargetSize,
    iconSize,
    gap,
  );

  void validate() {
    assert(
      backgroundColor == null || gradient == null,
      'WButtonStyle.backgroundColor 与 gradient 只能选一个',
    );
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
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Gradient?>? gradient,
    WidgetStateProperty<BoxBorder?>? border,
    BorderRadius? borderRadius,
    WidgetStateProperty<List<BoxShadow>?>? boxShadow,
    EdgeInsetsGeometry? padding,
    AlignmentGeometry? alignment,
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
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gradient: gradient ?? this.gradient,
      border: border ?? this.border,
      borderRadius: borderRadius ?? this.borderRadius,
      boxShadow: boxShadow ?? this.boxShadow,
      padding: padding ?? this.padding,
      alignment: alignment ?? this.alignment,
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

  /// 静态改背景色，内部包装为 WidgetStatePropertyAll，并清空 gradient。
  WButtonStyle withBackgroundColor(Color color) => _copyNullable(
    backgroundColor: WidgetStatePropertyAll(color),
    gradient: null,
  );

  /// 静态改前景色，内部包装为 WidgetStatePropertyAll。
  WButtonStyle withForegroundColor(Color color) =>
      copyWith(foregroundColor: WidgetStatePropertyAll(color));

  /// 静态改边框，内部包装为 WidgetStatePropertyAll。
  WButtonStyle withBorder(BoxBorder border) =>
      _copyNullable(border: WidgetStatePropertyAll(border));

  /// 静态改阴影，内部包装为 WidgetStatePropertyAll。
  WButtonStyle withBoxShadow(List<BoxShadow> shadows) => _copyNullable(
    boxShadow: WidgetStatePropertyAll(List<BoxShadow>.unmodifiable(shadows)),
  );

  /// 静态改文字样式，内部包装为 WidgetStatePropertyAll。
  WButtonStyle withTextStyle(TextStyle textStyle) => copyWith(
    textStyle: WidgetStatePropertyAll(textStyle),
  );

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
      backgroundColor: identical(backgroundColor, _unset)
          ? this.backgroundColor
          : backgroundColor as WidgetStateProperty<Color?>?,
      gradient: identical(gradient, _unset)
          ? this.gradient
          : gradient as WidgetStateProperty<Gradient?>?,
      border: identical(border, _unset) ? this.border : border as WidgetStateProperty<BoxBorder?>?,
      borderRadius: identical(borderRadius, _unset)
          ? this.borderRadius
          : borderRadius as BorderRadius?,
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

  /// 只清空 textStyle，保留 foregroundColor。
  WButtonStyle withoutTextStyle() => _copyNullable(textStyle: null);

  /// 清空 textStyle 和 foregroundColor。
  WButtonStyle withoutText() => _copyNullable(
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
