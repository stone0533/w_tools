import 'package:flutter/foundation.dart';

import '../task/async_task.dart';
import 'async_state.dart';

/// 管理一个异步区块的状态与加载动作。
///
/// 每个页面区块使用一个独立实例；旧请求返回后不会覆盖新请求的状态。
/// 每次 [load] 会取消上一次的 [WCancelToken]（loader 若接收 token 可据此中止），
/// [dispose] 也会取消；取消是协作式的，底层 Future 是否中止由 loader 决定。
///
/// 所有异常（包括 `Error`）都会转为 failed，方便 UI 展示；需要区分业务异常与
/// 编程错误时，请直接使用 [WAsync]。
class WAsyncController<T> {
  WAsyncController(
    this._loader, {
    this.options,
    bool Function(T value)? isEmpty,
    WAsyncState<T>? initial,
  }) : _isEmpty = isEmpty,
       _state = ValueNotifier(initial ?? WAsyncState<T>.loading());

  /// 列表场景：空列表自动归为 empty。
  static WAsyncController<List<E>> list<E>(
    Future<List<E>> Function() loader, {
    WAsyncOptions? options,
    WAsyncState<List<E>>? initial,
  }) {
    return WAsyncController<List<E>>(
      loader,
      options: options,
      isEmpty: (value) => value.isEmpty,
      initial: initial,
    );
  }

  final Future<T> Function() _loader;

  /// 执行选项（错误兜底等）；页面级加载状态由控制器自己维护，不需要 `loading`
  final WAsyncOptions? options;

  final bool Function(T value)? _isEmpty;
  final ValueNotifier<WAsyncState<T>> _state;

  /// 外部只读；状态变更必须经过 controller。
  ValueListenable<WAsyncState<T>> get state => _state;

  int _generation = 0;
  bool _disposed = false;
  WCancelToken? _token;

  /// 重新加载；失败时保留旧数据。
  Future<void> load() async {
    if (_disposed) return;

    _token?.cancel('superseded by a newer load');
    final token = _token = WCancelToken();

    final previousData = _state.value.dataOrNull;
    final generation = ++_generation;
    _state.value = WAsyncState.loading(previousData: previousData);

    Object? failure;
    (T,)? result;
    try {
      result = await WAsync.run<T, (T,)>(
        _loader,
        // 控制器自己管理四态，不再触发 options.loading 双重 loading
        options: options?.copyWith(loading: null),
        onSuccess: (value) => (value,),
        onError: (error) {
          failure = error;
          // 方法级 onError 会屏蔽 options.onError，这里显式补一次
          try {
            options?.onError?.call(error);
          } catch (_) {
            // 忽略兜底回调自身异常
          }
        },
        cancelToken: token,
      );
    } catch (error) {
      // 旧实现把所有异常（含 Error）转为 failed；保持该语义
      if (_disposed || generation != _generation || token.isCancelled) return;
      _state.value = WAsyncState.failed(error, previousData: previousData);
      return;
    }

    if (_disposed || generation != _generation || token.isCancelled) return;

    if (result != null) {
      final value = result.$1;
      _state.value = _isEmpty?.call(value) == true ? WAsyncState.empty() : WAsyncState.ready(value);
      return;
    }

    _state.value = WAsyncState.failed(
      failure ?? StateError('加载失败'),
      previousData: previousData,
    );
  }

  /// 手动重试入口。
  Future<void> retry() => load();

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _token?.cancel('controller disposed');
    _state.dispose();
  }
}
