import 'package:flutter/cupertino.dart';

/// 圆角裁剪组件，用于为子组件添加圆角
class WClipRRect extends StatelessWidget {
  /// 裁剪配置
  final WClipRRectConfig? config;

  /// 子组件
  final Widget child;

  /// 裁剪行为，默认 antiAlias
  final Clip clipBehavior;

  /// 构造函数
  ///
  /// - [key]：组件键
  /// - [config]：裁剪配置
  /// - [child]：子组件
  /// - [clipBehavior]：裁剪行为
  const WClipRRect({
    super.key,
    this.config,
    required this.child,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final config = this.config ?? WClipRRectConfig();
    return ClipRRect(
      borderRadius: config._borderRadius,
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}

/// 圆角裁剪配置类，用于配置裁剪的圆角
class WClipRRectConfig {
  /// 圆角半径
  BorderRadiusGeometry _borderRadius = BorderRadius.zero;

  /// 设置圆角半径
  set borderRadius(BorderRadiusGeometry value) {
    _borderRadius = value;
  }

  /// 设置所有角的圆角半径
  ///
  /// - [radius]：圆角半径
  /// 返回：WClipRRectConfig 实例，用于链式调用
  WClipRRectConfig borderRadiusAll(double radius) {
    _borderRadius = BorderRadius.all(Radius.circular(radius));
    return this;
  }
}
