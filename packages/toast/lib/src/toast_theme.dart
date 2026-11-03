import 'package:flutter/widgets.dart';

import 'toast_style.dart';

/// 全局默认提示样式。
///
/// 放在 App 根部（`wrapApp` / `appWrapper`）即可让页面里的
/// `WToast.showSuccess(..., context: context)` 自动使用同一套样式；
/// 调用处显式传 `style:` 时仍然优先。
class WToastTheme extends InheritedWidget {
  const WToastTheme({super.key, required this.style, required super.child});

  /// 默认样式
  final WToastStyle style;

  static WToastTheme? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<WToastTheme>();
  }

  @override
  bool updateShouldNotify(WToastTheme oldWidget) => style != oldWidget.style;
}
