import 'package:flutter/material.dart';

/// 导航栏的外层装饰 / padding。
///
/// 选中态、切换动画与点击拦截由 `WNavController` / `WNavBar` 负责，不要放进这里。
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
