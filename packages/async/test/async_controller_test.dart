import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_async/w_tools_async.dart';

void main() {
  group('WAsyncController', () {
    test('load 成功进入 ready', () async {
      final controller = WAsyncController<int>(() async => 1);
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.state.value.isReady, isTrue);
      expect(controller.state.value.data, 1);
    });

    test('支持初始状态', () {
      final controller = WAsyncController<int>(
        () async => 2,
        initial: const WAsyncState.ready(1),
      );
      addTearDown(controller.dispose);

      expect(controller.state.value.data, 1);
    });

    test('list 空列表进入 empty', () async {
      final controller = WAsyncController.list<int>(() async => <int>[]);
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.state.value.isEmpty, isTrue);
    });

    test('Error 也会转为 failed', () async {
      final controller = WAsyncController<int>(
        () async => throw StateError('bug'),
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.state.value.isFailed, isTrue);
      expect(controller.state.value.error, isA<StateError>());
    });

    test('失败保留旧数据', () async {
      var fail = false;
      final controller = WAsyncController<int>(() async {
        if (fail) throw Exception('boom');
        return 1;
      });
      addTearDown(controller.dispose);

      await controller.load();
      fail = true;
      await controller.retry();

      expect(controller.state.value.isFailed, isTrue);
      expect(controller.state.value.data, 1);
    });

    test('旧请求返回不覆盖新请求', () async {
      final first = Completer<int>();
      final second = Completer<int>();
      var calls = 0;
      final controller = WAsyncController<int>(() {
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
      final controller = WAsyncController<int>(() => completer.future);
      final loading = controller.load();

      controller.dispose();
      completer.complete(1);

      await expectLater(loading, completes);
    });

    test('dispose 后 load 不再改状态', () async {
      final controller = WAsyncController<int>(() async => 1);
      controller.dispose();

      await controller.load();

      expect(controller.state.value.isLoading, isTrue);
    });

    test('withToken：新 load 会取消上一个 token', () async {
      final tokens = <WCancelToken>[];
      final completers = <Completer<int>>[];
      final controller = WAsyncController.withToken((token) {
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

    test('withToken：dispose 会取消当前 token', () async {
      WCancelToken? seen;
      final completer = Completer<int>();
      final controller = WAsyncController.withToken((token) {
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
        () async => throw StateError('bug'),
        onError: (error) => reported = error,
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.state.value.isFailed, isTrue);
      expect(reported, isA<StateError>());
    });
  });
}
