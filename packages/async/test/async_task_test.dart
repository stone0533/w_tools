import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_async/w_tools_async.dart';

WAsyncOptions optionsWith({
  void Function()? start,
  void Function()? end,
  void Function(Object?)? onError,
}) {
  return WAsyncOptions(
    loading: (start == null && end == null) ? null : WAsyncLoading(onStart: start, onEnd: end),
    onError: onError,
  );
}

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
      final options = optionsWith(start: () => startCount++, end: () => endCount++);

      await expectLater(
        WAsync.run<int, int>(
          () async => throw StateError('bug'),
          options: options,
        ),
        throwsStateError,
      );

      expect(startCount, 1);
      expect(endCount, 1);
    });

    // ─── retry ───

    test('retry should retry on error', () async {
      int attempt = 0;
      final result = await WAsync.retry<String, String>(
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

    test('retry 最终失败时 onError 只调用一次', () async {
      var errorCount = 0;
      final result = await WAsync.retry<int, int>(
        () async => throw 'fail',
        onSuccess: (value) => value,
        onError: (_) => errorCount++,
        retryCount: 2,
        retryDelay: Duration.zero,
      );

      expect(result, isNull);
      expect(errorCount, 1);
    });

    test('retry 在重试等待期间取消会立即结束', () async {
      final cancelToken = WCancelToken();
      final stopwatch = Stopwatch()..start();

      final future = WAsync.retry<int, int>(
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

    test('options.onError 仅在未传 onError 时调用', () async {
      var fallbackCount = 0;
      final options = optionsWith(onError: (_) => fallbackCount++);

      await WAsync.run<int, int>(() async => throw 'fail', options: options);
      expect(fallbackCount, 1);

      await WAsync.run<int, int>(
        () async => throw 'fail',
        options: options,
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

    test('retry 不对 onSuccess 异常重试', () async {
      var calls = 0;
      final result = await WAsync.retry<int, int>(
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

    test('retry 不重试编程错误（Error）', () async {
      var attempts = 0;
      Object? reported;
      await expectLater(
        WAsync.retry<int, int>(
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

    test('retry retryCount 为 0 时只执行一次', () async {
      var attempts = 0;
      final result = await WAsync.retry<int, int>(
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

    test('retry 负数参数抛出 ArgumentError', () async {
      await expectLater(
        WAsync.retry<int, int>(() async => 1, retryCount: -1),
        throwsArgumentError,
      );
      await expectLater(
        WAsync.retry<int, int>(
          () async => 1,
          retryDelay: const Duration(seconds: -1),
        ),
        throwsArgumentError,
      );
    });

    test('retry retryIf 返回 false 时不重试', () async {
      var attempts = 0;
      var errorCount = 0;

      final result = await WAsync.retry<int, int>(
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

    test('retry 按 retryIf 过滤后再重试', () async {
      var attempts = 0;

      final result = await WAsync.retry<int, int>(
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

    test('retry 透传 retryIf', () async {
      var attempts = 0;

      final result = await WAsync.retry<int, int>(
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

    // ─── timeout ───

    test('timeout should return null on timeout', () async {
      final result = await WAsync.timeout(
        () async => Future.delayed(const Duration(seconds: 1)),
        const Duration(milliseconds: 100),
      );
      expect(result, null);
    });

    test('timeout should complete within timeout', () async {
      final startTime = DateTime.now();
      await WAsync.timeout(
        () async {
          await Future.delayed(const Duration(milliseconds: 100));
          return 'delayed result';
        },
        const Duration(milliseconds: 200),
      );
      final duration = DateTime.now().difference(startTime);
      expect(duration.inMilliseconds, greaterThanOrEqualTo(100));
    });

    test('timeout 超时后底层任务仍会继续执行', () async {
      var completed = false;

      final result = await WAsync.timeout<int, int>(
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

    test('timeout 等待期间取消会立即返回 null', () async {
      final cancelToken = WCancelToken();
      final stopwatch = Stopwatch()..start();
      var errorCount = 0;

      final future = WAsync.timeout<int, int>(
        () async {
          await Future.delayed(const Duration(seconds: 5));
          return 1;
        },
        const Duration(seconds: 10),
        onError: (_) => errorCount++,
        cancelToken: cancelToken,
      );

      await Future.delayed(const Duration(milliseconds: 50));
      cancelToken.cancel();
      final result = await future;
      stopwatch.stop();

      expect(result, isNull);
      expect(errorCount, 0);
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
    });

    test('timeout 取消后底层任务仍继续执行', () async {
      var completed = false;
      final cancelToken = WCancelToken();

      final future = WAsync.timeout<int, int>(
        () async {
          await Future.delayed(const Duration(milliseconds: 100));
          completed = true;
          return 1;
        },
        const Duration(seconds: 10),
        cancelToken: cancelToken,
      );

      await Future.delayed(const Duration(milliseconds: 20));
      cancelToken.cancel();
      expect(await future, isNull);
      expect(completed, isFalse);

      await Future.delayed(const Duration(milliseconds: 150));
      expect(completed, isTrue);
    });

    test('timeout 负数超时抛出 ArgumentError', () async {
      await expectLater(
        WAsync.timeout<int, int>(
          () async => 1,
          const Duration(seconds: -1),
        ),
        throwsArgumentError,
      );
    });

    // ─── wait ───

    test('wait should return converted results via onSuccess', () async {
      final results = await WAsync.parallel<int, List<int>>(
        [Future.value(1), Future.value(2), Future.value(3)],
        onSuccess: (list) => list,
      );
      expect(results, [1, 2, 3]);
    });

    test('wait should return null when onSuccess not provided', () async {
      final results = await WAsync.parallel([
        Future.value(1),
        Future.value(2),
        Future.value(3),
      ]);
      expect(results, null);
    });

    test('wait eagerError 为 false 时等待全部完成后再上报错误', () async {
      var allCompleted = false;
      var errorCount = 0;

      final result = await WAsync.parallel<int, int>(
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
        WAsync.parallel<int, int>([
          Future.value(1),
          Future<int>.error(StateError('bug')),
        ]),
        throwsStateError,
      );
    });

    test('wait 空集合视为成功空结果并触发 Loading', () async {
      var startCount = 0;
      var endCount = 0;
      final options = optionsWith(start: () => startCount++, end: () => endCount++);

      final result = await WAsync.parallel<int, int>(
        <Future<int>>[],
        options: options,
        onSuccess: (list) => list.length,
      );

      expect(result, 0);
      expect(startCount, 1);
      expect(endCount, 1);
    });

    test('wait 在等待期间取消会立即返回 null', () async {
      final cancelToken = WCancelToken();
      final stopwatch = Stopwatch()..start();
      var errorCount = 0;

      final future = WAsync.parallel<int, int>(
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

    // ─── pool ───

    test('pool should process tasks in batches', () async {
      final results = await WAsync.pool<int, List<int>>(
        [1, 2, 3, 4, 5].map(
          (i) =>
              () async => i,
        ),
        onSuccess: (list) => list,
        concurrency: 2,
      );
      expect(results, [1, 2, 3, 4, 5]);
    });

    test('pool should return null when onSuccess not provided', () async {
      final results = await WAsync.pool(
        [1, 2, 3, 4, 5].map(
          (i) =>
              () async => i,
        ),
        concurrency: 2,
      );
      expect(results, null);
    });

    test('pool 并发数小于 1 时抛出 ArgumentError', () async {
      await expectLater(
        WAsync.pool<int, List<int>>(
          [() async => 1],
          onSuccess: (list) => list,
          concurrency: 0,
        ),
        throwsArgumentError,
      );
    });

    test('pool 真正限制同时在执行的任务数', () async {
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

      final results = await WAsync.pool<int, List<int>>(
        tasks,
        onSuccess: (list) => list,
        concurrency: 3,
      );

      expect(maxRunning, lessThanOrEqualTo(3));
      expect(results, List.generate(10, (i) => i));
    });

    test('pool 任务失败时停止启动新任务并上报一次错误', () async {
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

      final result = await WAsync.pool<int, List<int>>(
        tasks,
        onSuccess: (list) => list,
        onError: (_) => errorCount++,
        concurrency: 2,
      );

      expect(result, isNull);
      expect(errorCount, 1);
      expect(started, lessThan(10));
    });

    test('pool 空任务列表返回空结果', () async {
      final result = await WAsync.pool<int, List<int>>(
        <Future<int> Function()>[],
        onSuccess: (list) => list,
      );

      expect(result, isEmpty);
    });

    test('pool 不吞掉编程错误（Error）', () async {
      await expectLater(
        WAsync.pool<int, int>([
          () async => throw StateError('bug'),
        ]),
        throwsStateError,
      );
    });

    test('pool 取消后不再启动新任务', () async {
      final cancelToken = WCancelToken();
      var secondStarted = false;

      final future = WAsync.pool<int, int>(
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

    test('first 委托执行并返回第一个完成结果', () async {
      final result = await WAsync.first<int, int>(
        [
          Future.delayed(const Duration(milliseconds: 50), () => 1),
          Future.delayed(const Duration(milliseconds: 10), () => 2),
        ],
        onSuccess: (value) => value,
      );
      expect(result, 2);
    });

    test('copyWith 保留未指定的字段，传 null 可清空', () {
      void onError(Object? _) {}
      final options = WAsyncOptions(
        loading: WAsyncLoading(onStart: () {}),
        onError: onError,
      );

      final copy = options.copyWith();
      expect(copy.loading, same(options.loading));
      expect(copy.onError, same(onError));

      final cleared = options.copyWith(loading: null, onError: null);
      expect(cleared.loading, isNull);
      expect(cleared.onError, isNull);
      // 原对象不受影响
      expect(options.loading, isNotNull);
    });

    test('共享 WAsyncLoading 时并发执行只触发一次开始 / 结束', () async {
      var startCount = 0;
      var completeCount = 0;
      final options = optionsWith(start: () => startCount++, end: () => completeCount++);

      final first = WAsync.run<int, int>(
        () async {
          await Future.delayed(const Duration(milliseconds: 50));
          return 1;
        },
        options: options,
        onSuccess: (value) => value,
      );
      final second = WAsync.run<int, int>(
        () async {
          await Future.delayed(const Duration(milliseconds: 200));
          return 2;
        },
        options: options,
        onSuccess: (value) => value,
      );

      expect(startCount, 1);

      await Future.delayed(const Duration(milliseconds: 100));
      expect(completeCount, 0);

      await Future.wait([first, second]);
      expect(completeCount, 1);
    });

    test('顺序执行时每次都触发开始与结束', () async {
      var startCount = 0;
      var completeCount = 0;
      final options = optionsWith(start: () => startCount++, end: () => completeCount++);

      await WAsync.run<int, int>(() async => 1, options: options, onSuccess: (v) => v);
      await WAsync.run<int, int>(() async => 2, options: options, onSuccess: (v) => v);

      expect(startCount, 2);
      expect(completeCount, 2);
    });

    test('不传 loading 时不跟踪加载状态（不再有 showLoading 开关）', () async {
      var startCount = 0;
      var completeCount = 0;
      final options = optionsWith(onError: (_) {});

      expect(options.loading, isNull);

      final result = await WAsync.run<int, int>(
        () async => 1,
        options: options,
        onSuccess: (value) => value,
      );

      expect(result, 1);
      expect(startCount, 0);
      expect(completeCount, 0);
    });

    test('onStart 抛异常时业务仍正常执行', () async {
      final options = WAsyncOptions(
        loading: WAsyncLoading(onStart: () => throw 'loading failed'),
      );

      final result = await WAsync.run<int, int>(
        () async => 1,
        options: options,
        onSuccess: (value) => value,
      );

      expect(result, 1);
    });

    test('已取消的操作不触发加载回调', () async {
      var startCount = 0;
      var completeCount = 0;
      final options = optionsWith(start: () => startCount++, end: () => completeCount++);
      final cancelToken = WCancelToken()..cancel('before start');

      final result = await WAsync.run<int, int>(
        () async => 1,
        options: options,
        onSuccess: (value) => value,
        cancelToken: cancelToken,
      );

      expect(result, isNull);
      expect(startCount, 0);
      expect(completeCount, 0);
    });

    // ─── any ───

    test('any should return first completed result', () async {
      final result = await WAsync.first<int, int>(
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

      final future = WAsync.first<int, int>(
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
      final result = await WAsync.first<int, int>(
        <Future<int>>[],
        onSuccess: (value) => value,
      );
      expect(result, isNull);
    });

    test('first 空集合不触发加载回调', () async {
      var startCount = 0;
      var endCount = 0;
      final options = optionsWith(start: () => startCount++, end: () => endCount++);

      final result = await WAsync.first<int, int>(
        <Future<int>>[],
        options: options,
        onSuccess: (value) => value,
      );

      expect(result, isNull);
      expect(startCount, 0);
      expect(endCount, 0);
    });

    // ─── serial ───

    test('serial should execute in order', () async {
      final executionOrder = <int>[];
      await WAsync.serial([
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

    test('serial should return null when onSuccess not provided', () async {
      final result = await WAsync.serial<int, List<int>>([
        () async => 1,
        () async => 2,
        () async => 3,
      ]);
      expect(result, null);
    });

    test('serial with onSuccess should return collected results', () async {
      final result = await WAsync.serial<int, List<int>>(
        [() async => 1, () async => 2, () async => 3],
        onSuccess: (list) => list,
      );
      expect(result, [1, 2, 3]);
    });

    test('serial 遇错后不再执行后续任务', () async {
      var secondCalled = false;
      var errorCount = 0;

      final result = await WAsync.serial<int, int>(
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

    test('serial 取消会等当前任务结束后返回 null', () async {
      final cancelToken = WCancelToken();
      var completed = false;

      final future = WAsync.serial<int, int>(
        [
          () async {
            await Future.delayed(const Duration(milliseconds: 60));
            completed = true;
            return 1;
          },
        ],
        cancelToken: cancelToken,
      );

      await Future.delayed(const Duration(milliseconds: 10));
      cancelToken.cancel();
      final result = await future;

      expect(result, isNull);
      expect(completed, isTrue);
    });

    test('serial 支持任意 Iterable', () async {
      final result = await WAsync.serial<int, List<int>>(
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
