import 'package:flutter/widgets.dart';

import 'image_types.dart';

/// 图片默认加载 UI 作用域。
///
/// 只负责默认占位符、错误占位和进度 UI；图片颜色/圆角/边框等视觉样式
/// 仍由 [WImageStyle] 决定。
@immutable
class WImageDefaults {
  const WImageDefaults({
    this.placeholderBuilder,
    this.errorBuilder,
    this.progressBuilder,
  });

  /// 默认占位符；返回 null 时回退到内置占位。
  final Widget? Function(BuildContext context, String data)? placeholderBuilder;

  /// 默认错误占位；返回 null 时回退到内置错误占位。
  final Widget? Function(BuildContext context, String data, WImageError error)? errorBuilder;

  /// 默认进度 UI；返回 null 时回退到内置占位。
  final Widget? Function(
    BuildContext context,
    String data,
    WImageProgress progress,
  )? progressBuilder;
}

/// 按子树提供 [WImageDefaults]。
class WImageDefaultsScope extends InheritedWidget {
  const WImageDefaultsScope({
    super.key,
    required this.defaults,
    required super.child,
  });

  final WImageDefaults defaults;

  static WImageDefaults? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WImageDefaultsScope>()?.defaults;

  static WImageDefaults of(BuildContext context) => maybeOf(context) ?? const WImageDefaults();

  @override
  bool updateShouldNotify(WImageDefaultsScope oldWidget) =>
      defaults.placeholderBuilder != oldWidget.defaults.placeholderBuilder ||
      defaults.errorBuilder != oldWidget.defaults.errorBuilder ||
      defaults.progressBuilder != oldWidget.defaults.progressBuilder;
}
