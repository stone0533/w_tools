import 'package:flutter/foundation.dart';

import '../task/async_task.dart';
import 'async_state.dart';

/// 分页 loader：页码 + 取消令牌。
typedef WAsyncPageLoader<T> = Future<WAsyncPage<T>> Function(int page, WCancelToken token);

/// 一页数据 + 是否还有更多。
///
/// [hasMore] 为 null 时沿用旧规则：本页非空即认为还有更多。
@immutable
class WAsyncPage<T> {
  const WAsyncPage({required this.items, this.hasMore});

  final List<T> items;
  final bool? hasMore;
}

/// 分页 footer 的展示状态，由 [WAsyncPagedSnapshot.footerStatus] 派生。
enum WAsyncPagedFooterStatus {
  /// 不显示 footer（首屏 loading / empty / 整页 failed，或第一页就到底）。
  hidden,

  /// 正在追加下一页。
  loading,

  /// 追加失败；可点击重试。
  failed,

  /// 已翻过页且没有更多。
  noMore,

  /// 可以继续上拉 / 加载更多。
  loadMore,
}

/// 分页列表在某一刻的只读快照。
///
/// 唯一的变化通知入口是 [WAsyncPagedController.snapshot]；footer 读
/// [footerStatus]，需要错误文案时读 [loadMoreError]，需要判断是否还能加载时读
/// [hasMore]。
@immutable
class WAsyncPagedSnapshot<T> {
  const WAsyncPagedSnapshot({
    required this.state,
    required this.footerStatus,
    required this.loadMoreError,
    required this.hasMore,
  });

  /// 列表四态（首屏 / 刷新 / 旧数据保留）。
  final WAsyncState<List<T>> state;

  /// footer 应展示的状态。
  final WAsyncPagedFooterStatus footerStatus;

  /// 最近一次追加失败的错误；没有失败时为 null。
  final Object? loadMoreError;

  /// 是否还有下一页。
  final bool hasMore;

  /// 是否正在追加下一页（由 [footerStatus] 派生）。
  bool get isLoadingMore => footerStatus == WAsyncPagedFooterStatus.loading;

  @override
  bool operator ==(Object other) =>
      other is WAsyncPagedSnapshot<T> &&
      other.state == state &&
      other.footerStatus == footerStatus &&
      other.loadMoreError == loadMoreError &&
      other.hasMore == hasMore;

  @override
  int get hashCode => Object.hash(state, footerStatus, loadMoreError, hasMore);

  @override
  String toString() =>
      'WAsyncPagedSnapshot<$T>(footer: ${footerStatus.name}, '
      'hasMore: $hasMore)';
}

/// 列表分页状态：首屏、刷新、追加、hasMore 与 loadMore 错误。
///
/// 观察入口只有两个：
/// - [snapshot]：footer / 提示条 / 是否还能加载；
/// - [state]：直接喂给 `WAsyncView` 的只读视图。
///
/// 两者都由同一个内部通知源派生，不会出现两套状态漂移。
/// 分页状态控制器。
///
/// `refresh` / `loadMore` 内部不读取全局 hooks（无全局 hooks）；页面四态与 footer
/// 由 `WAsyncPagedList` / `WAsyncPagedSliver` 负责。
class WAsyncPagedController<T> {
  WAsyncPagedController(
    WAsyncPageLoader<T> loader, {
    int initialPage = 1,
    void Function(Object error)? onError,
    WAsyncState<List<T>>? initial,
  }) : this._(
         loader,
         initialPage: initialPage,
         onError: onError,
         initial: initial,
       );

  /// 列表 loader 的便捷构造：本页非空即认为还有更多。
  static WAsyncPagedController<E> list<E>(
    Future<List<E>> Function(int page, WCancelToken token) loader, {
    int initialPage = 1,
    void Function(Object error)? onError,
    WAsyncState<List<E>>? initial,
  }) {
    return WAsyncPagedController<E>(
      (page, token) async => WAsyncPage<E>(items: await loader(page, token)),
      initialPage: initialPage,
      onError: onError,
      initial: initial,
    );
  }

  WAsyncPagedController._(
    this._loader, {
    int initialPage = 1,
    this.onError,
    WAsyncState<List<T>>? initial,
  }) : _initialPage = _checkInitialPage(initialPage),
       _page = _resolvePage(initialPage, initial),
       _hasMore = _hasMoreFromInitial(initial),
       _state = initial ?? WAsyncState<List<T>>.loading() {
    _snapshot = ValueNotifier<WAsyncPagedSnapshot<T>>(_buildSnapshot());
    _stateView = _PagedStateView<T>(_snapshot);
  }

