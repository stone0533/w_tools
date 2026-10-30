import 'package:flutter/foundation.dart';

import 'async_state.dart';

/// 管理一个异步区块的状态与加载动作。
///
/// 每个页面区块使用一个独立实例；旧请求返回后不会覆盖新请求的状态。
///
/// [load] / [dispose] 不会中止已经启动的底层 [Future]，只保证旧结果不写入
/// 状态；需要真正取消请求时，由 loader 自己接收 `WCancelToken`。
///
/// 所有异常（包括 `Error`）都会转为 failed，方便 UI 展示；需要区分
/// 业务异常与编程错误时，请直接使用 `WAsync`。
class WAsyncController<T> {
  WAsyncController(
    this._loader, {
    bool Function(T value)? isEmpty,
    WAsyncState<T>? initial,
  })  : _isEmpty = isEmpty,
        _state = ValueNotifier(initial ?? WAsyncState<T>.loading());

  /// 列表场景：空列表自动归为 empty。
  static WAsyncController<List<E>> list<E>(
    Future<List<E>> Function() loader, {
    WAsyncState<List<E>>? initial,
  }) {
    return WAsyncController<List<E>>(
      loader,
      isEmpty: (value) => value.isEmpty,
      initial: initial,
    );
  }

  final Future<T> Function() _loader;
  final bool Function(T value)? _isEmpty;
  final ValueNotifier<WAsyncState<T>> _state;

  /// 外部只读；状态变更必须经过 controller。
  ValueListenable<WAsyncState<T>> get state => _state;

  int _generation = 0;
  bool _disposed = false;

  /// 重新加载；失败时保留旧数据。
  Future<void> load() async {
    if (_disposed) return;

    final previousData = _state.value.dataOrNull;
    final generation = ++_generation;
    _state.value = WAsyncState.loading(previousData: previousData);

    try {
      final value = await _loader();
      if (_disposed || generation != _generation) return;

      _state.value = _isEmpty?.call(value) == true ? WAsyncState.empty() : WAsyncState.ready(value);
    } catch (error) {
      if (_disposed || generation != _generation) return;
      _state.value = WAsyncState.failed(error, previousData: previousData);
    }
  }

  /// 手动重试入口。
  Future<void> retry() => load();

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _state.dispose();
  }
}
