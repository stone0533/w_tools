import 'package:flutter/material.dart';

/// 自定义标签栏组件
///
/// 对 Material [TabBar] 的轻量封装，支持样式、指示器、分割线与对齐方式配置；
/// 控制器可外部传入，未传入时由外层 [DefaultTabController] 提供。
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
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      tabAlignment: widget.config._tabAlignment,
      onTap: widget.onTap,
    );
  }
}

/// 标签栏配置类
///
/// 所有字段均可通过 setter 配置，也可用 [copy] / [copyWith] 生成副本。
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

  /// 创建当前配置的副本
  WTabBarConfig copy() => copyWith();

  /// 创建当前配置的副本，并可以选择性地更新某些属性
  ///
  /// 参数为 null 表示沿用原值。
  WTabBarConfig copyWith({
    TextStyle? labelStyle,
    TextStyle? unselectedLabelStyle,
    Color? dividerColor,
    double? dividerHeight,
    EdgeInsetsGeometry? padding,
    bool? isScrollable,
    TabBarIndicatorSize? indicatorSize,
    Color? indicatorColor,
    Decoration? indicator,
    double? indicatorWeight,
    TabAlignment? tabAlignment,
  }) {
    final copy = WTabBarConfig();
    copy._labelStyle = labelStyle ?? _labelStyle;
    copy._unselectedLabelStyle = unselectedLabelStyle ?? _unselectedLabelStyle;
    copy._dividerColor = dividerColor ?? _dividerColor;
    copy._dividerHeight = dividerHeight ?? _dividerHeight;
    copy._padding = padding ?? _padding;
    copy._isScrollable = isScrollable ?? _isScrollable;
    copy._indicatorSize = indicatorSize ?? _indicatorSize;
    copy._indicatorColor = indicatorColor ?? _indicatorColor;
    copy._indicator = indicator ?? _indicator;
    copy._indicatorWeight = indicatorWeight ?? _indicatorWeight;
    copy._tabAlignment = tabAlignment ?? _tabAlignment;
    return copy;
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
