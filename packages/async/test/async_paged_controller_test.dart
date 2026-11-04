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

    test('refresh 进行中 loadMore 不追加、不请求第一页', () async {
      final calls = <int>[];
      final pending = Completer<List<int>>();
      final controller = WAsyncPagedController<int>((page) async {
        calls.add(page);
        if (calls.length == 2) return pending.future;
        return const [1, 2];
      });
      addTearDown(controller.dispose);

      await controller.refresh();
      expect(calls, [1]);

      final refreshing = controller.refresh();
      await controller.loadMore();

      // 刷新未完成时 loadMore 直接返回，不会用被重置的 _page 请求第一页
      expect(calls, [1, 1]);
      pending.complete(const [9, 9]);
      await refreshing;
      expect(controller.state.value.data, [9, 9]);
    });

    test('initial.ready 时 loadMore 从下一页开始', () async {
      final calls = <int>[];
      final controller = WAsyncPagedController<int>(
        (page) async {
          calls.add(page);
          return page == 2 ? const [3] : const [1, 2];
        },
        initial: const WAsyncState<List<int>>.ready([1, 2]),
      );
      addTearDown(controller.dispose);

      await controller.loadMore();
      expect(calls, [2]);
      expect(controller.state.value.data, [1, 2, 3]);
    });

    test('initial.ready 为空列表时没有更多，不请求下一页', () async {
      var calls = 0;
      final controller = WAsyncPagedController<int>(
        (page) async {
          calls++;
          return const [1];
        },
        initial: const WAsyncState<List<int>>.ready([]),
      );
      addTearDown(controller.dispose);

      expect(controller.hasMore, isFalse);
      await controller.loadMore();
      expect(calls, 0);
    });

    test('initial.empty 时没有更多，不请求下一页', () async {
      var calls = 0;
      final controller = WAsyncPagedController<int>(
        (page) async {
          calls++;
          return const [1];
        },
        initial: const WAsyncState<List<int>>.empty(),
      );
      addTearDown(controller.dispose);

      expect(controller.hasMore, isFalse);
      await controller.loadMore();
      expect(calls, 0);
    });

    test('refresh 空页进入 empty', () async {
      final controller = WAsyncPagedController<int>((page) async => const []);
      addTearDown(controller.dispose);
      await controller.refresh();
      expect(controller.state.value.isEmpty, isTrue);
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

    test('刷新失败保留旧分页游标，避免 loadMore 重复第一页', () async {
      var fail = false;
      final pages = <int, List<int>>{
        1: [1],
        2: [2],
        3: [3],
      };
      final controller = WAsyncPagedController<int>((page) async {
        if (fail) throw StateError('refresh failed');
        return pages[page] ?? const <int>[];
      });
      addTearDown(controller.dispose);

      await controller.refresh();
      await controller.loadMore();
      expect(controller.state.value.data, [1, 2]);

      fail = true;
      await controller.refresh();
      expect(controller.state.value.isFailed, isTrue);
      expect(controller.state.value.data, [1, 2]);

      fail = false;
      await controller.loadMore();
      expect(controller.state.value.data, [1, 2, 3]);
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

    test('hasMoreListenable 跟随 hasMore 变化', () async {
      final controller = WAsyncPagedController<int>(
        (page) async => page == 1 ? const [1] : const <int>[],
      );
      addTearDown(controller.dispose);
      final seen = <bool>[];
      controller.hasMoreListenable.addListener(() => seen.add(controller.hasMore));

      await controller.refresh();
      await controller.loadMore();

      expect(seen, contains(false));
      expect(controller.hasMoreListenable.value, isFalse);
    });

    test('refresh 会取消在途 loadMore 的 token', () async {
      final loadMoreStarted = Completer<WCancelToken>();
      final page2 = Completer<List<int>>();
      final controller = WAsyncPagedController.withToken((page, token) {
        if (page == 1) return Future.value(const [1]);
        loadMoreStarted.complete(token);
        return page2.future;
      });
      addTearDown(controller.dispose);

      await controller.refresh();
      final loadMore = controller.loadMore();
      final token = await loadMoreStarted.future;

      final refreshing = controller.refresh();
      expect(token.isCancelled, isTrue);

      page2.complete(const [2]);
      await loadMore;
      await refreshing;

      // 在途结果被丢弃，列表只剩刷新后的第一页
      expect(controller.state.value.data, [1]);
    });

    test('dispose 会取消 refresh 的 token', () async {
      WCancelToken? seen;
      final pending = Completer<List<int>>();
      final controller = WAsyncPagedController.withToken((page, token) {
        seen = token;
        return pending.future;
      });

      final loading = controller.refresh();
      controller.dispose();

      expect(seen, isNotNull);
      expect(seen!.isCancelled, isTrue);

      pending.complete(const [1]);
      await loading;
    });

    test('Error 也会回调 options.onError', () async {
      Object? reported;
      final controller = WAsyncPagedController<int>(
        (page) async => throw StateError('bug'),
        options: WAsyncOptions(onError: (error) => reported = error),
      );
      addTearDown(controller.dispose);

      await controller.refresh();

      expect(controller.state.value.isFailed, isTrue);
      expect(reported, isA<StateError>());
    });

    test('initialPage 必须大于 0（release 也校验）', () {
      expect(
        () => WAsyncPagedController<int>(
          (page) async => const <int>[],
          initialPage: 0,
        ),
        throwsArgumentError,
      );
    });

    test('传 options.activity 会触发断言（分页自己管加载状态）', () {
      expect(
        () => WAsyncPagedController<int>(
          (page) async => const <int>[],
          options: WAsyncOptions(activity: WAsyncActivity()),
        ),
        throwsAssertionError,
      );
    });
  });
}
