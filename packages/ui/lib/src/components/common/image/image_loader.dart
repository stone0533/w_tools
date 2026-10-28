import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'image_load_state.dart';
import 'image_retry_policy.dart';
import 'image_types.dart';

/// 图片加载快照（供 [WImageController.state] 监听）。
@immutable
class WImageLoadSnapshot {
  const WImageLoadSnapshot({
    this.status,
    this.progress,
    this.attempt = 0,
  });

  final WImageLoadStatus? status;
  final WImageProgress? progress;
  final int attempt;

  bool get isLoading => status == WImageLoadStatus.loading;
  bool get isCompleted => status == WImageLoadStatus.completed;
  bool get isFailed => status == WImageLoadStatus.failed;

  @override
  String toString() =>
      'WImageLoadSnapshot(status: $status, attempt: $attempt, progress: $progress)';
}

/// 图片加载状态持有者：把 `WImageLoadState` 与 `ValueListenable` 组合。
///
/// 渲染仍由 WImage 的 State 负责；Loader 负责可观察的加载状态。
class WImageLoader extends WImageLoadState {
  WImageLoader({
    required int retryCount,
    required int retryDelay,
    this.onStatus,
    this.onProgress,
    Random? random,
  })  : _random = random ?? Random(),
        _retryCount = retryCount,
        _retryDelay = retryDelay {
    reset(retryCount: retryCount, retryDelay: retryDelay);
  }

  final ValueNotifier<WImageLoadSnapshot> _notifier =
      ValueNotifier<WImageLoadSnapshot>(const WImageLoadSnapshot());

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

  /// 只读状态流
  ValueListenable<WImageLoadSnapshot> get state => _notifier;

  /// 把当前状态推给监听者
  void emit() {
    _notifier.value = WImageLoadSnapshot(
      status: status,
      progress: pendingProgress,
      attempt: attempt,
    );
  }

  bool get hasRetries => attempt < _retryCount;

  @override
  void reset({required int retryCount, required int retryDelay}) {
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryCount = retryCount;
    _retryDelay = retryDelay;
    error = null;
    super.reset(retryCount: retryCount, retryDelay: retryDelay);
    emit();
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
      error = null;
      emit();
    }
    return changed;
  }

  @override
  void beginAttempt() {
    super.beginAttempt();
    emit();
  }

  /// 进入 loading（无进度事件时使用）
  void markLoading() {
    if (markStatus(WImageLoadStatus.loading)) {
      onStatus?.call(WImageLoadStatus.loading);
    }
    emit();
  }

  /// 收到进度
  void handleProgress(WImageProgress progress) {
    pendingProgress = progress;
    if (markStatus(WImageLoadStatus.loading)) {
      onStatus?.call(WImageLoadStatus.loading);
    }
    emit();
    onProgress?.call(progress);
  }

  /// 成功加载到首帧
  void handleCompleted({bool notifyProgress = false}) {
    error = null;
    if (markStatus(WImageLoadStatus.completed)) {
      onStatus?.call(WImageLoadStatus.completed);
    }
    if (notifyProgress && !completedProgressSent) {
      completedProgressSent = true;
      onProgress?.call(const WImageProgress(downloadedBytes: 1, totalBytes: 1));
    }
    emit();
  }

  /// 失败；[retry] 决定是否按网络错误策略自动重试
  void handleError(
    Object cause,
    WImageError error, {
    bool retry = false,
  }) {
    this.error = error;
    if (retry && hasRetries && isRetryableNetworkError(cause)) {
      _scheduleRetry();
      return;
    }
    if (markStatus(WImageLoadStatus.failed)) {
      onStatus?.call(WImageLoadStatus.failed);
    }
    emit();
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
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      if (generation != _generationAtSchedule) return;
      beginAttempt();
      retryScheduled = false;
      error = null;
      emit();
    });
    // 记录本次调度对应的 generation，数据变化/手动重试后旧定时器不再生效
    _generationAtSchedule = generation;
    emit();
  }

  int _generationAtSchedule = 0;

  /// 手动重试：取消定时器并立即开始新一轮
  void retryNow() {
    _retryTimer?.cancel();
    _retryTimer = null;
    beginAttempt();
    generation++;
    retryScheduled = false;
    pendingProgress = null;
    error = null;
    emit();
  }

  void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _notifier.dispose();
  }
}
