import 'dart:async';
import 'dart:convert';

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

    test('withPage 首屏不足一页：hasMore=false，不再请求第二页', () async {
      final calls = <int>[];
      final controller = WAsyncPagedController<int>.withPage((page) async {
        calls.add(page);
        return const WAsyncPage(items: [1, 2, 3], hasMore: false);
      });
      addTearDown(controller.dispose);

      await controller.refresh();
      expect(controller.state.value.data, [1, 2, 3]);
      expect(controller.hasMore, isFalse);
      expect(controller.hasLoadedMoreThanOnePage, isFalse);

      await controller.loadMore();
      expect(calls, [1], reason: '首屏已到底，不应再请求 page=2');
    });

    test('withPage 非空页显式 hasMore=false 时立即停止', () async {
      final calls = <int>[];
      final controller = WAsyncPagedController<int>.withPage((page) async {
        calls.add(page);
        return page == 1
            ? const WAsyncPage(items: [1], hasMore: true)
            : const WAsyncPage(items: [2], hasMore: false);
      });
      addTearDown(controller.dispose);

      await controller.refresh();
      expect(controller.hasMore, isTrue);
      await controller.loadMore();
      expect(controller.state.value.data, [1, 2]);
      expect(controller.hasMore, isFalse);
      expect(controller.hasLoadedMoreThanOnePage, isTrue);

      await controller.loadMore();
      expect(calls, [1, 2]);
    });

    test('withPage 第二页空列表仍然覆盖 hasMore=true', () async {
      final controller = WAsyncPagedController<int>.withPage((page) async {
        return page == 1
            ? const WAsyncPage(items: [1], hasMore: true)
            : const WAsyncPage(items: [], hasMore: true);
      });
      addTearDown(controller.dispose);

      await controller.refresh();
      await controller.loadMore();
      expect(controller.state.value.data, [1]);
      expect(controller.hasMore, isFalse);
    });

    test('withPageToken 支持显式 hasMore', () async {
      final controller = WAsyncPagedController<int>.withPageToken((page, token) async {
        return const WAsyncPage(items: [1, 2], hasMore: false);
      });
      addTearDown(controller.dispose);

      await controller.refresh();
      expect(controller.state.value.data, [1, 2]);
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

      // 刷新未完成时 loadMore 直接返回，不会用未提交的游标请求下一页
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

    test('Error 也会回调 onError', () async {
      Object? reported;
      final controller = WAsyncPagedController<int>(
        (page) async => throw StateError('bug'),
        onError: (error) => reported = error,
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

    test('最后一页为空时 hasMoreListenable 通知，但 state 不变', () async {
      final controller = WAsyncPagedController<int>(
        (page) async => page == 1 ? const [1] : const <int>[],
      );
      addTearDown(controller.dispose);

      await controller.refresh();
      final stateBefore = controller.state.value;
      final seen = <bool>[];
      controller.hasMoreListenable.addListener(
        () => seen.add(controller.hasMore),
      );

      await controller.loadMore();

      expect(controller.hasMore, isFalse);
      expect(seen, <bool>[false]);
      expect(controller.state.value, same(stateBefore));
    });

    test('changes 在 refresh / loadMore / hasMore 变化时通知', () async {
      final controller = WAsyncPagedController<int>(
        (page) async => page == 1 ? const [1] : const <int>[],
      );
      addTearDown(controller.dispose);
      var notifications = 0;
      void listener() => notifications++;
      controller.changes.addListener(listener);
      addTearDown(() => controller.changes.removeListener(listener));

      await controller.refresh();
      final afterRefresh = notifications;
      expect(afterRefresh, greaterThan(0));

      await controller.loadMore();
      expect(notifications, greaterThan(afterRefresh));
      expect(controller.hasMore, isFalse);
    });

    test('追加后的列表不可变', () async {
      final controller = WAsyncPagedController<int>(
        (page) async => page == 1 ? const [1] : const [2],
      );
      addTearDown(controller.dispose);

      await controller.refresh();
      await controller.loadMore();

      final data = controller.state.value.data!;
      expect(data, <int>[1, 2]);
      expect(() => data.add(3), throwsUnsupportedError);
      expect(() => data[0] = 9, throwsUnsupportedError);
      expect(() => data.length = 1, throwsUnsupportedError);
    });

    test('跨 chunk 追加的索引 / 内容 / toList / json 正确', () async {
      final pages = <int, List<int>>{
        1: List<int>.generate(200, (index) => index),
        2: List<int>.generate(200, (index) => 200 + index),
      };
      final controller = WAsyncPagedController<int>(
        (page) async => pages[page] ?? const <int>[],
      );
      addTearDown(controller.dispose);

      await controller.refresh();
      final firstPage = controller.state.value.data!;
      await controller.loadMore();

      final data = controller.state.value.data!;
      final expected = List<int>.generate(400, (index) => index);
      expect(data.length, 400);
      expect(data[0], 0);
      expect(data[255], 255);
      expect(data[256], 256);
      expect(data[399], 399);
      expect(data.toList(), expected);
      expect(data.sublist(250, 260), expected.sublist(250, 260));
      expect(data.reversed.first, 399);
      expect(data.contains(256), isTrue);
      expect(data.indexOf(300), 300);
      expect(jsonEncode(data), jsonEncode(expected));
      expect(data.toString(), contains('399'));

      // 旧快照不被后续 append 改写。
      expect(firstPage.length, 200);
      expect(firstPage[199], 199);
    });
  });

  group('页号：page / hasLoadedMoreThanOnePage', () {
    test('refresh 之前 page 是首屏页码，且不算翻过页', () {
      final controller = WAsyncPagedController<int>((page) async => const [1], initialPage: 3);
      addTearDown(controller.dispose);

      expect(controller.page, 3);
      expect(controller.hasLoadedMoreThanOnePage, isFalse);
    });

    test('首屏成功后 page 指向下一页，但仍不算翻过页', () async {
      final controller = WAsyncPagedController<int>((page) async => const [1]);
      addTearDown(controller.dispose);

      await controller.refresh();
      expect(controller.page, 2);
      expect(controller.hasLoadedMoreThanOnePage, isFalse);
    });

    test('追加成功后 page 前进，并标记已翻过页', () async {
      final pages = <int, List<int>>{
        3: [1],
        4: [2],
      };
      final controller = WAsyncPagedController<int>(
        (page) async => pages[page] ?? const <int>[],
        initialPage: 3,
      );
      addTearDown(controller.dispose);

      await controller.refresh();
      expect(controller.page, 4);
      await controller.loadMore();
      expect(controller.page, 5);
      expect(controller.hasLoadedMoreThanOnePage, isTrue);
    });

    test('loadMore 失败不推进页号，也不误报翻过页', () async {
      final controller = WAsyncPagedController<int>((page) async {
        if (page == 1) return const [1];
        throw StateError('boom');
      });
      addTearDown(controller.dispose);

      await controller.refresh();
      await controller.loadMore();
      expect(controller.loadMoreError.value, isNotNull);
      expect(controller.page, 2);
      expect(controller.hasLoadedMoreThanOnePage, isFalse);
    });

    test('刷新失败回滚页号，已翻过页的状态保持', () async {
      var failRefresh = false;
      final controller = WAsyncPagedController<int>((page) async {
        if (failRefresh) throw StateError('boom');
        return page == 1 ? const [1] : const [2];
      });
      addTearDown(controller.dispose);

      await controller.refresh();
      await controller.loadMore();
      expect(controller.hasLoadedMoreThanOnePage, isTrue);

      failRefresh = true;
      await controller.refresh();
      expect(controller.page, 3);
      expect(controller.hasLoadedMoreThanOnePage, isTrue);
    });
  });

  group('刷新取代（#118）', () {
    test('刷新在飞时再次 refresh 取消旧请求，旧结果不写回', () async {
      final tokens = <WCancelToken>[];
      final pending = <Completer<List<int>>>[];
      final controller = WAsyncPagedController<int>.withToken((_, token) {
        tokens.add(token);
        final completer = Completer<List<int>>();
        pending.add(completer);
        return completer.future;
      });
      addTearDown(controller.dispose);

      final first = controller.refresh();
      final second = controller.refresh();

      expect(tokens, hasLength(2));
      expect(tokens[0].isCancelled, isTrue);
      expect(tokens[1].isCancelled, isFalse);

      pending[0].complete(const [1]);
      await first;
      pending[1].complete(const [2]);
      await second;

      expect(controller.state.value.data, [2]);
    });

    test('旧 refresh 结束不会清掉新 refresh 的 in-flight 闸门', () async {
      final calls = <int>[];
      var pageOneCalls = 0;
      final second = Completer<List<int>>();
      final controller = WAsyncPagedController<int>((page) async {
        calls.add(page);
        if (page != 1) return const [2];
        return pageOneCalls++ == 0 ? const [1] : second.future;
      });
      addTearDown(controller.dispose);

      final first = controller.refresh();
      final newer = controller.refresh();
      await first;

      await controller.loadMore();
      expect(calls, [1, 1]);

      second.complete(const [2]);
      await newer;
      await controller.loadMore();
      expect(calls, [1, 1, 2]);
    });

    test('刷新被取代后失败，保留上一次成功的页号', () async {
      final pending = <Completer<List<int>>>[];
      final calls = <int>[];
      var failRefresh = false;
      final controller = WAsyncPagedController<int>((page) async {
        calls.add(page);
        if (failRefresh) {
          final completer = Completer<List<int>>();
          pending.add(completer);
          return completer.future;
        }
        return <int>[page];
      });
      addTearDown(controller.dispose);

      await controller.refresh();
      await controller.loadMore();
      await controller.loadMore();
      expect(controller.page, 4);

      failRefresh = true;
      calls.clear();
      final first = controller.refresh();
      final second = controller.refresh();
      expect(calls, [1, 1]);
      pending[0].completeError(StateError('old refresh'));
      pending[1].completeError(StateError('new refresh'));
      await Future.wait([first, second]);

      expect(controller.state.value.isFailed, isTrue);
      expect(controller.page, 4);
      expect(controller.hasMore, isTrue);

      failRefresh = false;
      calls.clear();
      await controller.loadMore();
      expect(calls, [4]);
      expect(controller.state.value.data, [1, 2, 3, 4]);
    });
  });

  group('本地替换（#112）', () {
    test('replaceData 替换数据并沿用分页游标', () async {
      final calls = <int>[];
      final controller = WAsyncPagedController<int>((page) async {
        calls.add(page);
        return <int>[page];
      });
      addTearDown(controller.dispose);

      await controller.refresh();
      controller.replaceData(const [9, 8]);

      expect(controller.state.value.data, [9, 8]);
      expect(controller.page, 2);

      await controller.loadMore();
      expect(calls, [1, 2]);
      expect(controller.state.value.data, [9, 8, 2]);
    });

    test('replaceData 在首次加载前视为第一页', () async {
      final calls = <int>[];
      final controller = WAsyncPagedController<int>((page) async {
        calls.add(page);
        return <int>[page];
      });
      addTearDown(controller.dispose);

      controller.replaceData(const [9]);
      expect(controller.page, 2);

      await controller.loadMore();
      expect(calls, [2]);
      expect(controller.state.value.data, [9, 2]);
    });

    test('replaceData 空列表进入 empty 且默认没有更多', () async {
      var calls = 0;
      final controller = WAsyncPagedController<int>((page) async {
        calls++;
        return const [1];
      });
      addTearDown(controller.dispose);

      await controller.refresh();
      controller.replaceData(const []);

      expect(controller.state.value.isEmpty, isTrue);
      expect(controller.hasMore, isFalse);

      await controller.loadMore();
      expect(calls, 1);
    });

    test('replaceData 默认沿用 hasMore=false', () async {
      final controller = WAsyncPagedController<int>(
        (page) async => page == 1 ? const [1] : const <int>[],
      );
      addTearDown(controller.dispose);

      await controller.refresh();
      await controller.loadMore();
      expect(controller.hasMore, isFalse);

      controller.replaceData(const [9]);
      expect(controller.hasMore, isFalse);
    });

    test('replaceData 可显式指定 page / hasMore', () async {
      final calls = <int>[];
      final controller = WAsyncPagedController<int>((page) async {
        calls.add(page);
        return <int>[page];
      });
      addTearDown(controller.dispose);

      controller.replaceData(const [7], page: 5, hasMore: true);
      expect(controller.page, 5);

      await controller.loadMore();
      expect(calls, [5]);
      expect(controller.state.value.data, [7, 5]);
    });

    test('replaceData 取消在飞 refresh，旧结果不覆盖', () async {
      final pending = Completer<List<int>>();
      final controller = WAsyncPagedController<int>.withToken((_, token) {
        return pending.future;
      });
      addTearDown(controller.dispose);

      final refreshing = controller.refresh();
      controller.replaceData(const [9, 8]);

      expect(controller.state.value.data, [9, 8]);

      pending.complete(const [1, 2]);
      await refreshing;

      expect(controller.state.value.data, [9, 8]);
    });

    test('replaceData 取消在飞 refresh 后 loadMore 仍可用', () async {
      final pending = Completer<List<int>>();
      var calls = 0;
      final controller = WAsyncPagedController<int>((page) async {
        calls++;
        if (calls == 1) return pending.future;
        return <int>[page];
      });
      addTearDown(controller.dispose);

      final refreshing = controller.refresh();
      controller.replaceData(const [9], page: 3);
      pending.complete(const [1]);
      await refreshing;

      await controller.loadMore();
      expect(controller.state.value.data, [9, 3]);
    });

    test('replaceData 取消在飞 loadMore，旧结果不追加', () async {
      final page2 = Completer<List<int>>();
      final controller = WAsyncPagedController<int>((page) async {
        if (page == 1) return const [1];
        return page2.future;
      });
      addTearDown(controller.dispose);

      await controller.refresh();
      final loading = controller.loadMore();
      controller.replaceData(const [9, 8]);

      page2.complete(const [2]);
      await loading;

      expect(controller.state.value.data, [9, 8]);
    });

    test('replaceData 复制输入列表且 state.data 不可变', () async {
      final controller = WAsyncPagedController<int>((page) async => const [1]);
      addTearDown(controller.dispose);

      final input = <int>[1, 2];
      controller.replaceData(input);
      input.add(3);

      expect(controller.state.value.data, [1, 2]);
      expect(() => controller.state.value.data!.add(4), throwsUnsupportedError);
    });

    test('replaceData 清空 loadMoreError', () async {
      final controller = WAsyncPagedController<int>((page) async {
        if (page == 1) return const [1];
        throw StateError('page failed');
      });
      addTearDown(controller.dispose);

      await controller.refresh();
      await controller.loadMore();
      expect(controller.loadMoreError.value, isNotNull);

      controller.replaceData(const [2]);
      expect(controller.loadMoreError.value, isNull);
    });

    test('replaceData page 必须大于 0', () {
      final controller = WAsyncPagedController<int>((page) async => const [1]);
      addTearDown(controller.dispose);

      expect(
        () => controller.replaceData(const [1], page: 0),
        throwsArgumentError,
      );
    });

    test('dispose 后 replaceData 不做事', () {
      final controller = WAsyncPagedController<int>((page) async => const [1]);
      controller.dispose();

      controller.replaceData(const [1]);
    });

    test('replaceData 通知 changes', () {
      final controller = WAsyncPagedController<int>((page) async => const [1]);
      addTearDown(controller.dispose);
      var notifications = 0;
      void listener() => notifications++;
      controller.changes.addListener(listener);
      addTearDown(() => controller.changes.removeListener(listener));

      controller.replaceData(const [2]);

      expect(notifications, greaterThan(0));
    });
  });
}
