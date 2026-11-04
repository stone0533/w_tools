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
    final config = this.config ?? const WClipRRectConfig();
    return ClipRRect(
      borderRadius: config.borderRadius,
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}

/// 圆角裁剪配置类（不可变；用构造 / [copyWith] 派生）
@immutable
class WClipRRectConfig {
  /// 创建配置
  const WClipRRectConfig({this.borderRadius = BorderRadius.zero});

  /// 所有角统一圆角
  WClipRRectConfig.all(double radius) : borderRadius = BorderRadius.all(Radius.circular(radius));

  /// 圆角半径
  final BorderRadiusGeometry borderRadius;

  /// 创建副本
  WClipRRectConfig copyWith({BorderRadiusGeometry? borderRadius}) {
    return WClipRRectConfig(borderRadius: borderRadius ?? this.borderRadius);
  }
}
