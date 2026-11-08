import 'package:flutter/widgets.dart';

import 'image_slots.dart';

/// 图片默认加载 UI 作用域。
///
/// 只有 [WImageSlots] 会被继承；图片颜色/圆角/边框等视觉样式仍由
/// `WImageStyle` 决定，加载行为由单张图的 `WImageLoadOptions` 决定。
///
/// 优先级：单图 `WImage.slots` 的非空字段 > 本作用域 > 内置兜底。
@immutable
class WImageTheme extends InheritedWidget {
  const WImageTheme({
    super.key,
    required this.slots,
    required super.child,
  });

  final WImageSlots slots;

  static WImageSlots? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WImageTheme>()?.slots;

  static WImageSlots of(BuildContext context) => maybeOf(context) ?? const WImageSlots();

  @override
  bool updateShouldNotify(WImageTheme oldWidget) => slots != oldWidget.slots;
}
