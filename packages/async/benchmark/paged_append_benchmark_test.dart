import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_async/w_tools_async.dart';

/// 手动基准：`flutter test benchmark/paged_append_benchmark_test.dart`
///
/// 不进 CI；用于判断 ASYNC-009 的 O(n²) 是否需要持久化结构。
void main() {
  test('paged append benchmark', () async {
    final elapsed = <String, int>{};
    for (final n in <int>[1000, 10000, 50000, 100000]) {
      for (final pageSize in <int>[20, 50]) {
        final pageCount = (n / pageSize).ceil();
        final pages = List<List<int>>.generate(
          pageCount,
          (page) => List<int>.generate(
            pageSize,
            (index) => page * pageSize + index,
          ),
        );
        final controller = WAsyncPagedController<int>(
          (page) async => page <= pageCount ? pages[page - 1] : const <int>[],
        );

        final watch = Stopwatch()..start();
        await controller.refresh();
        while (controller.hasMore) {
          await controller.loadMore();
        }
        watch.stop();

        final rss = ProcessInfo.currentRss ~/ (1024 * 1024);
        final key = 'N=$n P=$pageSize';
        elapsed[key] = watch.elapsedMilliseconds;
        // ignore: avoid_print
        print('$key ${watch.elapsedMilliseconds}ms rss=${rss}MB');
        controller.dispose();
      }
    }

    // 决策门槛：50k / 100k 的整段追加不应退化到“每页复制全表”。
    expect(elapsed['N=50000 P=20'], lessThan(300));
    expect(elapsed['N=100000 P=20'], lessThan(700));
  }, timeout: const Timeout(Duration(minutes: 5)));
}
