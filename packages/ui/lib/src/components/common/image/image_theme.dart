import 'package:flutter/widgets.dart';

import 'image_types.dart';

/// 图片默认样式（占位符/错误占位）。
///
/// 作用域由 [WImageTheme] 提供；没有 theme 时使用组件内置兜底。
@immutable
class WImageThemeData {
  const WImageThemeData({
    this.defaultPlaceholder,
    this.defaultErrorWidget,
    this.defaultProgressBuilder,
  });

  final Widget? defaultPlaceholder;
  final Widget? defaultErrorWidget;
  final Widget? Function(BuildContext, String, WImageProgress)? defaultProgressBuilder;
}

/// 图片主题（InheritedWidget），替代无 context 的全局单例做局部覆盖。
class WImageTheme extends InheritedWidget {
  const WImageTheme({
    super.key,
    required this.data,
    required super.child,
  });

  final WImageThemeData data;

  static WImageThemeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WImageTheme>()?.data;

  static WImageThemeData of(BuildContext context) => maybeOf(context) ?? const WImageThemeData();

  @override
  bool updateShouldNotify(WImageTheme oldWidget) =>
      data.defaultPlaceholder != oldWidget.data.defaultPlaceholder ||
      data.defaultErrorWidget != oldWidget.data.defaultErrorWidget ||
      data.defaultProgressBuilder != oldWidget.data.defaultProgressBuilder;
}
