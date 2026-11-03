import 'dart:async';

import 'package:flutter/foundation.dart';

import 'async_loading.dart';
import 'cancel_token.dart';

export 'async_loading.dart';
export 'cancel_token.dart';

/// 执行选项（纯数据）。
///
/// 只负责「加载状态怎么合并」与「没传 onError 时的兜底回调」；
/// 不含运行时状态，也没有转发方法——执行入口只有 [WAsync]。
///
/// - 业务异常（`Exception`）会被捕获并通过 onError / [onError] 上报；
/// - 编程错误（`Error`，如 `TypeError` / `StateError`）原样向上抛；
/// - 取消属于正常结束，不回调错误。
@immutable
class WAsyncOptions {
  /// 创建执行选项
  ///
  /// [loading] 需要合并并发加载状态时传入（显式 opt-in），否则不跟踪。
  /// [onError] 只在调用处没有单独传 `onError` 时生效。
  const WAsyncOptions({this.loading, this.onError});

  /// 并发加载状态合并器；为空表示不跟踪加载状态
  final WAsyncLoading? loading;

  /// 兜底错误回调
  final void Function(Object? error)? onError;

  static const Object _unset = Object();

  /// 创建副本；传 `null` 可以清空 `loading` / `onError`
  WAsyncOptions copyWith({
    Object? loading = _unset,
    Object? onError = _unset,
  }) {
    return WAsyncOptions(
      loading: identical(loading, _unset) ? this.loading : loading as WAsyncLoading?,
      onError: identical(onError, _unset) ? this.onError : onError as void Function(Object?)?,
    );
  }
}

/// 异步执行助手。
///
/// 统一处理加载回调、错误回调与协作式取消：业务异常被捕获并通过
/// `onError`（或 [WAsyncOptions.onError]）上报，方法返回 null；
/// 编程错误（`Error`）原样抛出。取消不会中止底层 Future，只让后续检查点提前结束。
/// 参数错误（`concurrency < 1`、负数的 `retryCount` / `retryDelay` / `timeout`）
/// 以失败的 Future 返回 [ArgumentError]。
class WAsync {
  // 纯静态工具类，禁止实例化
  WAsync._();

  /// 执行单个异步操作
  static Future<R?> run<T, R>(
    Future<T> Function() task, {
    WAsyncOptions? options,
    R? Function(T)? onSuccess,
    void Function(Object?)? onError,
    WCancelToken? cancelToken,
  }) {
    return _executeWithLoading<R?>(
      options,
      () async {
        cancelToken?.throwIfCancelled();
        final result = await task();
        cancelToken?.throwIfCancelled();
        return onSuccess?.call(result);
      },
      onError,
      cancelToken: cancelToken,
    );
  }

  /// 执行单个异步操作并支持重试
  ///
  /// 只对 `Exception` 重试，可用 [retryIf] 过滤；取消与 `Error` 不重试。
  /// `onSuccess` 抛出的异常不会触发重试。
  static Future<R?> retry<T, R>(
    Future<T> Function() task, {
    WAsyncOptions? options,
    R? Function(T)? onSuccess,
    void Function(Object?)? onError,
    int retryCount = 3,
    Duration retryDelay = const Duration(seconds: 1),
    bool Function(Object error)? retryIf,
    WCancelToken? cancelToken,
  }) {
    if (retryCount < 0) {
      return Future<R?>.error(
        ArgumentError.value(retryCount, 'retryCount', '重试次数不能为负数'),
      );
    }
    if (retryDelay.isNegative) {
      return Future<R?>.error(
        ArgumentError.value(retryDelay, 'retryDelay', '重试间隔不能为负数'),
      );
    }

    var attempt = 0;

    return _executeWithLoading<R?>(
      options,
      () async {
        late T result;
        while (true) {
          try {
            cancelToken?.throwIfCancelled();
            attempt++;
            result = await task();
            break;
          } catch (e) {
            if (e is WCancellationException || e is Error) rethrow;
            if (attempt <= retryCount && (retryIf?.call(e) ?? true)) {
              await _cancelableDelay(retryDelay, cancelToken);
              continue;
            }
            rethrow;
          }
        }

        cancelToken?.throwIfCancelled();
        return onSuccess?.call(result);
      },
      onError,
      cancelToken: cancelToken,
    );
  }

