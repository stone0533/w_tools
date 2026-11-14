import 'dart:async';

import 'async_result.dart';
import 'cancel_token.dart';

export 'async_result.dart';
export 'cancel_token.dart';

/// 异步执行助手。
///
/// 两套入口：
/// - [tryRun] / [settle]：返回 [WAsyncResult]，不抛业务异常；
/// - [run] / [retry] / [timeout]：失败抛异常，取消抛 [WCancellationException]。
///
/// 并发需求直接用 `Future.wait` / `Future.any` / `package:async`；
/// 本包只保留和「多区块页面」直接相关的执行入口。
///
/// 参数错误（`concurrency < 1`、负数的 `retryCount` / `retryDelay` / `timeout`）
/// 以失败的 Future 返回 [ArgumentError]。
class WAsync {
  WAsync._();

  /// 执行单个异步操作并返回结果对象。
  ///
  /// 成功返回 [WAsyncSuccess]；业务异常/编程错误返回 [WAsyncFailure]；
  /// 取消返回 [WAsyncCancelled]。取消不会中止已经开始执行的 Future。
  ///
  /// [onError] 只是失败通知，不会改变返回值；回调自身异常会被忽略。
  ///
  /// 取消与失败在同一轮竞态时，非 [Error] 的失败按取消处理；编程错误仍返回
  /// [WAsyncFailure]，避免把 TypeError / StateError 吞成取消。
  static Future<WAsyncResult<T>> tryRun<T>(
    Future<T> Function() task, {
    void Function(Object error)? onError,
    WCancelToken? cancelToken,
  }) async {
    if (cancelToken?.isCancelled == true) {
      return WAsyncCancelled<T>(cancelToken?.cancelReason);
    }

    try {
      cancelToken?.throwIfCancelled();
      final future = task();
      final result = cancelToken == null
          ? await future
          : await _awaitWithCancellation(future, cancelToken);
      cancelToken?.throwIfCancelled();
      return WAsyncSuccess<T>(result);
    } on WCancellationException catch (e, stackTrace) {
      if (cancelToken?.isCancelled == true) {
        return WAsyncCancelled<T>(e.reason);
      }
      _notifyError(onError, e);
      return WAsyncFailure<T>(e, stackTrace);
    } catch (e, stackTrace) {
      // 任务失败与 token 取消可能在同一轮发生；取消优先，但不吞编程错误。
      if (cancelToken?.isCancelled == true && e is! Error) {
        return WAsyncCancelled<T>(cancelToken?.cancelReason);
      }
      _notifyError(onError, e);
      return WAsyncFailure<T>(e, stackTrace);
    }
  }

  /// 执行并直接返回成功值；失败抛异常，取消失抛 [WCancellationException]。
  ///
  /// [onError] 只是通知，不会吞掉异常；`.then(onSuccess)` 必须同时提供
  /// `onError` / `catchError`，否则会产生 unhandled Future；不需要抛异常的调用方
  /// 改用 [tryRun]。
  static Future<T> run<T>(
    Future<T> Function() task, {
    void Function(Object error)? onError,
    WCancelToken? cancelToken,
  }) async {
    return _unwrap(
      await tryRun<T>(task, onError: onError, cancelToken: cancelToken),
    );
  }

  /// 重试后返回成功值；最终失败抛异常。
  ///
  /// [retryDelayBuilder] 按失败次数（从 1 开始）生成本次重试前的等待时间，
  /// 优先于 [retryDelay]；返回负值时抛 [ArgumentError]。
  /// [onRetry] 在每次等待前通知一次，自身异常会被忽略，不影响重试结果。
  static Future<T> retry<T>(
    Future<T> Function() task, {
    void Function(Object error)? onError,
    int retryCount = 3,
    Duration retryDelay = const Duration(seconds: 1),
    Duration Function(int attempt)? retryDelayBuilder,
    void Function(int attempt, Object error, Duration delay)? onRetry,
    bool Function(Object error)? retryIf,
    WCancelToken? cancelToken,
  }) async {
    if (retryCount < 0) {
      throw ArgumentError.value(retryCount, 'retryCount', '重试次数不能为负数');
    }
    if (retryDelay.isNegative) {
      throw ArgumentError.value(retryDelay, 'retryDelay', '重试间隔不能为负数');
    }
    return _unwrap(
      await tryRun<T>(
        () async {
          var attempt = 0;
          while (true) {
            try {
              cancelToken?.throwIfCancelled();
              attempt++;
              final future = task();
              final result = cancelToken == null
                  ? await future
                  : await _awaitWithCancellation(future, cancelToken);
              cancelToken?.throwIfCancelled();
              return result;
            } catch (e) {
              if (e is WCancellationException || e is Error) rethrow;
              if (attempt <= retryCount && (retryIf?.call(e) ?? true)) {
                final delay = retryDelayBuilder?.call(attempt) ?? retryDelay;
                if (delay.isNegative) {
                  throw ArgumentError.value(
                    delay,
                    'retryDelayBuilder',
                    '重试间隔不能为负数',
                  );
                }
                _notifyRetry(onRetry, attempt, e, delay);
                await _cancelableDelay(delay, cancelToken);
                continue;
              }
              rethrow;
            }
          }
        },
        onError: onError,
        cancelToken: cancelToken,
      ),
    );
  }

