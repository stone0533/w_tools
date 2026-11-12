import 'dart:async';

import 'package:flutter/foundation.dart';

import 'async_theme.dart';

/// 触发一次 retry，并把同步 / 异步失败统一交给 [onRetryError] 或 FlutterError。
///
/// 这是 [WAsyncView] / [WAsyncStateSliver] 的内部实现，不从 barrel 导出。
void fireAsyncRetry({
  required Future<void> Function() retry,
  required String context,
  WAsyncRetryErrorHandler? onRetryError,
}) {
  try {
    unawaited(
      retry().then<void>(
        (_) {},
        onError: (Object error, StackTrace stackTrace) {
          _reportRetryError(
            error,
            stackTrace,
            context: context,
            onRetryError: onRetryError,
          );
        },
      ),
    );
  } catch (error, stackTrace) {
    _reportRetryError(
      error,
      stackTrace,
      context: context,
      onRetryError: onRetryError,
    );
  }
}

void _reportRetryError(
  Object error,
  StackTrace stackTrace, {
  required String context,
  WAsyncRetryErrorHandler? onRetryError,
}) {
  if (onRetryError != null) {
    try {
      onRetryError(error, stackTrace);
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
      context: ErrorDescription(context),
    ),
  );
}
