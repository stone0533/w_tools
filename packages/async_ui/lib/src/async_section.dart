import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:w_tools_async/w_tools_async.dart';

/// 业务页面单区块的规范入口。
///
/// 内部使用 [WAsyncView]：
/// - loading / empty / error / errorBanner / refreshing 默认走 `WAsyncTheme`；
/// - 需要设计稿口径时，可传对应的 per-block builder；
/// - [onRetry] 默认接 [WAsyncController.load]，失败态默认有恢复入口。
///
/// [controller] 由页面持有；请在页面 `initState` / `onInit` 调 `controller.load()`，
/// 并在 dispose / onClose 调 `controller.dispose()`。
class WAsyncSection<T> extends StatelessWidget {
  const WAsyncSection({
    super.key,
    required this.controller,
    required this.builder,
    this.onRetry,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.errorBannerBuilder,
    this.refreshingBuilder,
  });

  final WAsyncController<T> controller;
  final Widget Function(BuildContext context, T data) builder;

  /// 自定义重试回调；为 null 时使用 [WAsyncController.load]。
  final VoidCallback? onRetry;
  final WidgetBuilder? loadingBuilder;
  final WidgetBuilder? emptyBuilder;
  final WAsyncErrorWidgetBuilder? errorBuilder;
  final WAsyncErrorWidgetBuilder? errorBannerBuilder;
  final WidgetBuilder? refreshingBuilder;

  @override
  Widget build(BuildContext context) {
    return WAsyncView<T>(
      state: controller.state,
      onRetry: onRetry ?? () => unawaited(controller.load()),
      readyBuilder: builder,
      loadingBuilder: loadingBuilder,
      emptyBuilder: emptyBuilder,
      errorBuilder: errorBuilder,
      errorBannerBuilder: errorBannerBuilder,
      refreshingBuilder: refreshingBuilder,
    );
  }
}
