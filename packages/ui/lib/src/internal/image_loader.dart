import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'image_load_state.dart';
import '../components/common/image/image_retry_policy.dart';
import '../components/common/image/image_types.dart';

/// 图片加载状态持有者：`WImageLoadState` + `ChangeNotifier`。
///
/// 渲染仍由 WImage 的 State 负责；Loader 只负责可观察的加载状态。
@internal
class WImageLoader extends WImageLoadState with ChangeNotifier {
  WImageLoader({
    required int retryCount,
    required int retryDelay,
    this.onStatus,
    this.onProgress,
    Random? random,
  }) : _random = random ?? Random(),
       _retryCount = retryCount,
       _retryDelay = retryDelay {
    reset(retryCount: retryCount, retryDelay: retryDelay);
  }

  /// 状态回调（State 负责切到 post-frame）
  final ValueChanged<WImageLoadStatus>? onStatus;

  /// 进度回调
  final ValueChanged<WImageProgress>? onProgress;

  int _retryCount;
  int _retryDelay;
  final Random _random;
  Timer? _retryTimer;

  /// 最近一次错误
  WImageError? error;

  bool _disposed = false;
  WImageLoadStatus? _lastNotifiedStatus;
  int? _lastNotifiedAttempt;
  bool? _lastNotifiedRetryScheduled;
  Object? _lastNotifiedError;

  /// 把当前状态推给监听者（State 负责在 build 期延后重建）。
  ///
  /// 纯进度变化不触发：进度走 onProgress，重建只看状态 / 重试 / 错误。
  void _notify() {
    if (_disposed) return;
    if (status == _lastNotifiedStatus &&
        attempt == _lastNotifiedAttempt &&
        retryScheduled == _lastNotifiedRetryScheduled &&
        identical(error, _lastNotifiedError)) {
      return;
    }
    _lastNotifiedStatus = status;
    _lastNotifiedAttempt = attempt;
    _lastNotifiedRetryScheduled = retryScheduled;
    _lastNotifiedError = error;
    notifyListeners();
  }

  bool get hasRetries => autoRetries < _retryCount;

  @override
  void reset({required int retryCount, required int retryDelay}) {
    final wasActive = status != WImageLoadStatus.idle;
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryCount = retryCount;
    _retryDelay = retryDelay;
    error = null;
    super.reset(retryCount: retryCount, retryDelay: retryDelay);
    if (wasActive) onStatus?.call(WImageLoadStatus.idle);
    _notify();
  }

  @override
  bool syncRetryConfig({required int retryCount, required int retryDelay}) {
    final changed = super.syncRetryConfig(
      retryCount: retryCount,
      retryDelay: retryDelay,
    );
    if (changed) {
      _retryCount = retryCount;
      _retryDelay = retryDelay;
      _retryTimer?.cancel();
      _retryTimer = null;
      // 保留已有 error：失败后修改 retry 配置不应把 failed 状态变成“无错误”
      _notify();
    }
    return changed;
  }

  @override
  void beginAttempt() {
    super.beginAttempt();
    _notify();
  }

  /// 进入 loading（无进度事件时使用）
  void markLoading() {
    if (status == WImageLoadStatus.completed || status == WImageLoadStatus.failed) {
      return;
    }
    if (markStatus(WImageLoadStatus.loading)) {
      onStatus?.call(WImageLoadStatus.loading);
    }
    _notify();
  }

  /// 收到进度
  void handleProgress(WImageProgress progress) {
    if (status == WImageLoadStatus.completed || status == WImageLoadStatus.failed) {
      return;
    }
    final changed = pendingProgress != progress;
    pendingProgress = progress;
    if (markStatus(WImageLoadStatus.loading)) {
      onStatus?.call(WImageLoadStatus.loading);
    }
    _notify();
    // 父级/自身重建会让 loadingBuilder 用同一个 progress 再调用一次；
    // 只有进度真正变化时才对外回调，避免调用方 setState 造成重建放大。
    if (changed) onProgress?.call(progress);
  }

  /// 成功加载到首帧。
  ///
  /// 允许从 `failed` 恢复为 `completed`（例如迟到的成功帧），并取消已排队的重试。
  void handleCompleted({bool notifyProgress = false}) {
    _retryTimer?.cancel();
    _retryTimer = null;
    retryScheduled = false;
    error = null;
    if (markStatus(WImageLoadStatus.completed)) {
      onStatus?.call(WImageLoadStatus.completed);
    }
    if (notifyProgress && !completedProgressSent) {
      completedProgressSent = true;
      pendingProgress = const WImageProgress.complete();
      onProgress?.call(pendingProgress!);
    }
    _notify();
  }

  /// 失败；[retry] 决定是否按网络错误策略自动重试
  void handleError(
    Object cause,
    WImageError error, {
    bool retry = false,
  }) {
    if (status == WImageLoadStatus.completed) return;
    if (retry && hasRetries && isRetryableNetworkError(cause)) {
      if (retryScheduled) return;
      this.error = error;
      _scheduleRetry();
      return;
    }
    if (status == WImageLoadStatus.failed) return;
    this.error = error;
    if (markStatus(WImageLoadStatus.failed)) {
      onStatus?.call(WImageLoadStatus.failed);
    }
    _notify();
  }

  /// 直接失败（例如 Web 不支持 file://）
  void fail(WImageError error) => handleError(error, error);

  void _scheduleRetry() {
    if (retryScheduled) return;
    retryScheduled = true;
    final delay = retryDelayFor(
      attempt,
      base: Duration(milliseconds: _retryDelay),
      random: _random,
    );
    _generationAtSchedule = generation;
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      if (generation != _generationAtSchedule) return;
      super.beginAttempt();
      retryScheduled = false;
      error = null;
      _notify();
    });
    _notify();
  }

  int _generationAtSchedule = 0;

  /// 手动重试：取消定时器并立即开始新一轮
  void retryNow() {
    _retryTimer?.cancel();
    _retryTimer = null;
    generation++;
    retryScheduled = false;
    pendingProgress = null;
    error = null;
    super.beginManualAttempt();
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    _retryTimer = null;
    retryScheduled = false;
    super.dispose();
  }
}
