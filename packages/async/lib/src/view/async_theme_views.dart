import 'package:flutter/material.dart';

import 'async_error_banner.dart';
import 'async_error_view.dart';
import 'async_strings.dart';
import 'async_theme.dart';

/// 四态视图的统一解析入口：显式 builder > [WAsyncTheme] > 包内默认。
///
/// [WAsyncView] / [WAsyncStateSliver] 内部都走这里，保证两条渲染路径的默认值
/// 不会各自漂移。`WAsyncStateBuilder` 这类「自己搭滚动壳」的场景也可以用它拿到
/// 全局默认，避免每个滚动页重写一遍 loading / empty / error：
///
/// ```dart
/// final views = WAsyncThemeViews.of(context);
///
/// WAsyncStateBuilder<List<Gift>>(
///   state: controller.state,
///   builder: (context, state) => SmartRefresher(
///     onRefresh: controller.load,
///     child: CustomScrollView(
///       slivers: [
///         ...state.when(
///           loading: () => [SliverFillRemaining(child: views.loading(context))],
///           empty: () => [SliverFillRemaining(child: views.empty(context))],
///           failed: (error) => [
///             SliverFillRemaining(
///               child: views.error(context, error, controller.load),
///             ),
///           ],
///           ready: (gifts) => [SliverList(...)],
///         ),
///       ],
///     ),
///   ),
/// )
/// ```
///
/// 约定：
/// - `retry` 为 null 时仍会调用显式 / 主题 builder，并把 `null` 传进去；
///   builder 自己决定是否渲染重试按钮。包内默认视图不带按钮。
/// - `sliver*` 默认值是非滚动 Widget；[maybeRefreshingSliver] 可能返回 null
///   （默认不额外加进度，刷新进度由外层 `SmartRefresher` 负责）。
class WAsyncThemeViews {
  const WAsyncThemeViews._(this._theme);

  /// 读取最近的 [WAsyncTheme]；没有时全部回退到包内默认。
  static WAsyncThemeViews of(BuildContext context) {
    return WAsyncThemeViews._(WAsyncTheme.maybeOf(context));
  }

  final WAsyncTheme? _theme;

  WAsyncStrings get _strings => _theme?.strings ?? const WAsyncStrings();

  // ─── 普通视图（WAsyncView）───

  /// 加载中：默认转圈。
  Widget loading(BuildContext context, {WidgetBuilder? explicit}) {
    return explicit?.call(context) ??
        _theme?.loadingBuilder?.call(context) ??
        const Center(child: CircularProgressIndicator());
  }

  /// 空数据：默认使用 `WAsyncStrings.empty`。
  Widget empty(BuildContext context, {WidgetBuilder? explicit}) {
    return explicit?.call(context) ??
        _theme?.emptyBuilder?.call(context) ??
        Center(child: Text(_strings.empty));
  }

  /// 加载失败：默认 [WAsyncErrorView]；没有 retry 时不带按钮。
  Widget error(
    BuildContext context,
    Object error,
    VoidCallback? retry, {
    WAsyncErrorWidgetBuilder? explicit,
  }) {
    return explicit?.call(context, error, retry) ??
        _theme?.errorBuilder?.call(context, error, retry) ??
        WAsyncErrorView(
          error: error,
          onRetry: retry,
          title: _strings.errorTitle,
          retryText: _strings.retry,
        );
  }

  /// 刷新失败但保留旧数据：默认 [WAsyncErrorBanner]。
  Widget errorBanner(
    BuildContext context,
    Object error,
    VoidCallback? retry, {
    WAsyncErrorWidgetBuilder? explicit,
  }) {
    return explicit?.call(context, error, retry) ??
        _theme?.errorBannerBuilder?.call(context, error, retry) ??
        WAsyncErrorBanner(
          error: error,
          onRetry: retry,
          title: _strings.errorTitle,
          retryText: _strings.retry,
        );
  }

  /// 刷新中：默认线性进度条。
  Widget refreshing(BuildContext context, {WidgetBuilder? explicit}) {
    return explicit?.call(context) ??
        _theme?.refreshingBuilder?.call(context) ??
        const LinearProgressIndicator();
  }

  // ─── Sliver 视图（WAsyncStateSliver）───

  /// sliver 加载中：默认转圈（非滚动 Widget）。
  Widget sliverLoading(BuildContext context, {WidgetBuilder? explicit}) {
    return explicit?.call(context) ??
        _theme?.sliverLoadingBuilder?.call(context) ??
        const Center(child: CircularProgressIndicator());
  }

  /// sliver 空数据：默认使用 `WAsyncStrings.empty`（非滚动 Widget）。
  Widget sliverEmpty(BuildContext context, {WidgetBuilder? explicit}) {
    return explicit?.call(context) ??
        _theme?.sliverEmptyBuilder?.call(context) ??
        Center(child: Text(_strings.empty));
  }

  /// sliver 失败：默认 [WAsyncErrorView]；没有 retry 时不带按钮。
  Widget sliverError(
    BuildContext context,
    Object error,
    VoidCallback? retry, {
    WAsyncErrorWidgetBuilder? explicit,
  }) {
    return explicit?.call(context, error, retry) ??
        _theme?.sliverErrorBuilder?.call(context, error, retry) ??
        WAsyncErrorView(
          error: error,
          onRetry: retry,
          title: _strings.errorTitle,
          retryText: _strings.retry,
        );
  }

  /// sliver 刷新失败但有旧数据：默认 [WAsyncErrorBanner]。
  Widget sliverErrorBanner(
    BuildContext context,
    Object error,
    VoidCallback? retry, {
    WAsyncErrorWidgetBuilder? explicit,
  }) {
    return explicit?.call(context, error, retry) ??
        _theme?.sliverErrorBannerBuilder?.call(context, error, retry) ??
        WAsyncErrorBanner(
          error: error,
          onRetry: retry,
          title: _strings.errorTitle,
          retryText: _strings.retry,
        );
  }

  /// sliver 刷新中：默认返回 null（不额外加进度，交给外层 SmartRefresher）。
  Widget? maybeRefreshingSliver(BuildContext context, {WidgetBuilder? explicit}) {
    return (explicit ?? _theme?.refreshingSliverBuilder)?.call(context);
  }
}
