// ============== 取消令牌 ==============

/// 协作式取消令牌
///
/// 传入 [WAsync] 各执行方法的 `cancelToken` 后，任务会在开始、结束以及
/// 重试等待等边界处检查取消状态。取消不会中止已经开始执行的 Future，
/// 只会让后续的检查点提前结束。
/// 令牌取消后不可复用：后续任务会在开始前直接返回 null。
class WCancelToken {
  /// 是否已取消
  bool _isCancelled = false;

  /// 取消原因，由 [cancel] 设置
  Object? _cancelReason;

  /// 取消回调集合
  ///
  /// [cancel] 触发后会统一清空，因此所有回调都只执行一次；
  /// 回调自身抛出的异常会被忽略。
  final Set<void Function(Object?)> _listeners = {};

  /// 是否已取消
  bool get isCancelled => _isCancelled;

  /// 取消原因；未取消时为 null
  Object? get cancelReason => _cancelReason;

  /// 添加取消回调
  ///
  /// 若令牌已取消，回调会立即以 [cancelReason] 调用，且不会被登记。
  void addListener(void Function(Object? reason) callback) {
    if (_isCancelled) {
      try {
        callback(_cancelReason);
      } catch (e) {
        // 回调异常不影响取消流程
      }
      return;
    }
    _listeners.add(callback);
  }

  /// 移除取消回调
  ///
  /// 移除未登记的监听不会报错。
  void removeListener(void Function(Object? reason) callback) {
    _listeners.remove(callback);
  }

  /// 取消操作，并通知所有监听
  ///
  /// 重复调用只会更新 [cancelReason]，不再触发回调（监听已在首次取消时清空）。
  void cancel([Object? reason]) {
    _isCancelled = true;
    _cancelReason = reason;
    // 遍历副本，允许回调内部增删监听
    for (final callback in _listeners.toList()) {
      try {
        callback(reason);
      } catch (e) {
        // 回调异常不影响取消流程
      }
    }
    _listeners.clear();
  }

  /// 若已取消则抛出 [WCancellationException]，否则不做任何事
  void throwIfCancelled() {
    if (_isCancelled) {
      throw WCancellationException(_cancelReason);
    }
  }

  /// 清空尚未触发的取消回调
  ///
  /// 不会重置 [isCancelled] / [cancelReason]。
  void clearListeners() {
    _listeners.clear();
  }
}

/// 取消异常
///
/// 由 [WCancelToken.throwIfCancelled] 抛出；[WAsync] 会将其视为正常结束，
/// 不回调 `onError`，并返回 null。
class WCancellationException implements Exception {
  /// 取消原因
  final Object? reason;

  /// 创建取消异常
  WCancellationException(this.reason);

  @override
  String toString() {
    return 'WCancellationException: $reason';
  }
}