  /// 超时后返回成功值；超时抛 [TimeoutException]。
  static Future<T> timeout<T>(
    Future<T> Function() task,
    Duration timeout, {
    void Function(Object error)? onError,
    WCancelToken? cancelToken,
  }) async {
    if (timeout.isNegative) {
      throw ArgumentError.value(timeout, 'timeout', '超时时间不能为负数');
    }
    return _unwrap(
      await tryRun<T>(
        () async {
          cancelToken?.throwIfCancelled();
          final future = task().timeout(
            timeout,
            onTimeout: () => throw TimeoutException(
              'Operation timed out after $timeout',
              timeout,
            ),
          );
          final result = cancelToken == null
              ? await future
              : await _awaitWithCancellation(future, cancelToken);
          cancelToken?.throwIfCancelled();
          return result;
        },
        onError: onError,
        cancelToken: cancelToken,
      ),
    );
  }

  /// 并发执行一组任务工厂，等待全部结束，结果顺序与输入一致。
  ///
  /// 单个任务失败不会让整体抛错，每个任务都以 [WAsyncResult] 返回；
  /// 失败任务会触发一次 [onError]（按失败个数，不是按批次）。
  /// 内部用私有 worker 池限流，默认最多 [concurrency] 个任务同时执行。
  static Future<List<WAsyncResult<T>>> settle<T>(
    Iterable<Future<T> Function()> tasks, {
    int concurrency = 4,
    void Function(Object error)? onError,
    WCancelToken? cancelToken,
  }) async {
    if (concurrency < 1) {
      throw ArgumentError.value(concurrency, 'concurrency', '并发数必须大于 0');
    }

    final taskList = tasks.toList();
    final results = List<WAsyncResult<T>?>.filled(taskList.length, null);
    var nextIndex = 0;

    Future<void> worker() async {
      while (true) {
        final index = nextIndex++;
        if (index >= taskList.length) return;
        results[index] = await tryRun<T>(
          taskList[index],
          onError: onError,
          cancelToken: cancelToken,
        );
      }
    }

    final workerCount = taskList.length < concurrency ? taskList.length : concurrency;
    await Future.wait(List.generate(workerCount, (_) => worker()));
    return results.cast<WAsyncResult<T>>();
  }

  static T _unwrap<T>(WAsyncResult<T> result) {
    return switch (result) {
      WAsyncSuccess<T>(:final value) => value,
      WAsyncFailure<T>(:final error, :final stackTrace) => Error.throwWithStackTrace(
        error,
        stackTrace,
      ),
      WAsyncCancelled<T>(:final reason) => throw WCancellationException(reason),
    };
  }

  static void _notifyError(
    void Function(Object error)? onError,
    Object error,
  ) {
    try {
      onError?.call(error);
    } catch (_) {
      // 错误通知自身异常不影响结果
    }
  }

  static void _notifyRetry(
    void Function(int attempt, Object error, Duration delay)? callback,
    int attempt,
    Object error,
    Duration delay,
  ) {
    if (callback == null) return;
    try {
      callback(attempt, error, delay);
    } catch (_) {
      // 重试观测回调自身异常不影响重试
    }
  }

  /// 等待 [future] 完成，同时响应取消（内部使用）。
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
      return await Future.any<T>([future, cancelCompleter.future]);
    } finally {
      cancelToken.removeListener(onCancel);
    }
  }

  /// 可被取消的延迟（内部使用）。
  static Future<void> _cancelableDelay(
    Duration delay,
    WCancelToken? cancelToken,
  ) async {
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
        completer.completeError(
          WCancellationException(cancelToken.cancelReason),
        );
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
}
