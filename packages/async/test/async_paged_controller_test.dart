// ignore_for_file: deprecated_member_use_from_same_package
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_async/w_tools_async.dart';

/// 记录请求页码并按页码返回数据；[lastPage] 决定 `hasMore`。
WAsyncPagedController<int> _controller(
  Map<int, List<int>> pages, {
  int? lastPage,
  int initialPage = 1,
  WAsyncState<List<int>>? initial,
  void Function(Object error)? onError,
  List<int>? requested,
}) {
  return WAsyncPagedController<int>(
    (page, token) async {
      requested?.add(page);
      final items = pages[page];
      if (items == null) throw StateError('unexpected page $page');
      return WAsyncPage<int>(
        items: items,
        hasMore: lastPage == null ? null : page < lastPage,
      );
    },
    initialPage: initialPage,
    initial: initial,
    onError: onError,
  );
}

void main() {
  setUp(() => WAsync.defaultHooks = WAsyncHooks.none);
  tearDown(() => WAsync.defaultHooks = WAsyncHooks.none);

  group('WAsyncPage', () {
    test('items / hasMore 原样保留', () {
      const page = WAsyncPage<int>(items: [1, 2], hasMore: false);
      expect(page.items, [1, 2]);
      expect(page.hasMore, isFalse);
    });
  });

  group('refresh / loadMore', () {
    test('refresh 加载第一页并可继续追加', () async {
      final requested = <int>[];
      final controller = _controller(
        {
          1: [10],
          2: [20],
          3: [30],
        },
        lastPage: 3,
        requested: requested,
      );
      addTearDown(controller.dispose);

      await controller.refresh();
      expect(controller.state.value.data, [10]);
      expect(controller.snapshot.value.footerStatus, WAsyncPagedFooterStatus.loadMore);
      expect(controller.snapshot.value.hasMore, isTrue);

      await controller.loadMore();
      expect(controller.state.value.data, [10, 20]);
      expect(controller.snapshot.value.footerStatus, WAsyncPagedFooterStatus.loadMore);

      await controller.loadMore();
      expect(controller.state.value.data, [10, 20, 30]);
      expect(controller.snapshot.value.footerStatus, WAsyncPagedFooterStatus.noMore);
      expect(controller.snapshot.value.hasMore, isFalse);
      expect(requested, [1, 2, 3]);
    });

    test('首屏显式 hasMore=false：footer hidden，不再请求第二页', () async {
      final requested = <int>[];
      final controller = _controller(
        {
          1: [1, 2],
        },
        lastPage: 1,
        requested: requested,
      );
      addTearDown(controller.dispose);

      await controller.refresh();
      expect(controller.snapshot.value.footerStatus, WAsyncPagedFooterStatus.hidden);

      await controller.loadMore();
      expect(requested, [1]);
    });

    test('第二页空列表：hasMore=false，state 不变，footer hidden', () async {
      final requested = <int>[];
      final controller = _controller(
        {
          1: [1],
          2: <int>[],
        },
        lastPage: 2,
        requested: requested,
      );
      addTearDown(controller.dispose);

      await controller.refresh();
      final before = controller.state.value;
      var notified = 0;
      controller.snapshot.addListener(() => notified++);

      await controller.loadMore();

      expect(controller.state.value, same(before));
      expect(controller.state.value.data, [1]);
      expect(controller.snapshot.value.hasMore, isFalse);
      expect(controller.snapshot.value.footerStatus, WAsyncPagedFooterStatus.hidden);
      expect(notified, greaterThan(0));
    });

    test('loadMore 初始无数据时回到 refresh', () async {
      final requested = <int>[];
      final controller = _controller(
        {
          1: [1],
        },
        lastPage: 1,
        requested: requested,
      );
      addTearDown(controller.dispose);

      await controller.loadMore();

      expect(requested, [1]);
      expect(controller.state.value.data, [1]);
    });

    test('refresh 进行中 loadMore 不追加、不请求第一页', () async {
      final gate = Completer<void>();
      final requested = <int>[];
      final controller = WAsyncPagedController<int>((page, _) async {
        requested.add(page);
        await gate.future;
        return WAsyncPage<int>(items: [page], hasMore: true);
      });
      addTearDown(controller.dispose);

      final refreshing = controller.refresh();
      await Future<void>.delayed(Duration.zero);
      await controller.loadMore();
      expect(requested, [1]);

      gate.complete();
      await refreshing;
      expect(controller.state.value.data, [1]);
    });

    test('loadMore 期间 snapshot.isLoadingMore 为 true', () async {
      final gate = Completer<void>();
      final controller = WAsyncPagedController<int>((page, _) async {
        if (page == 1) return const WAsyncPage<int>(items: [1], hasMore: true);
        await gate.future;
        return const WAsyncPage<int>(items: [2]);
      });
      addTearDown(controller.dispose);

      await controller.refresh();
      final appending = controller.loadMore();
      await Future<void>.delayed(Duration.zero);

      expect(controller.snapshot.value.isLoadingMore, isTrue);
      expect(controller.snapshot.value.footerStatus, WAsyncPagedFooterStatus.loading);

      gate.complete();
      await appending;

      expect(controller.snapshot.value.isLoadingMore, isFalse);
      expect(controller.state.value.data, [1, 2]);
    });
  });

  group('失败与取消', () {
    test('loadMore 失败只写 loadMoreError，不清空列表', () async {
      var fail = true;
      final controller = WAsyncPagedController<int>((page, _) async {
        if (page == 1) return const WAsyncPage<int>(items: [1], hasMore: true);
        if (fail) throw StateError('boom');
        return const WAsyncPage<int>(items: [2], hasMore: false);
      });
      addTearDown(controller.dispose);

      await controller.refresh();
      await controller.loadMore();

      expect(controller.state.value.data, [1]);
      expect(controller.snapshot.value.loadMoreError, isA<StateError>());
      expect(controller.snapshot.value.footerStatus, WAsyncPagedFooterStatus.failed);

      fail = false;
      await controller.loadMore();

      expect(controller.state.value.data, [1, 2]);
      expect(controller.snapshot.value.loadMoreError, isNull);
      expect(controller.snapshot.value.footerStatus, WAsyncPagedFooterStatus.noMore);
    });

    test('refresh 失败保留旧数据与分页游标', () async {
      var failRefresh = false;
      final requested = <int>[];
      final controller = WAsyncPagedController<int>((page, _) async {
        requested.add(page);
        if (page == 1) {
          if (failRefresh) throw Exception('refresh boom');
          return const WAsyncPage<int>(items: [1], hasMore: true);
        }
        return const WAsyncPage<int>(items: [2], hasMore: true);
      });
      addTearDown(controller.dispose);

      await controller.refresh();
      failRefresh = true;
      await controller.refresh();

      expect(controller.state.value.isFailed, isTrue);
      expect(controller.state.value.data, [1]);

      await controller.loadMore();
      expect(requested, [1, 1, 2]);
      expect(controller.state.value.data, [1, 2]);
    });

    test('refresh 在飞时再次 refresh：旧结果不写回', () async {
      final first = Completer<WAsyncPage<int>>();
      final second = Completer<WAsyncPage<int>>();
      var calls = 0;
      final controller = WAsyncPagedController<int>((_, __) {
        calls++;
        return calls == 1 ? first.future : second.future;
      });
      addTearDown(controller.dispose);

      final firstRefresh = controller.refresh();
      final secondRefresh = controller.refresh();

      second.complete(const WAsyncPage<int>(items: [2], hasMore: true));
      await secondRefresh;
      first.complete(const WAsyncPage<int>(items: [1], hasMore: true));
      await firstRefresh;

      expect(controller.state.value.data, [2]);
    });

    test('refresh 会取消在途 loadMore 的 token', () async {
      WCancelToken? loadMoreToken;
      final never = Completer<WAsyncPage<int>>();
      final controller = WAsyncPagedController<int>((page, token) {
        if (page == 1) {
          return Future.value(const WAsyncPage<int>(items: [1], hasMore: true));
        }
        loadMoreToken = token;
        return never.future;
      });
      addTearDown(controller.dispose);

      await controller.refresh();
      final appending = controller.loadMore();
      await Future<void>.delayed(Duration.zero);

      await controller.refresh();
      expect(loadMoreToken!.isCancelled, isTrue);

      never.complete(const WAsyncPage<int>(items: [99], hasMore: true));
      await appending;
      expect(controller.state.value.data, [1]);
    });

    test('dispose 会取消 refresh 的 token', () async {
      WCancelToken? token;
      final gate = Completer<WAsyncPage<int>>();
      final controller = WAsyncPagedController<int>((_, seen) {
        token = seen;
        return gate.future;
      });

      final refreshing = controller.refresh();
      await Future<void>.delayed(Duration.zero);
      controller.dispose();

      expect(token!.isCancelled, isTrue);

      gate.complete(const WAsyncPage<int>(items: [1]));
      await refreshing;
    });

    test('dispose 会取消 loadMore 的 token', () async {
      WCancelToken? loadMoreToken;
      final gate = Completer<WAsyncPage<int>>();
      final controller = WAsyncPagedController<int>((page, token) {
        if (page == 1) {
          return Future.value(const WAsyncPage<int>(items: [1], hasMore: true));
        }
        loadMoreToken = token;
        return gate.future;
      });

      await controller.refresh();
      final appending = controller.loadMore();
      await Future<void>.delayed(Duration.zero);
      controller.dispose();

      expect(loadMoreToken!.isCancelled, isTrue);

      gate.complete(const WAsyncPage<int>(items: [2]));
      await appending;
    });

    test('Error 也会回调 onError', () async {
      Object? reported;
      final controller = WAsyncPagedController<int>(
        (_, __) async => throw StateError('boom'),
        onError: (error) => reported = error,
      );
      addTearDown(controller.dispose);

      await controller.refresh();

      expect(controller.state.value.isFailed, isTrue);
      expect(reported, isA<StateError>());
    });

    test('onError 内重新 refresh：旧失败不覆盖新状态', () async {
      late WAsyncPagedController<int> controller;
      Future<void>? secondRefresh;
      final gate = Completer<WAsyncPage<int>>();
      var calls = 0;
      controller = WAsyncPagedController<int>(
        (page, _) {
          calls++;
          if (calls == 1) {
            return Future<WAsyncPage<int>>.error(StateError('first'));
          }
          return gate.future;
        },
        onError: (error) {
          if (calls == 1) secondRefresh = controller.refresh();
        },
      );
      addTearDown(controller.dispose);

      await controller.refresh();
      expect(controller.state.value.isLoading, isTrue);

      gate.complete(const WAsyncPage<int>(items: [2], hasMore: false));
      await secondRefresh;

      expect(controller.state.value.data, [2]);
    });

    test('onError 内 refresh：旧 loadMore 失败不污染新状态', () async {
      late WAsyncPagedController<int> controller;
      Future<void>? refreshFuture;
      var calls = 0;
      controller = WAsyncPagedController<int>(
        (page, _) async {
          calls++;
          if (calls == 1) {
            return const WAsyncPage<int>(items: [1], hasMore: true);
          }
          if (page == 2) throw StateError('loadMore failed');
          return const WAsyncPage<int>(items: [1], hasMore: true);
        },
        onError: (error) {
          refreshFuture = controller.refresh();
        },
      );
      addTearDown(controller.dispose);

      await controller.refresh();
      await controller.loadMore();
      await refreshFuture;

      expect(controller.snapshot.value.loadMoreError, isNull);
      expect(
        controller.snapshot.value.footerStatus,
        WAsyncPagedFooterStatus.loadMore,
      );
    });

    test('onError 内 replaceData：旧 loadMore 失败不污染新状态', () async {
      late WAsyncPagedController<int> controller;
      var calls = 0;
      controller = WAsyncPagedController<int>(
        (page, _) async {
          calls++;
          if (calls == 1) {
            return const WAsyncPage<int>(items: [1], hasMore: true);
          }
          if (page == 2) throw StateError('loadMore failed');
          return const WAsyncPage<int>(items: [1], hasMore: true);
        },
        onError: (error) {
          controller.replaceData(const [9]);
        },
      );
      addTearDown(controller.dispose);

      await controller.refresh();
      await controller.loadMore();

      expect(controller.snapshot.value.loadMoreError, isNull);
      expect(controller.state.value.data, [9]);
    });

    test('initialPage 必须大于 0（release 也校验）', () {
      expect(
        () => WAsyncPagedController<int>(
          (_, __) async => const WAsyncPage<int>(items: []),
          initialPage: 0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('initial / 初始状态', () {
    test('initial.ready 时 loadMore 从下一页开始', () async {
      final requested = <int>[];
      final controller = _controller(
        {
          2: [2],
        },
        lastPage: 2,
        initialPage: 1,
        initial: const WAsyncState.ready([1]),
        requested: requested,
      );
      addTearDown(controller.dispose);

      await controller.loadMore();

      expect(requested, [2]);
      expect(controller.state.value.data, [1, 2]);
    });

    test('initial.ready 为空列表时没有更多', () async {
      final requested = <int>[];
      final controller = _controller(
        {
          1: [1],
        },
        lastPage: 1,
        initial: const WAsyncState<List<int>>.ready([]),
        requested: requested,
      );
      addTearDown(controller.dispose);

      expect(controller.snapshot.value.hasMore, isFalse);
      await controller.loadMore();
      expect(requested, isEmpty);
    });

    test('initial.empty 时没有更多', () async {
      final requested = <int>[];
      final controller = _controller(
        {
          1: [1],
        },
        lastPage: 1,
        initial: const WAsyncState<List<int>>.empty(),
        requested: requested,
      );
      addTearDown(controller.dispose);

      expect(controller.snapshot.value.hasMore, isFalse);
      await controller.loadMore();
      expect(requested, isEmpty);
    });
  });

  group('快照通知', () {
    test('refresh / loadMore / hasMore 变化都会通知 snapshot', () async {
      final controller = _controller(
        {
          1: [1],
          2: [2],
        },
        lastPage: 2,
      );
      addTearDown(controller.dispose);

      var notified = 0;
      controller.snapshot.addListener(() => notified++);

      await controller.refresh();
      expect(notified, greaterThan(0));
      final afterRefresh = notified;

      await controller.loadMore();
      expect(notified, greaterThan(afterRefresh));
      expect(controller.snapshot.value.footerStatus, WAsyncPagedFooterStatus.noMore);
    });

    test('refresh 期间 footer hidden，完成后恢复', () async {
      final gate = Completer<void>();
      var calls = 0;
      final controller = WAsyncPagedController<int>((page, _) async {
        calls++;
        if (calls == 1) {
          return const WAsyncPage<int>(items: [1], hasMore: true);
        }
        await gate.future;
        return const WAsyncPage<int>(items: [1], hasMore: true);
      });
      addTearDown(controller.dispose);

      await controller.refresh();
      expect(
        controller.snapshot.value.footerStatus,
        WAsyncPagedFooterStatus.loadMore,
      );

      final refreshing = controller.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(
        controller.snapshot.value.footerStatus,
        WAsyncPagedFooterStatus.hidden,
        reason: 'refresh 期间 loadMore 被忽略，footer 不应继续显示加载更多',
      );

      gate.complete();
      await refreshing;
      expect(
        controller.snapshot.value.footerStatus,
        WAsyncPagedFooterStatus.loadMore,
      );
    });

    test('state 只在四态变化时通知，footer 变化不重建内容', () async {
      final gate = Completer<void>();
      final controller = WAsyncPagedController<int>((page, _) async {
        if (page == 1) return const WAsyncPage<int>(items: [1], hasMore: true);
        await gate.future;
        return const WAsyncPage<int>(items: [2], hasMore: false);
      });
      addTearDown(controller.dispose);

      await controller.refresh();

      var stateNotified = 0;
      controller.state.addListener(() => stateNotified++);

      final appending = controller.loadMore();
      await Future<void>.delayed(Duration.zero);
      expect(stateNotified, 0, reason: 'loadMore 开始只改 footer，不改四态');

      gate.complete();
      await appending;
      expect(stateNotified, 1);
    });
  });

  group('replaceData', () {
    test('替换数据并沿用分页游标', () async {
      final requested = <int>[];
      final controller = _controller(
        {
          1: [1],
          2: [2],
        },
        lastPage: 2,
        requested: requested,
      );
      addTearDown(controller.dispose);

      await controller.refresh();
      controller.replaceData(const [9, 8]);

      expect(controller.state.value.data, [9, 8]);
      expect(controller.snapshot.value.footerStatus, WAsyncPagedFooterStatus.loadMore);

      await controller.loadMore();
      expect(requested, [1, 2]);
      expect(controller.state.value.data, [9, 8, 2]);
    });

    test('首次加载前 replaceData 视为第一页', () async {
      final requested = <int>[];
      final controller = _controller(
        {
          2: [2],
        },
        lastPage: 2,
        requested: requested,
      );
      addTearDown(controller.dispose);

      controller.replaceData(const [9]);
      await controller.loadMore();

      expect(requested, [2]);
      expect(controller.state.value.data, [9, 2]);
    });

    test('空列表进入 empty 且默认没有更多', () {
      final controller = _controller({
        1: [1],
      }, lastPage: 1);
      addTearDown(controller.dispose);

      controller.replaceData(const []);

      expect(controller.state.value.isEmpty, isTrue);
      expect(controller.snapshot.value.hasMore, isFalse);
      expect(controller.snapshot.value.footerStatus, WAsyncPagedFooterStatus.hidden);
    });

    test('显式 hasMore 覆盖默认值', () {
      final controller = _controller({
        1: [1],
      }, lastPage: 1);
      addTearDown(controller.dispose);

      controller.replaceData(const [9], hasMore: true);
      expect(controller.snapshot.value.footerStatus, WAsyncPagedFooterStatus.loadMore);

      controller.replaceData(const [9], hasMore: false);
      expect(controller.snapshot.value.footerStatus, WAsyncPagedFooterStatus.hidden);
    });

    test('取消在飞 refresh，旧结果不覆盖', () async {
      final gate = Completer<WAsyncPage<int>>();
      final controller = WAsyncPagedController<int>((_, __) => gate.future);
      addTearDown(controller.dispose);

      final refreshing = controller.refresh();
      await Future<void>.delayed(Duration.zero);
      controller.replaceData(const [9, 8]);

      gate.complete(const WAsyncPage<int>(items: [1, 2], hasMore: true));
      await refreshing;

      expect(controller.state.value.data, [9, 8]);
    });

    test('取消在飞 loadMore，旧结果不追加', () async {
      final gate = Completer<WAsyncPage<int>>();
      final controller = WAsyncPagedController<int>((page, _) {
        if (page == 1) {
          return Future.value(const WAsyncPage<int>(items: [1], hasMore: true));
        }
        return gate.future;
      });
      addTearDown(controller.dispose);

      await controller.refresh();
      final appending = controller.loadMore();
      await Future<void>.delayed(Duration.zero);
      controller.replaceData(const [9, 8]);

      gate.complete(const WAsyncPage<int>(items: [2], hasMore: true));
      await appending;

      expect(controller.state.value.data, [9, 8]);
    });

    test('复制输入列表且 state.data 不可变', () {
      final input = <int>[1, 2];
      final controller = _controller({
        1: [1],
      }, lastPage: 1);
      addTearDown(controller.dispose);

      controller.replaceData(input);
      input.add(3);

      expect(controller.state.value.data, [1, 2]);
      expect(() => controller.state.value.data!.add(4), throwsUnsupportedError);
    });

    test('清空 loadMoreError', () async {
      final controller = WAsyncPagedController<int>((page, _) async {
        if (page == 1) return const WAsyncPage<int>(items: [1], hasMore: true);
        throw StateError('boom');
      });
      addTearDown(controller.dispose);

      await controller.refresh();
      await controller.loadMore();
      expect(controller.snapshot.value.loadMoreError, isNotNull);

      controller.replaceData(const [2]);
      expect(controller.snapshot.value.loadMoreError, isNull);
    });

    test('通知 snapshot', () {
      final controller = _controller({
        1: [1],
      }, lastPage: 1);
      addTearDown(controller.dispose);

      var notified = 0;
      controller.snapshot.addListener(() => notified++);

      controller.replaceData(const [2]);
      expect(notified, 1);
    });

    test('dispose 后 replaceData 不做事', () {
      final controller = _controller({
        1: [1],
      }, lastPage: 1);
      controller.dispose();

      controller.replaceData(const [1]);

      expect(controller.snapshot.value.state.isLoading, isTrue);
    });
  });

  group('列表语义', () {
    test('list 便捷构造：空首页进入 empty', () async {
      final controller = WAsyncPagedController.list<int>(
        (page, _) async => const <int>[],
      );
      addTearDown(controller.dispose);

      await controller.refresh();

      expect(controller.state.value.isEmpty, isTrue);
      expect(controller.snapshot.value.hasMore, isFalse);
      expect(controller.snapshot.value.footerStatus, WAsyncPagedFooterStatus.hidden);
    });

    test('追加后的列表不可变且顺序正确', () async {
      final controller = WAsyncPagedController<int>((page, _) async {
        if (page > 3) return const WAsyncPage<int>(items: []);
        return WAsyncPage<int>(
          items: List<int>.generate(200, (index) => (page - 1) * 200 + index),
          hasMore: page < 2,
        );
      });
      addTearDown(controller.dispose);

      await controller.refresh();
      await controller.loadMore();
      await controller.loadMore();

      final data = controller.state.value.data!;
      expect(data, hasLength(400));
      expect(data.first, 0);
      expect(data[199], 199);
      expect(data[200], 200);
      expect(data.last, 399);
      expect(() => data.add(1), throwsUnsupportedError);
      expect(data.toList(), hasLength(400));
    });
  });

  test('initial failed(previousData) 保留游标并从下一页继续', () async {
    final requested = <int>[];
    final controller = _controller(
      {
        2: [2],
      },
      lastPage: 2,
      initial: WAsyncState<List<int>>.failed(
        StateError('boom'),
        previousData: const [1],
      ),
      requested: requested,
    );
    addTearDown(controller.dispose);

    expect(controller.snapshot.value.footerStatus, WAsyncPagedFooterStatus.loadMore);
    await controller.loadMore();

    expect(requested, [2]);
    expect(controller.state.value.data, [1, 2]);
  });

  group('WAsyncPagedController defaultHooks', () {
    test('refresh / loadMore 不继承 defaultHooks', () async {
      final events = <String>[];
      WAsync.defaultHooks = WAsyncHooks(
        onStart: () => events.add('start'),
        onError: (_) => events.add('error'),
        onFinally: () => events.add('finally'),
      );
      final controller = _controller(
        {
          1: [1],
          2: [2],
        },
        lastPage: 2,
      );
      addTearDown(controller.dispose);

      await controller.refresh();
      await controller.loadMore();

      expect(controller.state.value.data, [1, 2]);
      expect(events, isEmpty);
    });
  });
}
