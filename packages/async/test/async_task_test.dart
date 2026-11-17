import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_async/w_tools_async.dart';

void main() {
  group('WAsyncResult', () {
    test('tryRun 成功返回 WAsyncSuccess', () async {
      final result = await WAsync.tryRun(() async => 42);
      expect(result, isA<WAsyncSuccess<int>>());
      expect((result as WAsyncSuccess<int>).value, 42);
    });

    test('tryRun 失败返回 WAsyncFailure 并回调 onError', () async {
      Object? reported;
      final result = await WAsync.tryRun<int>(
        () async => throw StateError('boom'),
        onError: (e) => reported = e,
      );
      expect(result, isA<WAsyncFailure<int>>());
      expect((result as WAsyncFailure<int>).error, isA<StateError>());
      expect(reported, isA<StateError>());
    });

    test('onError 回调抛错不影响结果', () async {
      final result = await WAsync.tryRun<int>(
        () async => throw Exception('boom'),
        onError: (_) => throw StateError('onError'),
      );
      expect(result, isA<WAsyncFailure<int>>());
    });

    test('result pattern 可解构 isProgrammingError', () async {
      final result = await WAsync.tryRun<int>(() async => throw StateError('x'));
      switch (result) {
        case WAsyncFailure(:final isProgrammingError):
          expect(isProgrammingError, isTrue);
        default:
          fail('expected failure');
      }
    });

    test('无 token 时任务抛 WCancellationException 仍算失败', () async {
      final result = await WAsync.tryRun<int>(
        () async => throw WCancellationException('not a token cancel'),
      );
      expect(result, isA<WAsyncFailure<int>>());
      expect((result as WAsyncFailure<int>).error, isA<WCancellationException>());
    });

    test('WAsyncFailure 能区分编程错误', () async {
      final error = await WAsync.tryRun<int>(() async => throw StateError('bug'));
      final exception = await WAsync.tryRun<int>(() async => throw Exception('api'));
      expect((error as WAsyncFailure<int>).isProgrammingError, isTrue);
      expect((exception as WAsyncFailure<int>).isProgrammingError, isFalse);
    });

    test('tryRun 取消返回 WAsyncCancelled', () async {
      final token = WCancelToken();
      final future = WAsync.tryRun<int>(
        () async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return 1;
        },
        cancelToken: token,
      );
      token.cancel('test');
      expect(await future, isA<WAsyncCancelled<int>>());
    });

    test('取消与失败竞态：Exception 取消优先，Error 保留失败', () async {
      final token = WCancelToken();
      final completer = Completer<int>();
      final future = WAsync.tryRun<int>(
        () => completer.future,
        cancelToken: token,
      );
      completer.completeError(Exception('boom'));
      token.cancel('stop');

      expect(await future, isA<WAsyncCancelled<int>>());

      final errorToken = WCancelToken();
      final errorCompleter = Completer<int>();
      final errorFuture = WAsync.tryRun<int>(
        () => errorCompleter.future,
        cancelToken: errorToken,
      );
      errorCompleter.completeError(StateError('bug'));
      errorToken.cancel('stop');

      expect(await errorFuture, isA<WAsyncFailure<int>>());
    });

    test('run 失败抛异常，取消抛 WCancellationException', () async {
      await expectLater(WAsync.run<int>(() async => throw StateError('x')), throwsStateError);
      final token = WCancelToken()..cancel('stop');
      await expectLater(
        WAsync.run<int>(() async => 1, cancelToken: token),
        throwsA(isA<WCancellationException>()),
      );
    });

    test('run + onError 仍抛（onError 只是通知）', () async {
      var reported = false;
      await expectLater(
        WAsync.run<int>(
          () async => throw StateError('x'),
          onError: (_) => reported = true,
        ),
        throwsStateError,
      );
      expect(reported, isTrue, reason: 'onError 应被调用，但不能吞掉 run 的异常');
    });
  });

  group('onStart / onFinally', () {
    test('run 成功：onStart → task → onFinally', () async {
      final events = <String>[];
      final value = await WAsync.run<int>(
        () async {
          events.add('task');
          return 1;
        },
        onStart: () => events.add('start'),
        onFinally: () => events.add('finally'),
      );
      expect(value, 1);
      expect(events, ['start', 'task', 'finally']);
    });

    test('run 失败：onError 在 onFinally 之前', () async {
      final events = <String>[];
      await expectLater(
        WAsync.run<int>(
          () async {
            events.add('task');
            throw StateError('boom');
          },
          onStart: () => events.add('start'),
          onError: (_) => events.add('error'),
          onFinally: () => events.add('finally'),
        ),
        throwsStateError,
      );
      expect(events, ['start', 'task', 'error', 'finally']);
    });

    test('tryRun 取消仍执行 onFinally', () async {
      final token = WCancelToken();
      final events = <String>[];
      final future = WAsync.tryRun<int>(
        () async {
          events.add('task');
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return 1;
        },
        onStart: () => events.add('start'),
        onFinally: () => events.add('finally'),
        cancelToken: token,
      );
      token.cancel('stop');
      expect(await future, isA<WAsyncCancelled<int>>());
      expect(events, ['start', 'task', 'finally']);
    });

    test('已取消 token 不执行 onStart / onFinally', () async {
      final token = WCancelToken()..cancel('stop');
      final events = <String>[];
      final result = await WAsync.tryRun<int>(
        () async {
          events.add('task');
          return 1;
        },
        onStart: () => events.add('start'),
        onFinally: () => events.add('finally'),
        cancelToken: token,
      );
      expect(result, isA<WAsyncCancelled<int>>());
      expect(events, isEmpty);
    });

    test('回调抛异常不影响结果，onFinally 仍执行', () async {
      final events = <String>[];
      final value = await WAsync.run<int>(
        () async {
          events.add('task');
          return 1;
        },
        onStart: () {
          events.add('start');
          throw StateError('start');
        },
        onFinally: () {
          events.add('finally');
          throw StateError('finally');
        },
      );
      expect(value, 1);
      expect(events, ['start', 'task', 'finally']);
    });
  });

  group('Retry / 超时', () {
    test('retry 成功Retry并返回结果', () async {
      var attempts = 0;
      final value = await WAsync.retry<int>(
        () async {
          attempts++;
          if (attempts < 3) throw Exception('fail');
          return attempts;
        },
        retryCount: 3,
        retryDelay: Duration.zero,
      );
      expect(value, 3);
      expect(attempts, 3);
    });

    test('retry 最终失败抛异常且 onError 只调用一次', () async {
      var errors = 0;
      await expectLater(
        WAsync.retry<int>(
          () async => throw Exception('fail'),
          retryCount: 1,
          retryDelay: Duration.zero,
          onError: (_) => errors++,
        ),
        throwsException,
      );
      expect(errors, 1);
    });

    test('retry 不Retry Error', () async {
      var attempts = 0;
      await expectLater(
        WAsync.retry<int>(
          () async {
            attempts++;
            throw StateError('bug');
          },
          retryCount: 5,
          retryDelay: Duration.zero,
        ),
        throwsStateError,
      );
      expect(attempts, 1);
    });

    test('retry 参数校验', () async {
      await expectLater(WAsync.retry<int>(() async => 1, retryCount: -1), throwsArgumentError);
      await expectLater(
        WAsync.retry<int>(() async => 1, retryDelay: const Duration(seconds: -1)),
        throwsArgumentError,
      );
    });

    test('retry 支持退避构造器与 attempt 观测', () async {
      var calls = 0;
      final attempts = <int>[];
      final errors = <Object>[];
      final delays = <Duration>[];

      final value = await WAsync.retry<int>(
        () async {
          calls++;
          if (calls < 4) throw Exception('fail $calls');
          return calls;
        },
        retryCount: 3,
        retryDelay: const Duration(days: 1),
        retryDelayBuilder: (attempt) {
          delays.add(Duration(milliseconds: attempt));
          return Duration.zero;
        },
        onRetry: (attempt, error, delay) {
          attempts.add(attempt);
          errors.add(error);
        },
      );

      expect(value, 4);
      expect(calls, 4);
      expect(attempts, [1, 2, 3]);
      expect(errors, hasLength(3));
      expect(errors.every((error) => error is Exception), isTrue);
      expect(delays, const [
        Duration(milliseconds: 1),
        Duration(milliseconds: 2),
        Duration(milliseconds: 3),
      ]);
    });

    test('retryDelayBuilder 返回负值抛 ArgumentError', () async {
      await expectLater(
        WAsync.retry<int>(
          () async => throw Exception('fail'),
          retryCount: 1,
          retryDelayBuilder: (_) => const Duration(seconds: -1),
        ),
        throwsArgumentError,
      );
    });

    test('onRetry 抛错不影响重试', () async {
      var calls = 0;
      final value = await WAsync.retry<int>(
        () async {
          calls++;
          if (calls < 2) throw Exception('fail');
          return 1;
        },
        retryCount: 1,
        retryDelay: Duration.zero,
        onRetry: (_, _, _) => throw StateError('callback'),
      );
      expect(value, 1);
    });

    test('retryCount 是重试次数：总尝试 = retryCount + 1', () async {
      var attempts = 0;
      await expectLater(
        WAsync.retry<int>(
          () async {
            attempts++;
            throw Exception('fail');
          },
          retryCount: 2,
          retryDelay: Duration.zero,
        ),
        throwsException,
      );
      expect(attempts, 3);
    });

    test('timeout 超时抛 TimeoutException', () async {
      await expectLater(
        WAsync.timeout<int>(
          () => Future.delayed(const Duration(milliseconds: 100), () => 1),
          const Duration(milliseconds: 10),
        ),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('timeout 负值参数校验', () async {
      await expectLater(
        WAsync.timeout<int>(() async => 1, const Duration(seconds: -1)),
        throwsArgumentError,
      );
    });

    test('timeout 异常包含时长', () async {
      try {
        await WAsync.timeout<int>(
          () => Completer<int>().future,
          const Duration(milliseconds: 5),
        );
        fail('expected timeout');
      } on TimeoutException catch (error) {
        expect(error.duration, const Duration(milliseconds: 5));
      }
    });
  });

  group('settle', () {
    test('保留每个结果与顺序', () async {
      final results = await WAsync.settle<int>([
        () async => 1,
        () async => throw StateError('boom'),
        () async => 3,
      ]);

      expect(results, hasLength(3));
      expect((results[0] as WAsyncSuccess<int>).value, 1);
      expect(results[1], isA<WAsyncFailure<int>>());
      expect((results[2] as WAsyncSuccess<int>).value, 3);
    });

    test('限制并发且保持顺序', () async {
      var active = 0;
      var peak = 0;
      final results = await WAsync.settle<int>(
        List.generate(5, (index) {
          return () async {
            active++;
            if (active > peak) peak = active;
            await Future<void>.delayed(const Duration(milliseconds: 5));
            active--;
            return index;
          };
        }),
        concurrency: 2,
      );

      expect(
        results.map((result) => (result as WAsyncSuccess<int>).value),
        [0, 1, 2, 3, 4],
      );
      expect(peak, lessThanOrEqualTo(2));
    });

    test('取消时返回 Cancelled 而不是整批抛错', () async {
      final token = WCancelToken();
      final never = Completer<int>();
      final future = WAsync.settle<int>(
        [() => never.future, () => never.future],
        cancelToken: token,
      );
      await Future<void>.delayed(Duration.zero);
      token.cancel('stop');

      final results = await future;
      expect(results, hasLength(2));
      expect(results.every((result) => result.isCancelled), isTrue);
    });

    test('空集合返回空列表；并发数非法抛 ArgumentError', () async {
      expect(await WAsync.settle<int>([]), isEmpty);
      await expectLater(
        WAsync.settle<int>([], concurrency: 0),
        throwsArgumentError,
      );
    });

    test('onError 按失败任务逐个通知', () async {
      final errors = <Object>[];
      final results = await WAsync.settle<int>(
        [
          () async => throw Exception('a'),
          () async => 1,
          () async => throw Exception('b'),
        ],
        onError: errors.add,
      );

      expect(results.where((result) => result.isFailure), hasLength(2));
      expect(errors, hasLength(2));
    });
  });

  test('retryIf 返回 false 时只尝试一次', () async {
    var attempts = 0;

    await expectLater(
      WAsync.retry<int>(
        () async {
          attempts++;
          throw Exception('not retryable');
        },
        retryCount: 3,
        retryDelay: Duration.zero,
        retryIf: (_) => false,
      ),
      throwsException,
    );

    expect(attempts, 1);
  });

  group('取消边界', () {
    test('retry 在重试等待期间取消', () async {
      final token = WCancelToken();
      final future = WAsync.retry<int>(
        () async => throw Exception('fail'),
        retryCount: 10,
        retryDelay: const Duration(days: 1),
        cancelToken: token,
      );
      await Future<void>.delayed(Duration.zero);
      token.cancel('stop');
      await expectLater(future, throwsA(isA<WCancellationException>()));
    });

    test('timeout 等待期间取消', () async {
      final token = WCancelToken();
      final completer = Completer<int>();
      final future = WAsync.timeout<int>(
        () => completer.future,
        const Duration(days: 1),
        cancelToken: token,
      );
      await Future<void>.delayed(Duration.zero);
      token.cancel('stop');
      await expectLater(future, throwsA(isA<WCancellationException>()));
    });

    test('settle 等待期间取消', () async {
      final token = WCancelToken();
      final never = Completer<int>();
      final future = WAsync.settle<int>(
        [() => never.future],
        cancelToken: token,
      );
      await Future<void>.delayed(Duration.zero);
      token.cancel('stop');
      final results = await future;
      expect(results.single.isCancelled, isTrue);
    });
  });

  group('WCancelToken 边界', () {
    test('取消后注册监听立即回调', () {
      var reason = Object();
      final token = WCancelToken()..cancel('stop');
      token.addListener((value) => reason = value!);
      expect(reason, 'stop');
    });

    test('异常 toString', () {
      expect(WCancellationException('stop').toString(), contains('stop'));
    });
  });
}
