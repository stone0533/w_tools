import 'package:flutter/foundation.dart';

import '../task/async_task.dart';
import 'async_state.dart';

typedef WAsyncPageLoader<T> = Future<List<T>> Function(int page);

/// 列表分页状态：首屏、刷新、追加、hasMore 与 loadMore 错误。
///
/// 与 [WAsyncController] 分开：普通请求用 [WAsyncController]，
/// 需要追加下一页时用 [WAsyncPagedController]。
/// 刷新会取消上一次的 [WCancelToken]（loader 若接收 token 可据此中止）。
class WAsyncPagedController<T> {
  WAsyncPagedController(
    this._loader, {
    this.initialPage = 1,
    this.options,
    WAsyncState<List<T>>? initial,
  }) : _page = initial?.dataOrNull != null ? initialPage + 1 : initialPage,
       _state = ValueNotifier(initial ?? WAsyncState<List<T>>.loading());

  final WAsyncPageLoader<T> _loader;
  final int initialPage;

  /// 执行选项（错误兜底等）；分页的加载状态由本类维护，传入的 `loading` 会被忽略
  final WAsyncOptions? options;

  final ValueNotifier<WAsyncState<List<T>>> _state;
  final ValueNotifier<bool> _isLoadingMore = ValueNotifier(false);
  final ValueNotifier<Object?> _loadMoreError = ValueNotifier(null);

  int _page;
  bool _hasMore = true;
  bool _disposed = false;
  int _generation = 0;
  bool _refreshing = false;
  WCancelToken? _token;

  ValueListenable<WAsyncState<List<T>>> get state => _state;
  ValueListenable<bool> get isLoadingMore => _isLoadingMore;
  ValueListenable<Object?> get loadMoreError => _loadMoreError;

  /// 是否还有下一页。
  ///
  /// 这是普通 getter，不是 ValueListenable；footer 应同时监听
  /// [isLoadingMore] / [loadMoreError] / [state]。
  bool get hasMore => _hasMore;

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
    _token?.cancel('superseded by a newer refresh');
    final token = _token = WCancelToken();

    final oldData = _state.value.dataOrNull;
    final oldPage = _page;
    final oldHasMore = _hasMore;
    final generation = ++_generation;
    _page = initialPage;
    _hasMore = true;
    _loadMoreError.value = null;
    _state.value = WAsyncState<List<T>>.loading(previousData: oldData);

    Object? failure;
    (List<T>,)? result;
    try {
      result = await WAsync.run<List<T>, (List<T>,)>(
        () => _loader(initialPage),
        options: options?.copyWith(loading: null),
        onSuccess: (value) => (value,),
        onError: (error) {
          failure = error;
          try {
            options?.onError?.call(error);
          } catch (_) {
            // 忽略兜底回调自身异常
          }
        },
        cancelToken: token,
      );
    } catch (error) {
      if (_disposed || generation != _generation || token.isCancelled) return;
      _page = oldPage;
      _hasMore = oldHasMore;
      _state.value = WAsyncState<List<T>>.failed(error, previousData: oldData);
      return;
    }

    if (_disposed || generation != _generation || token.isCancelled) return;

    if (result == null) {
      // 刷新失败：保留旧列表与旧分页游标，否则下一次 loadMore 会重复追加
      _page = oldPage;
      _hasMore = oldHasMore;
      _state.value = WAsyncState<List<T>>.failed(
        failure ?? StateError('加载失败'),
        previousData: oldData,
      );
      return;
    }

    final page = result.$1;
    _page = initialPage + 1;
    _hasMore = page.isNotEmpty;
    final items = List<T>.unmodifiable(page);
    _state.value = items.isEmpty ? WAsyncState<List<T>>.empty() : WAsyncState<List<T>>.ready(items);
  }

  /// 追加下一页；失败只写 [loadMoreError]，不会清空已有列表。
  Future<void> loadMore() async {
    // 刷新 / 首屏进行中不要追加：refresh 已把 _page 重置为第一页，
    // 此时追加会重复请求第一页并污染旧列表。
    if (_disposed || _isLoadingMore.value || !_hasMore || _refreshing) {
      return;
    }

    final current = _state.value.dataOrNull;
    if (current == null) {
      await refresh();
      return;
    }

    // 页码在请求前快照，避免请求期间 refresh 修改 _page
    final requestedPage = _page;

    final generation = _generation;
    _isLoadingMore.value = true;
    _loadMoreError.value = null;

    Object? failure;
    (List<T>,)? result;
    try {
      result = await WAsync.run<List<T>, (List<T>,)>(
        () => _loader(requestedPage),
        options: options?.copyWith(loading: null),
        onSuccess: (value) => (value,),
        onError: (error) {
          failure = error;
          try {
            options?.onError?.call(error);
          } catch (_) {
            // 兜底回调自身异常不影响分页状态
          }
        },
      );
    } catch (error) {
      failure = error;
    } finally {
      if (!_disposed) _isLoadingMore.value = false;
    }

    if (_disposed || generation != _generation) return;

    if (result == null) {
      _loadMoreError.value = failure ?? StateError('加载失败');
      return;
    }

    final page = result.$1;
    if (page.isEmpty) {
      _hasMore = false;
      return;
    }

    _page++;
    _state.value = WAsyncState<List<T>>.ready(
      List<T>.unmodifiable([...current, ...page]),
    );
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _token?.cancel('controller disposed');
    _state.dispose();
    _isLoadingMore.dispose();
    _loadMoreError.dispose();
  }
}
