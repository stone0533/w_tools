import 'package:flutter/material.dart';

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

  Widget? _placeholder;
  Widget? _errorWidget;

  /// 固定加载占位符（只由 setter 设置；直接写 builder 时这里为 null）
  Widget? get placeholder => _placeholder;

  /// 设置加载中占位符（固定 Widget 形式）
  set placeholder(Widget? placeholder) {
    _placeholder = placeholder;
    placeholderBuilder = placeholder == null ? null : (_, __) => placeholder;
  }

  /// 固定错误占位符（只由 setter 设置；直接写 builder 时这里为 null）
  Widget? get errorWidget => _errorWidget;

  /// 设置错误占位符（固定 Widget 形式）
  set errorWidget(Widget? errorWidget) {
    _errorWidget = errorWidget;
    errorWidgetBuilder = errorWidget == null ? null : (_, __, ___) => errorWidget;
  }

  /// 构造函数
  WImageConfig();

  /// 校验配置（debug 下 assert；WImage 在创建/更新/构建时复用）
  void validate() {
    assert(retryCount >= 0, 'retryCount 不能为负');
    assert(retryDelay >= 0, 'retryDelay 不能为负');
    assert(memCacheWidth == null || memCacheWidth! > 0, 'memCacheWidth 必须大于 0');
    assert(memCacheHeight == null || memCacheHeight! > 0, 'memCacheHeight 必须大于 0');
    assert(aspectRatio == null || aspectRatio! > 0, 'aspectRatio 必须大于 0');
    assert(width == null || width! >= 0, 'width 不能为负');
    assert(height == null || height! >= 0, 'height 不能为负');
    assert(
      !(aspectRatio != null && width != null && height != null),
      'aspectRatio 与固定 width/height 不要同时设置（约束会冲突）',
    );
  }

  /// 复制一份配置（浅拷贝；builder / map 等引用共享）
  ///
  /// 用于“以现有配置为底，再覆盖少量字段”的场景，避免修改调用方传入的配置。
  WImageConfig copy() {
    final c = WImageConfig()
      ..width = width
      ..height = height
      ..fit = fit
      ..memCacheWidth = memCacheWidth
      ..memCacheHeight = memCacheHeight
      ..placeholderBuilder = placeholderBuilder
      ..errorWidgetBuilder = errorWidgetBuilder
      ..progressBuilder = progressBuilder
      ..retryCount = retryCount
      ..retryDelay = retryDelay
      ..borderRadius = borderRadius
      ..border = border
      ..boxShadow = boxShadow
      ..margin = margin
      ..padding = padding
      ..aspectRatio = aspectRatio
      ..semanticLabel = semanticLabel
      ..excludeFromSemantics = excludeFromSemantics
      ..gaplessPlayback = gaplessPlayback
      ..filterQuality = filterQuality
      ..alignment = alignment
      ..httpHeaders = httpHeaders
      ..cacheKey = cacheKey
      .._placeholder = _placeholder
      .._errorWidget = _errorWidget;
    return c;
  }

  /// 设置图片宽高（链式）
  ///
  /// 与 [WImageConfig.square] 不同，这里可以只传其中一个。
  WImageConfig dimensions(double? width, double? height) {
    this.width = width;
    this.height = height;
    return this;
  }

  /// 设置正方形边长（链式）
  WImageConfig square(double side) {
    width = side;
    height = side;
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
    _applyCacheLimits();
  }

  /// 恢复默认占位符与缓存上限（测试/多实例隔离用）
  void reset() {
    defaultPlaceholder = null;
    defaultErrorWidget = null;
    maxCacheSize = 1000;
    maxCacheMemory = 100 * 1024 * 1024;
    _applyCacheLimits();
  }

  void _applyCacheLimits() {
    // 统一到 Flutter 的 ImageCache：asset / 网络解码后的位图共用同一预算
    final imageCache = PaintingBinding.instance.imageCache;
    imageCache.maximumSize = maxCacheSize;
    imageCache.maximumSizeBytes = maxCacheMemory;
  }
}
