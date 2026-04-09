import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:w_tools/w.dart';

/// 增强版脚手架组件，提供更多自定义选项
class WScaffold extends StatelessWidget {
  /// 主体内容
  final Widget? body;

  /// 背景颜色
  final Color? backgroundColor;

  /// 系统状态栏样式
  final SystemUiOverlayStyle? systemStatusBarStyle;

  /// 底层 widget，会显示在 body 下方
  final Widget? underlayWidget;

  /// 是否包含顶部安全区域
  final bool includeTopSafeArea;

  /// 是否包含底部安全区域
  final bool includeBottomSafeArea;

  /// 创建脚手架
  const WScaffold({
    super.key,
    this.body,
    this.backgroundColor,
    this.systemStatusBarStyle,
    this.underlayWidget,
    this.includeTopSafeArea = false,
    this.includeBottomSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget? content = body;

    // 处理安全空间
    if (content != null) {
      if (includeTopSafeArea) {
        content = content.withTopSafeSpace();
      }
      if (includeBottomSafeArea) {
        content = content.withBottomSafeSpace();
      }
    }

    // 如果提供了底层 widget，使用 Stack 叠加
    if (underlayWidget != null) {
      final children = <Widget>[underlayWidget!];
      if (content != null) {
        children.add(content);
      }
      content = Stack(fit: StackFit.expand, children: children);
    }

    // 创建基础 Scaffold
    final scaffold = Scaffold(
      backgroundColor: backgroundColor,
      body: content,
    );

    // 如果提供了系统状态栏样式，则使用 AnnotatedRegion 包装
    return systemStatusBarStyle != null
        ? AnnotatedRegion<SystemUiOverlayStyle>(
            value: systemStatusBarStyle!,
            child: scaffold,
          )
        : scaffold;
  }
}

/// WScaffold 配置类，用于链式构建 WScaffold
class WScaffoldConfig {
  /// 背景颜色
  Color? _backgroundColor;

  /// 系统状态栏样式
  SystemUiOverlayStyle? _systemStatusBarStyle;

  /// 底层 widget
  Widget? _underlayWidget;

  /// 是否包含顶部安全区域
  bool _includeTopSafeArea = false;

  /// 是否包含底部安全区域
  bool _includeBottomSafeArea = true;

  /// 设置背景颜色
  set backgroundColor(Color? value) {
    _backgroundColor = value;
  }

  /// 设置系统状态栏样式
  set systemStatusBarStyle(SystemUiOverlayStyle? value) {
    _systemStatusBarStyle = value;
  }

  /// 设置底层 widget
  set underlayWidget(Widget? value) {
    _underlayWidget = value;
  }

  /// 设置是否包含顶部安全区域
  set includeTopSafeArea(bool value) {
    _includeTopSafeArea = value;
  }

  /// 设置是否包含底部安全区域
  set includeBottomSafeArea(bool value) {
    _includeBottomSafeArea = value;
  }

  /// 构建 WScaffold
  ///
  /// @param body 主体内容
  /// @param backgroundColor 背景颜色
  /// @param systemStatusBarStyle 系统状态栏样式
  /// @param underlayWidget 底层 widget
  /// @param includeTopSafeArea 是否包含顶部安全区域
  /// @param includeBottomSafeArea 是否包含底部安全区域
  /// @return WScaffold 实例
  Widget build({
    Widget? body,
    Color? backgroundColor,
    SystemUiOverlayStyle? systemStatusBarStyle,
    Widget? underlayWidget,
    bool? includeTopSafeArea,
    bool? includeBottomSafeArea,
  }) {
    return WScaffold(
      backgroundColor: backgroundColor ?? _backgroundColor,
      systemStatusBarStyle: systemStatusBarStyle ?? _systemStatusBarStyle,
      underlayWidget: underlayWidget ?? _underlayWidget,
      includeTopSafeArea: includeTopSafeArea ?? _includeTopSafeArea,
      includeBottomSafeArea: includeBottomSafeArea ?? _includeBottomSafeArea,
      body: body,
    );
  }

  /// 创建当前配置的副本
  ///
  /// @return WScaffoldConfig 实例的副本
  WScaffoldConfig copy() {
    return copyWith();
  }

  /// 创建当前配置的副本，并可以选择性地更新某些属性
  ///
  /// @param backgroundColor 背景颜色
  /// @param systemStatusBarStyle 系统状态栏样式
  /// @param underlayWidget 底层 widget
  /// @param includeTopSafeArea 是否包含顶部安全区域
  /// @param includeBottomSafeArea 是否包含底部安全区域
  /// @return WScaffoldConfig 实例，包含更新后的配置
  WScaffoldConfig copyWith({
    Color? backgroundColor,
    SystemUiOverlayStyle? systemStatusBarStyle,
    Widget? underlayWidget,
    bool? includeTopSafeArea,
    bool? includeBottomSafeArea,
  }) {
    final copy = WScaffoldConfig();
    copy._backgroundColor = backgroundColor ?? _backgroundColor;
    copy._systemStatusBarStyle = systemStatusBarStyle ?? _systemStatusBarStyle;
    copy._underlayWidget = underlayWidget ?? _underlayWidget;
    copy._includeTopSafeArea = includeTopSafeArea ?? _includeTopSafeArea;
    copy._includeBottomSafeArea = includeBottomSafeArea ?? _includeBottomSafeArea;
    return copy;
  }
}
