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

/// 图片加载错误
///
/// `WImageStyle.errorWidgetBuilder` 的第三个参数会收到它的子类型，
/// 调用方可以按类型分支处理。
sealed class WImageError implements Exception {
  /// 创建错误
  const WImageError(this.data);

  /// 触发错误的原始数据（调用方传给 `WImage` 的 `data`）
  final String data;

  /// 可读的原因
  String get message;

  @override
  String toString() => 'WImageError($message, data: $data)';
}

/// 数据为空（空串 / 纯空白）
final class WImageEmptyError extends WImageError {
  /// 创建错误
  const WImageEmptyError(super.data);

  @override
  String get message => '图片数据为空';
}

/// 网络加载失败
final class WImageNetworkError extends WImageError {
  /// 创建错误
  const WImageNetworkError(super.data, this.cause);

  /// 底层异常（通常是 `NetworkImageLoadException` / `HttpException`）
  final Object? cause;

  @override
  String get message => '网络图片加载失败';
}

/// 本地资源加载失败
final class WImageAssetError extends WImageError {
  /// 创建错误
  const WImageAssetError(super.data, this.cause);

  /// 底层异常
  final Object? cause;

  @override
  String get message => '本地资源加载失败';
}

/// Base64 解码失败
final class WImageDecodeError extends WImageError {
  /// 创建错误
  const WImageDecodeError(super.data, this.cause);

  /// 底层异常
  final Object? cause;

  @override
  String get message => 'Base64 解码失败';
}

/// 本地文件读取失败
final class WImageFileError extends WImageError {
  /// 创建错误
  const WImageFileError(super.data, this.cause);

  /// 底层异常
  final Object? cause;

  @override
  String get message => '本地文件读取失败';
}

/// 当前平台不支持该来源（例如 Web 上的 `file://`）
final class WImageUnsupportedError extends WImageError {
  /// 创建错误
  const WImageUnsupportedError(super.data, this.platform);

  /// 不支持的平台描述
  final String platform;

  @override
  String get message => '当前平台不支持 $platform 图片';
}
