import 'package:flutter/material.dart';

import 'async_strings.dart';

typedef WAsyncRetryErrorHandler = void Function(Object error, StackTrace stackTrace);

typedef WAsyncErrorWidgetBuilder =
    Widget Function(
      BuildContext context,
      Object error,
      VoidCallback onRetry,
    );

/// 异步视图的全局默认主题（普通视图 + sliver 视图合在一处）。
///
/// 放在 App 根部（推荐 `WAppPlugin.wrapApp` / `WAppOptions.appWrapper`）即可让多个页面共享
/// 默认 loading / empty / error / 刷新视图；单个 `WAsyncView` / `WAsyncStateSliver`
/// 的显式 builder 仍然优先。
///
/// - `*Builder` 作用于 [WAsyncView] / `WAsyncStateBuilder`；
/// - `sliver*Builder` 作用于 `WAsyncStateSliver`，loading / empty / error 必须是
///   **非滚动** Widget；`refreshingSliverBuilder` 必须返回 sliver。
///
/// 旧入口已在 3.0 删除；本类为唯一的全局默认视图入口。
class WAsyncTheme extends InheritedWidget {
  const WAsyncTheme({
    super.key,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.errorBannerBuilder,
    this.refreshingBuilder,
    this.sliverLoadingBuilder,
    this.sliverEmptyBuilder,
    this.sliverErrorBuilder,
    this.sliverErrorBannerBuilder,
    this.refreshingSliverBuilder,
    this.strings = const WAsyncStrings(),
    required super.child,
  });

  /// 普通视图：加载中
  final WidgetBuilder? loadingBuilder;

  /// 普通视图：空数据
  final WidgetBuilder? emptyBuilder;

  /// 普通视图：加载失败（整块替换）
  final WAsyncErrorWidgetBuilder? errorBuilder;

  /// 普通视图：刷新失败但有旧数据（底部条）
  final WAsyncErrorWidgetBuilder? errorBannerBuilder;

  /// 普通视图：刷新中（顶部指示器）
  final WidgetBuilder? refreshingBuilder;

  /// sliver：加载中（非滚动 Widget）
  final WidgetBuilder? sliverLoadingBuilder;

  /// sliver：空数据（非滚动 Widget）
  final WidgetBuilder? sliverEmptyBuilder;

  /// sliver：加载失败（非滚动 Widget）
  final WAsyncErrorWidgetBuilder? sliverErrorBuilder;

  /// sliver：刷新失败但有旧数据（作为 sliver 追加）
  final WAsyncErrorWidgetBuilder? sliverErrorBannerBuilder;

  /// sliver：刷新中，必须返回 sliver
  final WidgetBuilder? refreshingSliverBuilder;

  /// UI 文案；默认中性英文，可注入项目本地化文案。
  final WAsyncStrings strings;

  static WAsyncTheme? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<WAsyncTheme>();
  }

  @override
  bool updateShouldNotify(WAsyncTheme oldWidget) {
    return loadingBuilder != oldWidget.loadingBuilder ||
        emptyBuilder != oldWidget.emptyBuilder ||
        errorBuilder != oldWidget.errorBuilder ||
        errorBannerBuilder != oldWidget.errorBannerBuilder ||
        refreshingBuilder != oldWidget.refreshingBuilder ||
        sliverLoadingBuilder != oldWidget.sliverLoadingBuilder ||
        sliverEmptyBuilder != oldWidget.sliverEmptyBuilder ||
        sliverErrorBuilder != oldWidget.sliverErrorBuilder ||
        sliverErrorBannerBuilder != oldWidget.sliverErrorBannerBuilder ||
        refreshingSliverBuilder != oldWidget.refreshingSliverBuilder ||
        strings != oldWidget.strings;
  }
}
