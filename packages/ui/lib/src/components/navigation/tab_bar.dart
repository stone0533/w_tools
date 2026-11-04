import 'package:flutter/material.dart';

/// 自定义标签栏组件
///
/// 对 Material [TabBar] 的轻量封装，支持样式、指示器、分割线与对齐方式配置；
/// 控制器可外部传入，未传入时由外层 [DefaultTabController] 提供。
class WTabBar extends StatelessWidget {
  /// 标签栏配置
  final WTabBarConfig? config;

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
    required this.tabs,
    this.controller,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final config = this.config ?? const WTabBarConfig();
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
      overlayColor: WidgetStateProperty.all(
        config.overlayColor ?? Colors.transparent,
      ),
      tabAlignment: config.tabAlignment,
      onTap: onTap,
    );
  }
}

/// 标签栏配置类（不可变；用构造 / [copyWith] 派生）
@immutable
class WTabBarConfig {
  /// 创建配置
  const WTabBarConfig({
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

  /// 选中标签样式
  final TextStyle? labelStyle;

  /// 未选中标签样式
  final TextStyle? unselectedLabelStyle;

  /// 分割线颜色
  final Color? dividerColor;

  /// 分割线高度
  final double? dividerHeight;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 是否可滚动
  final bool isScrollable;

  /// 指示器大小
  final TabBarIndicatorSize? indicatorSize;

  /// 指示器颜色
  final Color? indicatorColor;

  /// 指示器
  final Decoration? indicator;

  /// 指示器权重
  final double indicatorWeight;

  /// 标签对齐方式
  final TabAlignment? tabAlignment;

  /// 点击 / hover overlay 颜色；null 时透明
  final Color? overlayColor;

  /// 创建当前配置的副本
  WTabBarConfig copy() => copyWith();

  /// 创建副本并选择性更新（可空字段传 null 表示清空）
  WTabBarConfig copyWith({
    Object? labelStyle = _unset,
    Object? unselectedLabelStyle = _unset,
    Object? dividerColor = _unset,
    Object? dividerHeight = _unset,
    Object? padding = _unset,
    bool? isScrollable,
    Object? indicatorSize = _unset,
    Object? indicatorColor = _unset,
    Object? indicator = _unset,
    double? indicatorWeight,
    Object? tabAlignment = _unset,
    Object? overlayColor = _unset,
  }) {
    return WTabBarConfig(
      labelStyle: identical(labelStyle, _unset) ? this.labelStyle : labelStyle as TextStyle?,
      unselectedLabelStyle: identical(unselectedLabelStyle, _unset)
          ? this.unselectedLabelStyle
          : unselectedLabelStyle as TextStyle?,
      dividerColor: identical(dividerColor, _unset) ? this.dividerColor : dividerColor as Color?,
      dividerHeight: identical(dividerHeight, _unset)
          ? this.dividerHeight
          : dividerHeight as double?,
      padding: identical(padding, _unset) ? this.padding : padding as EdgeInsetsGeometry?,
      isScrollable: isScrollable ?? this.isScrollable,
      indicatorSize: identical(indicatorSize, _unset)
          ? this.indicatorSize
          : indicatorSize as TabBarIndicatorSize?,
      indicatorColor: identical(indicatorColor, _unset)
          ? this.indicatorColor
          : indicatorColor as Color?,
      indicator: identical(indicator, _unset) ? this.indicator : indicator as Decoration?,
      indicatorWeight: indicatorWeight ?? this.indicatorWeight,
      tabAlignment: identical(tabAlignment, _unset)
          ? this.tabAlignment
          : tabAlignment as TabAlignment?,
      overlayColor: identical(overlayColor, _unset) ? this.overlayColor : overlayColor as Color?,
    );
  }

  /// 构建标签栏
  WTabBar build({
    required List<Widget> tabs,
    TabController? controller,
    void Function(int)? onTap,
  }) {
    return WTabBar(
      config: this,
      tabs: tabs,
      controller: controller,
      onTap: onTap,
    );
  }
}

const Object _unset = Object();
