import 'package:flutter/material.dart';

typedef WAsyncErrorWidgetBuilder = Widget Function(
  BuildContext context,
  Object error,
  VoidCallback onRetry,
);

/// 异步视图的显式默认配置。
///
/// 放在 App 根部即可让多个页面共享默认 loading / empty / error 视图；
/// 单个 WAsyncView 仍可显式覆盖。
///
/// 只作用于 [WAsyncView]；[WAsyncBuilder] 由调用方自行构建状态 UI，
/// 不会读取这些默认值。
class WAsyncViewDefaults extends InheritedWidget {
  const WAsyncViewDefaults({
    super.key,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.errorBannerBuilder,
    this.refreshingBuilder,
    required super.child,
  });

  final WidgetBuilder? loadingBuilder;
  final WidgetBuilder? emptyBuilder;
  final WAsyncErrorWidgetBuilder? errorBuilder;
  final WAsyncErrorWidgetBuilder? errorBannerBuilder;
  final WidgetBuilder? refreshingBuilder;

  static WAsyncViewDefaults? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<WAsyncViewDefaults>();
  }

  @override
  bool updateShouldNotify(WAsyncViewDefaults oldWidget) {
    return loadingBuilder != oldWidget.loadingBuilder ||
        emptyBuilder != oldWidget.emptyBuilder ||
        errorBuilder != oldWidget.errorBuilder ||
        errorBannerBuilder != oldWidget.errorBannerBuilder ||
        refreshingBuilder != oldWidget.refreshingBuilder;
  }
}
