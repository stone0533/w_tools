import 'package:flutter/material.dart';

import 'tab_style.dart';

export 'tab_style.dart';

/// 自定义标签栏组件
///
/// 对 Material [TabBar] 的轻量封装，支持样式、指示器、分割线与对齐方式配置；
/// 控制器可外部传入，未传入时由外层 [DefaultTabController] 提供。
class WTabBar extends StatelessWidget {
  /// 标签栏样式
  final WTabBarStyle style;

  /// 标签列表
  final List<Widget> tabs;

  /// 标签控制器
  final TabController? controller;

  /// 点击回调
  final void Function(int)? onTap;

  /// 创建标签栏
  const WTabBar({
    super.key,
    this.style = const WTabBarStyle(),
    required this.tabs,
    this.controller,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = this.style;
    return TabBar(
      controller: controller,
      padding: style.padding,
      isScrollable: style.isScrollable,
      tabs: tabs,
      labelStyle: style.labelStyle,
      unselectedLabelStyle: style.unselectedLabelStyle,
      labelColor: style.labelColor,
      unselectedLabelColor: style.unselectedLabelColor,
      labelPadding: style.labelPadding,
      indicatorPadding: style.indicatorPadding ?? EdgeInsets.zero,
      textScaler: style.textScaler,
      indicatorSize: style.indicatorSize,
      indicatorColor: style.indicatorColor,
      indicator: style.indicator,
      indicatorWeight: style.indicatorWeight,
      indicatorAnimation: style.indicatorAnimation,
      dividerColor: style.dividerColor,
      dividerHeight: style.dividerHeight,
      overlayColor: style.overlayColor == null ? null : WidgetStateProperty.all(style.overlayColor),
      splashFactory: style.splashFactory,
      mouseCursor: style.mouseCursor,
      enableFeedback: style.enableFeedback,
      splashBorderRadius: style.splashBorderRadius,
      tabAlignment: style.tabAlignment,
      onTap: onTap,
    );
  }
}
