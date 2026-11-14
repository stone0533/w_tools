import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../state/async_state.dart';
import 'async_theme.dart';
import 'async_theme_views.dart';

/// 把 [WAsyncState] 渲染成 sliver：
///
/// - ready → [readySliverBuilder]；
/// - loading / empty / failed（无数据）→ [SliverFillRemaining]；
/// - failed + 旧数据 → [WAsyncErrorBanner]（列表上方）+ ready sliver；
/// - refreshing + 旧数据 → ready sliver；刷新进度由外层 `SmartRefresher` 负责。
///
/// 始终返回同一个 [SliverMainAxisGroup]，并用固定首槽保证 failed + 旧数据 /
/// refreshing 切换时 ready 子树不被重建。
/// [readySliverBuilder] 必须返回 sliver（例如 `SliverList`），不能返回 box。
///
/// loading / empty / error 的默认值来自 `WAsyncTheme` 的普通 builder；这些
/// builder 返回普通 Widget（不是 sliver），本组件会自己包 `SliverFillRemaining`。
///
/// 没有重试入口时（[onRetry] 为 null）[errorBuilder] / [errorBannerBuilder] 仍会收到
/// `null` 的 retry，由 builder 决定是否渲染按钮；包内默认视图不带按钮。
class WAsyncStateSliver<T> extends StatelessWidget {
  const WAsyncStateSliver({
    super.key,
    required this.state,
    required this.readySliverBuilder,
    this.onRetry,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.errorBannerBuilder,
    this.hasScrollBody = false,
  });

  final ValueListenable<WAsyncState<T>> state;
  final Widget Function(BuildContext context, T data) readySliverBuilder;
  final VoidCallback? onRetry;
  final WidgetBuilder? loadingBuilder;
  final WidgetBuilder? emptyBuilder;
  final WAsyncErrorWidgetBuilder? errorBuilder;
  final WAsyncErrorWidgetBuilder? errorBannerBuilder;
  final bool hasScrollBody;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<WAsyncState<T>>(
      valueListenable: state,
      builder: (context, value, _) => _buildSlivers(context, value),
    );
  }

  Widget _buildSlivers(BuildContext context, WAsyncState<T> value) {
    final data = value.data;
    final views = WAsyncThemeViews.of(context);
    final slivers = <Widget>[];

    if (value.isReady) {
      // ready 的 data 允许为 null（T 可空），不能再用 data != null 判 ready
      slivers.add(_emptySlot());
      slivers.add(readySliverBuilder(context, value.data as T));
    } else if (data != null) {
      // 固定首槽：banner 出现 / 消失时 ready 子树仍在同一位置，不会被重建。
      slivers.add(
        value.isFailed
            ? SliverToBoxAdapter(
                child: views.errorBanner(
                  context,
                  value.error!,
                  onRetry,
                  explicit: errorBannerBuilder,
                ),
              )
            : _emptySlot(),
      );
      slivers.add(readySliverBuilder(context, data));
    } else {
      final Widget child;
      if (value.isLoading) {
        child = views.loading(context, explicit: loadingBuilder);
      } else if (value.isEmpty) {
        child = views.empty(context, explicit: emptyBuilder);
      } else {
        // data 为 null 且不是 loading / empty / ready，只剩 failed。
        child = views.error(
          context,
          value.error!,
          onRetry,
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
