import 'package:flutter/foundation.dart';

import 'image_load_state.dart';
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
  final ValueNotifier<WImageLoadSnapshot> _notifier =
      ValueNotifier<WImageLoadSnapshot>(const WImageLoadSnapshot());

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

  @override
  void reset({required int retryCount, required int retryDelay}) {
    super.reset(retryCount: retryCount, retryDelay: retryDelay);
    emit();
  }

  @override
  bool syncRetryConfig({required int retryCount, required int retryDelay}) {
    final changed = super.syncRetryConfig(
      retryCount: retryCount,
      retryDelay: retryDelay,
    );
    if (changed) emit();
    return changed;
  }

  @override
  void beginAttempt() {
    super.beginAttempt();
    emit();
  }

  void dispose() => _notifier.dispose();
}
