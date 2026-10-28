import 'package:flutter/material.dart';

/// 按钮按压效果。
enum WButtonEffectType {
  /// 无效果
  none,

  /// 按下时透明度降低
  opacity,

  /// 按下时轻微缩小
  scale,
}

/// 按钮动效配置。
@immutable
class WButtonMotion {
  const WButtonMotion({
    this.effect = WButtonEffectType.opacity,
    this.pressedOpacity = 0.7,
    this.pressedScale = 0.95,
    this.duration = const Duration(milliseconds: 100),
    this.curve = Curves.easeInOut,
  });

  final WButtonEffectType effect;
  final double pressedOpacity;
  final double pressedScale;
  final Duration duration;
  final Curve curve;

  void validate() {
    assert(
      pressedOpacity >= 0 && pressedOpacity <= 1,
      'pressedOpacity 必须在 0..1',
    );
    assert(
      pressedScale >= 0.1 && pressedScale <= 1,
      'pressedScale 必须在 0.1..1',
    );
    assert(!duration.isNegative, 'duration 不能为负');
  }

  WButtonMotion copyWith({
    WButtonEffectType? effect,
    double? pressedOpacity,
    double? pressedScale,
    Duration? duration,
    Curve? curve,
  }) {
    return WButtonMotion(
      effect: effect ?? this.effect,
      pressedOpacity: pressedOpacity ?? this.pressedOpacity,
      pressedScale: pressedScale ?? this.pressedScale,
      duration: duration ?? this.duration,
      curve: curve ?? this.curve,
    );
  }
}
