import 'package:flutter/material.dart';

import '../press_effect.dart';

/// 按钮动效配置。
@immutable
class WButtonMotion {
  const WButtonMotion({
    this.effect = WPressEffect.opacity,
    this.pressedOpacity = 0.7,
    this.pressedScale = 0.95,
    this.duration = const Duration(milliseconds: 100),
    this.curve = Curves.easeInOut,
  });

  final WPressEffect effect;
  final double pressedOpacity;
  final double pressedScale;
  final Duration duration;
  final Curve curve;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WButtonMotion &&
          other.effect == effect &&
          other.pressedOpacity == pressedOpacity &&
          other.pressedScale == pressedScale &&
          other.duration == duration &&
          other.curve == curve;

  @override
  int get hashCode => Object.hash(effect, pressedOpacity, pressedScale, duration, curve);

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
    WPressEffect? effect,
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
