import 'package:flutter/material.dart';

import 'tab_bar_config.dart';

/// 标签栏的视觉 / 布局样式；新代码优先用它替代 config。
@immutable
class WTabBarStyle {
  const WTabBarStyle({
    this.labelStyle,
    this.unselectedLabelStyle,
    this.dividerColor,
    this.dividerHeight,
    this.padding,
    this.isScrollable = false,
    this.indicatorSize,
    this.indicatorColor,
    this.indicator,
    this.indicatorWeight = 2.0,
    this.tabAlignment,
    this.overlayColor,
  });

  final TextStyle? labelStyle;
  final TextStyle? unselectedLabelStyle;
  final Color? dividerColor;
  final double? dividerHeight;
  final EdgeInsetsGeometry? padding;
  final bool isScrollable;
  final TabBarIndicatorSize? indicatorSize;
  final Color? indicatorColor;
  final Decoration? indicator;
  final double indicatorWeight;
  final TabAlignment? tabAlignment;
  final Color? overlayColor;

  /// 转成旧配置，供 WTabBar 内部统一处理。
  WTabBarConfig toConfig() {
    return WTabBarConfig(
      labelStyle: labelStyle,
      unselectedLabelStyle: unselectedLabelStyle,
      dividerColor: dividerColor,
      dividerHeight: dividerHeight,
      padding: padding,
      isScrollable: isScrollable,
      indicatorSize: indicatorSize,
      indicatorColor: indicatorColor,
      indicator: indicator,
      indicatorWeight: indicatorWeight,
      tabAlignment: tabAlignment,
      overlayColor: overlayColor,
    );
  }
}
