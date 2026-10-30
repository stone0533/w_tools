import 'package:flutter/foundation.dart';

/// 异步区块的状态。
///
/// 与 `WAsync`（执行 + 自动重试）配套：`WAsync` 负责「怎么请求」，
/// 本类负责「界面该显示什么」。典型用法是每个独立请求持有一个状态：
///
/// ```dart
/// var gifts = const WAsyncState<List<Gift>>.loading();
///
/// Future<void> loadGifts() async {
///   final result = await WAsync.run(() => api.gifts());
///   gifts = WAsyncState.ofList(result);
/// }
/// ```
enum WAsyncStatus {
  /// 首次请求进行中（**不是**「没有数据」）
  loading,

  /// 已加载且有数据
  ready,

  /// 已加载，但数据为空
  empty,

  /// 请求失败（需要重试入口）
  failed,
}

/// 一次异步请求的状态快照（不可变）。
///
/// 约定：
/// - 首次请求发出前是 [loading]，不能用 [empty] 占位；
/// - 请求成功但结果为空才是 [empty]；
/// - 请求失败是 [failed]，与「没有数据」是两种不同状态；
/// - 已有数据时刷新失败**不要**退回 [failed]（保留旧数据 + 提示即可）。
@immutable
class WAsyncState<T> {
  /// 首次请求进行中；[previousData] 用于刷新时保留旧数据。
  const WAsyncState.loading({T? previousData})
      : status = WAsyncStatus.loading,
        data = previousData,
        error = null;

  /// 加载成功且有数据
  const WAsyncState.ready(T this.data)
      : status = WAsyncStatus.ready,
        error = null;

  /// 加载成功但没有数据
  const WAsyncState.empty()
      : status = WAsyncStatus.empty,
        data = null,
        error = null;

  /// 加载失败；[previousData] 用于刷新失败时保留旧数据。
  const WAsyncState.failed(Object this.error, {T? previousData})
      : status = WAsyncStatus.failed,
        data = previousData;

  /// 列表类数据的便捷构造：null 或空列表都视为 [empty]。
  ///
  /// ```dart
  /// final state = WAsyncState.ofList<Gift>(result);
  /// ```
  static WAsyncState<List<E>> ofList<E>(List<E>? list) => (list == null || list.isEmpty)
      ? WAsyncState<List<E>>.empty()
      : WAsyncState<List<E>>.ready(list);

  final WAsyncStatus status;
  final T? data;
  final Object? error;

  bool get isLoading => status == WAsyncStatus.loading;
  bool get isReady => status == WAsyncStatus.ready;
  bool get isEmpty => status == WAsyncStatus.empty;
  bool get isFailed => status == WAsyncStatus.failed;

  /// 按状态取值，四态必须全覆盖（不可漏分支）。
  R when<R>({
    required R Function() loading,
    required R Function(T data) ready,
    required R Function() empty,
    required R Function(Object error) failed,
  }) {
    switch (status) {
      case WAsyncStatus.loading:
        return loading();
      case WAsyncStatus.ready:
        return ready(data as T);
      case WAsyncStatus.empty:
        return empty();
      case WAsyncStatus.failed:
        return failed(error!);
    }
  }

  /// 最近一次可用数据；loading / failed 时也可能是刷新前的旧数据。
  T? get dataOrNull => data;

  /// 是否是在保留旧数据的前提下刷新。
  bool get isRefreshing => isLoading && data != null;

  /// 保留已有数据的错误信息（超过 [maxLength] 时截断，避免日志/文案过长）。
  String errorMessage({int maxLength = 120}) {
    assert(maxLength >= 0, 'maxLength 不能为负数');
    final text = error?.toString() ?? '';
    return text.length <= maxLength ? text : '${text.substring(0, maxLength)}…';
  }

  @override
  bool operator ==(Object other) =>
      other is WAsyncState<T> &&
      other.status == status &&
      other.data == data &&
      other.error == error;

  @override
  int get hashCode => Object.hash(status, data, error);

  @override
  String toString() => 'WAsyncState<$T>(status: ${status.name}, '
      'hasData: ${data != null}, error: $error)';
}
