import 'package:flutter/material.dart';

import 'async_strings.dart';

typedef WAsyncErrorWidgetBuilder =
    Widget Function(
      BuildContext context,
      Object error,
      VoidCallback? onRetry,
    );

/// 异步视图的全局默认主题。
///
/// 放在 App 根部（推荐 `WAppPlugin.wrapApp` / `WAppOptions.appWrapper`）即可让多个页面共享
/// 默认 loading / empty / error / 刷新视图；单个 `WAsyncView` / `WAsyncStateSliver`
/// 的显式 builder 仍然优先。
///
/// [WAsyncStateSliver] 复用同一组 builder：`loadingBuilder` / `emptyBuilder` /
/// `errorBuilder` / `errorBannerBuilder` 返回普通 Widget（不是 sliver），
/// sliver 组件会自己包 `SliverFillRemaining` / `SliverToBoxAdapter`。
class WAsyncTheme extends InheritedWidget {
  const WAsyncTheme({
    super.key,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.errorBannerBuilder,
    this.refreshingBuilder,
    this.strings = const WAsyncStrings(),
    required super.child,
  });

  /// 加载中
  final WidgetBuilder? loadingBuilder;

  /// 空数据
  final WidgetBuilder? emptyBuilder;

  /// 加载失败（整块替换）
  final WAsyncErrorWidgetBuilder? errorBuilder;

  /// 刷新失败但有旧数据（内容盒底部条）
  final WAsyncErrorWidgetBuilder? errorBannerBuilder;

  /// 刷新中（内容盒顶部指示器）
  final WidgetBuilder? refreshingBuilder;

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
        strings != oldWidget.strings;
  }
}
