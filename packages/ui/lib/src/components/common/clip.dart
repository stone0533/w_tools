import 'package:flutter/cupertino.dart';

/// 圆角裁剪组件，用于为子组件添加圆角
class WClipRRect extends StatelessWidget {
  /// 裁剪配置（8.0 移除；新代码直接传 [borderRadius]）
  /// remove-in: 8.0.0
  @Deprecated('Use borderRadius instead; config 将在 8.0 移除')
  final WClipRRectConfig? config;

  /// 圆角；与 [config] 二选一，优先使用本参数
  final BorderRadiusGeometry? borderRadius;

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
    this.borderRadius,
    required this.child,
    this.clipBehavior = Clip.antiAlias,
  }) : assert(
         config == null || borderRadius == null,
         'WClipRRect: config 与 borderRadius 只能传一个',
       );

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? config?.borderRadius ?? BorderRadius.zero;
    return ClipRRect(
      borderRadius: radius,
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

  @override
  bool operator ==(Object other) => other is WClipRRectConfig && other.borderRadius == borderRadius;

  @override
  int get hashCode => borderRadius.hashCode;
}
