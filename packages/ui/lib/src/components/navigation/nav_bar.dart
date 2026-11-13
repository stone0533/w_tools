import 'dart:async';

import 'package:flutter/material.dart';
import '../common/pressable.dart';
import 'nav_controller.dart';
import 'nav_style.dart';

export 'nav_style.dart';

/// 底部导航栏组件
///
/// 由传入的 [controller]（`WNavController`）驱动选中态与切换动画，
/// 每个导航项交由 [itemBuilder] 渲染。
///
/// [controller] 由调用方持有并负责释放，本组件只负责添加 / 移除监听。
class WNavBar extends StatefulWidget {
  /// 标签栏样式
  final WNavBarStyle? style;

  /// 导航项构建器
  final Widget Function(BuildContext, int, bool) itemBuilder;

  /// 导航切换前回调；返回 `false` 阻止切换。
  ///
  /// `FutureOr<bool>` 同时接受同步 / 异步结果。
  final FutureOr<bool> Function(int)? onBeforeTap;

  /// 导航栏控制器
  final WNavController controller;

  /// 是否避开底部安全区（home indicator / 手势条）。
  ///
  /// 默认 true：`WNavBar` 通常放在 `WScaffold.bottomNavigationBar`，需要自己
  /// 处理底部 inset。放在页面 body 内或已由外层 `SafeArea` 包裹时传 false。
  final bool safeArea;

  const WNavBar({
    super.key,
    this.style,
    required this.itemBuilder,
    this.onBeforeTap,
    required this.controller,
    this.safeArea = true,
  });

  @override
  State<WNavBar> createState() => _WNavBarState();
}

class _WNavBarState extends State<WNavBar> {
  late WNavController _controller;
  late final VoidCallback _listener;
  int _tapToken = 0;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _listener = () {
      if (mounted) setState(() {});
    };
    _controller.addListener(_listener);
  }

  @override
  void didUpdateWidget(WNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // controller 由外部持有：替换时把监听迁移到新实例
    if (oldWidget.controller != widget.controller) {
      _controller.removeListener(_listener);
      _controller = widget.controller;
      _controller.addListener(_listener);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_listener);
    // 不释放 controller：生命周期由调用方管理
    super.dispose();
  }

  Future<void> _handleTap(int index) async {
    // 异步回调可能乱序返回：只有最后一次点击的 future 能触发切换，
    // 否则慢回调会覆盖用户后来的选择。
    final token = ++_tapToken;
    final beforeTap = widget.onBeforeTap;
    if (beforeTap != null) {
      final allowed = await beforeTap(index);
      if (!mounted || token != _tapToken || !allowed) return;
    }
    await _controller.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    // 构建导航项内容
    Widget navContent = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (int i = 0; i < _controller.length; i++)
          Expanded(
            child: Semantics(
              button: true,
              selected: i == _controller.currentIndex,
              child: WPressable(
                onTap: () => _handleTap(i),
                child: RepaintBoundary(
                  child: widget.itemBuilder(context, i, i == _controller.currentIndex),
                ),
              ),
            ),
          ),
      ],
    );

    if (widget.safeArea) {
      navContent = SafeArea(top: false, child: navContent);
    }

    final decoration = widget.style?.decoration;
    final padding = widget.style?.padding;
    if (decoration == null && padding == null) {
      return navContent;
    }

    return Container(
      decoration: decoration,
      padding: padding,
      child: navContent,
    );
  }
}
