import 'package:flutter/foundation.dart';

import '../task/async_task.dart';
import 'async_state.dart';

/// 接收 [WCancelToken] 的 loader。
typedef WAsyncTokenLoader<T> = Future<T> Function(WCancelToken token);

/// 管理一个异步区块的状态与加载动作。
///
/// 每个页面区块使用一个独立实例；旧请求返回后不会覆盖新请求的状态。
/// [load] 会取消上一次的 [WCancelToken]；[dispose] 也会取消。
class WAsyncController<T> {
  WAsyncController(
    Future<T> Function() loader, {
    WAsyncOptions? options,
    bool Function(T value)? isEmpty,
    WAsyncState<T>? initial,
  }) : this._(
         (token) => loader(),
         options: options,
         isEmpty: isEmpty,
         initial: initial,
       );

  /// 需要感知取消的 loader 版本。
  WAsyncController.withToken(
    WAsyncTokenLoader<T> loader, {
    WAsyncOptions? options,
    bool Function(T value)? isEmpty,
    WAsyncState<T>? initial,
  }) : this._(
         loader,
         options: options,
         isEmpty: isEmpty,
         initial: initial,
       );

  WAsyncController._(
    this._loader, {
    this.options,
    bool Function(T value)? isEmpty,
    WAsyncState<T>? initial,
  }) : assert(
         options == null || options.activity == null,
         'WAsyncController 自己维护四态，options.activity 会被忽略；'
         '并发活动计数请直接用 WAsync。',
       ),
       _isEmpty = isEmpty,
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

  final WAsyncTokenLoader<T> _loader;

  /// 执行选项；页面级状态由控制器维护，传入 [WAsyncOptions.activity] 会断言。
  final WAsyncOptions? options;

  final bool Function(T value)? _isEmpty;
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
      options: options?.withoutActivity(),
      cancelToken: token,
    );

    if (_disposed || generation != _generation || token.isCancelled) return;

    switch (result) {
      case WAsyncSuccess<T>(:final value):
        _state.value = _isEmpty?.call(value) == true
            ? WAsyncState<T>.empty()
            : WAsyncState<T>.ready(value);
      case WAsyncFailure<T>(:final error):
        _state.value = WAsyncState<T>.failed(
          error,
          previousData: previousData,
        );
      case WAsyncCancelled<T>():
        return;
    }
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
