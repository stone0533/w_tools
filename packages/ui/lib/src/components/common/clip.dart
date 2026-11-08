import 'package:flutter/widgets.dart';

/// 圆角裁剪组件，用于为子组件添加圆角。
class WClipRRect extends StatelessWidget {
  /// 圆角
  final BorderRadiusGeometry? borderRadius;

  /// 子组件
  final Widget child;

  /// 裁剪行为，默认 antiAlias
  final Clip clipBehavior;

  /// 构造函数
  ///
  /// - [key]：组件键
  /// - [borderRadius]：圆角
  /// - [child]：子组件
  /// - [clipBehavior]：裁剪行为
  const WClipRRect({
    super.key,
    this.borderRadius,
    required this.child,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.zero;
    return ClipRRect(
      borderRadius: radius,
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}
