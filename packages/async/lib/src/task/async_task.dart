import 'dart:async';

import 'package:flutter/foundation.dart';

import 'async_activity.dart';
import 'async_result.dart';
import 'cancel_token.dart';

export 'async_activity.dart';
export 'async_result.dart';
export 'cancel_token.dart';

/// 执行选项（纯数据）。
///
/// [activity] 用于合并并发加载状态（显式 opt-in）；[onError] 是失败**通知**回调，
/// 不会吞掉异常。执行结果由 [WAsync.tryRun] / 抛异常入口显式表达，不再用 null 表示失败。
@immutable
class WAsyncOptions {
  const WAsyncOptions({this.activity, this.onError});

  /// 并发活动计数器；为空表示不跟踪加载状态。
  final WAsyncActivity? activity;

  /// 失败通知回调；抛错会被忽略。
  ///
  /// 只是通知，不会改变 [WAsync.run] / [WAsync.map] / [WAsync.retry] /
  /// [WAsync.timeout] 的抛异常语义，也不会让 Future 变成成功。
  /// 调用方仍需 catchError / try-catch，或改用 [WAsync.tryRun]。
  final void Function(Object error)? onError;

  /// 去掉并发活动计数器，保留错误回调。
  WAsyncOptions withoutActivity() => WAsyncOptions(onError: onError);

  /// 去掉错误通知回调，保留并发活动计数器。
  ///
  /// 调用点自己处理错误时用它，避免 `onError` 与调用点重复上报。
  WAsyncOptions withoutOnError() => WAsyncOptions(activity: activity);
}

