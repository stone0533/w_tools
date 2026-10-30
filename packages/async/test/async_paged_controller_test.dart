import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_async/w_tools_async.dart';

void main() {
  group('WAsyncPagedController', () {
    test('refresh 加载第一页并可继续追加', () async {
      final pages = <int, List<int>>{
        1: [1, 2],
        2: [3],
      };
      final controller = WAsyncPagedController<int>(
        (page) async => pages[page] ?? const <int>[],
      );
      addTearDown(controller.dispose);

      await controller.refresh();
      expect(controller.state.value.data, [1, 2]);
      expect(controller.hasMore, isTrue);

      await controller.loadMore();
      expect(controller.state.value.data, [1, 2, 3]);
      expect(controller.hasMore, isTrue);

      await controller.loadMore();
      expect(controller.state.value.data, [1, 2, 3]);
      expect(controller.hasMore, isFalse);
    });

    test('loadMore 初始无数据时回到 refresh', () async {
      var calls = 0;
      final controller = WAsyncPagedController<int>((page) async {
        calls++;
        return const [1];
      });
      addTearDown(controller.dispose);

      await controller.loadMore();
      expect(calls, 1);
      expect(controller.state.value.data, [1]);
    });

    test('loadMore 失败只写 loadMoreError，不清空列表', () async {
      final controller = WAsyncPagedController<int>((page) async {
        if (page == 1) return const [1];
        throw StateError('page failed');
      });
      addTearDown(controller.dispose);

      await controller.refresh();
      await controller.loadMore();

      expect(controller.state.value.data, [1]);
      expect(controller.loadMoreError.value, isA<StateError>());
      expect(controller.isLoadingMore.value, isFalse);
    });

    test('refresh 失败保留旧数据', () async {
      var fail = false;
      final controller = WAsyncPagedController<int>((page) async {
        if (fail) throw StateError('refresh failed');
        return const [1];
      });
      addTearDown(controller.dispose);

      await controller.refresh();
      fail = true;
      await controller.refresh();

      expect(controller.state.value.isFailed, isTrue);
      expect(controller.state.value.data, [1]);
    });

    test('loadMore 期间 isLoadingMore 为 true', () async {
      final page2 = Completer<List<int>>();
      final controller = WAsyncPagedController<int>((page) async {
        if (page == 1) return const [1];
        return page2.future;
      });
      addTearDown(controller.dispose);

      await controller.refresh();
      final loading = controller.loadMore();
      expect(controller.isLoadingMore.value, isTrue);

      page2.complete(const [2]);
      await loading;
      expect(controller.isLoadingMore.value, isFalse);
      expect(controller.state.value.data, [1, 2]);
    });
  });
}
