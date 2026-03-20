import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:w_tools/w.dart';

/// 增强版脚手架组件，提供更多自定义选项
class WScaffold extends StatelessWidget {
  /// 主体内容
  final Widget? body;

  /// 背景颜色
  final Color? backgroundColor;

  /// 系统 UI 覆盖样式
  final SystemUiOverlayStyle? systemUiOverlayStyle;

  /// 背景 widget，会显示在 body 下方
  final Widget? backgroundWidget;

  /// 是否添加顶部安全空间
  final bool withTopSafeSpace;

  /// 是否添加底部安全空间
  final bool withBottomSafeSpace;

  /// 创建脚手架
  const WScaffold({
    super.key,
    this.body,
    this.backgroundColor,
    this.systemUiOverlayStyle,
    this.backgroundWidget,
    this.withTopSafeSpace = false,
    this.withBottomSafeSpace = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget? content = body;

    // 处理安全空间
    if (content != null) {
      if (withTopSafeSpace) {
        content = content.withTopSafeSpace();
      }
      if (withBottomSafeSpace) {
        content = content.withBottomSafeSpace();
      }
    }

    // 如果提供了背景 widget，使用 Stack 叠加
    if (backgroundWidget != null) {
      final children = <Widget>[backgroundWidget!];
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

    // 如果提供了系统 UI 覆盖样式，则使用 AnnotatedRegion 包装
    return systemUiOverlayStyle != null
        ? AnnotatedRegion<SystemUiOverlayStyle>(
            value: systemUiOverlayStyle!,
            child: scaffold,
          )
        : scaffold;
  }
}

/// WScaffold 配置类，用于链式构建 WScaffold
class WScaffoldConfig {
  /// 背景颜色
  Color? _backgroundColor;

  /// 系统 UI 覆盖样式
  SystemUiOverlayStyle? _systemUiOverlayStyle;

  /// 背景 widget
  Widget? _backgroundWidget;

  /// 是否添加顶部安全空间
  bool _withTopSafeSpace = false;

  /// 是否添加底部安全空间
  bool _withBottomSafeSpace = true;

  /// 设置背景颜色
  set backgroundColor(Color? value) {
    _backgroundColor = value;
  }

  /// 设置系统 UI 覆盖样式
  set systemUiOverlayStyle(SystemUiOverlayStyle? value) {
    _systemUiOverlayStyle = value;
  }

  /// 设置背景 widget
  set backgroundWidget(Widget? value) {
    _backgroundWidget = value;
  }

  /// 设置是否添加顶部安全空间
  set withTopSafeSpace(bool value) {
    _withTopSafeSpace = value;
  }

  /// 设置是否添加底部安全空间
  set withBottomSafeSpace(bool value) {
    _withBottomSafeSpace = value;
  }

  /// 构建 WScaffold
  Widget build({Widget? body}) {
    return WScaffold(
      backgroundColor: _backgroundColor,
      systemUiOverlayStyle: _systemUiOverlayStyle,
      backgroundWidget: _backgroundWidget,
      withTopSafeSpace: _withTopSafeSpace,
      withBottomSafeSpace: _withBottomSafeSpace,
      body: body,
    );
  }
}
