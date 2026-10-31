import 'package:flutter/material.dart';

/// 页面保持组件，用于保持子组件的状态
class WKeepAliveWrapper extends StatefulWidget {
  /// 子组件
  final Widget child;

  /// 是否保持组件状态，默认值为 true
  final bool keepAlive;

  /// 构造函数
  ///
  /// - [key]：组件键
  /// - [child]：子组件
  /// - [keepAlive]：是否保持组件状态
  const WKeepAliveWrapper({
    super.key,
    required this.child,
    this.keepAlive = true,
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
}
