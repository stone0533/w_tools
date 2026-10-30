import 'package:flutter/foundation.dart';

import 'async_state.dart';

typedef WAsyncPageLoader<T> = Future<List<T>> Function(int page);

/// 列表分页状态：首屏、刷新、追加、hasMore 与 loadMore 错误。
///
/// 与 [WAsyncController] 分开：普通请求用 [WAsyncController]，
/// 需要追加下一页时用 [WAsyncPagedController]。
class WAsyncPagedController<T> {
  WAsyncPagedController(
    this._loader, {
    this.initialPage = 1,
    WAsyncState<List<T>>? initial,
  })  : _page = initialPage,
        _state = ValueNotifier(initial ?? WAsyncState<List<T>>.loading());

  final WAsyncPageLoader<T> _loader;
  final int initialPage;

  final ValueNotifier<WAsyncState<List<T>>> _state;
  final ValueNotifier<bool> _isLoadingMore = ValueNotifier(false);
  final ValueNotifier<Object?> _loadMoreError = ValueNotifier(null);

  int _page;
  bool _hasMore = true;
  bool _disposed = false;
  int _generation = 0;

  ValueListenable<WAsyncState<List<T>>> get state => _state;
  ValueListenable<bool> get isLoadingMore => _isLoadingMore;
  ValueListenable<Object?> get loadMoreError => _loadMoreError;

  bool get hasMore => _hasMore;

  /// 重新加载第一页；失败时保留旧数据。
  Future<void> refresh() async {
    if (_disposed) return;

    final oldData = _state.value.dataOrNull;
    final generation = ++_generation;
    _page = initialPage;
    _hasMore = true;
    _loadMoreError.value = null;
    _state.value = WAsyncState<List<T>>.loading(previousData: oldData);

    try {
      final page = await _loader(initialPage);
      if (_disposed || generation != _generation) return;

      _page = initialPage + 1;
      _hasMore = page.isNotEmpty;
      final items = List<T>.unmodifiable(page);
      _state.value =
          items.isEmpty ? WAsyncState<List<T>>.empty() : WAsyncState<List<T>>.ready(items);
    } catch (error) {
      if (_disposed || generation != _generation) return;
      _state.value = WAsyncState<List<T>>.failed(
        error,
        previousData: oldData,
      );
    }
  }

  /// 追加下一页；失败只写 [loadMoreError]，不会清空已有列表。
  Future<void> loadMore() async {
    if (_disposed || _isLoadingMore.value || !_hasMore) return;

    final current = _state.value.dataOrNull;
    if (current == null) {
      await refresh();
      return;
    }

    final generation = _generation;
    _isLoadingMore.value = true;
    _loadMoreError.value = null;

    try {
      final page = await _loader(_page);
      if (_disposed || generation != _generation) return;

      if (page.isEmpty) {
        _hasMore = false;
        return;
      }

      _page++;
      _state.value = WAsyncState<List<T>>.ready(
        List<T>.unmodifiable([...current, ...page]),
      );
    } catch (error) {
      if (_disposed || generation != _generation) return;
      _loadMoreError.value = error;
    } finally {
      if (!_disposed) _isLoadingMore.value = false;
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _state.dispose();
    _isLoadingMore.dispose();
    _loadMoreError.dispose();
  }
}
