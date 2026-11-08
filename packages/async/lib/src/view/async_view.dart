import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../state/async_state.dart';
import 'async_theme.dart';
import 'async_theme_views.dart';

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
/// [WAsyncTheme] 或显式 builder 覆盖。
///
/// [WAsyncView] 适合页面主体、Column 或 ListView item；
/// 为错误条/刷新条约束有界宽度，不强制高度。
///
/// [onRetry] 由调用方负责处理异常；推荐直接传 `WAsyncController.load`。
/// 为 null 时 [errorBuilder] / [errorBannerBuilder] 仍会收到 `null` 的 retry，
/// 由 builder 决定是否渲染按钮；包内默认视图不带按钮。
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
    this.onRetry,
    this.onRetryError,
    required this.readyBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.errorBannerBuilder,
    this.refreshingBuilder,
  });

  final ValueListenable<WAsyncState<T>> state;

  /// 重试回调；为 null 时错误态不渲染重试按钮。
  final Future<void> Function()? onRetry;

  /// retry 失败时的观测出口；不传时走 `FlutterError.reportError`。
  final WAsyncRetryErrorHandler? onRetryError;
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
        final views = WAsyncThemeViews.of(context);
        final data = value.data;

        if (data != null && value.isRefreshing) {
          return _buildContent(
            context,
            data: data,
            overlay: Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: views.refreshing(context, explicit: refreshingBuilder),
            ),
          );
        }

        if (data != null && value.isFailed) {
          return _buildContent(
            context,
            data: data,
            overlay: Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: views.errorBanner(
                context,
                value.error!,
                _retry(),
                explicit: errorBannerBuilder,
              ),
            ),
          );
        }

        return value.when(
          loading: () => views.loading(context, explicit: loadingBuilder),
          ready: (data) => _buildContent(context, data: data),
          empty: () => views.empty(context, explicit: emptyBuilder),
          failed: (error) => views.error(
            context,
            error,
            _retry(),
            explicit: errorBuilder,
          ),
        );
      },
    );
  }

  /// 把异步重试包装成安全的 VoidCallback；没有 retry 时返回 null。
  VoidCallback? _retry() {
    final retry = onRetry;
    if (retry == null) return null;
    return () => _fireRetry(retry);
  }

  void _fireRetry(Future<void> Function() retry) {
    try {
      unawaited(
        retry().then<void>(
          (_) {},
          onError: _reportRetryError,
        ),
      );
    } catch (error, stackTrace) {
      _reportRetryError(error, stackTrace);
    }
  }

  void _reportRetryError(Object error, StackTrace stackTrace) {
    final handler = onRetryError;
    if (handler != null) {
      try {
        handler(error, stackTrace);
      } catch (_) {
        // 观测回调自身异常不破坏 UI
      }
      return;
    }
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'w_tools_async',
        context: ErrorDescription('while retrying WAsyncView'),
      ),
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
}
