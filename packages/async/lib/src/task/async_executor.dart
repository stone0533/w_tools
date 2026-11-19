import 'async_task.dart';

/// 携带默认 [WAsyncHooks] 的执行器。
///
/// 在 app composition root 创建一次并注入：
///
/// ```dart
/// final appAsync = WAsyncExecutor(
///   WAsyncHooks(
///     onStart: AppLoading.show,
///     onError: AppToast.error,
///     onFinally: AppLoading.hide,
///   ),
/// );
///
/// await appAsync.run(() => api.save());
/// ```
///
/// 每个方法都允许单次 `hooks` 覆盖；显式 `onStart` / `onError` / `onFinally`
/// 仍然优先。`WAsyncController` / `WAsyncPagedController` 不使用执行器。
class WAsyncExecutor {
  const WAsyncExecutor(this.hooks);

  /// 默认 hooks；不会读取任何全局状态。
  final WAsyncHooks hooks;

  Future<T> run<T>(
    Future<T> Function() task, {
    WAsyncHooks? hooks,
    void Function()? onStart,
    void Function(Object error)? onError,
    void Function()? onFinally,
    WCancelToken? cancelToken,
  }) {
    return WAsync.run<T>(
      task,
      hooks: hooks ?? this.hooks,
      onStart: onStart,
      onError: onError,
      onFinally: onFinally,
      cancelToken: cancelToken,
    );
  }

  Future<WAsyncResult<T>> tryRun<T>(
    Future<T> Function() task, {
    WAsyncHooks? hooks,
    void Function()? onStart,
    void Function(Object error)? onError,
    void Function()? onFinally,
    WCancelToken? cancelToken,
  }) {
    return WAsync.tryRun<T>(
      task,
      hooks: hooks ?? this.hooks,
      onStart: onStart,
      onError: onError,
      onFinally: onFinally,
      cancelToken: cancelToken,
    );
  }

  Future<T> retry<T>(
    Future<T> Function() task, {
    WAsyncHooks? hooks,
    void Function()? onStart,
    void Function(Object error)? onError,
    void Function()? onFinally,
    int retryCount = 3,
    Duration retryDelay = const Duration(seconds: 1),
    Duration Function(int attempt)? retryDelayBuilder,
    void Function(int attempt, Object error, Duration delay)? onRetry,
    bool Function(Object error)? retryIf,
    WCancelToken? cancelToken,
  }) {
    return WAsync.retry<T>(
      task,
      hooks: hooks ?? this.hooks,
      onStart: onStart,
      onError: onError,
      onFinally: onFinally,
      retryCount: retryCount,
      retryDelay: retryDelay,
      retryDelayBuilder: retryDelayBuilder,
      onRetry: onRetry,
      retryIf: retryIf,
      cancelToken: cancelToken,
    );
  }

  Future<T> timeout<T>(
    Future<T> Function() task,
    Duration timeout, {
    WAsyncHooks? hooks,
    void Function()? onStart,
    void Function(Object error)? onError,
    void Function()? onFinally,
    WCancelToken? cancelToken,
  }) {
    return WAsync.timeout<T>(
      task,
      timeout,
      hooks: hooks ?? this.hooks,
      onStart: onStart,
      onError: onError,
      onFinally: onFinally,
      cancelToken: cancelToken,
    );
  }

  Future<List<WAsyncResult<T>>> settle<T>(
    Iterable<Future<T> Function()> tasks, {
    WAsyncHooks? hooks,
    int concurrency = 4,
    void Function()? onStart,
    void Function(Object error)? onError,
    void Function()? onFinally,
    WCancelToken? cancelToken,
  }) {
    return WAsync.settle<T>(
      tasks,
      hooks: hooks ?? this.hooks,
      concurrency: concurrency,
      onStart: onStart,
      onError: onError,
      onFinally: onFinally,
      cancelToken: cancelToken,
    );
  }
}
