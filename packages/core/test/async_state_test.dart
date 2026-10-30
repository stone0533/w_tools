import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_core/src/utils/async_state.dart';

void main() {
  group('WAsyncState', () {
    test('四态构造与判定', () {
      const loading = WAsyncState<int>.loading();
      const ready = WAsyncState<int>.ready(1);
      const empty = WAsyncState<int>.empty();
      final failed = WAsyncState<int>.failed(Exception('boom'));

      expect(loading.status, WAsyncStatus.loading);
      expect(loading.isLoading, isTrue);
      expect(loading.data, isNull);

      expect(ready.isReady, isTrue);
      expect(ready.data, 1);

      expect(empty.isEmpty, isTrue);
      expect(empty.data, isNull);

      expect(failed.isFailed, isTrue);
      expect(failed.error, isA<Exception>());
      expect(failed.dataOrNull, isNull);
    });

    test('ofList：null 与空列表都是 empty，非空才是 ready', () {
      expect(WAsyncState.ofList<int>(null).isEmpty, isTrue);
      expect(WAsyncState.ofList<int>(const []).isEmpty, isTrue);
      expect(WAsyncState.ofList<int>(const [1, 2]).isReady, isTrue);
      expect(WAsyncState.ofList<int>(const [1, 2]).data, const [1, 2]);
    });

    test('when 覆盖四态', () {
      String describe(WAsyncState<int> s) => s.when(
            loading: () => 'loading',
            ready: (data) => 'ready:$data',
            empty: () => 'empty',
            failed: (error) => 'failed:$error',
          );

      expect(describe(const WAsyncState<int>.loading()), 'loading');
      expect(describe(const WAsyncState<int>.ready(7)), 'ready:7');
      expect(describe(const WAsyncState<int>.empty()), 'empty');
      expect(describe(WAsyncState<int>.failed(StateError('x'))), startsWith('failed:'));
    });

    test('loading / failed 可保留旧数据', () {
      const refreshing = WAsyncState<int>.loading(previousData: 5);
      expect(refreshing.isLoading, isTrue);
      expect(refreshing.isRefreshing, isTrue);
      expect(refreshing.dataOrNull, 5);

      final failed = WAsyncState<int>.failed(
        Exception('e'),
        previousData: 5,
      );
      expect(failed.isFailed, isTrue);
      expect(failed.dataOrNull, 5);
    });

    test('errorMessage 截断过长错误', () {
      final long = WAsyncState<int>.failed('x' * 300);
      expect(long.errorMessage(maxLength: 10).length, 11);
      expect(long.errorMessage(maxLength: 10).endsWith('…'), isTrue);
    });

    test('errorMessage 负数 maxLength 按 0 处理', () {
      final state = WAsyncState<int>.failed(Exception('e'));
      expect(state.errorMessage(maxLength: -1), '…');
    });

    test('值相等与 hashCode', () {
      expect(const WAsyncState<int>.ready(1), const WAsyncState<int>.ready(1));
      expect(const WAsyncState<int>.ready(1).hashCode, const WAsyncState<int>.ready(1).hashCode);
      expect(const WAsyncState<int>.ready(1), isNot(const WAsyncState<int>.ready(2)));
    });
  });
}
