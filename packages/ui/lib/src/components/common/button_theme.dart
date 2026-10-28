import 'package:flutter/widgets.dart';

import 'button_size.dart';
import 'button_style.dart';

/// 按钮主题：App 级默认按钮样式。
@immutable
class WButtonThemeData {
  const WButtonThemeData({
    this.primary,
    this.secondary,
    this.text,
    this.danger,
    this.variants = const <String, WButtonStyle>{},
    this.sizes = const <String, WButtonSize>{},
    this.base,
    this.defaultSize,
  });

  final WButtonStyle? primary;
  final WButtonStyle? secondary;
  final WButtonStyle? text;
  final WButtonStyle? danger;

  /// 项目自定义变体，例如 brand / warning / success
  final Map<String, WButtonStyle> variants;

  /// 项目自定义命名尺寸，例如 compact / hero
  final Map<String, WButtonSize> sizes;

  /// 所有变体的兜底样式
  final WButtonStyle? base;

  /// 默认尺寸；variant 构造未显式传 size 时使用
  final WButtonSize? defaultSize;

  WButtonStyle? resolveStyle(String? variant) {
    if (variant == null) return primary ?? base;
    final semantic = switch (variant) {
      'primary' => primary,
      'secondary' => secondary,
      'text' => text,
      'danger' => danger,
      _ => null,
    };
    return variants[variant] ?? semantic ?? base;
  }

  WButtonSize? resolveSize(String? name) {
    if (name == null) return defaultSize;
    return sizes[name];
  }
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
      data.danger != oldWidget.data.danger ||
      data.variants != oldWidget.data.variants ||
      data.sizes != oldWidget.data.sizes ||
      data.base != oldWidget.data.base ||
      data.defaultSize != oldWidget.data.defaultSize;
}
