import 'package:flutter/material.dart';

/// 页面保持组件，用于保持子组件的状态
class WKeepAliveWrapper extends StatefulWidget {
  /// 子组件
  final Widget child;

  /// 是否保持组件状态，默认值为 true
  final bool keepAlive;

  /// 当组件被保持时触发的回调
  final VoidCallback? onKeepAlive;

  /// 当组件从保持状态恢复时触发的回调
  final VoidCallback? onRevive;

  /// 构造函数
  ///
  /// @param key 组件键
  /// @param child 子组件
  /// @param keepAlive 是否保持组件状态
  /// @param onKeepAlive 当组件被保持时触发的回调
  /// @param onRevive 当组件从保持状态恢复时触发的回调
  const WKeepAliveWrapper({
    super.key,
    required this.child,
    this.keepAlive = true,
    this.onKeepAlive,
    this.onRevive,
  });

  @override
  State<WKeepAliveWrapper> createState() => _WKeepAliveWrapperState();
}

/// WKeepAliveWrapper 的状态类
class _WKeepAliveWrapperState extends State<WKeepAliveWrapper> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  /// 是否保持组件状态
  ///
  /// @return 返回 widget.keepAlive 的值
  @override
  bool get wantKeepAlive => widget.keepAlive;

  @override
  void didUpdateWidget(WKeepAliveWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当 keepAlive 状态变化时，可以在这里进行处理
  }

  @override
  void activate() {
    super.activate();
    // 当组件从保持状态恢复时触发
    widget.onRevive?.call();
  }

  @override
  void deactivate() {
    // 当组件被保持时触发
    if (wantKeepAlive) {
      widget.onKeepAlive?.call();
    }
    super.deactivate();
  }
}
