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

  WAsyncHooks _hooks(WAsyncHooks? hooks, bool disableOnError) {
    final base = hooks ?? this.hooks;
    if (!disableOnError) return base;
    return WAsyncHooks(
      onStart: base.onStart,
      onFinally: base.onFinally,
    );
  }

  Future<T> run<T>(
    Future<T> Function() task, {
    WAsyncHooks? hooks,
    bool disableOnError = false,
    void Function()? onStart,
    void Function(Object error)? onError,
    void Function()? onFinally,
    WCancelToken? cancelToken,
  }) {
    return WAsync.run<T>(
      task,
      hooks: _hooks(hooks, disableOnError),
      onStart: onStart,
      onError: onError,
      onFinally: onFinally,
      cancelToken: cancelToken,
    );
  }

  Future<WAsyncResult<T>> tryRun<T>(
    Future<T> Function() task, {
    WAsyncHooks? hooks,
    bool disableOnError = false,
    void Function()? onStart,
    void Function(Object error)? onError,
    void Function()? onFinally,
    WCancelToken? cancelToken,
  }) {
    return WAsync.tryRun<T>(
      task,
      hooks: _hooks(hooks, disableOnError),
      onStart: onStart,
      onError: onError,
      onFinally: onFinally,
      cancelToken: cancelToken,
    );
  }

  Future<T> retry<T>(
    Future<T> Function() task, {
    WAsyncHooks? hooks,
    bool disableOnError = false,
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
      hooks: _hooks(hooks, disableOnError),
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
    bool disableOnError = false,
    void Function()? onStart,
    void Function(Object error)? onError,
    void Function()? onFinally,
    WCancelToken? cancelToken,
  }) {
    return WAsync.timeout<T>(
      task,
      timeout,
      hooks: _hooks(hooks, disableOnError),
      onStart: onStart,
      onError: onError,
      onFinally: onFinally,
      cancelToken: cancelToken,
    );
  }

  Future<List<WAsyncResult<T>>> tryAll<T>(
    Iterable<Future<T> Function()> tasks, {
    WAsyncHooks? hooks,
    bool disableOnError = false,
    int concurrency = 4,
    void Function()? onStart,
    void Function(Object error)? onError,
    void Function()? onFinally,
    WCancelToken? cancelToken,
  }) {
    return WAsync.tryAll<T>(
      tasks,
      hooks: _hooks(hooks, disableOnError),
      concurrency: concurrency,
      onStart: onStart,
      onError: onError,
      onFinally: onFinally,
      cancelToken: cancelToken,
    );
  }

  /// 旧名称；请改用 [tryAll]。
  ///
  /// remove-in: 9.0.0
  @Deprecated('Use WAsyncExecutor.tryAll')
  Future<List<WAsyncResult<T>>> settle<T>(
    Iterable<Future<T> Function()> tasks, {
    WAsyncHooks? hooks,
    bool disableOnError = false,
    int concurrency = 4,
    void Function()? onStart,
    void Function(Object error)? onError,
    void Function()? onFinally,
    WCancelToken? cancelToken,
  }) {
    return tryAll<T>(
      tasks,
      hooks: hooks,
      disableOnError: disableOnError,
      concurrency: concurrency,
      onStart: onStart,
      onError: onError,
      onFinally: onFinally,
      cancelToken: cancelToken,
    );
  }
}
