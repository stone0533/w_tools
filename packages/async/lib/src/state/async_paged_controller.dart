import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../task/async_task.dart';
import 'async_state.dart';

typedef WAsyncPageLoader<T> = Future<List<T>> Function(int page);

/// 接收 [WCancelToken] 的分页 loader。
typedef WAsyncTokenPageLoader<T> = Future<List<T>> Function(int page, WCancelToken token);

/// 列表分页状态：首屏、刷新、追加、hasMore 与 loadMore 错误。
class WAsyncPagedController<T> {
  WAsyncPagedController(
    WAsyncPageLoader<T> loader, {
    int initialPage = 1,
    void Function(Object error)? onError,
    WAsyncState<List<T>>? initial,
  }) : this._(
         (page, _) => loader(page),
         initialPage: initialPage,
         onError: onError,
         initial: initial,
       );

  /// 需要感知取消的分页 loader 版本。
  WAsyncPagedController.withToken(
    WAsyncTokenPageLoader<T> loader, {
    int initialPage = 1,
    void Function(Object error)? onError,
    WAsyncState<List<T>>? initial,
  }) : this._(
         loader,
         initialPage: initialPage,
         onError: onError,
         initial: initial,
       );

  WAsyncPagedController._(
    this._loader, {
    this.initialPage = 1,
    this.onError,
    WAsyncState<List<T>>? initial,
  }) : _page = _resolvePage(initialPage, initial),
       _hasMore = ValueNotifier(_hasMoreFromInitial(initial)),
       _state = ValueNotifier(initial ?? WAsyncState<List<T>>.loading());

  static int _resolvePage<T>(
    int initialPage,
    WAsyncState<List<T>>? initial,
  ) {
    if (initialPage < 1) {
      throw ArgumentError.value(initialPage, 'initialPage', '必须大于 0');
    }
    return (initial?.data?.isNotEmpty ?? false) ? initialPage + 1 : initialPage;
  }

  /// 初始状态为空列表时视为没有更多；null / 未提供时仍允许加载。
  static bool _hasMoreFromInitial<T>(WAsyncState<List<T>>? initial) {
    if (initial == null) return true;
    // empty 与 ready([]) 都表示“已加载且没有数据”，不应再请求下一页。
    if (initial.isEmpty) return false;
    return initial.data?.isNotEmpty ?? true;
  }

  final WAsyncTokenPageLoader<T> _loader;
  final int initialPage;

  /// 失败兜底回调；分页状态由控制器维护，不提供 activity。
  final void Function(Object error)? onError;

  final ValueNotifier<WAsyncState<List<T>>> _state;
  final ValueNotifier<bool> _isLoadingMore = ValueNotifier(false);
  final ValueNotifier<Object?> _loadMoreError = ValueNotifier(null);
  final ValueNotifier<bool> _hasMore;
  late final Listenable _changes = Listenable.merge([
    _state,
    _isLoadingMore,
    _loadMoreError,
    _hasMore,
  ]);

  int _page;
  bool _disposed = false;
  int _generation = 0;
  bool _refreshing = false;
  WCancelToken? _refreshToken;
  WCancelToken? _loadMoreToken;

  ValueListenable<WAsyncState<List<T>>> get state => _state;
  ValueListenable<bool> get isLoadingMore => _isLoadingMore;
  ValueListenable<Object?> get loadMoreError => _loadMoreError;

  /// 是否还有下一页。
  ///
  /// 最后一页返回空列表时这里会变 [false]，但 [state] 不变；
  /// 只按 [state] 重建的 footer 必须额外监听 [hasMoreListenable]。
  bool get hasMore => _hasMore.value;

  /// [hasMore] 的监听入口；footer 用它感知「加载更多 → 没有更多」。
  ValueListenable<bool> get hasMoreListenable => _hasMore;

  /// state / isLoadingMore / loadMoreError / hasMore 任一变化都会通知。
  ///
  /// footer 只需要一个监听入口时用它；[dispose] 后不要再添加监听。
  /// 只需要粒度更细的通知时，仍可用 [state] / [isLoadingMore] /
  /// [loadMoreError] / [hasMoreListenable]。
  Listenable get changes => _changes;

