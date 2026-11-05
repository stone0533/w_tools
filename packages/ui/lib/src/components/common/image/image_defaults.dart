import 'package:flutter/widgets.dart';

import 'image_config.dart';

/// 图片默认加载 UI 作用域。
///
/// 只负责默认占位符、错误占位和进度 UI；图片颜色/圆角/边框等视觉样式
/// 仍由 [WImageStyle] 决定。
///
/// 优先级：WImageLoadConfig 的 builder/widget > 本作用域 > 内置兜底。
@immutable
class WImageDefaultsScope extends InheritedWidget {
  const WImageDefaultsScope({
    super.key,
    required this.defaults,
    required super.child,
  });

  final WImageLoadConfig defaults;

  static WImageLoadConfig? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WImageDefaultsScope>()?.defaults;

  static WImageLoadConfig of(BuildContext context) => maybeOf(context) ?? const WImageLoadConfig();

  @override
  bool updateShouldNotify(WImageDefaultsScope oldWidget) => defaults != oldWidget.defaults;
}
