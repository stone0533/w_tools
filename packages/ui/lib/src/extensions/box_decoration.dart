import 'package:flutter/material.dart';

const Object _unset = Object();

/// 让 [BoxDecoration] 可组合，避免重复写完整构造。
///
/// `withGradient` / `withColor` 只设置对应字段，不会自动清空另一个；
/// 需要唯一背景时显式调用 `withoutColor()` / `withoutGradient()`。
extension WBoxDecorationExtension on BoxDecoration {
  BoxDecoration _copy({
    Object? color = _unset,
    Object? image = _unset,
    Object? border = _unset,
    Object? borderRadius = _unset,
    Object? boxShadow = _unset,
    Object? gradient = _unset,
    Object? backgroundBlendMode = _unset,
    BoxShape? shape,
  }) {
    return BoxDecoration(
      color: identical(color, _unset) ? this.color : color as Color?,
      image: identical(image, _unset) ? this.image : image as DecorationImage?,
      border: identical(border, _unset) ? this.border : border as BoxBorder?,
      borderRadius: identical(borderRadius, _unset)
          ? this.borderRadius
          : borderRadius as BorderRadiusGeometry?,
      boxShadow: identical(boxShadow, _unset) ? this.boxShadow : boxShadow as List<BoxShadow>?,
      gradient: identical(gradient, _unset) ? this.gradient : gradient as Gradient?,
      backgroundBlendMode: identical(backgroundBlendMode, _unset)
          ? this.backgroundBlendMode
          : backgroundBlendMode as BlendMode?,
      shape: shape ?? this.shape,
    );
  }

  /// 只设置 color，不会清空 gradient。
  ///
  /// 需要唯一背景时先调用 [withoutGradient]。
  BoxDecoration withColor(Color color) => _copy(color: color);

  BoxDecoration withoutColor() => _copy(color: null);

  /// 只设置 gradient，不会清空 color。
  ///
  /// 需要唯一背景时先调用 [withoutColor]。
  BoxDecoration withGradient(Gradient gradient) => _copy(gradient: gradient);

  BoxDecoration withoutGradient() => _copy(gradient: null);

  BoxDecoration withBorder(BoxBorder border) => _copy(border: border);

  BoxDecoration withoutBorder() => _copy(border: null);

  BoxDecoration withBorderRadius(BorderRadiusGeometry radius) {
    assert(shape != BoxShape.circle, 'circle 不能设置 borderRadius');
    return _copy(borderRadius: radius);
  }

  BoxDecoration withoutBorderRadius() => _copy(borderRadius: null);

  /// 设置阴影；列表会复制为不可变，避免调用方后续修改影响装饰。
  BoxDecoration withShadow(List<BoxShadow> shadow) =>
      _copy(boxShadow: List<BoxShadow>.unmodifiable(shadow));

  BoxDecoration withoutShadow() => _copy(boxShadow: null);

  BoxDecoration withShape(BoxShape shape) {
    assert(
      shape != BoxShape.circle || borderRadius == null,
      'circle 不能同时保留 borderRadius，请用 circle()',
    );
    return _copy(shape: shape);
  }

  /// 转为圆形，并清空 borderRadius。
  BoxDecoration circle() => _copy(
        shape: BoxShape.circle,
        borderRadius: null,
      );
}
