import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'image_load_state.dart';
import 'image_notifier.dart';
import 'image_retry_policy.dart';
import 'image_types.dart';

/// 图片加载状态持有者：把 `WImageLoadState` 与 `ValueListenable` 组合。
///
/// 渲染仍由 WImage 的 State 负责；Loader 负责可观察的加载状态。
@internal
class WImageLoader extends WImageLoadState {
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

  final ValueNotifier<WImageLoadSnapshot> _notifier =
      WImageDeferredValueNotifier<WImageLoadSnapshot>(const WImageLoadSnapshot());

  /// 状态回调（State 负责切到 post-frame）
  final ValueChanged<WImageLoadStatus>? onStatus;

  /// 进度回调
  final ValueChanged<WImageProgress>? onProgress;

  int _retryCount;
  int _retryDelay;
  int? _scheduledDelayMs;
  final Random _random;
  Timer? _retryTimer;

  /// 最近一次错误
  WImageError? error;

  /// 只读状态流
  ValueListenable<WImageLoadSnapshot> get state => _notifier;

  /// 把当前状态推给监听者
  void emit() {
    final next = WImageLoadSnapshot(
      status: status,
      progress: pendingProgress,
      attempt: attempt,
      error: error,
      retryScheduled: retryScheduled,
      retryDelayMs: retryScheduled ? _scheduledDelayMs : null,
    );
    if (_notifier.value == next) return;
    _notifier.value = next;
  }

  bool get hasRetries => autoRetries < _retryCount;

  @override
  void reset({required int retryCount, required int retryDelay}) {
    final wasActive = status != WImageLoadStatus.idle;
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryCount = retryCount;
    _retryDelay = retryDelay;
    _scheduledDelayMs = null;
    error = null;
    super.reset(retryCount: retryCount, retryDelay: retryDelay);
    if (wasActive) onStatus?.call(WImageLoadStatus.idle);
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
      _scheduledDelayMs = null;
      _retryTimer?.cancel();
      _retryTimer = null;
      // 保留已有 error：失败后修改 retry 配置不应把 failed 状态变成“无错误”
      emit();
    }
    return changed;
  }

  @override
  void beginAttempt() {
    _scheduledDelayMs = null;
    super.beginAttempt();
    emit();
  }

  /// 进入 loading（无进度事件时使用）
  void markLoading() {
    if (status == WImageLoadStatus.completed || status == WImageLoadStatus.failed) {
      return;
    }
    if (markStatus(WImageLoadStatus.loading)) {
      onStatus?.call(WImageLoadStatus.loading);
    }
    emit();
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
    emit();
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
    _scheduledDelayMs = null;
    error = null;
    if (markStatus(WImageLoadStatus.completed)) {
      onStatus?.call(WImageLoadStatus.completed);
    }
    if (notifyProgress && !completedProgressSent) {
      completedProgressSent = true;
      pendingProgress = const WImageProgress.complete();
      onProgress?.call(pendingProgress!);
    }
    emit();
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
    _scheduledDelayMs = delay.inMilliseconds;
    _generationAtSchedule = generation;
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      if (generation != _generationAtSchedule) return;
      super.beginAttempt();
      retryScheduled = false;
      _scheduledDelayMs = null;
      error = null;
      emit();
    });
    emit();
  }

  int _generationAtSchedule = 0;

  /// 手动重试：取消定时器并立即开始新一轮
  void retryNow() {
    _retryTimer?.cancel();
    _retryTimer = null;
    generation++;
    retryScheduled = false;
    _scheduledDelayMs = null;
    pendingProgress = null;
    error = null;
    super.beginManualAttempt();
    emit();
  }

  void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _scheduledDelayMs = null;
    if (retryScheduled) {
      retryScheduled = false;
      emit();
    }
    // 不 dispose notifier：controller 可能在 WImage 卸载后仍持有它。
    // notifier 会随 loader/controller 一起被 GC。
  }
}
