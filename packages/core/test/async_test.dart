import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_core/src/utils/async_task.dart';

void main() {
  group('WAsync Tests', () {
    // ─── run ───

    test('run should return converted result via onSuccess', () async {
      final result = await WAsync.run<String, int>(
        () async => 'test',
        onSuccess: (s) => s.length,
      );
      expect(result, 4);
    });

    test('run should return null when onSuccess not provided', () async {
      // 不传 onSuccess，返回 null 是设计行为
      final result = await WAsync.run(() async => 'test');
      expect(result, null);
    });

    test('run should return null on error', () async {
      final result = await WAsync.run(() async => throw 'error');
      expect(result, null);
    });

    test('run should return null on cancellation', () async {
      final cancelToken = WCancelToken();
      final future = WAsync.run(
        () async {
          cancelToken.throwIfCancelled();
          await Future.delayed(const Duration(seconds: 1));
          return 'success';
        },
        cancelToken: cancelToken,
      );
      cancelToken.cancel();
      final result = await future;
      expect(result, null);
    });

    test('run 遇到编程错误（Error）时向上抛出且不上报 onError', () async {
      Object? reported;
      await expectLater(
        WAsync.run<int, int>(
          () async => throw StateError('bug'),
          onError: (e) => reported = e,
        ),
        throwsStateError,
      );
      expect(reported, isNull);
    });

    test('Error 向上抛出时仍会结束 loading', () async {
      var startCount = 0;
      var endCount = 0;
      final config = WAsyncConfig(
        onLoadingStart: () => startCount++,
        onLoadingEnd: () => endCount++,
      );

      await expectLater(
        WAsync.run<int, int>(
          () async => throw StateError('bug'),
          config: config,
        ),
        throwsStateError,
      );

      expect(startCount, 1);
      expect(endCount, 1);
    });

    // ─── runWithRetry ───

    test('runWithRetry should retry on error', () async {
      int attempt = 0;
      final result = await WAsync.runWithRetry<String, String>(
        () async {
          attempt++;
          if (attempt < 3) {
            throw 'retry error';
          }
          return 'success after retry';
        },
        onSuccess: (r) => r,
        retryCount: 3,
        retryDelay: const Duration(milliseconds: 10),
      );
      expect(result, 'success after retry');
      expect(attempt, 3);
    });

    test('runWithRetry 最终失败时 onError 只调用一次', () async {
      var errorCount = 0;
      final result = await WAsync.runWithRetry<int, int>(
        () async => throw 'fail',
        onSuccess: (value) => value,
        onError: (_) => errorCount++,
        retryCount: 2,
        retryDelay: Duration.zero,
      );

      expect(result, isNull);
      expect(errorCount, 1);
    });

    test('runWithRetry 在重试等待期间取消会立即结束', () async {
      final cancelToken = WCancelToken();
      final stopwatch = Stopwatch()..start();

      final future = WAsync.runWithRetry<int, int>(
        () async => throw 'fail',
        onSuccess: (value) => value,
        retryCount: 3,
        retryDelay: const Duration(seconds: 5),
        cancelToken: cancelToken,
      );

      await Future.delayed(const Duration(milliseconds: 50));
      cancelToken.cancel();
      final result = await future;
      stopwatch.stop();

      expect(result, isNull);
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
    });

    test('onError 抛异常时仍返回 null', () async {
      final result = await WAsync.run<int, int>(
        () async => throw 'fail',
        onSuccess: (value) => value,
        onError: (_) => throw 'onError failed',
      );
      expect(result, isNull);
    });

    test('fallbackOnError 仅在未传 onError 时调用', () async {
      var fallbackCount = 0;
      final config = WAsyncConfig(
        showLoading: false,
        fallbackOnError: (_) => fallbackCount++,
      );

      await config.run<int, int>(() async => throw 'fail');
      expect(fallbackCount, 1);

      await config.run<int, int>(
        () async => throw 'fail',
        onError: (_) {},
      );
      expect(fallbackCount, 1);
    });

    test('onSuccess 抛出 Error 时向上抛出', () async {
      await expectLater(
        WAsync.run<int, int>(
          () async => 1,
          onSuccess: (_) => throw StateError('bug'),
        ),
        throwsStateError,
      );
    });

    test('runWithRetry 不对 onSuccess 异常重试', () async {
      var calls = 0;
      final result = await WAsync.runWithRetry<int, int>(
        () async {
          calls++;
          return 1;
        },
        onSuccess: (_) => throw 'map failed',
        retryCount: 3,
        retryDelay: Duration.zero,
      );

      expect(result, isNull);
      expect(calls, 1);
    });

    test('runWithRetry 不重试编程错误（Error）', () async {
      var attempts = 0;
      Object? reported;
      await expectLater(
        WAsync.runWithRetry<int, int>(
          () async {
            attempts++;
            throw StateError('bug');
          },
          onError: (e) => reported = e,
          retryCount: 3,
          retryDelay: Duration.zero,
        ),
        throwsStateError,
      );

      expect(attempts, 1);
      expect(reported, isNull);
    });

    test('runWithRetry retryCount 为 0 时只执行一次', () async {
      var attempts = 0;
      final result = await WAsync.runWithRetry<int, int>(
        () async {
          attempts++;
          throw 'fail';
        },
        retryCount: 0,
        retryDelay: Duration.zero,
      );

      expect(result, isNull);
      expect(attempts, 1);
    });

    test('runWithRetry 负数参数抛出 ArgumentError', () async {
      await expectLater(
        WAsync.runWithRetry<int, int>(() async => 1, retryCount: -1),
        throwsArgumentError,
      );
      await expectLater(
        WAsync.runWithRetry<int, int>(
          () async => 1,
          retryDelay: const Duration(seconds: -1),
        ),
        throwsArgumentError,
      );
    });

    test('runWithRetry retryIf 返回 false 时不重试', () async {
      var attempts = 0;
      var errorCount = 0;

      final result = await WAsync.runWithRetry<int, int>(
        () async {
          attempts++;
          throw const FormatException('fatal');
        },
        onSuccess: (value) => value,
        onError: (_) => errorCount++,
        retryCount: 3,
        retryDelay: Duration.zero,
        retryIf: (_) => false,
      );

      expect(result, isNull);
      expect(attempts, 1);
      expect(errorCount, 1);
    });

    test('runWithRetry 按 retryIf 过滤后再重试', () async {
      var attempts = 0;

      final result = await WAsync.runWithRetry<int, int>(
        () async {
          attempts++;
          if (attempts == 1) {
            throw const FormatException('retry me');
          }
          return 1;
        },
        onSuccess: (value) => value,
        retryCount: 3,
        retryDelay: Duration.zero,
        retryIf: (error) => error is FormatException,
      );

      expect(result, 1);
      expect(attempts, 2);
    });

    test('WAsyncConfig.runWithRetry 透传 retryIf', () async {
      var attempts = 0;
      final config = WAsyncConfig(showLoading: false);

      final result = await config.runWithRetry<int, int>(
        () async {
          attempts++;
          throw const FormatException('fatal');
        },
        retryCount: 3,
        retryDelay: Duration.zero,
        retryIf: (_) => false,
      );

      expect(result, isNull);
      expect(attempts, 1);
    });

    // ─── runWithTimeout ───

    test('runWithTimeout should return null on timeout', () async {
      final result = await WAsync.runWithTimeout(
        () async => Future.delayed(const Duration(seconds: 1)),
        const Duration(milliseconds: 100),
      );
      expect(result, null);
    });

    test('runWithTimeout should complete within timeout', () async {
      final startTime = DateTime.now();
      await WAsync.runWithTimeout(
        () async {
          await Future.delayed(const Duration(milliseconds: 100));
          return 'delayed result';
        },
        const Duration(milliseconds: 200),
      );
      final duration = DateTime.now().difference(startTime);
      expect(duration.inMilliseconds, greaterThanOrEqualTo(100));
    });

    test('runWithTimeout 超时后底层任务仍会继续执行', () async {
      var completed = false;

      final result = await WAsync.runWithTimeout<int, int>(
        () async {
          await Future.delayed(const Duration(milliseconds: 100));
          completed = true;
          return 1;
        },
        const Duration(milliseconds: 50),
        onSuccess: (value) => value,
      );

      expect(result, isNull);
      expect(completed, isFalse);

      await Future.delayed(const Duration(milliseconds: 100));
      expect(completed, isTrue);
    });

    test('runWithTimeout 负数超时抛出 ArgumentError', () async {
      await expectLater(
        WAsync.runWithTimeout<int, int>(
          () async => 1,
          const Duration(seconds: -1),
        ),
        throwsArgumentError,
      );
    });

    // ─── wait ───

    test('wait should return converted results via onSuccess', () async {
      final results = await WAsync.wait<int, List<int>>(
        [Future.value(1), Future.value(2), Future.value(3)],
        onSuccess: (list) => list,
      );
      expect(results, [1, 2, 3]);
    });

    test('wait should return null when onSuccess not provided', () async {
      final results = await WAsync.wait([
        Future.value(1),
        Future.value(2),
        Future.value(3),
      ]);
      expect(results, null);
    });

    test('wait eagerError 为 false 时等待全部完成后再上报错误', () async {
      var allCompleted = false;
      var errorCount = 0;

      final result = await WAsync.wait<int, int>(
        [
          Future.value(1),
          Future<int>.error('fail'),
          Future.delayed(const Duration(milliseconds: 50), () {
            allCompleted = true;
            return 3;
          }),
        ],
        onSuccess: (list) => list.length,
        onError: (_) => errorCount++,
        eagerError: false,
      );

      expect(result, isNull);
      expect(errorCount, 1);
      expect(allCompleted, isTrue);
    });

    test('wait 遇到编程错误（Error）时向上抛出', () async {
      await expectLater(
        WAsync.wait<int, int>([
          Future.value(1),
          Future<int>.error(StateError('bug')),
        ]),
        throwsStateError,
      );
    });

    test('wait 在等待期间取消会立即返回 null', () async {
      final cancelToken = WCancelToken();
      final stopwatch = Stopwatch()..start();
      var errorCount = 0;

      final future = WAsync.wait<int, int>(
        [Future.delayed(const Duration(milliseconds: 300), () => 1)],
        onError: (_) => errorCount++,
        cancelToken: cancelToken,
      );

      await Future.delayed(const Duration(milliseconds: 50));
      cancelToken.cancel();
      final result = await future;
      stopwatch.stop();

      expect(result, isNull);
      expect(errorCount, 0);
      expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 250)));
    });

    // ─── runAllWithConcurrency ───

    test('runAllWithConcurrency should process tasks in batches', () async {
      final results = await WAsync.runAllWithConcurrency<int, List<int>>(
        [1, 2, 3, 4, 5].map(
          (i) =>
              () async => i,
        ),
        onSuccess: (list) => list,
        concurrency: 2,
      );
      expect(results, [1, 2, 3, 4, 5]);
    });

    test('runAllWithConcurrency should return null when onSuccess not provided', () async {
      final results = await WAsync.runAllWithConcurrency(
        [1, 2, 3, 4, 5].map(
          (i) =>
              () async => i,
        ),
        concurrency: 2,
      );
      expect(results, null);
    });

    test('runAllWithConcurrency 并发数小于 1 时抛出 ArgumentError', () async {
      await expectLater(
        WAsync.runAllWithConcurrency<int, List<int>>(
          [() async => 1],
          onSuccess: (list) => list,
          concurrency: 0,
        ),
        throwsArgumentError,
      );
    });

    test('runAllWithConcurrency 真正限制同时在执行的任务数', () async {
      var running = 0;
      var maxRunning = 0;

      final tasks = List.generate(10, (i) {
        return () async {
          running++;
          if (running > maxRunning) {
            maxRunning = running;
          }
          await Future.delayed(const Duration(milliseconds: 20));
          running--;
          return i;
        };
      });

      final results = await WAsync.runAllWithConcurrency<int, List<int>>(
        tasks,
        onSuccess: (list) => list,
        concurrency: 3,
      );

      expect(maxRunning, lessThanOrEqualTo(3));
      expect(results, List.generate(10, (i) => i));
    });

    test('runAllWithConcurrency 任务失败时停止启动新任务并上报一次错误', () async {
      var started = 0;
      var errorCount = 0;

      final tasks = List.generate(10, (i) {
        return () async {
          started++;
          if (i == 1) {
            throw 'task failed';
          }
          await Future.delayed(const Duration(milliseconds: 10));
          return i;
        };
      });

      final result = await WAsync.runAllWithConcurrency<int, List<int>>(
        tasks,
        onSuccess: (list) => list,
        onError: (_) => errorCount++,
        concurrency: 2,
      );

      expect(result, isNull);
      expect(errorCount, 1);
      expect(started, lessThan(10));
    });

    test('runAllWithConcurrency 空任务列表返回空结果', () async {
      final result = await WAsync.runAllWithConcurrency<int, List<int>>(
        <Future<int> Function()>[],
        onSuccess: (list) => list,
      );

      expect(result, isEmpty);
    });

    test('runAllWithConcurrency 不吞掉编程错误（Error）', () async {
      await expectLater(
        WAsync.runAllWithConcurrency<int, int>([
          () async => throw StateError('bug'),
        ]),
        throwsStateError,
      );
    });

    test('runAllWithConcurrency 取消后不再启动新任务', () async {
      final cancelToken = WCancelToken();
      var secondStarted = false;

      final future = WAsync.runAllWithConcurrency<int, int>(
        [
          () async {
            await Future.delayed(const Duration(milliseconds: 100));
            return 1;
          },
          () async {
            secondStarted = true;
            return 2;
          },
        ],
        concurrency: 1,
        cancelToken: cancelToken,
      );

      await Future.delayed(const Duration(milliseconds: 20));
      cancelToken.cancel();
      final result = await future;

      expect(result, isNull);
      expect(secondStarted, isFalse);
    });

    test('WAsyncConfig.any 委托执行并返回第一个完成结果', () async {
      final config = WAsyncConfig(showLoading: false);
      final result = await config.any<int, int>(
        [
          Future.delayed(const Duration(milliseconds: 50), () => 1),
          Future.delayed(const Duration(milliseconds: 10), () => 2),
        ],
        onSuccess: (value) => value,
      );
      expect(result, 2);
    });

    test('WAsyncConfig.copyWith 保留未指定的回调', () {
      void onStart() {}
      final config = WAsyncConfig(onLoadingStart: onStart);
      final copy = config.copyWith(showLoading: false);

      expect(copy.showLoading, isFalse);
      expect(copy.onLoadingStart, same(onStart));
      expect(copy.onLoadingEnd, isNull);
      expect(copy.fallbackOnError, isNull);
    });

    test('WAsyncConfig 并发执行时合并加载状态', () async {
      var startCount = 0;
      var completeCount = 0;
      final config = WAsyncConfig(
        onLoadingStart: () => startCount++,
        onLoadingEnd: () => completeCount++,
      );

      final first = config.run<int, int>(
        () async {
          await Future.delayed(const Duration(milliseconds: 50));
          return 1;
        },
        onSuccess: (value) => value,
      );
      final second = config.run<int, int>(
        () async {
          await Future.delayed(const Duration(milliseconds: 200));
          return 2;
        },
        onSuccess: (value) => value,
      );

      // 两个操作共享同一个 config，开始回调只触发一次
      expect(startCount, 1);

      await Future.delayed(const Duration(milliseconds: 100));
      // 第一个已结束，但第二个仍在执行，完成回调不应触发
      expect(completeCount, 0);

      await Future.wait([first, second]);
      expect(completeCount, 1);
    });

    test('WAsyncConfig 顺序执行时每次都触发开始与结束', () async {
      var startCount = 0;
      var completeCount = 0;
      final config = WAsyncConfig(
        onLoadingStart: () => startCount++,
        onLoadingEnd: () => completeCount++,
      );

      await config.run<int, int>(() async => 1, onSuccess: (value) => value);
      await config.run<int, int>(() async => 2, onSuccess: (value) => value);

      expect(startCount, 2);
      expect(completeCount, 2);
    });

    test('WAsyncConfig.showLoading 为 false 时不触发加载回调', () async {
      var startCount = 0;
      var completeCount = 0;
      final config = WAsyncConfig(
        showLoading: false,
        onLoadingStart: () => startCount++,
        onLoadingEnd: () => completeCount++,
      );

      await config.run<int, int>(() async => 1, onSuccess: (value) => value);

      expect(startCount, 0);
      expect(completeCount, 0);
    });

    test('onLoadingStart 抛异常时业务仍正常执行', () async {
      final config = WAsyncConfig(onLoadingStart: () => throw 'loading failed');

      final result = await config.run<int, int>(
        () async => 1,
        onSuccess: (value) => value,
      );

      expect(result, 1);
    });

    test('已取消的操作不触发加载回调', () async {
      var startCount = 0;
      var completeCount = 0;
      final config = WAsyncConfig(
        onLoadingStart: () => startCount++,
        onLoadingEnd: () => completeCount++,
      );
      final cancelToken = WCancelToken()..cancel('before start');

      final result = await config.run<int, int>(
        () async => 1,
        onSuccess: (value) => value,
        cancelToken: cancelToken,
      );

      expect(result, isNull);
      expect(startCount, 0);
      expect(completeCount, 0);
    });

    // ─── any ───

    test('any should return first completed result', () async {
      final result = await WAsync.any<int, int>(
        [
          Future.delayed(const Duration(milliseconds: 100), () => 1),
          Future.delayed(const Duration(milliseconds: 50), () => 2),
          Future.delayed(const Duration(milliseconds: 150), () => 3),
        ],
        onSuccess: (r) => r,
      );
      expect(result, 2);
    });

    test('any 在等待期间取消会立即返回 null', () async {
      final cancelToken = WCancelToken();
      final stopwatch = Stopwatch()..start();
      var errorCount = 0;

      final future = WAsync.any<int, int>(
        [Future.delayed(const Duration(milliseconds: 300), () => 1)],
        onError: (_) => errorCount++,
        cancelToken: cancelToken,
      );

      await Future.delayed(const Duration(milliseconds: 50));
      cancelToken.cancel();
      final result = await future;
      stopwatch.stop();

      expect(result, isNull);
      expect(errorCount, 0);
      expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 250)));
    });

    test('any 空集合返回 null', () async {
      final result = await WAsync.any<int, int>(
        <Future<int>>[],
        onSuccess: (value) => value,
      );
      expect(result, isNull);
    });

    test('any 空集合不触发加载回调', () async {
      var startCount = 0;
      var endCount = 0;
      final config = WAsyncConfig(
        onLoadingStart: () => startCount++,
        onLoadingEnd: () => endCount++,
      );

      final result = await config.any<int, int>(
        <Future<int>>[],
        onSuccess: (value) => value,
      );

      expect(result, isNull);
      expect(startCount, 0);
      expect(endCount, 0);
    });

    // ─── sequence ───

    test('sequence should execute in order', () async {
      final executionOrder = <int>[];
      await WAsync.sequence([
        () async {
          await Future.delayed(const Duration(milliseconds: 50));
          executionOrder.add(1);
          return 1;
        },
        () async {
          await Future.delayed(const Duration(milliseconds: 30));
          executionOrder.add(2);
          return 2;
        },
        () async {
          await Future.delayed(const Duration(milliseconds: 10));
          executionOrder.add(3);
          return 3;
        },
      ]);
      expect(executionOrder, [1, 2, 3]);
    });

    test('sequence should return null when onSuccess not provided', () async {
      final result = await WAsync.sequence<int, List<int>>([
        () async => 1,
        () async => 2,
        () async => 3,
      ]);
      expect(result, null);
    });

    test('sequence with onSuccess should return collected results', () async {
      final result = await WAsync.sequence<int, List<int>>(
        [() async => 1, () async => 2, () async => 3],
        onSuccess: (list) => list,
      );
      expect(result, [1, 2, 3]);
    });

    test('sequence 遇错后不再执行后续任务', () async {
      var secondCalled = false;
      var errorCount = 0;

      final result = await WAsync.sequence<int, int>(
        [
          () async => throw 'fail',
          () async {
            secondCalled = true;
            return 2;
          },
        ],
        onError: (_) => errorCount++,
      );

      expect(result, isNull);
      expect(secondCalled, isFalse);
      expect(errorCount, 1);
    });

    test('sequence 支持任意 Iterable', () async {
      final result = await WAsync.sequence<int, List<int>>(
        {1, 2, 3}.map(
          (i) =>
              () async => i,
        ),
        onSuccess: (list) => list,
      );
      expect(result, [1, 2, 3]);
    });
  });

  group('WCancelToken', () {
    test('取消后注册的回调立即以取消原因执行', () {
      final token = WCancelToken();
      dynamic received;

      token.cancel('timeout');
      token.addListener((reason) => received = reason);

      expect(received, 'timeout');
    });

    test('取消时允许回调内部移除监听', () {
      final token = WCancelToken();
      late void Function(dynamic) callback;
      callback = (reason) => token.removeListener(callback);

      token.addListener(callback);
      expect(() => token.cancel(), returnsNormally);
    });

    test('clearListeners 不影响取消状态', () {
      final token = WCancelToken();
      token.addListener((_) {});
      token.clearListeners();

      expect(token.isCancelled, isFalse);
    });
  });
}
