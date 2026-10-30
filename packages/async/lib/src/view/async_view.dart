import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../state/async_state.dart';
import 'async_error_view.dart';
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
  });

  final ValueListenable<WAsyncState<T>> state;
  final Future<void> Function() onRetry;
  final Widget Function(BuildContext context, T data) readyBuilder;
  final WidgetBuilder? loadingBuilder;
  final WidgetBuilder? emptyBuilder;
  final WAsyncErrorWidgetBuilder? errorBuilder;

  /// failed + 旧数据时的紧凑错误条构建器。
  final WAsyncErrorWidgetBuilder? errorBannerBuilder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<WAsyncState<T>>(
      valueListenable: state,
      builder: (context, value, _) {
        final defaults = WAsyncViewDefaults.maybeOf(context);
        final data = value.dataOrNull;

        if (data != null && value.isRefreshing) {
          return SizedBox(
            width: double.infinity,
            child: Stack(
              children: [
                readyBuilder(context, data),
                const Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: LinearProgressIndicator(),
                ),
              ],
            ),
          );
        }

        if (data != null && value.isFailed) {
          final error =
              errorBannerBuilder ?? defaults?.errorBannerBuilder ?? _defaultErrorBannerBuilder;
          return SizedBox(
            width: double.infinity,
            child: Stack(
              children: [
                readyBuilder(context, data),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: error(
                    context,
                    value.error!,
                    () => onRetry(),
                  ),
                ),
              ],
            ),
          );
        }

        return value.when(
          loading: () =>
              (loadingBuilder ?? defaults?.loadingBuilder)?.call(context) ??
              _defaultLoadingBuilder(context),
          ready: (data) => readyBuilder(context, data),
          empty: () =>
              (emptyBuilder ?? defaults?.emptyBuilder)?.call(context) ??
              _defaultEmptyBuilder(context),
          failed: (error) => (errorBuilder ?? defaults?.errorBuilder ?? _defaultErrorBuilder)(
            context,
            error,
            () => onRetry(),
          ),
        );
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
    return WAsyncErrorView(
      error: error,
      onRetry: onRetry,
      compact: true,
    );
  }
}
