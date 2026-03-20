import 'package:flutter/cupertino.dart';

/// 圆角裁剪组件，用于为子组件添加圆角
class WClipRRect extends StatelessWidget {
  /// 裁剪配置
  final WClipRRectConfig config;

  /// 子组件
  final Widget child;

  /// 构造函数
  ///
  /// @param key 组件键
  /// @param config 裁剪配置
  /// @param child 子组件
  const WClipRRect({super.key, required this.config, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(borderRadius: config._borderRadius, child: child);
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
  /// @param radius 圆角半径
  /// @return WClipRRectConfig 实例，用于链式调用
  WClipRRectConfig borderRadiusAll(double radius) {
    _borderRadius = BorderRadius.all(Radius.circular(radius));
    return this;
  }
}
