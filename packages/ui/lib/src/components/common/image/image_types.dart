import 'package:flutter/foundation.dart';

/// 图片加载状态枚举
enum WImageLoadStatus {
  /// 加载中
  loading,

  /// 加载完成
  completed,

  /// 加载失败
  failed,
}

/// 图片类型枚举
enum WImageType {
  /// 本地资源
  asset,

  /// 网络图片
  network,

  /// 文件图片
  file,

  /// Base64 图片
  base64,

  /// 任意 [ImageProvider]（含内存图片）
  provider,
}

/// 图片加载进度
///
/// 与具体网络实现解耦：`WImage` 的进度回调都发这个值，
/// 调用方不需要依赖 `cached_network_image` 的 `DownloadProgress`。
@immutable
class WImageProgress {
  /// 创建进度
  const WImageProgress({this.downloadedBytes, this.totalBytes});

  /// 已下载字节数（未知时为 null）
  final int? downloadedBytes;

  /// 总字节数（服务端未返回 Content-Length 时为 null）
  final int? totalBytes;

  /// 进度比例（0.0 - 1.0）；总大小未知或非法时返回 null
  double? get fraction {
    final total = totalBytes;
    if (total == null || total <= 0) return null;
    return ((downloadedBytes ?? 0) / total).clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) {
    return other is WImageProgress &&
        other.downloadedBytes == downloadedBytes &&
        other.totalBytes == totalBytes;
  }

  @override
  int get hashCode => Object.hash(downloadedBytes, totalBytes);

  @override
  String toString() {
    final total = totalBytes;
    return 'WImageProgress(${downloadedBytes ?? 0}/$total)';
  }
}

/// 图片加载错误的分类
enum WImageErrorKind {
  /// 数据为空
  empty,

  /// 网络加载失败
  network,

  /// 本地资源加载失败
  asset,

  /// Base64 解码失败
  decode,

  /// 任意 ImageProvider 解码失败
  provider,

  /// 本地文件读取失败
  file,

  /// 当前平台不支持
  unsupported,
}

/// 图片加载错误
///
/// 4.2 起用 [kind] 区分错误类型；子类已弃用（5.0 移除）。
sealed class WImageError implements Exception {
  /// 创建错误
  const WImageError(this.data, this.kind);

  /// 触发错误的原始数据（调用方传给 `WImage` 的 `data`）
  final String data;

  /// 错误分类
  final WImageErrorKind kind;

  /// 可读的原因
  String get message;

  @override
  String toString() => 'WImageError($message, data: $data)';
}

/// 数据为空（空串 / 纯空白）
/// remove-in: 5.0.0
@Deprecated('5.0 移除：用 WImageError.kind')
final class WImageEmptyError extends WImageError {
  /// 创建错误
  const WImageEmptyError(String data) : super(data, WImageErrorKind.empty);

  @override
  String get message => '图片数据为空';
}

/// 网络加载失败
/// remove-in: 5.0.0
@Deprecated('5.0 移除：用 WImageError.kind')
final class WImageNetworkError extends WImageError {
  /// 创建错误
  const WImageNetworkError(String data, this.cause) : super(data, WImageErrorKind.network);

  /// 底层异常（通常是 `NetworkImageLoadException` / `HttpException`）
  final Object? cause;

  @override
  String get message => '网络图片加载失败';
}

/// 本地资源加载失败
/// remove-in: 5.0.0
@Deprecated('5.0 移除：用 WImageError.kind')
final class WImageAssetError extends WImageError {
  /// 创建错误
  const WImageAssetError(String data, this.cause) : super(data, WImageErrorKind.asset);

  /// 底层异常
  final Object? cause;

  @override
  String get message => '本地资源加载失败';
}

/// Base64 解码失败
/// remove-in: 5.0.0
@Deprecated('5.0 移除：用 WImageError.kind')
final class WImageDecodeError extends WImageError {
  /// 创建错误
  const WImageDecodeError(String data, this.cause) : super(data, WImageErrorKind.decode);

  /// 底层异常
  final Object? cause;

  @override
  String get message => 'Base64 解码失败';
}

/// 任意 [ImageProvider] / 内存图片解码失败
/// remove-in: 5.0.0
@Deprecated('5.0 移除：用 WImageError.kind')
final class WImageProviderError extends WImageError {
  /// 创建错误
  const WImageProviderError(String data, this.cause) : super(data, WImageErrorKind.provider);

  /// 底层异常
  final Object? cause;

  @override
  String get message => '图片解码失败';
}

/// 本地文件读取失败
/// remove-in: 5.0.0
@Deprecated('5.0 移除：用 WImageError.kind')
final class WImageFileError extends WImageError {
  /// 创建错误
  const WImageFileError(String data, this.cause) : super(data, WImageErrorKind.file);

  /// 底层异常
  final Object? cause;

  @override
  String get message => '本地文件读取失败';
}

/// 当前平台不支持该来源（例如 Web 上的 `file://`）
/// remove-in: 5.0.0
@Deprecated('5.0 移除：用 WImageError.kind')
final class WImageUnsupportedError extends WImageError {
  /// 创建错误
  const WImageUnsupportedError(String data, this.platform)
    : super(data, WImageErrorKind.unsupported);

  /// 不支持的平台描述
  final String platform;

  @override
  String get message => '当前平台不支持 $platform 图片';
}

/// 图片加载快照（供 [WImageController.state] 监听）。
@immutable
class WImageLoadSnapshot {
  const WImageLoadSnapshot({
    this.status,
    this.progress,
    this.attempt = 0,
    this.error,
    this.retryScheduled = false,
    this.retryDelayMs,
  });

  final WImageLoadStatus? status;
  final WImageProgress? progress;
  final int attempt;
  final WImageError? error;
  final bool retryScheduled;
  final int? retryDelayMs;

  bool get isLoading => status == WImageLoadStatus.loading;
  bool get isCompleted => status == WImageLoadStatus.completed;
  bool get isFailed => status == WImageLoadStatus.failed;

  @override
  bool operator ==(Object other) =>
      other is WImageLoadSnapshot &&
      other.status == status &&
      other.progress == progress &&
      other.attempt == attempt &&
      other.error == error &&
      other.retryScheduled == retryScheduled &&
      other.retryDelayMs == retryDelayMs;

  @override
  int get hashCode => Object.hash(
    status,
    progress,
    attempt,
    error,
    retryScheduled,
    retryDelayMs,
  );

  @override
  String toString() =>
      'WImageLoadSnapshot(status: $status, attempt: $attempt, '
      'progress: $progress, retryScheduled: $retryScheduled)';
}
