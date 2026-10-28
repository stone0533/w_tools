import 'package:flutter/material.dart';

import 'button_style.dart';

/// 按钮主题。
///
/// 通过 `ThemeData.extensions` 注册；不再提供额外的 InheritedWidget 入口。
@immutable
class WButtonThemeData extends ThemeExtension<WButtonThemeData> {
  WButtonThemeData({
    this.primary,
    this.secondary,
    this.text,
    this.danger,
    Map<String, WButtonStyle> variants = const <String, WButtonStyle>{},
  }) : variants = Map.unmodifiable(variants);

  final WButtonStyle? primary;
  final WButtonStyle? secondary;
  final WButtonStyle? text;
  final WButtonStyle? danger;

  /// 项目自定义变体，例如 brand / warning / success
  final Map<String, WButtonStyle> variants;

  WButtonStyle? resolveStyle(String? variant) {
    if (variant == null) return primary;
    final semantic = switch (variant) {
      'primary' => primary,
      'secondary' => secondary,
      'text' => text,
      'danger' => danger,
      _ => null,
    };
    return variants[variant] ?? semantic;
  }

  @override
  WButtonThemeData copyWith({
    WButtonStyle? primary,
    WButtonStyle? secondary,
    WButtonStyle? text,
    WButtonStyle? danger,
    Map<String, WButtonStyle>? variants,
  }) {
    return WButtonThemeData(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      text: text ?? this.text,
      danger: danger ?? this.danger,
      variants: variants ?? this.variants,
    );
  }

  @override
  WButtonThemeData lerp(covariant WButtonThemeData? other, double t) {
    if (other == null) return this;
    return t < 0.5 ? this : other;
  }
}
