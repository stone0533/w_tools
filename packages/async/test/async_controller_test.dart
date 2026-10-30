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

    test('list 空列表进入 empty', () async {
      final controller = WAsyncController.list<int>(() async => <int>[]);
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.state.value.isEmpty, isTrue);
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
      expect(controller.state.value.dataOrNull, 1);
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

    test('dispose 后 load 不再改状态', () async {
      final controller = WAsyncController<int>(() async => 1);
      controller.dispose();

      await controller.load();

      expect(controller.state.value.isLoading, isTrue);
    });
  });
}
