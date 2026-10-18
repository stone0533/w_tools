import 'package:flutter/material.dart';

/// 页面保持组件，用于保持子组件的状态
class WKeepAliveWrapper extends StatefulWidget {
  /// 子组件
  final Widget child;

  /// 是否保持组件状态，默认值为 true
  final bool keepAlive;

  /// 当组件因保活被移出 widget 树时触发的回调
  ///
  /// 仅在 [keepAlive] 为 true 时触发。
  final VoidCallback? onDeactivated;

  /// 当组件重新插入 widget 树时触发的回调
  final VoidCallback? onRevive;

  /// 构造函数
  ///
  /// - [key]：组件键
  /// - [child]：子组件
  /// - [keepAlive]：是否保持组件状态
  /// - [onDeactivated]：当组件被移出 widget 树时触发的回调
  /// - [onRevive]：当组件从保持状态恢复时触发的回调
  const WKeepAliveWrapper({
    super.key,
    required this.child,
    this.keepAlive = true,
    this.onDeactivated,
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
  /// 直接透传 [WKeepAliveWrapper.keepAlive]。
  @override
  bool get wantKeepAlive => widget.keepAlive;

  @override
  void didUpdateWidget(WKeepAliveWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    // keepAlive 变化时需通知 mixin 重新计算保活状态，否则运行期关闭保活不会生效
    if (oldWidget.keepAlive != widget.keepAlive) {
      updateKeepAlive();
    }
  }

  @override
  void activate() {
    super.activate();
    // 组件被重新插入 widget 树时触发
    widget.onRevive?.call();
  }

  @override
  void deactivate() {
    // 组件被移出 widget 树时触发
    if (wantKeepAlive) {
      widget.onDeactivated?.call();
    }
    super.deactivate();
  }
}