  static int _checkInitialPage(int initialPage) {
    if (initialPage < 1) {
      throw ArgumentError.value(initialPage, 'initialPage', '必须大于 0');
    }
    return initialPage;
  }

  static int _resolvePage<T>(int initialPage, WAsyncState<List<T>>? initial) {
    return (initial?.data?.isNotEmpty ?? false) ? initialPage + 1 : initialPage;
  }

  /// 初始为空列表时视为没有更多；null / 未提供时仍允许加载。
  static bool _hasMoreFromInitial<T>(WAsyncState<List<T>>? initial) {
    if (initial == null) return true;
    if (initial.isEmpty) return false;
    return initial.data?.isNotEmpty ?? true;
  }

  final WAsyncPageLoader<T> _loader;
  final int _initialPage;

  /// 失败兜底回调；分页状态由控制器维护。
  final void Function(Object error)? onError;

  late final ValueNotifier<WAsyncPagedSnapshot<T>> _snapshot;
  late final ValueListenable<WAsyncState<List<T>>> _stateView;

  WAsyncState<List<T>> _state;
  bool _isLoadingMore = false;
  Object? _loadMoreError;
  bool _hasMore;

  int _page;
  bool _disposed = false;
  int _generation = 0;
  bool _refreshing = false;
  WCancelToken? _refreshToken;
  WCancelToken? _loadMoreToken;

  /// 唯一的分页状态通知入口。
  ValueListenable<WAsyncPagedSnapshot<T>> get snapshot => _snapshot;

  /// 列表四态的只读视图；直接传给 `WAsyncView`。
  ValueListenable<WAsyncState<List<T>>> get state => _stateView;

  /// 重新加载第一页；失败时保留旧数据。
  ///
  /// 刷新在飞时再次调用会取消上一次请求并以本次为准：旧请求的结果不会写入
  /// [state]。切换筛选 / 搜索时直接再调一次即可，不需要禁用输入。
  Future<void> refresh() async {
    if (_disposed) return;
    final generation = ++_generation;
    _refreshing = true;
    try {
      await _refresh(generation);
    } finally {
      // 被取代的旧 refresh 结束时不能清掉新 refresh 的闸门。
      if (!_disposed && generation == _generation) {
        _refreshing = false;
        _emit();
      }
    }
  }

  Future<void> _refresh(int generation) async {
    _refreshToken?.cancel('superseded by a newer refresh');
    _loadMoreToken?.cancel('refreshed while loadMore was in flight');
    final token = _refreshToken = WCancelToken();

    final previousData = _state.data;
    _isLoadingMore = false;
    _loadMoreError = null;
    _state = WAsyncState<List<T>>.loading(previousData: previousData);
    _emit();

    final result = await WAsync.tryRun<WAsyncPage<T>>(
      () => _loader(_initialPage, token),
      hooks: WAsyncHooks.none,
      onError: onError,
      cancelToken: token,
    );

    if (_disposed || generation != _generation || token.isCancelled) return;

    if (result is WAsyncSuccess<WAsyncPage<T>>) {
      final page = result.value;
      final items = page.items;
      _page = _initialPage + 1;
      _hasMore = items.isEmpty ? false : (page.hasMore ?? true);
      _state = items.isEmpty
          ? WAsyncState<List<T>>.empty()
          : WAsyncState<List<T>>.ready(List<T>.unmodifiable(items));
      _emit();
    } else if (result is WAsyncFailure<WAsyncPage<T>>) {
      // 失败时保留上一次成功的页号 / hasMore，避免被取代的刷新回滚到
      // 另一次刷新的临时值。
      _state = WAsyncState<List<T>>.failed(
        result.error,
        previousData: previousData,
      );
      _emit();
    }
    // WAsyncCancelled 已在上面的 token.isCancelled 提前返回。
  }

