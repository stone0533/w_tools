import 'package:flutter/painting.dart';

/// 全局图片缓存预算。
///
/// 直接作用于 Flutter 的 [ImageCache]，对 asset / 网络 / Base64 解码后的位图统一生效。
/// 这是**无 context** 的进程级配置；占位符默认值请用 `WImageTheme`。
class WImageCachePolicy {
  WImageCachePolicy._();

  /// 最大缓存数量（与 Flutter `ImageCache` 默认一致）
  static int maxSize = 1000;

  /// 最大缓存内存（默认 100MB）
  static int maxMemoryBytes = 100 * 1024 * 1024;

  /// 设置并立即应用到 [PaintingBinding.instance.imageCache]。
  static void configure({int? maxSize, int? maxMemoryBytes}) {
    if (maxSize != null && maxSize > 0) WImageCachePolicy.maxSize = maxSize;
    if (maxMemoryBytes != null && maxMemoryBytes > 0) {
      WImageCachePolicy.maxMemoryBytes = maxMemoryBytes;
    }
    apply();
  }

  /// 恢复默认值并应用
  static void reset() {
    maxSize = 1000;
    maxMemoryBytes = 100 * 1024 * 1024;
    apply();
  }

  /// 只应用当前值，不修改配置
  static void apply() {
    final cache = PaintingBinding.instance.imageCache;
    cache.maximumSize = maxSize;
    cache.maximumSizeBytes = maxMemoryBytes;
  }
}
