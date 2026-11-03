import 'package:flutter/widgets.dart';

import 'async_view_defaults.dart';

/// `WAsyncStateSliver` 的默认视图。
///
/// 与 [WAsyncViewDefaults] 分开：这里的 loading / empty / error builder
/// 会被放进 `SliverFillRemaining(hasScrollBody: false)`，必须是**非滚动**
/// 的普通 Widget；不要把 `AppRefreshable` / `SingleChildScrollView` 放进来。
///
/// [refreshingSliverBuilder] 必须返回 sliver。
///
/// 2.2 起推荐 [WAsyncTheme]（`sliver*Builder`）；本类 3.0 移除。
/// remove-in: 3.0.0
@Deprecated('2.2 起用 WAsyncTheme 的 sliver*Builder；3.0 移除')
class WAsyncSliverDefaults extends InheritedWidget {
  const WAsyncSliverDefaults({
    super.key,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.errorBannerBuilder,
    this.refreshingSliverBuilder,
    required super.child,
  });

  final WidgetBuilder? loadingBuilder;
  final WidgetBuilder? emptyBuilder;
  final WAsyncErrorWidgetBuilder? errorBuilder;
  final WAsyncErrorWidgetBuilder? errorBannerBuilder;
  final WidgetBuilder? refreshingSliverBuilder;

  static WAsyncSliverDefaults? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<WAsyncSliverDefaults>();
  }

  @override
  bool updateShouldNotify(WAsyncSliverDefaults oldWidget) {
    return loadingBuilder != oldWidget.loadingBuilder ||
        emptyBuilder != oldWidget.emptyBuilder ||
        errorBuilder != oldWidget.errorBuilder ||
        errorBannerBuilder != oldWidget.errorBannerBuilder ||
        refreshingSliverBuilder != oldWidget.refreshingSliverBuilder;
  }
}
