import 'package:flutter/material.dart';

import '../state/async_state.dart';
import 'async_error_banner.dart';
import 'async_error_view.dart';
import 'async_view_defaults.dart';

/// 把 [WAsyncState] 渲染成 sliver：
///
/// - ready → [readySliverBuilder]；
/// - loading / empty / failed（无数据）→ [SliverFillRemaining]；
/// - failed + 旧数据 → ready sliver + [WAsyncErrorBanner]；
/// - refreshing + 旧数据 → ready sliver；如需额外进度，显式传
///   [refreshingSliverBuilder]。默认不添加进度条，避免和 SmartRefresher
///   自带的刷新指示器重复。
///
/// 始终返回同一个 [SliverMainAxisGroup]，避免状态切换重建 ready 子树。
/// [readySliverBuilder] 必须返回 sliver（例如 `SliverList`），不能返回 box。
class WAsyncStateSliver<T> extends StatelessWidget {
  const WAsyncStateSliver({
    super.key,
    required this.state,
    required this.readySliverBuilder,
    required this.onRetry,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.errorBannerBuilder,
    this.refreshingSliverBuilder,
    this.hasScrollBody = false,
  });

  final WAsyncState<T> state;
  final Widget Function(BuildContext context, T data) readySliverBuilder;
  final VoidCallback onRetry;
  final WidgetBuilder? loadingBuilder;
  final WidgetBuilder? emptyBuilder;
  final WAsyncErrorWidgetBuilder? errorBuilder;
  final WAsyncErrorWidgetBuilder? errorBannerBuilder;
  final WidgetBuilder? refreshingSliverBuilder;
  final bool hasScrollBody;

  @override
  Widget build(BuildContext context) {
    final data = state.dataOrNull;
    final slivers = <Widget>[];

    if (data != null) {
      slivers.add(readySliverBuilder(context, data));

      if (state.isRefreshing && refreshingSliverBuilder != null) {
        slivers.add(refreshingSliverBuilder!(context));
      }

      if (state.isFailed) {
        final banner = errorBannerBuilder ?? _defaultErrorBannerBuilder;
        slivers.add(
          SliverToBoxAdapter(
            child: banner(context, state.error!, onRetry),
          ),
        );
      }
    } else if (state.isReady) {
      slivers.add(const SliverToBoxAdapter(child: SizedBox.shrink()));
    } else {
      slivers.add(
        SliverFillRemaining(
          hasScrollBody: hasScrollBody,
          child: switch (state.status) {
            WAsyncStatus.loading =>
              loadingBuilder?.call(context) ?? const Center(child: CircularProgressIndicator()),
            WAsyncStatus.empty => emptyBuilder?.call(context) ?? const Center(child: Text('暂无数据')),
            WAsyncStatus.failed => errorBuilder?.call(context, state.error!, onRetry) ??
                WAsyncErrorView(
                  error: state.error!,
                  onRetry: onRetry,
                ),
            WAsyncStatus.ready => const SizedBox.shrink(),
          },
        ),
      );
    }

    return SliverMainAxisGroup(slivers: slivers);
  }

  static Widget _defaultErrorBannerBuilder(
    BuildContext context,
    Object error,
    VoidCallback onRetry,
  ) {
    return WAsyncErrorBanner(
      error: error,
      onRetry: onRetry,
    );
  }
}
