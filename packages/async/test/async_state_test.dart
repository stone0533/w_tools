import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_async/w_tools_async.dart';

void main() {
  test('toString 包含状态与数据信息', () {
    const text = WAsyncState<int>.ready(1);
    expect(text.toString(), contains('ready'));
    expect(text.toString(), contains('hasData: true'));
  });

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
      expect(failed.data, isNull);
    });

    test('ofList：null 与空列表都是 empty，非空才是 ready（兼容旧名）', () {
      // ignore: deprecated_member_use_from_same_package
      const ofList = WAsyncState.ofList<int>;
      expect(ofList(null).isEmpty, isTrue);
      expect(ofList(const []).isEmpty, isTrue);
      expect(ofList(const [1, 2]).isReady, isTrue);
      expect(ofList(const [1, 2]).data, const [1, 2]);
    });

    test('list：与 ofList 等价，命名与 WAsyncController.list 对称', () {
      expect(WAsyncState.list<int>(null).isEmpty, isTrue);
      expect(WAsyncState.list<int>(const []).isEmpty, isTrue);
      expect(WAsyncState.list<int>(const [1, 2]).isReady, isTrue);
      expect(WAsyncState.list<int>(const [1, 2]).data, const [1, 2]);
    });

    test('list 不复制、不包装输入列表', () {
      final source = <int>[1, 2];
      final state = WAsyncState.list<int>(source);

      expect(state.data, same(source));
      source.add(3);
      expect(state.data, <int>[1, 2, 3]);
    });

    test('列表相等性是引用比较，不是深比较', () {
      final list = <int>[1, 2];
      expect(
        WAsyncState<List<int>>.ready(list),
        WAsyncState<List<int>>.ready(list),
      );

      final first = <int>[1, 2];
      final second = <int>[1, 2];
      expect(
        WAsyncState<List<int>>.ready(first),
        isNot(WAsyncState<List<int>>.ready(second)),
      );
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
      expect(refreshing.data, 5);

      final failed = WAsyncState<int>.failed(
        Exception('e'),
        previousData: 5,
      );
      expect(failed.isFailed, isTrue);
      expect(failed.data, 5);
    });

    test('值相等与 hashCode', () {
      expect(const WAsyncState<int>.ready(1), const WAsyncState<int>.ready(1));
      expect(const WAsyncState<int>.ready(1).hashCode, const WAsyncState<int>.ready(1).hashCode);
      expect(const WAsyncState<int>.ready(1), isNot(const WAsyncState<int>.ready(2)));
    });
  });

  group('WAsyncResult', () {
    test('isSuccess / isFailure / isCancelled 三态互斥', () {
      const success = WAsyncSuccess<int>(1);
      const failure = WAsyncFailure<int>('boom', StackTrace.empty);
      const cancelled = WAsyncCancelled<int>('stop');

      expect(success.isSuccess, isTrue);
      expect(success.isFailure, isFalse);
      expect(success.isCancelled, isFalse);

      expect(failure.isSuccess, isFalse);
      expect(failure.isFailure, isTrue);
      expect(failure.isCancelled, isFalse);

      expect(cancelled.isSuccess, isFalse);
      expect(cancelled.isFailure, isFalse);
      expect(cancelled.isCancelled, isTrue);
    });
  });
}
