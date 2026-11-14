import 'package:flutter/widgets.dart';

import '../../../internal/ui_strings.dart';

/// 图片加载状态枚举
enum WImageLoadStatus {
  /// 尚未开始加载 / 已重置
  idle,

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
  const WImageProgress({
    this.downloadedBytes,
    this.totalBytes,
    this.isComplete = false,
  });

  /// 加载完成信号。
  ///
  /// 不伪造字节数；需要判断是否完成用 [isComplete] / `fraction == 1.0`。
  const WImageProgress.complete() : downloadedBytes = null, totalBytes = null, isComplete = true;

  /// 已下载字节数（未知时为 null）
  final int? downloadedBytes;

  /// 总字节数（服务端未返回 Content-Length 时为 null）
  final int? totalBytes;

  /// 是否已经完成
  final bool isComplete;

  /// 进度比例（0.0 - 1.0）；完成时为 1.0，总大小未知或非法时返回 null
  double? get fraction {
    if (isComplete) return 1.0;
    final total = totalBytes;
    if (total == null || total <= 0) return null;
    return ((downloadedBytes ?? 0) / total).clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) {
    return other is WImageProgress &&
        other.downloadedBytes == downloadedBytes &&
        other.totalBytes == totalBytes &&
        other.isComplete == isComplete;
  }

  @override
  int get hashCode => Object.hash(downloadedBytes, totalBytes, isComplete);

  @override
  String toString() {
    if (isComplete) return 'WImageProgress(complete)';
    final total = totalBytes;
    return 'WImageProgress(${downloadedBytes ?? 0}/$total)';
  }
}

/// 图片加载错误的分类
enum WImageErrorKind {
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

/// 图片加载错误（4.2 起用 [kind] 区分；5.0 起不再提供子类）。
class WImageError implements Exception {
  /// 创建错误
  const WImageError(this.sourceValue, this.kind, {this.cause});

  /// 触发错误的原始来源字符串（通常是 `WImageSource.raw`）。
  final String sourceValue;

  /// 错误分类
  final WImageErrorKind kind;

  /// 底层原因（网络异常 / 解码异常等），可为空
  final Object? cause;

  /// 可读的原因（固定中文诊断文案，供日志 / `toString()`）。
  ///
  /// UI 请用 [localizedMessage]，它跟随当前 [Locale]。
  String get message => switch (kind) {
    WImageErrorKind.network => '网络图片加载失败',
    WImageErrorKind.asset => '本地资源加载失败',
    WImageErrorKind.decode => 'Base64 解码失败',
    WImageErrorKind.provider => '图片解码失败',
    WImageErrorKind.file => '本地文件读取失败',
    WImageErrorKind.unsupported => '当前平台不支持该图片源',
  };

  /// 按当前 [Locale] 返回错误文案（zh 中文 / 其他英文）。
  ///
  /// 需要在没有 [BuildContext] 的日志里保留固定中文时用 [message]。
  String localizedMessage(BuildContext context) => WUiStrings.of(context).imageErrorMessage(kind);

  /// 值相等只比较 [sourceValue] 与 [kind]；[cause] 是诊断信息，不参与相等。
  ///
  /// 这样错误去重 / 测试不会因为异常实例不同而失败。
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WImageError && other.sourceValue == sourceValue && other.kind == kind;

  @override
  int get hashCode => Object.hash(sourceValue, kind);

  @override
  String toString() => 'WImageError($message, source: $sourceValue)';
}
