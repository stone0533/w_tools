import 'package:flutter/widgets.dart';

import 'button_style.dart';

/// 按钮主题：App 级默认按钮样式。
@immutable
class WButtonThemeData {
  const WButtonThemeData({
    this.primary,
    this.secondary,
    this.text,
    this.danger,
  });

  final WButtonStyle? primary;
  final WButtonStyle? secondary;
  final WButtonStyle? text;
  final WButtonStyle? danger;
}

/// 按钮主题（InheritedWidget）。
class WButtonTheme extends InheritedWidget {
  const WButtonTheme({
    super.key,
    required this.data,
    required super.child,
  });

  final WButtonThemeData data;

  static WButtonThemeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WButtonTheme>()?.data;

  static WButtonThemeData of(BuildContext context) => maybeOf(context) ?? const WButtonThemeData();

  @override
  bool updateShouldNotify(WButtonTheme oldWidget) =>
      data.primary != oldWidget.data.primary ||
      data.secondary != oldWidget.data.secondary ||
      data.text != oldWidget.data.text ||
      data.danger != oldWidget.data.danger;
}
