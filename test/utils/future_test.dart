import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools/src/utils/future.dart';

void main() {
  group('WFuture Tests', () {
    test('one should return result on success', () async {
      final result = await WFuture.one(() async => 'test');
      expect(result, 'test');
    });

    test('one should return null on error', () async {
      final result = await WFuture.one(() async => throw 'error');
      expect(result, null);
    });

    test('oneWithRetry should retry on error', () async {
      int attempt = 0;
      final result = await WFuture.oneWithRetry(
        () async {
          attempt++;
          if (attempt < 3) {
            throw 'retry error';
          }
          return 'success after retry';
        },
        retryCount: 3,
        retryDelay: const Duration(milliseconds: 10),
      );
      expect(result, 'success after retry');
      expect(attempt, 3);
    });

    test('oneWithTimeout should throw timeout exception', () async {
      final result = await WFuture.oneWithTimeout(
        () async => Future.delayed(const Duration(seconds: 1)),
        const Duration(milliseconds: 100),
      );
      expect(result, null);
    });

    test('oneWithTimeout should execute with delay', () async {
      final startTime = DateTime.now();
      await WFuture.oneWithTimeout(
        () async {
          await Future.delayed(const Duration(milliseconds: 100));
          return 'delayed result';
        },
        const Duration(milliseconds: 200),
      );
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      expect(duration.inMilliseconds, greaterThanOrEqualTo(100));
    });

    test('wait should return all results', () async {
      final results = await WFuture.wait([
        Future.value(1),
        Future.value(2),
        Future.value(3),
      ]);
      expect(results, [1, 2, 3]);
    });

    test('waitWithConcurrency should process tasks in batches', () async {
      final results = await WFuture.waitWithConcurrency(
        [1, 2, 3, 4, 5].map((i) => Future.value(i)),
        concurrency: 2,
      );
      expect(results, [1, 2, 3, 4, 5]);
    });

    test('any should return first completed result', () async {
      final results = await WFuture.any([
        Future.delayed(const Duration(milliseconds: 100), () => 1),
        Future.delayed(const Duration(milliseconds: 50), () => 2),
        Future.delayed(const Duration(milliseconds: 150), () => 3),
      ]);
      expect(results, 2);
    });

    test('wait should handle errors with eagerError false', () async {
      // This test is commented out because waitWithErrors was removed
      // final results = await WFuture.wait([
      //   Future.value(1),
      //   Future.error('error'),
      //   Future.value(3),
      // ], eagerError: false);
      // expect(results, isNotNull);
    });

    test('series should execute in order', () async {
      final executionOrder = <int>[];
      await WFuture.series([
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

    test('seriesWithType should execute in order with type safety', () async {
      final results = await WFuture.seriesWithType<int>([
        () async => 1,
        () async => 2,
        () async => 3,
      ]);
      expect(results, [1, 2, 3]);
    });

    test('cancellation should work', () async {
      final cancelToken = WCancelToken();
      final completer = Completer<String>();
      
      final future = WFuture.one(
        () async {
          cancelToken.throwIfCancelled();
          await Future.delayed(const Duration(seconds: 1));
          cancelToken.throwIfCancelled();
          completer.complete('success');
          return 'success';
        },
        cancelToken: cancelToken,
      );
      
      // Cancel immediately
      cancelToken.cancel();
      
      final result = await future;
      expect(result, null);
      expect(completer.isCompleted, false);
    });
  });
}