/// 异步执行助手。
///
/// 两套入口：
/// - [tryRun]：返回 [WAsyncResult]，不抛业务异常；
/// - [run] / [map] / [retry] / [timeout] / [parallel] / [pool] / [first] / [serial]：
///   失败抛异常，取消抛 [WCancellationException]。
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
  /// 取消与失败在同一轮竞态时，非 [Error] 的失败按取消处理；编程错误仍返回
  /// [WAsyncFailure]，避免把 TypeError / StateError 吞成取消。
  static Future<WAsyncResult<T>> tryRun<T>(
    Future<T> Function() task, {
    WAsyncOptions? options,
    WCancelToken? cancelToken,
  }) async {
    if (cancelToken?.isCancelled == true) {
      return WAsyncCancelled<T>(cancelToken?.cancelReason);
    }

    final activity = options?.activity;
    activity?.begin();
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
      _notifyError(options, e);
      return WAsyncFailure<T>(e, stackTrace);
    } catch (e, stackTrace) {
      // 任务失败与 token 取消可能在同一轮发生；取消优先，但不吞编程错误。
      if (cancelToken?.isCancelled == true && e is! Error) {
        return WAsyncCancelled<T>(cancelToken?.cancelReason);
      }
      _notifyError(options, e);
      return WAsyncFailure<T>(e, stackTrace);
    } finally {
      activity?.end();
    }
  }

  /// 执行并直接返回成功值；失败抛异常，取消失抛 [WCancellationException]。
  ///
  /// [options] 里的 [WAsyncOptions.onError] 只是通知，不会吞掉异常；
  /// `.then(onSuccess)` 必须同时提供 `onError` / `catchError`，否则会产生
  /// unhandled Future；不需要抛异常的调用方改用 [tryRun]。
  static Future<T> run<T>(
    Future<T> Function() task, {
    WAsyncOptions? options,
    WCancelToken? cancelToken,
  }) async {
    return _unwrap(
      await tryRun<T>(task, options: options, cancelToken: cancelToken),
    );
  }

  /// 执行并映射成功值；失败/取消按 [run] 的规则抛出。
  static Future<R> map<T, R>(
    Future<T> Function() task, {
    required R Function(T value) onSuccess,
    WAsyncOptions? options,
    WCancelToken? cancelToken,
  }) async {
    return onSuccess(
      await run<T>(task, options: options, cancelToken: cancelToken),
    );
  }

  /// 重试后返回成功值；最终失败抛异常。
  ///
  /// [retryDelayBuilder] 按失败次数（从 1 开始）生成本次重试前的等待时间，
  /// 优先于 [retryDelay]；返回负值时抛 [ArgumentError]。
  /// [onRetry] 在每次等待前通知一次，自身异常会被忽略，不影响重试结果。
  static Future<T> retry<T>(
    Future<T> Function() task, {
    WAsyncOptions? options,
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
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  /// 超时后返回成功值；超时抛 [TimeoutException]。
  static Future<T> timeout<T>(
    Future<T> Function() task,
    Duration timeout, {
    WAsyncOptions? options,
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
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  /// 等待多个 Future（并行）；结果顺序与输入一致。
  static Future<List<T>> parallel<T>(
    Iterable<Future<T>> futures, {
    WAsyncOptions? options,
    bool eagerError = true,
    WCancelToken? cancelToken,
  }) async {
    return _unwrap(
      await tryRun<List<T>>(
        () async {
          cancelToken?.throwIfCancelled();
          final waitFuture = Future.wait(futures, eagerError: eagerError);
          final results = cancelToken == null
              ? await waitFuture
              : await _awaitWithCancellation(waitFuture, cancelToken);
          cancelToken?.throwIfCancelled();
          return results;
        },
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  /// 并发执行一组任务工厂，等待全部结束，结果顺序与输入一致。
  ///
  /// 与 [parallel] 的 all-or-nothing 不同：单个任务失败不会让整体抛错，
  /// 每个任务都以 [WAsyncResult] 返回，适合首页多个互相独立的区块。
  /// 内部用 [pool] 限流，默认最多 [concurrency] 个任务同时执行。
  ///
  /// [options] 会传给每个任务；共享的 `activity` 按并发活动计数
  /// （0→1 / 1→0），与 [parallel] 一致。需要逐任务计数请在每个任务里自行统计。
  static Future<List<WAsyncResult<T>>> settle<T>(
    Iterable<Future<T> Function()> tasks, {
    int concurrency = 4,
    WAsyncOptions? options,
    WCancelToken? cancelToken,
  }) {
    return pool<WAsyncResult<T>>(
      tasks.map(
        (task) =>
            () => tryRun<T>(
              task,
              options: options,
              cancelToken: cancelToken,
            ),
      ),
      concurrency: concurrency,
    );
  }

  /// 按并发上限执行任务工厂；结果顺序与任务顺序一致。
  static Future<List<T>> pool<T>(
    Iterable<Future<T> Function()> tasks, {
    WAsyncOptions? options,
    int concurrency = 4,
    WCancelToken? cancelToken,
  }) async {
    if (concurrency < 1) {
      throw ArgumentError.value(concurrency, 'concurrency', '并发数必须大于 0');
    }

    final taskList = tasks.toList();
    return _unwrap(
      await tryRun<List<T>>(
        () async {
          final results = List<T?>.filled(taskList.length, null);
          var nextIndex = 0;
          Object? firstError;
          StackTrace? firstStackTrace;
          var hasError = false;

          Future<void> worker() async {
            while (!hasError) {
              final index = nextIndex++;
              if (index >= taskList.length) return;
              try {
                cancelToken?.throwIfCancelled();
                final future = taskList[index]();
                results[index] = cancelToken == null
                    ? await future
                    : await _awaitWithCancellation(future, cancelToken);
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
            Error.throwWithStackTrace(firstError!, firstStackTrace!);
          }
          cancelToken?.throwIfCancelled();
          return results.cast<T>();
        },
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  /// 返回最先完成的结果；空集合抛 [StateError]。
  static Future<T> first<T>(
    Iterable<Future<T>> futures, {
    WAsyncOptions? options,
    WCancelToken? cancelToken,
  }) async {
    final futureList = futures.toList();
    if (futureList.isEmpty) {
      throw StateError('first 至少需要一个 Future');
    }
    return _unwrap(
      await tryRun<T>(
        () async {
          cancelToken?.throwIfCancelled();
          final anyFuture = Future.any(futureList);
          final result = cancelToken == null
              ? await anyFuture
              : await _awaitWithCancellation(anyFuture, cancelToken);
          cancelToken?.throwIfCancelled();
          return result;
        },
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  /// 按顺序执行；任一任务失败后停止。
  static Future<List<T>> serial<T>(
    Iterable<Future<T> Function()> tasks, {
    WAsyncOptions? options,
    WCancelToken? cancelToken,
  }) async {
    return _unwrap(
      await tryRun<List<T>>(
        () async {
          final results = <T>[];
          for (final task in tasks) {
            cancelToken?.throwIfCancelled();
            final future = task();
            results.add(
              cancelToken == null
                  ? await future
                  : await _awaitWithCancellation(future, cancelToken),
            );
          }
          cancelToken?.throwIfCancelled();
          return results;
        },
        options: options,
        cancelToken: cancelToken,
      ),
    );
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

  static void _notifyError(WAsyncOptions? options, Object error) {
    try {
      options?.onError?.call(error);
    } catch (_) {
      // 错误回调自身异常不影响结果
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
