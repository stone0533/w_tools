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
    WAsyncOptions? options,
    WAsyncState<List<T>>? initial,
  }) : this._(
         (page, _) => loader(page),
         initialPage: initialPage,
         options: options,
         initial: initial,
       );

  /// 需要感知取消的分页 loader 版本。
  WAsyncPagedController.withToken(
    WAsyncTokenPageLoader<T> loader, {
    int initialPage = 1,
    WAsyncOptions? options,
    WAsyncState<List<T>>? initial,
  }) : this._(
         loader,
         initialPage: initialPage,
         options: options,
         initial: initial,
       );

  WAsyncPagedController._(
    this._loader, {
    this.initialPage = 1,
    this.options,
    WAsyncState<List<T>>? initial,
  }) : _page = _resolvePage(initialPage, initial),
       _hasMore = ValueNotifier(_hasMoreFromInitial(initial)),
       _state = ValueNotifier(initial ?? WAsyncState<List<T>>.loading()) {
    final activity = options?.activity;
    if (activity != null) {
      throw ArgumentError.value(
        activity,
        'options.activity',
        'WAsyncPagedController 自己维护加载状态，不接受 activity；'
            '并发活动计数请直接用 WAsync。',
      );
    }
  }

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

  /// 执行选项；分页状态由控制器维护。
  /// 传入 [WAsyncOptions.activity] 会在构造时抛 [ArgumentError]，
  /// release 下也一样，不会静默忽略。
  final WAsyncOptions? options;

  final ValueNotifier<WAsyncState<List<T>>> _state;
  final ValueNotifier<bool> _isLoadingMore = ValueNotifier(false);
  final ValueNotifier<Object?> _loadMoreError = ValueNotifier(null);
  final ValueNotifier<bool> _hasMore;

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
      options: options?.withoutActivity(),
      cancelToken: token,
    );

    if (_disposed || generation != _generation || token.isCancelled) return;

    switch (result) {
      case WAsyncSuccess<List<T>>(:final value):
        _page = initialPage + 1;
        _hasMore.value = value.isNotEmpty;
        final items = List<T>.unmodifiable(value);
        _state.value = items.isEmpty
            ? WAsyncState<List<T>>.empty()
            : WAsyncState<List<T>>.ready(items);
      case WAsyncFailure<List<T>>(:final error):
        _page = oldPage;
        _hasMore.value = oldHasMore;
        _state.value = WAsyncState<List<T>>.failed(
          error,
          previousData: oldData,
        );
      case WAsyncCancelled<List<T>>():
        return;
    }
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
      options: options?.withoutActivity(),
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
        _state.value = WAsyncState<List<T>>.ready(
          List<T>.unmodifiable([...current, ...value]),
        );
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
