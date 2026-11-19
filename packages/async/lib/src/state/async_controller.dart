import 'package:flutter/foundation.dart';

import '../task/async_task.dart';
import 'async_state.dart';

/// 接收 [WCancelToken] 的 loader。
typedef WAsyncTokenLoader<T> = Future<T> Function(WCancelToken token);

/// 管理一个异步区块的状态与加载动作。
///
/// 每个页面区块使用一个独立实例；旧请求返回后不会覆盖新请求的状态。
/// [load] 会取消上一次的 [WCancelToken]；[dispose] 也会取消。
///
/// loader 统一接收 [WCancelToken]；不需要取消时写 `(_) => api.list()`。
/// 列表语义用 [WAsyncController.list]（空列表归 empty，data 为 unmodifiable）。
/// 页面区块的状态控制器。
///
/// [WAsyncController.load] 内部不读取全局 hooks（无全局 hooks）；页面 loading /
/// error 由 [WAsyncView] / WAsyncSection 负责。
class WAsyncController<T> {
  WAsyncController(
    WAsyncTokenLoader<T> loader, {
    void Function(Object error)? onError,
    bool Function(T value)? isEmpty,
    WAsyncState<T>? initial,
  }) : this._(
         loader,
         onError: onError,
         isEmpty: isEmpty,
         initial: initial,
       );

  WAsyncController._(
    this._loader, {
    this.onError,
    bool Function(T value)? isEmpty,
    T Function(T value)? normalize,
    WAsyncState<T>? initial,
  }) : _isEmpty = isEmpty,
       _normalize = normalize,
       _state = ValueNotifier(initial ?? WAsyncState<T>.loading());

  /// 列表场景：空列表自动归为 empty；`state.data` 为 unmodifiable。
  static WAsyncController<List<E>> list<E>(
    WAsyncTokenLoader<List<E>> loader, {
    void Function(Object error)? onError,
    WAsyncState<List<E>>? initial,
  }) {
    return WAsyncController<List<E>>._(
      loader,
      onError: onError,
      isEmpty: (value) => value.isEmpty,
      normalize: (value) => List<E>.unmodifiable(value),
      initial: initial,
    );
  }

  final WAsyncTokenLoader<T> _loader;

  /// 失败兜底回调；控制器自己维护四态。
  final void Function(Object error)? onError;

  final bool Function(T value)? _isEmpty;
  final T Function(T value)? _normalize;
  final ValueNotifier<WAsyncState<T>> _state;

  ValueListenable<WAsyncState<T>> get state => _state;

  int _generation = 0;
  bool _disposed = false;
  WCancelToken? _token;

  /// 重新加载；失败时保留旧数据。
  Future<void> load() async {
    if (_disposed) return;

    _token?.cancel('superseded by a newer load');
    final token = _token = WCancelToken();

    final previousData = _state.value.data;
    final generation = ++_generation;
    _state.value = WAsyncState.loading(previousData: previousData);

    final result = await WAsync.tryRun<T>(
      () => _loader(token),
      hooks: WAsyncHooks.none,
      onError: onError,
      cancelToken: token,
    );

    if (_disposed || generation != _generation || token.isCancelled) return;

    if (result is WAsyncSuccess<T>) {
      try {
        final value = _normalize?.call(result.value) ?? result.value;
        _state.value = _isEmpty?.call(value) == true
            ? WAsyncState<T>.empty()
            : WAsyncState<T>.ready(value);
      } catch (error) {
        // isEmpty / normalize 是调用方回调；抛错不能让 load() 的 Future 裸 reject。
        _notifyError(error);
        _state.value = WAsyncState<T>.failed(
          error,
          previousData: previousData,
        );
      }
    } else if (result is WAsyncFailure<T>) {
      _state.value = WAsyncState<T>.failed(
        result.error,
        previousData: previousData,
      );
    }
    // WAsyncCancelled 已在上面的 token.isCancelled 提前返回，不需要单独分支。
  }

  /// 用本地数据替换当前值（乐观更新）。
  ///
  /// 会取消在飞的 [load] 并让旧结果失效；构造时传入的 `isEmpty` 为 true 时
  /// 进入 empty。需要以服务端为准时随后再 [load]。
  void replaceData(T data) {
    if (_disposed) return;

    _generation++;
    _token?.cancel('local data replaced');
    _token = null;

    try {
      final value = _normalize?.call(data) ?? data;
      _state.value = _isEmpty?.call(value) == true
          ? WAsyncState<T>.empty()
          : WAsyncState<T>.ready(value);
    } catch (error) {
      _notifyError(error);
      _state.value = WAsyncState<T>.failed(
        error,
        previousData: _state.value.data,
      );
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _token?.cancel('controller disposed');
    _state.dispose();
  }

  void _notifyError(Object error) {
    try {
      onError?.call(error);
    } catch (_) {
      // onError 只是通知，自身异常不影响状态机
    }
  }
}
