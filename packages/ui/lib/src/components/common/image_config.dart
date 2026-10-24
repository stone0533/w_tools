import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../utils/image_cache_manager.dart';
import 'image_types.dart';

/// 图片配置类
///
/// 配置项都是公开字段（可直接读写，也可用 `..` 级联），并保留链式方法。
/// 构建组件的方法见 `image.dart` 的 `WImageConfigBuild` 扩展。
class WImageConfig {
  /// 图片宽度
  double? width;

  /// 图片高度
  double? height;

  /// 图片适配模式
  BoxFit fit = BoxFit.cover;

  /// 解码宽度上限（物理像素），列表缩略图必传
  int? memCacheWidth;

  /// 解码高度上限（物理像素）
  int? memCacheHeight;

  /// 加载中占位符构建器（推荐形式）
  Widget? Function(BuildContext, String)? placeholderBuilder;

  /// 错误占位符构建器（推荐形式）；第三个参数是 [WImageError]
  Widget? Function(BuildContext, String, WImageError)? errorWidgetBuilder;

  /// 进度指示器构建器（旧签名，参数是 `cached_network_image` 的 `DownloadProgress`）
  Widget? Function(BuildContext, String, DownloadProgress)? progressIndicatorBuilder;

  /// 进度指示器构建器（新签名，参数是 [WImageProgress]）
  Widget? Function(BuildContext, String, WImageProgress)? progressBuilder;

  /// 网络图片加载重试次数
  int retryCount = 0;

  /// 网络图片加载重试间隔（毫秒）
  int retryDelay = 1000;

  /// 圆角
  BorderRadius? borderRadius;

  /// 边框
  BoxBorder? border;

  /// 阴影
  List<BoxShadow>? boxShadow;

  /// 外边距
  EdgeInsets? margin;

  /// 内边距
  EdgeInsets? padding;

  /// 固定宽高比
  ///
  /// 设置后整个图片（含占位符）会被 `AspectRatio` 包裹：加载前后尺寸一致，
  /// 滚动列表里不会因为占位符高度为 0 而跳版。
  double? aspectRatio;

  /// 无障碍语义描述
  String? semanticLabel;

  /// 是否从语义树中排除图片
  bool excludeFromSemantics = false;

  /// 切换图片时是否保留上一帧（避免闪烁）
  bool gaplessPlayback = false;

  /// 图片采样质量
  FilterQuality filterQuality = FilterQuality.low;

  /// 图片对齐方式（小于目标框时生效）
  Alignment alignment = Alignment.center;

  /// 网络请求头（鉴权图片等）
  Map<String, String>? httpHeaders;

  /// 自定义缓存键（同一 URL 不同裁剪/版本时使用）
  String? cacheKey;

  /// 是否启用缓存
  ///
  /// 已废弃：资产图片统一走 `Image.asset` + Flutter `ImageCache`，
  /// 该开关不再改变行为；保留仅为源码兼容。
  @Deprecated('资产图片已统一走 Image.asset + Flutter ImageCache，该开关不再生效')
  bool cacheEnabled = true;

  /// 设置加载中占位符（固定 Widget 形式）
  set placeholder(Widget? placeholder) {
    placeholderBuilder = placeholder == null ? null : (_, __) => placeholder;
  }

  /// 设置错误占位符（固定 Widget 形式）
  set errorWidget(Widget? errorWidget) {
    errorWidgetBuilder = errorWidget == null ? null : (_, __, ___) => errorWidget;
  }

  /// 构造函数
  WImageConfig();

  /// 设置图片尺寸（链式）
  WImageConfig size(double? width, double? height) {
    width = width;
    height = height;
    return this;
  }

  /// 设置圆形图片（链式）
  WImageConfig circle(double radius) {
    width = radius * 2;
    height = radius * 2;
    borderRadius = BorderRadius.circular(radius);
    return this;
  }

  /// 按宽度适配（链式）
  WImageConfig fitWidth(double width) {
    fit = BoxFit.fitWidth;
    width = width;
    return this;
  }

  /// 按高度适配（链式）
  WImageConfig fitHeight(double height) {
    fit = BoxFit.fitHeight;
    height = height;
    return this;
  }

  /// 等比缩放至完整可见（链式）
  WImageConfig fitContain() {
    fit = BoxFit.contain;
    return this;
  }

  /// 等比缩放至铺满（链式）
  WImageConfig fitCover() {
    fit = BoxFit.cover;
    return this;
  }

  /// 拉伸铺满（链式）
  WImageConfig fitFill() {
    fit = BoxFit.fill;
    return this;
  }

  /// 不缩放（链式）
  WImageConfig fitNone() {
    fit = BoxFit.none;
    return this;
  }

  /// 等比缩小（链式）
  WImageConfig fitScaleDown() {
    fit = BoxFit.scaleDown;
    return this;
  }

  /// 居中显示（链式）
  ///
  /// 等价于 [fitContain]；保留旧名字仅为兼容，将在 2.0 移除。
  @Deprecated('等价于 fitContain()，将在 2.0 移除')
  WImageConfig fitCenter() {
    fit = BoxFit.contain;
    return this;
  }
}

/// 图片全局配置类
///
/// 单例：默认占位符与缓存上限都是全局的。
/// 调用 [configure] 时会把缓存上限写入 Flutter 的 `ImageCache`
/// （`PaintingBinding`），对 asset / 网络 / base64 统一生效。
///
/// 注意：[configure] 依赖 `WidgetsBinding`，需在
/// `WidgetsFlutterBinding.ensureInitialized()` 之后调用。
class WImageGlobalConfig {
  /// 单例实例
  static final WImageGlobalConfig _instance = WImageGlobalConfig._();

  /// 工厂构造函数
  factory WImageGlobalConfig() => _instance;

  /// 私有构造函数
  WImageGlobalConfig._();

  /// 默认加载中占位符
  Widget? defaultPlaceholder;

  /// 默认错误占位符
  Widget? defaultErrorWidget;

  /// 最大缓存数量（默认与 Flutter `ImageCache` 一致）
  int maxCacheSize = 1000;

  /// 最大缓存内存（默认与 Flutter `ImageCache` 一致，单位字节）
  int maxCacheMemory = 100 * 1024 * 1024;

  /// 配置全局默认值
  void configure({
    Widget? defaultPlaceholder,
    Widget? defaultErrorWidget,
    int? maxCacheSize,
    int? maxCacheMemory,
  }) {
    this.defaultPlaceholder = defaultPlaceholder;
    this.defaultErrorWidget = defaultErrorWidget;
    if (maxCacheSize != null) this.maxCacheSize = maxCacheSize;
    if (maxCacheMemory != null) this.maxCacheMemory = maxCacheMemory;

    // 统一到 Flutter 的 ImageCache：asset / 网络解码后的位图共用同一预算
    final imageCache = PaintingBinding.instance.imageCache;
    imageCache.maximumSize = this.maxCacheSize;
    imageCache.maximumSizeBytes = this.maxCacheMemory;

    // 兼容旧版本：原始字节缓存仍在，但 WImage 已不再使用
    WImageCacheManager().configureLimits(
      maxCacheSize: this.maxCacheSize,
      maxCacheMemory: this.maxCacheMemory,
    );
  }
}
