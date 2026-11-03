import 'package:flutter/widgets.dart';

import 'image_config.dart';
import 'image_types.dart';

/// 图片默认加载 UI 作用域。
///
/// 只负责默认占位符、错误占位和进度 UI；图片颜色/圆角/边框等视觉样式
/// 仍由 [WImageStyle] 决定。
@immutable
/// remove-in: 5.0.0
@Deprecated('5.0 移除：WImageDefaultsScope 直接接收 WImageLoadConfig')
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
///
/// 优先级：WImageLoadConfig 的 builder/widget > 本作用域 > 内置兜底。
class WImageDefaultsScope extends InheritedWidget {
  const WImageDefaultsScope({
    super.key,
    required this.defaults,
    required super.child,
  });

  final WImageLoadConfig defaults;

  static WImageLoadConfig? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WImageDefaultsScope>()?.defaults;

  static WImageLoadConfig of(BuildContext context) =>
      maybeOf(context) ?? const WImageLoadConfig();

  @override
  bool updateShouldNotify(WImageDefaultsScope oldWidget) =>
      defaults.placeholderBuilder != oldWidget.defaults.placeholderBuilder ||
      defaults.errorWidgetBuilder != oldWidget.defaults.errorWidgetBuilder ||
      defaults.progressBuilder != oldWidget.defaults.progressBuilder;
}
