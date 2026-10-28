import 'package:flutter/material.dart';

import '../layout/container.dart';
import 'text.dart';

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
    );
  }
}
