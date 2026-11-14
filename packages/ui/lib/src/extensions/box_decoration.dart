import 'package:flutter/material.dart';

const Object _unset = Object();

/// [BoxDecoration] 的高频组合糖。
///
/// 只保留两处真正省事的写法：
/// - [withBackground]：color / gradient 二选一，自动清空另一个（避免非法装饰）；
/// - [circle]：圆形 + 清空 borderRadius。
///
/// 其余字段（border / borderRadius / boxShadow / image）直接传给 `BoxDecoration` 构造器，
/// 不再逐个提供 `with*` / `without*` 方法。
extension WBoxDecorationExtension on BoxDecoration {
  BoxDecoration _copy({
    Object? color = _unset,
    Object? borderRadius = _unset,
    Object? gradient = _unset,
    BoxShape? shape,
  }) {
    return BoxDecoration(
      color: identical(color, _unset) ? this.color : color as Color?,
      image: image,
      border: border,
      borderRadius: identical(borderRadius, _unset)
          ? this.borderRadius
          : borderRadius as BorderRadiusGeometry?,
      boxShadow: boxShadow,
      gradient: identical(gradient, _unset) ? this.gradient : gradient as Gradient?,
      backgroundBlendMode: backgroundBlendMode,
      shape: shape ?? this.shape,
    );
  }

  /// 设置唯一背景：color / gradient 二选一，并清空另一个。
  BoxDecoration withBackground({Color? color, Gradient? gradient}) {
    assert(
      (color == null) != (gradient == null),
      'withBackground: color 与 gradient 必须且只能传一个',
    );
    return _copy(color: color, gradient: gradient);
  }

  /// 转为圆形，并清空 borderRadius。
  BoxDecoration circle() => _copy(
    shape: BoxShape.circle,
    borderRadius: null,
  );
}
