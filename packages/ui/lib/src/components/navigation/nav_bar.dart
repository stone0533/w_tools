import 'package:flutter/material.dart';
import '../layout/container.dart';
import 'nav_controller.dart';

/// 底部导航栏组件
///
/// 由传入的 [controller]（`WNavController`）驱动选中态与切换动画，
/// 每个导航项交由 [itemBuilder] 渲染。
///
/// [controller] 由调用方持有并负责释放，本组件只负责添加 / 移除监听。
class WNavBar extends StatefulWidget {
  /// 标签栏配置
  final WNavBarConfig config;

  /// 导航项构建器
  final Widget Function(BuildContext, int, bool) itemBuilder;

  /// 导航项点击回调
  final Future<bool?>? Function(int)? onItemTap;

  /// 导航栏控制器
  final WNavController controller;

  const WNavBar({
    super.key,
    required this.config,
    required this.itemBuilder,
    this.onItemTap,
    required this.controller,
  });

  @override
  State<WNavBar> createState() => _WNavBarState();
}

class _WNavBarState extends State<WNavBar> {
  late WNavController _controller;
  late final VoidCallback _listener;

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

  @override
  Widget build(BuildContext context) {
    // 构建导航项内容
    Widget navContent = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (int i = 0; i < _controller.length; i++)
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final result = await widget.onItemTap?.call(i);
                // 等待回调期间组件可能已卸载
                if (!mounted) return;
                if (result != false) {
                  _controller.animateTo(i);
                }
              },
              child: RepaintBoundary(
                child: widget.itemBuilder(context, i, i == _controller.currentIndex),
              ),
            ),
          ),
      ],
    );

    // 如果提供了容器配置，使用配置中的构建器
    if (widget.config._containerConfig != null) {
      return widget.config._containerConfig!.build(child: navContent);
    }

    // 默认直接返回导航内容
    return navContent;
  }
}

/// 导航栏配置类
class WNavBarConfig {
  /// 外层容器配置；为 null 时直接返回导航内容
  WContainerConfig? _containerConfig;

  /// 设置外层容器配置
  set containerConfig(WContainerConfig? value) {
    _containerConfig = value;
  }

  /// 构建导航栏
  WNavBar build({
    required Widget Function(BuildContext, int, bool) itemBuilder,
    Future<bool?>? Function(int)? onItemTap,
    required WNavController controller,
  }) {
    return WNavBar(
      config: this,
      itemBuilder: itemBuilder,
      onItemTap: onItemTap,
      controller: controller,
    );
  }
}
