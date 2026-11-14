import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_async/w_tools_async.dart';

void main() {
  group('WAsyncController', () {
    test('load 成功进入 ready', () async {
      final controller = WAsyncController<int>((_) async => 1);
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.state.value.isReady, isTrue);
      expect(controller.state.value.data, 1);
    });

    test('支持初始状态', () {
      final controller = WAsyncController<int>(
        (_) async => 2,
        initial: const WAsyncState.ready(1),
      );
      addTearDown(controller.dispose);

      expect(controller.state.value.data, 1);
    });

    test('list 空列表进入 empty', () async {
      final controller = WAsyncController.list<int>((_) async => <int>[]);
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.state.value.isEmpty, isTrue);
    });

    test('Error 也会转为 failed', () async {
      final controller = WAsyncController<int>(
        (_) async => throw StateError('bug'),
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.state.value.isFailed, isTrue);
      expect(controller.state.value.error, isA<StateError>());
    });

    test('失败保留旧数据', () async {
      var fail = false;
      final controller = WAsyncController<int>((_) async {
        if (fail) throw Exception('boom');
        return 1;
      });
      addTearDown(controller.dispose);

      await controller.load();
      fail = true;
      await controller.load();

      expect(controller.state.value.isFailed, isTrue);
      expect(controller.state.value.data, 1);
    });

    test('旧请求返回不覆盖新请求', () async {
      final first = Completer<int>();
      final second = Completer<int>();
      var calls = 0;
      final controller = WAsyncController<int>((_) {
        calls++;
        return calls == 1 ? first.future : second.future;
      });
      addTearDown(controller.dispose);

      final firstLoad = controller.load();
      final secondLoad = controller.load();

      second.complete(2);
      await secondLoad;
      first.complete(1);
      await firstLoad;

      expect(controller.state.value.data, 2);
    });

    test('load 期间 dispose 不抛异常', () async {
      final completer = Completer<int>();
      final controller = WAsyncController<int>((_) => completer.future);
      final loading = controller.load();

      controller.dispose();
      completer.complete(1);

      await expectLater(loading, completes);
    });

    test('dispose 后 load 不再改状态', () async {
      final controller = WAsyncController<int>((_) async => 1);
      controller.dispose();

      await controller.load();

      expect(controller.state.value.isLoading, isTrue);
    });

    test('新 load 会取消上一个 token', () async {
      final tokens = <WCancelToken>[];
      final completers = <Completer<int>>[];
      final controller = WAsyncController<int>((token) {
        tokens.add(token);
        final completer = Completer<int>();
        completers.add(completer);
        return completer.future;
      });
      addTearDown(controller.dispose);

      final first = controller.load();
      final second = controller.load();

      expect(tokens, hasLength(2));
      expect(tokens.first.isCancelled, isTrue);
      expect(tokens.last.isCancelled, isFalse);

      completers.last.complete(2);
      await second;
      completers.first.complete(1);
      await first;

      expect(controller.state.value.data, 2);
    });

    test('dispose 会取消当前 token', () async {
      WCancelToken? seen;
      final completer = Completer<int>();
      final controller = WAsyncController<int>((token) {
        seen = token;
        return completer.future;
      });

      final loading = controller.load();
      controller.dispose();

      expect(seen, isNotNull);
      expect(seen!.isCancelled, isTrue);

      completer.complete(1);
      await loading;
    });

    test('Error 也会回调 onError', () async {
      Object? reported;
      final controller = WAsyncController<int>(
        (_) async => throw StateError('bug'),
        onError: (error) => reported = error,
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.state.value.isFailed, isTrue);
      expect(reported, isA<StateError>());
    });

    test('isEmpty 抛错转为 failed，不让 load() reject', () async {
      Object? reported;
      final controller = WAsyncController<int>(
        (_) async => 1,
        isEmpty: (_) => throw StateError('isEmpty boom'),
        onError: (error) => reported = error,
      );
      addTearDown(controller.dispose);

      await expectLater(controller.load(), completes);

      expect(controller.state.value.isFailed, isTrue);
      expect(controller.state.value.error, isA<StateError>());
      expect(reported, isA<StateError>());
    });

    test('onError 内重新 load：旧失败不覆盖新状态', () async {
      late WAsyncController<int> controller;
      Future<void>? secondLoad;
      final gate = Completer<int>();
      var calls = 0;
      controller = WAsyncController<int>(
        (_) {
          calls++;
          if (calls == 1) return Future<int>.error(StateError('first'));
          return gate.future;
        },
        onError: (error) {
          if (calls == 1) secondLoad = controller.load();
        },
      );
      addTearDown(controller.dispose);

      await controller.load();
      expect(controller.state.value.isLoading, isTrue);

      gate.complete(2);
      await secondLoad;

      expect(controller.state.value.data, 2);
    });

    test('replaceData 的 isEmpty 抛错当前同步抛出', () {
      final controller = WAsyncController<int>(
        (_) async => 1,
        isEmpty: (_) => throw StateError('isEmpty boom'),
      );
      addTearDown(controller.dispose);

      // 当前行为：同步抛出；若决定与 load 一样转 failed，改这条用例 + 代码。
      expect(() => controller.replaceData(1), throwsStateError);
    });

    test('list 的 state.data 是不可变列表（与 Paged 一致）', () async {
      final source = <int>[1, 2];
      final controller = WAsyncController.list<int>((_) async => source);
      addTearDown(controller.dispose);

      await controller.load();

      final data = controller.state.value.data!;
      expect(data, <int>[1, 2]);
      expect(() => data.add(3), throwsUnsupportedError);

      source.add(3);
      expect(controller.state.value.data, <int>[1, 2]);
    });

    test('list loader 能感知 token，空列表进入 empty', () async {
      WCancelToken? seen;
      final controller = WAsyncController.list<int>((token) {
        seen = token;
        return Future.value(const <int>[]);
      });
      addTearDown(controller.dispose);

      await controller.load();

      expect(seen, isNotNull);
      expect(controller.state.value.isEmpty, isTrue);
      expect(controller.state.value.data, isNull);
    });

    test('replaceData 替换数据并取消在飞 load', () async {
      final completer = Completer<List<int>>();
      final controller = WAsyncController.list<int>(
        (_) => completer.future,
      );
      addTearDown(controller.dispose);

      final loading = controller.load();
      controller.replaceData(const [9, 8]);

      expect(controller.state.value.data, [9, 8]);

      completer.complete(const [1, 2]);
      await loading;

      expect(controller.state.value.data, [9, 8]);
    });

    test('replaceData 空列表进入 empty，list 数据不可变', () async {
      final controller = WAsyncController.list<int>((_) async => const [1]);
      addTearDown(controller.dispose);

      await controller.load();
      controller.replaceData(const []);
      expect(controller.state.value.isEmpty, isTrue);

      controller.replaceData(const [2, 3]);
      expect(controller.state.value.data, [2, 3]);
      expect(
        () => controller.state.value.data!.add(4),
        throwsUnsupportedError,
      );
    });

    test('replaceData dispose 后不做事', () {
      final controller = WAsyncController<int>((_) async => 1);
      controller.dispose();

      controller.replaceData(2);

      expect(controller.state.value.isLoading, isTrue);
    });
  });
}
