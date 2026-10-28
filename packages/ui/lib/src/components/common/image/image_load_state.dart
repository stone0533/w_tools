import 'image_types.dart';

/// 加载 / 重试 / 进度的一次性状态
///
/// 从 `WImage` 的状态里抽出来：重试时机、去重与进度合并都可以脱离 widget 阅读。
/// 真正的回调仍留在 State（依赖 `mounted` 与 widget 回调）。
///
/// 公开只为测试可见；不属于 barrel 导出的公共 API。
class WImageLoadState {
  /// 上一次已通知的加载状态
  WImageLoadStatus? status;

  /// 已执行的重试次数
  int attempt = 0;

  /// 加载代际：数据变化 / 手动重试时 +1，用来丢弃过期的延迟重试
  int generation = 0;

  /// 是否有待执行的重试（避免 errorWidget 多次构建时重复调度）
  bool retryScheduled = false;

  /// 是否已经上报过进度 1.0
  bool completedProgressSent = false;

  /// 是否有待上报的进度（同一帧内的多次进度只上报最后一次）
  bool progressScheduled = false;
  WImageProgress? pendingProgress;

  /// 上一次见到的重试配置（config 可变，只能靠快照检测变化）
  int retryCountSeen = 0;
  int retryDelaySeen = 1000;

  /// 重置到初始状态
  void reset({required int retryCount, required int retryDelay}) {
    status = null;
    attempt = 0;
    generation++;
    retryScheduled = false;
    completedProgressSent = false;
    progressScheduled = false;
    pendingProgress = null;
    retryCountSeen = retryCount;
    retryDelaySeen = retryDelay;
  }

  /// 标记新状态；返回是否发生变化（用于去重）
  bool markStatus(WImageLoadStatus next) {
    if (status == next) return false;
    status = next;
    return true;
  }

  /// 重试配置变化时重置重试进度；返回是否发生了变化
  bool syncRetryConfig({required int retryCount, required int retryDelay}) {
    if (retryCount == retryCountSeen && retryDelay == retryDelaySeen) {
      return false;
    }
    retryCountSeen = retryCount;
    retryDelaySeen = retryDelay;
    attempt = 0;
    retryScheduled = false;
    completedProgressSent = false;
    pendingProgress = null;
    // 取消已经排队的旧重试：_scheduleRetry 的回调会比对 generation
    generation++;
    return true;
  }

  /// 开始新一次尝试（自动重试或手动重试）
  void beginAttempt() {
    attempt++;
    status = null;
    completedProgressSent = false;
    pendingProgress = null;
  }
}
