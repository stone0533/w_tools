import 'package:flutter/material.dart';

import 'tab_bar_config.dart';
import 'tab_style.dart';

export 'tab_bar_config.dart';
export 'tab_style.dart';

/// 自定义标签栏组件
///
/// 对 Material [TabBar] 的轻量封装，支持样式、指示器、分割线与对齐方式配置；
/// 控制器可外部传入，未传入时由外层 [DefaultTabController] 提供。
class WTabBar extends StatelessWidget {
  /// 标签栏配置（旧入口，8.0 移除；新代码用 [style]）
  final WTabBarConfig? config;

  /// 标签栏样式
  final WTabBarStyle? style;

  /// 标签列表
  final List<Widget> tabs;

  /// 标签控制器
  final TabController? controller;

  /// 点击回调
  final void Function(int)? onTap;

  /// 创建标签栏
  const WTabBar({
    super.key,
    this.config,
    this.style,
    required this.tabs,
    this.controller,
    this.onTap,
  }) : assert(config == null || style == null, 'WTabBar: config 与 style 只能传一个');

  @override
  Widget build(BuildContext context) {
    final config = this.config ?? style?.toConfig() ?? const WTabBarConfig();
    return TabBar(
      controller: controller,
      padding: config.padding,
      isScrollable: config.isScrollable,
      tabs: tabs,
      labelStyle: config.labelStyle,
      unselectedLabelStyle: config.unselectedLabelStyle,
      indicatorSize: config.indicatorSize,
      indicatorColor: config.indicatorColor,
      indicator: config.indicator,
      indicatorWeight: config.indicatorWeight,
      dividerColor: config.dividerColor,
      dividerHeight: config.dividerHeight,
      overlayColor: config.overlayColor == null
          ? null
          : WidgetStateProperty.all(config.overlayColor),
      tabAlignment: config.tabAlignment,
      onTap: onTap,
    );
  }
}
