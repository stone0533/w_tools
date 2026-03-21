import 'package:flutter/material.dart';

/// 自定义标签栏组件
class WTabBar extends StatefulWidget {
  /// 标签栏配置
  final WTabBarConfig config;

  /// 标签列表
  final List<Widget> tabs;

  /// 标签控制器
  final TabController? controller;

  /// 点击回调
  final void Function(int)? onTap;

  /// 创建标签栏
  const WTabBar({
    super.key,
    required this.config,
    required this.tabs,
    this.controller,
    this.onTap,
  });

  @override
  State<WTabBar> createState() => _WTabBarState();
}

/// WTabBar 的状态类
class _WTabBarState extends State<WTabBar> {
  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: widget.controller,
      padding: widget.config._padding,
      isScrollable: widget.config._isScrollable,
      tabs: widget.tabs,
      labelStyle: widget.config._labelStyle,
      unselectedLabelStyle: widget.config._unselectedLabelStyle,
      indicatorSize: widget.config._indicatorSize,
      indicatorColor: widget.config._indicatorColor,
      indicator: widget.config._indicator,
      indicatorWeight: widget.config._indicatorWeight,
      dividerColor: widget.config._dividerColor,
      dividerHeight: widget.config._dividerHeight,
      physics: const NeverScrollableScrollPhysics(),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      tabAlignment: widget.config._tabAlignment,
      onTap: widget.onTap,
    );
  }
}

/// 标签栏配置类
class WTabBarConfig {
  TextStyle? _labelStyle;
  TextStyle? _unselectedLabelStyle;
  Color? _dividerColor;
  double? _dividerHeight;
  EdgeInsetsGeometry? _padding;
  bool _isScrollable = false;
  TabBarIndicatorSize? _indicatorSize;
  Color? _indicatorColor;
  Decoration? _indicator;
  double _indicatorWeight = 2.0;
  TabAlignment? _tabAlignment;

  /// 设置选中标签样式
  set labelStyle(TextStyle? value) {
    _labelStyle = value;
  }

  /// 设置未选中标签样式
  set unselectedLabelStyle(TextStyle? value) {
    _unselectedLabelStyle = value;
  }

  /// 设置分割线颜色
  set dividerColor(Color? value) {
    _dividerColor = value;
  }

  /// 设置分割线高度
  set dividerHeight(double? value) {
    _dividerHeight = value;
  }

  /// 设置内边距
  set padding(EdgeInsetsGeometry? value) {
    _padding = value;
  }

  /// 设置是否可滚动
  set isScrollable(bool value) {
    _isScrollable = value;
  }

  /// 设置指示器大小
  set indicatorSize(TabBarIndicatorSize? value) {
    _indicatorSize = value;
  }

  /// 设置指示器颜色
  set indicatorColor(Color? value) {
    _indicatorColor = value;
  }

  /// 设置指示器
  set indicator(Decoration? value) {
    _indicator = value;
  }

  /// 设置指示器权重
  set indicatorWeight(double value) {
    _indicatorWeight = value;
  }

  /// 设置标签对齐方式
  set tabAlignment(TabAlignment? value) {
    _tabAlignment = value;
  }

  /// 设置分割线
  WTabBarConfig divider(double dividerHeight, Color dividerColor) {
    _dividerHeight = dividerHeight;
    _dividerColor = dividerColor;
    return this;
  }

  /// 设置带高度和颜色的指示器
  WTabBarConfig indicatorWithHeightAndColor(double height, Color color) {
    _indicator = BoxDecoration(
      borderRadius: BorderRadius.zero,
      border: Border(
        bottom: BorderSide(width: height, color: color),
      ),
    );
    return this;
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
