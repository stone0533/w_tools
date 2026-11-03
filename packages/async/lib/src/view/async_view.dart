import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../state/async_state.dart';
import 'async_error_banner.dart';
import 'async_error_view.dart';
import 'async_theme.dart';
import 'async_view_defaults.dart';

/// 四态异步视图。
///
/// - loading：默认转圈；
/// - ready：调用 [readyBuilder]；
/// - empty：默认「暂无数据」；
/// - failed：默认 [WAsyncErrorView]，并通过 [onRetry] 重试；
/// - failed + 旧数据：保留内容，展示紧凑错误条；
/// - refreshing：保留内容，展示线性进度。
///
/// 默认 loading / empty / error 文案只是 fallback；正式项目应通过
/// [WAsyncViewDefaults] 或显式 builder 覆盖。
///
/// [WAsyncView] 适合页面主体、Column 或 ListView item；
/// 为错误条/刷新条约束有界宽度，不强制高度。
///
/// [onRetry] 由调用方负责处理异常；推荐直接传 `WAsyncController.load`。
///
/// [readyBuilder] 返回内容本身；需要 `SmartRefresher` / `RefreshIndicator`
/// 时，把滚动组件放进 [readyBuilder] 内部，不要包在 [WAsyncView] 外面。
///
/// ready / refreshing / failed + 旧数据共用同一层内容容器，
/// 状态切换不会重建 `readyBuilder` 的子树。
class WAsyncView<T> extends StatelessWidget {
  const WAsyncView({
    super.key,
    required this.state,
    required this.onRetry,
    required this.readyBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.errorBannerBuilder,
    this.refreshingBuilder,
  });

  final ValueListenable<WAsyncState<T>> state;
  final Future<void> Function() onRetry;
  final Widget Function(BuildContext context, T data) readyBuilder;
  final WidgetBuilder? loadingBuilder;
  final WidgetBuilder? emptyBuilder;
  final WAsyncErrorWidgetBuilder? errorBuilder;

  /// failed + 旧数据时的紧凑错误条构建器。
  final WAsyncErrorWidgetBuilder? errorBannerBuilder;

  /// refreshing 时的进度指示器；默认 [LinearProgressIndicator]。
  final WidgetBuilder? refreshingBuilder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<WAsyncState<T>>(
      valueListenable: state,
      builder: (context, value, _) {
        final theme = WAsyncTheme.maybeOf(context);
        // ignore: deprecated_member_use_from_same_package
        final legacy = WAsyncViewDefaults.maybeOf(context);
        final data = value.dataOrNull;

        if (data != null && value.isRefreshing) {
          final indicator = (refreshingBuilder ?? theme?.refreshingBuilder ?? legacy?.refreshingBuilder)?.call(context) ??
              const LinearProgressIndicator();

          return _buildContent(
            context,
            data: data,
            overlay: Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: indicator,
            ),
          );
        }

        if (data != null && value.isFailed) {
          final error =
              errorBannerBuilder ??
                  theme?.errorBannerBuilder ??
                  legacy?.errorBannerBuilder ??
                  _defaultErrorBannerBuilder;
          return _buildContent(
            context,
            data: data,
            overlay: Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: error(
                context,
                value.error!,
                () => onRetry(),
              ),
            ),
          );
        }

        return value.when(
          loading: () =>
              (loadingBuilder ?? theme?.loadingBuilder ?? legacy?.loadingBuilder)?.call(context) ??
              _defaultLoadingBuilder(context),
          ready: (data) => _buildContent(context, data: data),
          empty: () =>
              (emptyBuilder ?? theme?.emptyBuilder ?? legacy?.emptyBuilder)?.call(context) ??
              _defaultEmptyBuilder(context),
          failed: (error) => (errorBuilder ??
                  theme?.errorBuilder ??
                  legacy?.errorBuilder ??
                  _defaultErrorBuilder)(
            context,
            error,
            () => onRetry(),
          ),
        );
      },
    );
  }

  /// ready / refreshing / failed+data 都使用同一层 Stack，
  /// 避免 SmartRefresher 等 readyBuilder 子树在状态切换时被重新挂载。
  ///
  /// 只约束有界宽度，不强制高度；滚动组件的高度由页面父级决定。
  Widget _buildContent(
    BuildContext context, {
    required T data,
    Widget? overlay,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = Stack(
          children: [
            readyBuilder(context, data),
            if (overlay != null) overlay,
          ],
        );

        if (!constraints.hasBoundedWidth) return stack;
        return SizedBox(width: constraints.maxWidth, child: stack);
      },
    );
  }

  static Widget _defaultLoadingBuilder(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }

  static Widget _defaultEmptyBuilder(BuildContext context) {
    return const Center(child: Text('暂无数据'));
  }

  static Widget _defaultErrorBuilder(
    BuildContext context,
    Object error,
    VoidCallback onRetry,
  ) {
    return WAsyncErrorView(
      error: error,
      onRetry: onRetry,
    );
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
