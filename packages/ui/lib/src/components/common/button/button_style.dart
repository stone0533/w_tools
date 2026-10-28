import 'package:flutter/material.dart';

import '../../layout/container.dart';
import 'button_size.dart';
import '../text.dart';

/// 按钮点击效果
enum WButtonEffectType {
  /// 无效果
  none,

  /// 点击时透明度降低
  opacity,

  /// 点击时轻微缩小
  scale,

  /// 点击时震动
  shake,
}

/// 不可变的按钮样式。
///
/// 可跨页面复用；运行时状态（enabled / loading）不要放在这里。
@immutable
class WButtonStyle {
  /// 填充按钮的常用构造，避免手写 WContainerConfig / WTextConfig。
  factory WButtonStyle.filled({
    required Color backgroundColor,
    Color? foregroundColor,
    Color? borderColor,
    BorderRadiusGeometry? borderRadius,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    WTextConfig? textStyle,
    WButtonEffectType effect = WButtonEffectType.opacity,
    double pressedOpacity = 0.7,
  }) {
    final container = WContainerConfig()
      ..color = backgroundColor
      ..padding = padding
      ..borderRadius = borderRadius ?? BorderRadius.circular(8);
    if (borderColor != null) {
      container.border = Border.all(color: borderColor);
    }
    final text = textStyle?.copy() ?? WTextConfig();
    if (foregroundColor != null) text.color = foregroundColor;
    return WButtonStyle(
      container: container,
      textStyle: text,
      effect: effect,
      pressedOpacity: pressedOpacity,
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
    WButtonEffectType effect = WButtonEffectType.opacity,
    double pressedOpacity = 0.7,
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
      effect: effect,
      pressedOpacity: pressedOpacity,
      overlayBorderRadius: borderRadius ?? BorderRadius.circular(8),
    );
  }

  /// 文字按钮的常用构造。
  factory WButtonStyle.text({
    Color? foregroundColor,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    WTextConfig? textStyle,
    WButtonEffectType effect = WButtonEffectType.opacity,
    double pressedOpacity = 0.7,
  }) {
    final container = WContainerConfig()..color = Colors.transparent;
    final text = textStyle?.copy() ?? WTextConfig();
    if (foregroundColor != null) text.color = foregroundColor;
    return WButtonStyle(
      container: container,
      textStyle: text,
      effect: effect,
      pressedOpacity: pressedOpacity,
      overlayBorderRadius: BorderRadius.circular(8),
    );
  }

  WButtonStyle({
    this.effect = WButtonEffectType.opacity,
    this.pressedOpacity = 0.7,
    this.pressedScale = 0.95,
    this.animationDuration = const Duration(milliseconds: 100),
    this.curve = Curves.easeInOut,
    WContainerConfig? container,
    this.padding,
    WTextConfig? textStyle,
    this.semanticLabel,
    this.semanticHint,
    this.focusColor,
    this.hoverColor,
    this.overlayBorderRadius,
    this.disabledOpacity = 0.5,
    this.minWidth = 48,
    this.minHeight = 48,
    this.tapTargetSize = 48,
    this.loadingLabel = '加载中',
    this.iconSize = 18,
    this.gap = 8,
  })  : _container = container?.copy(),
        _textStyle = textStyle?.copy();

  final WButtonEffectType effect;
  final double pressedOpacity;
  final double pressedScale;
  final Duration animationDuration;
  final Curve curve;

  final WContainerConfig? _container;

  /// 容器样式快照；每次读取返回副本
  WContainerConfig? get container => _container?.copy();

  /// 无 container 时的外层 padding（有 container 时由 container.padding 控制）
  final EdgeInsetsGeometry? padding;

  final WTextConfig? _textStyle;

  /// 文本样式快照；每次读取返回副本
  WTextConfig? get textStyle => _textStyle?.copy();

  /// 无障碍标签（纯图标按钮建议必填）
  final String? semanticLabel;

  /// 无障碍提示
  final String? semanticHint;

  /// 键盘焦点 overlay（null 时使用 Theme.focusColor）
  final Color? focusColor;

  /// hover overlay（null 时使用 Theme.hoverColor）
  final Color? hoverColor;

  /// focus/hover overlay 的裁剪圆角；null 时不裁剪
  final BorderRadiusGeometry? overlayBorderRadius;

  /// 禁用时内容透明度（0..1）
  final double disabledOpacity;

