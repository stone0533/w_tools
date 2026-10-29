import 'package:flutter/material.dart';

/// 常用渐变方向，不绑定品牌色。
abstract final class WGradients {
  static LinearGradient vertical(
    List<Color> colors, {
    List<double>? stops,
  }) {
    return LinearGradient(
      colors: colors,
      stops: stops,
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  static LinearGradient horizontal(
    List<Color> colors, {
    List<double>? stops,
  }) {
    return LinearGradient(
      colors: colors,
      stops: stops,
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
  }

  static LinearGradient diagonal(
    List<Color> colors, {
    List<double>? stops,
  }) {
    return LinearGradient(
      colors: colors,
      stops: stops,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static RadialGradient radial(
    List<Color> colors, {
    List<double>? stops,
    AlignmentGeometry center = Alignment.center,
    double radius = 0.5,
  }) {
    return RadialGradient(
      colors: colors,
      stops: stops,
      center: center,
      radius: radius,
    );
  }
}
