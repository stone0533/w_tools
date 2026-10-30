import 'package:flutter/foundation.dart';

import 'async_state.dart';

/// 管理一个异步区块的状态与加载动作。
///
/// 每个页面区块使用一个独立实例；旧请求返回后不会覆盖新请求的状态。
class WAsyncController<T> {
  WAsyncController(
    this._loader, {
    bool Function(T value)? isEmpty,
  }) : _isEmpty = isEmpty;

  /// 列表场景：空列表自动归为 empty。
  static WAsyncController<List<E>> list<E>(
    Future<List<E>> Function() loader,
  ) {
    return WAsyncController<List<E>>(
      loader,
      isEmpty: (value) => value.isEmpty,
    );
  }

  final Future<T> Function() _loader;
  final bool Function(T value)? _isEmpty;

  final ValueNotifier<WAsyncState<T>> state = ValueNotifier(const WAsyncState.loading());

  int _generation = 0;
  bool _disposed = false;

  /// 重新加载；失败时保留旧数据。
  Future<void> load() async {
    if (_disposed) return;

    final previousData = state.value.dataOrNull;
    final generation = ++_generation;
    state.value = WAsyncState.loading(previousData: previousData);

    try {
      final value = await _loader();
      if (_disposed || generation != _generation) return;

      state.value = _isEmpty?.call(value) == true ? WAsyncState.empty() : WAsyncState.ready(value);
    } catch (error) {
      if (_disposed || generation != _generation) return;
      state.value = WAsyncState.failed(error, previousData: previousData);
    }
  }

  /// 手动重试入口。
  Future<void> retry() => load();

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    state.dispose();
  }
}