  /// 重新加载第一页；失败时保留旧数据。
  Future<void> refresh() async {
    if (_disposed || _refreshing) return;
    _refreshing = true;
    try {
      await _refresh();
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _refresh() async {
    _refreshToken?.cancel('superseded by a newer refresh');
    _loadMoreToken?.cancel('refreshed while loadMore was in flight');
    final token = _refreshToken = WCancelToken();

    final oldData = _state.value.data;
    final oldPage = _page;
    final oldHasMore = _hasMore.value;
    final generation = ++_generation;
    _page = initialPage;
    _hasMore.value = true;
    _loadMoreError.value = null;
    _state.value = WAsyncState<List<T>>.loading(previousData: oldData);

    final result = await WAsync.tryRun<List<T>>(
      () => _loader(initialPage, token),
      options: onError == null ? null : WAsyncOptions(onError: onError),
      cancelToken: token,
    );

    if (_disposed || generation != _generation || token.isCancelled) return;

    if (result is WAsyncSuccess<List<T>>) {
      final value = result.value;
      _page = initialPage + 1;
      _hasMore.value = value.isNotEmpty;
      _state.value = value.isEmpty
          ? WAsyncState<List<T>>.empty()
          : WAsyncState<List<T>>.ready(_ChunkedList<T>.from(value));
    } else if (result is WAsyncFailure<List<T>>) {
      _page = oldPage;
      _hasMore.value = oldHasMore;
      _state.value = WAsyncState<List<T>>.failed(
        result.error,
        previousData: oldData,
      );
    }
    // WAsyncCancelled 已在上面的 token.isCancelled 提前返回。
  }

  /// 追加下一页；失败只写 [loadMoreError]，不会清空已有列表。
  Future<void> loadMore() async {
    if (_disposed || _isLoadingMore.value || !_hasMore.value || _refreshing) {
      return;
    }

    final current = _state.value.data;
    if (current == null) {
      await refresh();
      return;
    }

    final requestedPage = _page;
    final token = _loadMoreToken = WCancelToken();
    final generation = _generation;
    _isLoadingMore.value = true;
    _loadMoreError.value = null;

    final result = await WAsync.tryRun<List<T>>(
      () => _loader(requestedPage, token),
      options: onError == null ? null : WAsyncOptions(onError: onError),
      cancelToken: token,
    );

    if (!_disposed) _isLoadingMore.value = false;
    if (_disposed || generation != _generation) return;

    switch (result) {
      case WAsyncSuccess<List<T>>(:final value):
        if (value.isEmpty) {
          _hasMore.value = false;
          return;
        }
        _page++;
        final next = current is _ChunkedList<T>
            ? current.appendAll(value)
            : _ChunkedList<T>.from(current).appendAll(value);
        _state.value = WAsyncState<List<T>>.ready(next);
      case WAsyncFailure<List<T>>(:final error):
        _loadMoreError.value = error;
      case WAsyncCancelled<List<T>>():
        return;
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _refreshToken?.cancel('controller disposed');
    _loadMoreToken?.cancel('controller disposed');
    _state.dispose();
    _isLoadingMore.dispose();
    _loadMoreError.dispose();
    _hasMore.dispose();
  }
}

/// 追加 O(页大小 + chunk 数) 的不可变列表。
///
/// 每次 append 只复制最后一个 chunk（≤ 256）和外层 chunk 引用，
/// 旧版本共享前面的 chunk，用于分页列表的结构共享。
class _ChunkedList<T> extends ListBase<T> {
  _ChunkedList._(this._chunks, this._length);

  factory _ChunkedList.from(Iterable<T> items) {
    final chunks = <List<T>>[];
    var current = <T>[];
    var length = 0;
    for (final item in items) {
      if (current.length == _chunkSize) {
        chunks.add(List<T>.unmodifiable(current));
        current = <T>[];
      }
      current.add(item);
      length++;
    }
    if (current.isNotEmpty) chunks.add(List<T>.unmodifiable(current));
    return _ChunkedList<T>._(List<List<T>>.unmodifiable(chunks), length);
  }

  static const int _chunkShift = 8;
  static const int _chunkSize = 1 << _chunkShift;

  final List<List<T>> _chunks;
  final int _length;

  @override
  int get length => _length;

  @override
  set length(int value) => throw UnsupportedError('不可变列表');

  @override
  T operator [](int index) {
    if (index < 0 || index >= _length) {
      throw RangeError.index(index, this);
    }
    return _chunks[index >> _chunkShift][index & (_chunkSize - 1)];
  }

  @override
  void operator []=(int index, T value) => throw UnsupportedError('不可变列表');

  /// 返回追加 [items] 后的新列表；当前列表不变。
  _ChunkedList<T> appendAll(Iterable<T> items) {
    final chunks = List<List<T>>.of(_chunks, growable: true);
    var last = chunks.isEmpty ? <T>[] : List<T>.of(chunks.removeLast(), growable: true);
    var length = _length;
    for (final item in items) {
      if (last.length == _chunkSize) {
        chunks.add(List<T>.unmodifiable(last));
        last = <T>[];
      }
      last.add(item);
      length++;
    }
    if (last.isNotEmpty) chunks.add(List<T>.unmodifiable(last));
    return _ChunkedList<T>._(List<List<T>>.unmodifiable(chunks), length);
  }

  @override
  String toString() => toList().toString();
}
