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
        options: WAsyncOptions(onError: (e) => reported = e),
      );
      expect(result, isA<WAsyncFailure<int>>());
      expect((result as WAsyncFailure<int>).error, isA<StateError>());
      expect(reported, isA<StateError>());
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

    test('run 失败抛异常，取消抛 WCancellationException', () async {
      await expectLater(WAsync.run<int>(() async => throw StateError('x')), throwsStateError);
      final token = WCancelToken()..cancel('stop');
      await expectLater(
        WAsync.run<int>(() async => 1, cancelToken: token),
        throwsA(isA<WCancellationException>()),
      );
    });

    test('map 映射成功值', () async {
      expect(await WAsync.map<int, String>(() async => 2, onSuccess: (v) => 'v=$v'), 'v=2');
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
          options: WAsyncOptions(onError: (_) => errors++),
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

    test('timeout 超时抛 TimeoutException', () async {
      await expectLater(
        WAsync.timeout<int>(
          () => Future.delayed(const Duration(milliseconds: 100), () => 1),
          const Duration(milliseconds: 10),
        ),
        throwsA(isA<TimeoutException>()),
      );
    });
  });

  group('组合执行', () {
    test('parallel 保持顺序', () async {
      expect(
        await WAsync.parallel<int>([
          Future.value(1),
          Future.value(2),
          Future.value(3),
        ]),
        [1, 2, 3],
      );
    });

    test('pool 限制并发并保持顺序', () async {
      var active = 0;
      var peak = 0;
      final values = await WAsync.pool<int>(
        List.generate(
          5,
          (i) => () async {
            active++;
            peak = active > peak ? active : peak;
            await Future<void>.delayed(const Duration(milliseconds: 10));
            active--;
            return i;
          },
        ),
        concurrency: 2,
      );
      expect(values, [0, 1, 2, 3, 4]);
      expect(peak, lessThanOrEqualTo(2));
      await expectLater(WAsync.pool<int>([], concurrency: 0), throwsArgumentError);
    });

    test('first 返回最先完成的结果，空集合抛错', () async {
      expect(await WAsync.first<int>([Future.value(1), Future.value(2)]), anyOf(1, 2));
      await expectLater(WAsync.first<int>([]), throwsStateError);
    });

    test('serial 顺序执行', () async {
      final values = await WAsync.serial<int>([
        () async => 1,
        () async => 2,
        () async => 3,
      ]);
      expect(values, [1, 2, 3]);
    });
  });

  group('WAsyncActivity', () {
    test('并发活动只触发一次开始 / 结束', () async {
      var starts = 0;
      var ends = 0;
      final activity = WAsyncActivity(
        onStart: () => starts++,
        onEnd: () => ends++,
      );
      final options = WAsyncOptions(activity: activity);
      await Future.wait([
        WAsync.run<int>(() async => 1, options: options),
        WAsync.run<int>(() async => 2, options: options),
      ]);
      expect(starts, 1);
      expect(ends, 1);
      expect(activity.isLoading, isFalse);
    });

    test('withoutActivity 保留 onError', () {
      final options = WAsyncOptions(
        activity: WAsyncActivity(),
        onError: (_) {},
      );
      final copy = options.withoutActivity();
      expect(copy.activity, isNull);
      expect(copy.onError, same(options.onError));
    });
  });
}