  /// 追加下一页；失败只写 [WAsyncPagedSnapshot.loadMoreError]，不会清空已有列表。
  Future<void> loadMore() async {
    if (_disposed || _isLoadingMore || !_hasMore || _refreshing) {
      return;
    }

    final current = _state.data;
    if (current == null) {
      await refresh();
      return;
    }

    final requestedPage = _page;
    final token = _loadMoreToken = WCancelToken();
    final generation = _generation;
    _isLoadingMore = true;
    _loadMoreError = null;
    _emit();

    final result = await WAsync.tryRun<WAsyncPage<T>>(
      () => _loader(requestedPage, token),
      hooks: WAsyncHooks.none,
      onError: onError,
      cancelToken: token,
    );

    if (_disposed) return;
    _isLoadingMore = false;
    // token 取消覆盖外部取代；generation 覆盖 onError 回调里重入
    // refresh / replaceData 的场景，避免旧失败在刷新之后写回 stale loadMoreError。
    if (generation != _generation) return;

    switch (result) {
      case WAsyncSuccess<WAsyncPage<T>>(:final value):
        final items = value.items;
        if (items.isEmpty) {
          _hasMore = false;
          _emit();
          return;
        }
        _page++;
        _hasMore = value.hasMore ?? true;
        _state = WAsyncState<List<T>>.ready(
          List<T>.unmodifiable([...current, ...items]),
        );
        _emit();
      case WAsyncFailure<WAsyncPage<T>>(:final error):
        _loadMoreError = error;
        _emit();
      case WAsyncCancelled<WAsyncPage<T>>():
        _emit();
        return;
    }
  }

  /// 用本地数据替换当前列表（乐观更新）。
  ///
  /// 会取消在飞的 [refresh] / [loadMore] 并让它们的结果失效，避免旧请求覆盖
  /// 本地修改；需要以服务端为准时随后再调 [refresh]。
  ///
  /// [hasMore] 默认沿用当前值；空列表默认 `false`。
  /// 传入的列表会复制成不可变列表；空列表进入 [WAsyncState.empty]，
  /// 并清空 [WAsyncPagedSnapshot.loadMoreError]。
  void replaceData(List<T> data, {bool? hasMore}) {
    if (_disposed) return;

    _generation++;
    _refreshToken?.cancel('local data replaced');
    _loadMoreToken?.cancel('local data replaced');
    _refreshing = false;
    _isLoadingMore = false;
    _loadMoreError = null;

    _page = _state.data == null && _page == _initialPage ? _initialPage + 1 : _page;
    _hasMore = hasMore ?? (data.isEmpty ? false : _hasMore);
    _state = data.isEmpty
        ? WAsyncState<List<T>>.empty()
        : WAsyncState<List<T>>.ready(List<T>.unmodifiable(data));
    _emit();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _refreshToken?.cancel('controller disposed');
    _loadMoreToken?.cancel('controller disposed');
    _snapshot.dispose();
  }

  void _emit() {
    _snapshot.value = _buildSnapshot();
  }

  WAsyncPagedSnapshot<T> _buildSnapshot() {
    return WAsyncPagedSnapshot<T>(
      state: _state,
      footerStatus: _footerStatus(),
      loadMoreError: _loadMoreError,
      hasMore: _hasMore,
    );
  }

  WAsyncPagedFooterStatus _footerStatus() {
    if (_state.data == null) return WAsyncPagedFooterStatus.hidden;
    // refresh 期间 loadMore 会被静默忽略，footer 不要继续显示「加载更多」。
    if (_refreshing) return WAsyncPagedFooterStatus.hidden;
    if (_loadMoreError != null) return WAsyncPagedFooterStatus.failed;
    if (_isLoadingMore) return WAsyncPagedFooterStatus.loading;
    if (!_hasMore) {
      return _page > _initialPage + 1
          ? WAsyncPagedFooterStatus.noMore
          : WAsyncPagedFooterStatus.hidden;
    }
    return WAsyncPagedFooterStatus.loadMore;
  }
}

/// 把分页快照的 `state` 暴露成 `ValueListenable<WAsyncState<List<T>>>`。
///
/// 内部使用；保证 `WAsyncView` 与 footer 看的是同一个通知源。
class _PagedStateView<T> implements ValueListenable<WAsyncState<List<T>>> {
  _PagedStateView(this._snapshot) : _last = _snapshot.value.state;

  final ValueListenable<WAsyncPagedSnapshot<T>> _snapshot;
  final List<VoidCallback> _listeners = [];
  WAsyncState<List<T>> _last;

  @override
  WAsyncState<List<T>> get value => _snapshot.value.state;

  void _onSnapshotChanged() {
    final next = _snapshot.value.state;
    if (next == _last) return;
    _last = next;
    for (final listener in List<VoidCallback>.of(_listeners)) {
      listener();
    }
  }

  @override
  void addListener(VoidCallback listener) {
    if (_listeners.isEmpty) {
      _last = value;
      _snapshot.addListener(_onSnapshotChanged);
    }
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    if (_listeners.remove(listener) && _listeners.isEmpty) {
      _snapshot.removeListener(_onSnapshotChanged);
    }
  }
}
