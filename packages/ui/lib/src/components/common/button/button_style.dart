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
  const WButtonStyle({
    this.effect = WButtonEffectType.opacity,
    this.pressedOpacity = 0.7,
    this.pressedScale = 0.95,
    this.animationDuration = const Duration(milliseconds: 100),
    this.curve = Curves.easeInOut,
    this.container,
    this.textStyle,
    this.semanticLabel,
    this.semanticHint,
    this.focusColor,
    this.hoverColor,
    this.disabledOpacity = 0.5,
    this.minWidth = 48,
    this.minHeight = 48,
    this.loadingLabel = '加载中',
    this.iconSize = 18,
    this.gap = 8,
  });

  final WButtonEffectType effect;
  final double pressedOpacity;
  final double pressedScale;
  final Duration animationDuration;
  final Curve curve;

  /// 容器样式模板（按只读使用；需要变化时请 copy）
  final WContainerConfig? container;

  /// 文本样式模板（按只读使用；需要变化时请 copy）
  final WTextConfig? textStyle;

  /// 无障碍标签（纯图标按钮建议必填）
  final String? semanticLabel;

  /// 无障碍提示
  final String? semanticHint;

  /// 键盘焦点 overlay（null 时使用 Theme.focusColor）
  final Color? focusColor;

  /// hover overlay（null 时使用 Theme.hoverColor）
  final Color? hoverColor;

  /// 禁用时内容透明度（0..1）
  final double disabledOpacity;

  /// 最小点击宽度（移动端建议 >= 48）
  final double minWidth;

  /// 最小点击高度
  final double minHeight;

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
    Object? textStyle = _unset,
    Object? semanticLabel = _unset,
    Object? semanticHint = _unset,
    Object? focusColor = _unset,
    Object? hoverColor = _unset,
    Object? disabledOpacity = _unset,
    Object? minWidth = _unset,
    Object? minHeight = _unset,
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
      textStyle: identical(textStyle, _unset) ? this.textStyle : textStyle as WTextConfig?,
      semanticLabel:
          identical(semanticLabel, _unset) ? this.semanticLabel : semanticLabel as String?,
      semanticHint: identical(semanticHint, _unset) ? this.semanticHint : semanticHint as String?,
      focusColor: identical(focusColor, _unset) ? this.focusColor : focusColor as Color?,
      hoverColor: identical(hoverColor, _unset) ? this.hoverColor : hoverColor as Color?,
      disabledOpacity: identical(disabledOpacity, _unset)
          ? this.disabledOpacity
          : (disabledOpacity as num).toDouble(),
      minWidth: identical(minWidth, _unset) ? this.minWidth : (minWidth as num).toDouble(),
      minHeight: identical(minHeight, _unset) ? this.minHeight : (minHeight as num).toDouble(),
      loadingLabel: identical(loadingLabel, _unset) ? this.loadingLabel : loadingLabel as String,
      iconSize: identical(iconSize, _unset) ? this.iconSize : (iconSize as num).toDouble(),
      gap: identical(gap, _unset) ? this.gap : (gap as num).toDouble(),
    );
  }

  /// 把尺寸令牌叠加到当前样式；只覆盖布局/文字/图标字段。
  WButtonStyle applySize(WButtonSize? size) {
    if (size == null) return this;
    final nextContainer = container?.copy();
    if (size.padding != null && nextContainer != null) {
      nextContainer.padding = size.padding;
    }
    final nextTextStyle = textStyle?.copyWith(
          fontSize: size.fontSize,
          fontWeight: size.fontWeight,
        ) ??
        size.textStyle;
    return copyWith(
      container: nextContainer,
      minWidth: size.minWidth ?? minWidth,
      minHeight: size.minHeight ?? minHeight,
      textStyle: nextTextStyle,
      iconSize: size.iconSize ?? iconSize,
      gap: size.gap ?? gap,
    );
  }
}
