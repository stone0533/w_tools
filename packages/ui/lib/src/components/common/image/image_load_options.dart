import 'package:flutter/foundation.dart';

/// 不可变的图片加载行为配置。
///
/// 只负责解码尺寸、重试与 gaplessPlayback；视觉样式由 `WImageStyle` 负责，
/// 占位 / 错误 / 进度 UI 由 `WImageSlots` 负责。
///
/// 7.0 起由 `WImageLoadConfig` 更名而来；7.0 起把 UI builder 拆到
/// `WImageSlots`，让 Options 只保留加载行为。
@immutable
class WImageLoadOptions {
  const WImageLoadOptions({
    this.memCacheWidth,
    this.memCacheHeight,
    this.gaplessPlayback = false,
    this.retryCount = 0,
    this.retryDelay = 1000,
  });

  /// 解码尺寸上限（物理像素）
  final int? memCacheWidth;
  final int? memCacheHeight;

  /// 换图时保留上一帧
  final bool gaplessPlayback;

  /// 网络自动重试次数
  final int retryCount;

  /// 重试基础间隔（毫秒）
  final int retryDelay;

  void validate() {
    assert(retryCount >= 0, 'retryCount 不能为负');
    assert(retryDelay >= 0, 'retryDelay 不能为负');
    assert(memCacheWidth == null || memCacheWidth! > 0, 'memCacheWidth 必须大于 0');
    assert(memCacheHeight == null || memCacheHeight! > 0, 'memCacheHeight 必须大于 0');
  }

  /// 派生新配置；传 null 表示保留当前值（不能用 copyWith 清空字段）。
  ///
  /// 需要清空解码尺寸时用 [withoutMemCacheWidth] / [withoutMemCacheHeight]。
  WImageLoadOptions copyWith({
    int? memCacheWidth,
    int? memCacheHeight,
    bool? gaplessPlayback,
    int? retryCount,
    int? retryDelay,
  }) {
    return WImageLoadOptions(
      memCacheWidth: memCacheWidth ?? this.memCacheWidth,
      memCacheHeight: memCacheHeight ?? this.memCacheHeight,
      gaplessPlayback: gaplessPlayback ?? this.gaplessPlayback,
      retryCount: retryCount ?? this.retryCount,
      retryDelay: retryDelay ?? this.retryDelay,
    );
  }

  WImageLoadOptions withoutMemCacheWidth() => WImageLoadOptions(
    memCacheHeight: memCacheHeight,
    gaplessPlayback: gaplessPlayback,
    retryCount: retryCount,
    retryDelay: retryDelay,
  );

  WImageLoadOptions withoutMemCacheHeight() => WImageLoadOptions(
    memCacheWidth: memCacheWidth,
    gaplessPlayback: gaplessPlayback,
    retryCount: retryCount,
    retryDelay: retryDelay,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WImageLoadOptions &&
          other.memCacheWidth == memCacheWidth &&
          other.memCacheHeight == memCacheHeight &&
          other.gaplessPlayback == gaplessPlayback &&
          other.retryCount == retryCount &&
          other.retryDelay == retryDelay;

  @override
  int get hashCode => Object.hash(
    memCacheWidth,
    memCacheHeight,
    gaplessPlayback,
    retryCount,
    retryDelay,
  );
}
