import 'package:flutter/material.dart';

/// 导航栏的视觉样式（外层装饰 / padding）；新代码优先用它替代 config。
@immutable
class WNavBarStyle {
  const WNavBarStyle({this.decoration, this.padding});

  final BoxDecoration? decoration;
  final EdgeInsetsGeometry? padding;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WNavBarStyle && other.decoration == decoration && other.padding == padding;

  @override
  int get hashCode => Object.hash(decoration, padding);
}