  /// 最小点击宽度（移动端建议 >= 48）
  final double minWidth;

  /// 最小点击高度（视觉/布局）
  final double minHeight;

  /// 实际 hit area 下限；视觉尺寸可以更小
  final double tapTargetSize;

  /// loading 时的无障碍文案
  final String loadingLabel;

  /// 图标尺寸（WButton.icon / label + icon）
  final double iconSize;

  /// 图标与文字间距
  final double gap;

  /// 校验（debug assert）
  void validate() {
    assert(
      pressedOpacity >= 0 && pressedOpacity <= 1,
      'pressedOpacity 必须在 0..1',
    );
    assert(
      pressedScale >= 0.1 && pressedScale <= 1,
      'pressedScale 必须在 0.1..1',
    );
    assert(!animationDuration.isNegative, 'animationDuration 不能为负');
    assert(
      disabledOpacity >= 0 && disabledOpacity <= 1,
      'disabledOpacity 必须在 0..1',
    );
    assert(minWidth >= 0 && minHeight >= 0, 'minWidth/minHeight 不能为负');
    assert(minWidth.isFinite && minHeight.isFinite, 'minWidth/minHeight 必须有限');
    assert(tapTargetSize >= 0 && tapTargetSize.isFinite, 'tapTargetSize 非法');
    assert(iconSize >= 0 && gap >= 0, 'iconSize/gap 不能为负');
  }

  static const Object _unset = Object();

  WButtonStyle copyWith({
    Object? effect = _unset,
    Object? pressedOpacity = _unset,
    Object? pressedScale = _unset,
    Object? animationDuration = _unset,
    Object? curve = _unset,
    Object? container = _unset,
    Object? padding = _unset,
    Object? textStyle = _unset,
    Object? semanticLabel = _unset,
    Object? semanticHint = _unset,
    Object? focusColor = _unset,
    Object? hoverColor = _unset,
    Object? overlayBorderRadius = _unset,
    Object? disabledOpacity = _unset,
    Object? minWidth = _unset,
    Object? minHeight = _unset,
    Object? tapTargetSize = _unset,
    Object? loadingLabel = _unset,
    Object? iconSize = _unset,
    Object? gap = _unset,
  }) {
    return WButtonStyle(
      effect: identical(effect, _unset) ? this.effect : effect as WButtonEffectType,
      pressedOpacity: identical(pressedOpacity, _unset)
          ? this.pressedOpacity
          : (pressedOpacity as num).toDouble(),
      pressedScale:
          identical(pressedScale, _unset) ? this.pressedScale : (pressedScale as num).toDouble(),
      animationDuration: identical(animationDuration, _unset)
          ? this.animationDuration
          : animationDuration as Duration,
      curve: identical(curve, _unset) ? this.curve : curve as Curve,
      container: identical(container, _unset) ? this.container : container as WContainerConfig?,
      padding: identical(padding, _unset) ? this.padding : padding as EdgeInsetsGeometry?,
      textStyle: identical(textStyle, _unset) ? this.textStyle : textStyle as WTextConfig?,
      semanticLabel:
          identical(semanticLabel, _unset) ? this.semanticLabel : semanticLabel as String?,
      semanticHint: identical(semanticHint, _unset) ? this.semanticHint : semanticHint as String?,
      focusColor: identical(focusColor, _unset) ? this.focusColor : focusColor as Color?,
      hoverColor: identical(hoverColor, _unset) ? this.hoverColor : hoverColor as Color?,
      overlayBorderRadius: identical(overlayBorderRadius, _unset)
          ? this.overlayBorderRadius
          : overlayBorderRadius as BorderRadiusGeometry?,
      disabledOpacity: identical(disabledOpacity, _unset)
          ? this.disabledOpacity
          : (disabledOpacity as num).toDouble(),
      minWidth: identical(minWidth, _unset) ? this.minWidth : (minWidth as num).toDouble(),
      minHeight: identical(minHeight, _unset) ? this.minHeight : (minHeight as num).toDouble(),
      tapTargetSize:
          identical(tapTargetSize, _unset) ? this.tapTargetSize : (tapTargetSize as num).toDouble(),
      loadingLabel: identical(loadingLabel, _unset) ? this.loadingLabel : loadingLabel as String,
      iconSize: identical(iconSize, _unset) ? this.iconSize : (iconSize as num).toDouble(),
      gap: identical(gap, _unset) ? this.gap : (gap as num).toDouble(),
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