  /// 执行单个异步操作并支持超时
  ///
  /// 超时只结束本次等待，底层 Future 不会被取消，会以 [TimeoutException] 上报。
  static Future<R?> timeout<T, R>(
    Future<T> Function() task,
    Duration timeout, {
    WAsyncOptions? options,
    R? Function(T)? onSuccess,
    void Function(Object?)? onError,
    WCancelToken? cancelToken,
  }) {
    if (timeout.isNegative) {
      return Future<R?>.error(
        ArgumentError.value(timeout, 'timeout', '超时时间不能为负数'),
      );
    }

    return _executeWithLoading<R?>(
      options,
      () async {
        cancelToken?.throwIfCancelled();
        final timeoutFuture = task().timeout(
          timeout,
          onTimeout: () => throw TimeoutException('Operation timed out'),
        );
        final result = cancelToken == null
            ? await timeoutFuture
            : await _awaitWithCancellation(timeoutFuture, cancelToken);
        cancelToken?.throwIfCancelled();
        return onSuccess?.call(result);
      },
      onError,
      cancelToken: cancelToken,
    );
  }

  /// 等待多个 Future（并行）
  ///
  /// 传入的 Future 在调用时已启动；需要限制并发用 [pool]。
  static Future<R?> parallel<T, R>(
    Iterable<Future<T>> futures, {
    WAsyncOptions? options,
    R? Function(List<T>)? onSuccess,
    void Function(Object?)? onError,
    bool eagerError = true,
    WCancelToken? cancelToken,
  }) {
    return _executeWithLoading<R?>(
      options,
      () async {
        cancelToken?.throwIfCancelled();
        final waitFuture = Future.wait(futures, eagerError: eagerError);
        final results = cancelToken == null
            ? await waitFuture
            : await _awaitWithCancellation(waitFuture, cancelToken);
        cancelToken?.throwIfCancelled();
        return onSuccess?.call(results);
      },
      onError,
      cancelToken: cancelToken,
    );
  }

  /// 按并发上限执行任务工厂（只有槽位可用时才调用工厂）
  ///
  /// 任一任务失败后停止启动新任务，并以第一个错误结束；
  /// 取消不会中止在途任务，会等它们结束后返回 null。
  static Future<R?> pool<T, R>(
    Iterable<Future<T> Function()> tasks, {
    WAsyncOptions? options,
    R? Function(List<T>)? onSuccess,
    void Function(Object?)? onError,
    int concurrency = 4,
    WCancelToken? cancelToken,
  }) {
    if (concurrency < 1) {
      return Future<R?>.error(
        ArgumentError.value(concurrency, 'concurrency', '并发数必须大于 0'),
      );
    }

    final taskList = tasks.toList();
    // 按任务下标占位，保证结果顺序与任务顺序一致
    final results = List<T?>.filled(taskList.length, null);

    return _executeWithLoading<R?>(
      options,
      () async {
        var nextIndex = 0;
        var hasError = false;
        Object? firstError;
        StackTrace? firstStackTrace;

        Future<void> worker() async {
          while (!hasError) {
            final index = nextIndex++;
            if (index >= taskList.length) return;

            try {
              cancelToken?.throwIfCancelled();
              results[index] = await taskList[index]();
            } catch (e, stackTrace) {
              if (!hasError) {
                hasError = true;
                firstError = e;
                firstStackTrace = stackTrace;
              }
              return;
            }
          }
        }

        final workerCount = taskList.length < concurrency ? taskList.length : concurrency;
        await Future.wait(List.generate(workerCount, (_) => worker()));

        if (hasError) {
          Error.throwWithStackTrace(
            firstError ?? StateError('任务执行失败'),
            firstStackTrace ?? StackTrace.current,
          );
        }

        cancelToken?.throwIfCancelled();
        return onSuccess?.call(results.cast<T>());
      },
      onError,
      cancelToken: cancelToken,
    );
  }

