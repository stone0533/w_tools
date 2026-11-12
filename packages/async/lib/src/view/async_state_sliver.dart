import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../state/async_state.dart';
import 'async_retry.dart';
import 'async_theme.dart';
import 'async_theme_views.dart';

/// 把 [WAsyncState] 渲染成 sliver：
///
/// - ready → [readySliverBuilder]；
/// - loading / empty / failed（无数据）→ [SliverFillRemaining]；
/// - failed + 旧数据 → [WAsyncErrorBanner]（列表上方）+ ready sliver；
/// - refreshing + 旧数据 → ready sliver；如需额外进度，显式传
///   [refreshingSliverBuilder]。默认不添加进度条，避免和 SmartRefresher
///   自带的刷新指示器重复。
///
/// 始终返回同一个 [SliverMainAxisGroup]，并用固定首槽保证 failed + 旧数据 /
/// refreshing 切换时 ready 子树不被重建。
/// [readySliverBuilder] 必须返回 sliver（例如 `SliverList`），不能返回 box。
///
/// loading / empty / error 的默认值来自 `WAsyncTheme` 的 `sliver*Builder`；这些 builder 必须返回非滚动内容。
///
/// 没有重试入口时（[onRetry] 为 null）[errorBuilder] / [errorBannerBuilder] 仍会收到
/// `null` 的 retry，由 builder 决定是否渲染按钮；包内默认视图不带按钮。
class WAsyncStateSliver<T> extends StatelessWidget {
  const WAsyncStateSliver({
    super.key,
    required this.state,
    required this.readySliverBuilder,
    this.onRetry,
    this.onRetryError,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.errorBannerBuilder,
    this.refreshingSliverBuilder,
    this.hasScrollBody = false,
  });

  final ValueListenable<WAsyncState<T>> state;
  final Widget Function(BuildContext context, T data) readySliverBuilder;
  final Future<void> Function()? onRetry;

  /// retry 失败时的观测出口；不传时走 `FlutterError.reportError`。
  final WAsyncRetryErrorHandler? onRetryError;
  final WidgetBuilder? loadingBuilder;
  final WidgetBuilder? emptyBuilder;
  final WAsyncErrorWidgetBuilder? errorBuilder;
  final WAsyncErrorWidgetBuilder? errorBannerBuilder;
  final WidgetBuilder? refreshingSliverBuilder;
  final bool hasScrollBody;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<WAsyncState<T>>(
      valueListenable: state,
      builder: (context, value, _) => _buildSlivers(context, value),
    );
  }

  void _fireRetry() {
    fireAsyncRetry(
      retry: onRetry!,
      onRetryError: onRetryError,
      context: 'while retrying WAsyncStateSliver',
    );
  }

  Widget _buildSlivers(BuildContext context, WAsyncState<T> value) {
    final data = value.data;
    final views = WAsyncThemeViews.of(context);
    final slivers = <Widget>[];
    // 没有重试入口时传 null；builder 自己决定是否渲染按钮。
    final VoidCallback? retry = onRetry == null ? null : _fireRetry;

    if (value.isReady) {
      // ready 的 data 允许为 null（T 可空），不能再用 data != null 判 ready
      slivers.add(_emptySlot());
      slivers.add(readySliverBuilder(context, value.data as T));
    } else if (data != null) {
      // 固定首槽：banner 出现 / 消失时 ready 子树仍在同一位置，不会被重建。
      slivers.add(
        value.isFailed
            ? SliverToBoxAdapter(
                child: views.sliverErrorBanner(
                  context,
                  value.error!,
                  retry,
                  explicit: errorBannerBuilder,
                ),
              )
            : _emptySlot(),
      );
      slivers.add(readySliverBuilder(context, data));

      if (value.isRefreshing) {
        final refreshing = views.maybeRefreshingSliver(
          context,
          explicit: refreshingSliverBuilder,
        );
        if (refreshing != null) slivers.add(refreshing);
      }
    } else {
      final Widget child;
      if (value.isLoading) {
        child = views.sliverLoading(context, explicit: loadingBuilder);
      } else if (value.isEmpty) {
        child = views.sliverEmpty(context, explicit: emptyBuilder);
      } else {
        // data 为 null 且不是 loading / empty / ready，只剩 failed。
        child = views.sliverError(
          context,
          value.error!,
          retry,
          explicit: errorBuilder,
        );
      }
      slivers.add(
        SliverFillRemaining(hasScrollBody: hasScrollBody, child: child),
      );
    }

    return SliverMainAxisGroup(slivers: slivers);
  }

  Widget _emptySlot() => const SliverToBoxAdapter(child: SizedBox.shrink());
}