  /// 返回最先完成的结果；空集合直接返回 null（不触发 onError）
  static Future<R?> first<T, R>(
    Iterable<Future<T>> futures, {
    WAsyncOptions? options,
    R? Function(T)? onSuccess,
    void Function(Object?)? onError,
    WCancelToken? cancelToken,
  }) {
    final futureList = futures.toList();
    if (futureList.isEmpty) return Future<R?>.value();

    return _executeWithLoading<R?>(
      options,
      () async {
        cancelToken?.throwIfCancelled();
        final anyFuture = Future.any(futureList);
        final result = cancelToken == null
            ? await anyFuture
            : await _awaitWithCancellation(anyFuture, cancelToken);
        cancelToken?.throwIfCancelled();
        return onSuccess?.call(result);
      },
      onError,
      cancelToken: cancelToken,
    );
  }

  /// 按顺序执行；任一任务失败后停止
  static Future<R?> serial<T, R>(
    Iterable<Future<T> Function()> tasks, {
    WAsyncOptions? options,
    R? Function(List<T>)? onSuccess,
    void Function(Object?)? onError,
    WCancelToken? cancelToken,
  }) {
    return _executeWithLoading<R?>(
      options,
      () async {
        final results = <T>[];
        for (final task in tasks) {
          cancelToken?.throwIfCancelled();
          results.add(await task());
        }
        cancelToken?.throwIfCancelled();
        return onSuccess?.call(results);
      },
      onError,
      cancelToken: cancelToken,
    );
  }

  /// 等待 [future] 完成，同时响应取消（内部使用）
  static Future<T> _awaitWithCancellation<T>(
    Future<T> future,
    WCancelToken cancelToken,
  ) async {
    cancelToken.throwIfCancelled();

    final cancelCompleter = Completer<T>();
    void onCancel(Object? _) {
      if (!cancelCompleter.isCompleted) {
        cancelCompleter.completeError(
          WCancellationException(cancelToken.cancelReason),
        );
      }
    }

    cancelToken.addListener(onCancel);
    try {
      // Future.any 会处理两个分支的错误，被放弃的 future 之后报错也不会
      // 变成未处理异常。
      return await Future.any<T>([future, cancelCompleter.future]);
    } finally {
      cancelToken.removeListener(onCancel);
    }
  }

  /// 可被取消的延迟（内部使用）
  static Future<void> _cancelableDelay(Duration delay, WCancelToken? cancelToken) async {
    if (cancelToken == null) {
      await Future.delayed(delay);
      return;
    }

    cancelToken.throwIfCancelled();

    final completer = Completer<void>();
    late final Timer timer;

    void onCancel(Object? _) {
      timer.cancel();
      if (!completer.isCompleted) {
        completer.completeError(WCancellationException(cancelToken.cancelReason));
      }
    }

    timer = Timer(delay, () {
      cancelToken.removeListener(onCancel);
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    cancelToken.addListener(onCancel);
    return completer.future;
  }

  /// 带加载状态的统一执行入口
  static Future<T?> _executeWithLoading<T>(
    WAsyncOptions? options,
    Future<T> Function() executeFunc,
    void Function(Object?)? onError, {
    WCancelToken? cancelToken,
  }) async {
    // 已取消的操作直接结束，避免 loading 回调出现 0→1→0 的闪烁
    if (cancelToken?.isCancelled == true) return null;

    final loading = options?.loading;

    try {
      loading?.begin();
      return await executeFunc();
    } catch (e) {
      // 编程错误不属于业务异常，原样向上抛
      if (e is Error) rethrow;
      // 取消属于正常结束：不回调 onError
      if (e is WCancellationException) return null;

      try {
        onError?.call(e);
      } catch (_) {
        // 忽略错误回调自身的异常
      }

      // 未提供 onError 时改用兜底回调
      if (onError == null) {
        try {
          options?.onError?.call(e);
        } catch (_) {
          // 忽略兜底错误回调自身的异常
        }
      }
      return null;
    } finally {
      loading?.end();
    }
  }
}
