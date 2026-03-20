import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';

import 'network_image_with_retry.dart';
import 'image_cache_manager.dart';

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

  /// Base64图片
  base64,
}

/// 图片组件
///
/// 支持加载网络图片和本地图片
/// 提供了加载状态回调、加载进度回调、占位符和错误处理
class WImage extends StatelessWidget {
  /// 缓存的默认占位符
  static final Widget _defaultPlaceholder = Container(
    color: Colors.grey[200],
  );

  /// 缓存的默认错误占位符
  static final Widget _defaultErrorWidget = Container(
    color: Colors.grey[200],
    child: const Icon(Icons.error),
  );

  /// 图片配置
  final WImageConfig config;
  
  /// 图片数据（网络URL、本地资源路径、文件路径或 Base64 数据）
  final String data;

  /// 加载状态回调
  final ValueChanged<WImageLoadStatus>? onLoadStatusChanged;

  /// 加载进度回调
  final ValueChanged<double>? onLoadProgress;

  /// 图片类型缓存，避免重复判断
  static final Map<String, WImageType> _imageTypeCache = {};

  /// 构造函数
  ///
  /// @param key 组件键
  /// @param config 图片配置
  /// @param data 图片数据（网络URL、本地资源路径、文件路径或 Base64 数据）
  /// @param onLoadStatusChanged 加载状态回调
  /// @param onLoadProgress 加载进度回调
  WImage({
    super.key,
    WImageConfig? config,
    required this.data,
    this.onLoadStatusChanged,
    this.onLoadProgress,
  }) : config = _createConfig(config);

  /// 创建配置
  ///
  /// @param config 图片配置
  /// @return WImageConfig 配置实例
  static WImageConfig _createConfig(WImageConfig? config) {
    if (config != null) {
      // 提供了 config
      return config;
    } else {
      // 未提供 config，返回默认配置
      return WImageConfig();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 默认占位符
    Widget defaultPlaceholder = _buildDefaultPlaceholder();

    // 默认错误占位符
    Widget defaultErrorWidget = _buildDefaultErrorWidget();

    // 创建图片加载器并加载图片
    final imageWidget = _createImageLoader(context, defaultPlaceholder, defaultErrorWidget);

    // 应用图片变换
    return _applyTransformations(imageWidget);
  }

  /// 确定图片类型
  ///
  /// @return WImageType 图片类型
  WImageType _determineImageType() {
    // 检查缓存中是否已有结果
    if (_imageTypeCache.containsKey(data)) {
      return _imageTypeCache[data]!;
    }

    // 直接通过 data 内容判断图片类型
    late WImageType imageType;
    if (data.startsWith('http://') || data.startsWith('https://')) {
      imageType = WImageType.network;
    } else if (data.startsWith('file://')) {
      imageType = WImageType.file;
    } else if (data.startsWith('data:image/')) {
      imageType = WImageType.base64;
    } else {
      imageType = WImageType.asset;
    }

    // 缓存结果
    _imageTypeCache[data] = imageType;
    return imageType;
  }

  /// 构建默认占位符
  ///
  /// @return Widget 默认占位符
  Widget _buildDefaultPlaceholder() {
    return SizedBox(
      width: config._width,
      height: config._height,
      child: _defaultPlaceholder,
    );
  }

  /// 构建默认错误占位符
  ///
  /// @return Widget 默认错误占位符
  Widget _buildDefaultErrorWidget() {
    return SizedBox(
      width: config._width,
      height: config._height,
      child: _defaultErrorWidget,
    );
  }

  /// 创建图片加载器
  Widget _createImageLoader(BuildContext context, Widget defaultPlaceholder, Widget defaultErrorWidget) {
    final imageType = _determineImageType();
    switch (imageType) {
      case WImageType.network:
        return _buildNetworkImage(defaultPlaceholder, defaultErrorWidget);
      case WImageType.asset:
        return _buildLocalImage(defaultPlaceholder, defaultErrorWidget);
      case WImageType.file:
        return _buildFileImage(context, defaultPlaceholder, defaultErrorWidget);
      case WImageType.base64:
        return _buildBase64Image(context, defaultPlaceholder, defaultErrorWidget);
    }
  }

  /// 构建网络图片
  ///
  /// @param defaultPlaceholder 默认占位符
  /// @param defaultErrorWidget 默认错误占位符
  /// @return Widget 网络图片组件
  Widget _buildNetworkImage(Widget defaultPlaceholder, Widget defaultErrorWidget) {
    // 构建图片加载完成的回调
    Widget imageBuilder(BuildContext context, ImageProvider imageProvider) {
      _handleLoadCompleted();
      return Image(
        image: imageProvider,
        width: config._width,
        height: config._height,
        fit: config._fit,
      );
    }

    // 构建错误处理回调
    Widget errorWidget(BuildContext context, String url, dynamic error) {
      _handleLoadFailed();
      final errorWidget = config._errorWidget?.call(context, url, error);
      return errorWidget ?? defaultErrorWidget;
    }

    // 如果不需要重试，直接返回 CachedNetworkImage
    if (config._retryCount <= 0) {
      // 检查是否设置了进度指示器构建器
      if (config._progressIndicatorBuilder != null) {
        return CachedNetworkImage(
          imageUrl: data,
          width: config._width,
          height: config._height,
          fit: config._fit,
          progressIndicatorBuilder: (context, url, downloadProgress) {
            _handleLoadLoading();
            onLoadProgress?.call(downloadProgress.progress ?? 0.0);
            final progressWidget = config._progressIndicatorBuilder?.call(
              context,
              url,
              downloadProgress,
            );
            return progressWidget ?? defaultPlaceholder;
          },
          errorWidget: errorWidget,
          imageBuilder: imageBuilder,
        );
      } else {
        return CachedNetworkImage(
          imageUrl: data,
          width: config._width,
          height: config._height,
          fit: config._fit,
          placeholder: (context, url) {
            _handleLoadLoading();
            final placeholderWidget = config._placeholder?.call(context, url);
            return placeholderWidget ?? defaultPlaceholder;
          },
          errorWidget: errorWidget,
          imageBuilder: imageBuilder,
        );
      }
    }

    // 实现重试机制
    return NetworkImageWithRetry(
      imageUrl: data,
      width: config._width,
      height: config._height,
      fit: config._fit,
      placeholder: config._placeholder,
      progressIndicatorBuilder: config._progressIndicatorBuilder,
      errorWidget: config._errorWidget,
      defaultPlaceholder: defaultPlaceholder,
      defaultErrorWidget: defaultErrorWidget,
      retryCount: config._retryCount,
      retryDelay: config._retryDelay,
      onLoadStatusChanged: onLoadStatusChanged,
      onLoadProgress: onLoadProgress,
    );
  }

  /// 处理加载开始
  void _handleLoadLoading() {
    onLoadStatusChanged?.call(WImageLoadStatus.loading);
  }

  /// 处理加载完成
  void _handleLoadCompleted() {
    onLoadStatusChanged?.call(WImageLoadStatus.completed);
    onLoadProgress?.call(1.0);
  }

  /// 处理加载失败
  void _handleLoadFailed() {
    onLoadStatusChanged?.call(WImageLoadStatus.failed);
  }

  /// 构建本地图片
  ///
  /// @param defaultPlaceholder 默认占位符
  /// @param defaultErrorWidget 默认错误占位符
  /// @return Widget 本地图片组件
  Widget _buildLocalImage(Widget defaultPlaceholder, Widget defaultErrorWidget) {
    if (config._cacheEnabled) {
      return FutureBuilder<Uint8List>(
        future: WImageCacheManager().cacheImage(data),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            _handleLoadLoading();
            return config._placeholder?.call(context, data) ?? defaultPlaceholder;
          } else if (snapshot.hasError) {
            _handleLoadFailed();
            return config._errorWidget?.call(context, data, snapshot.error) ??
                defaultErrorWidget;
          } else if (snapshot.hasData) {
            _handleLoadCompleted();
            return Image.memory(
              snapshot.data!,
              width: config._width,
              height: config._height,
              fit: config._fit,
            );
          } else {
            return config._placeholder?.call(context, data) ?? defaultPlaceholder;
          }
        },
      );
    } else {
      return Image.asset(
        data,
        width: config._width,
        height: config._height,
        fit: config._fit,
        errorBuilder: (context, error, stackTrace) {
          _handleLoadFailed();
          return config._errorWidget?.call(context, data, error) ?? defaultErrorWidget;
        },
      );
    }
  }

  /// 构建文件图片
  ///
  /// @param context 上下文
  /// @param defaultPlaceholder 默认占位符
  /// @param defaultErrorWidget 默认错误占位符
  /// @return Widget 文件图片组件
  Widget _buildFileImage(
    BuildContext context,
    Widget defaultPlaceholder,
    Widget defaultErrorWidget,
  ) {
    final file = File(data.replaceFirst('file://', ''));

    return FutureBuilder<bool>(
      future: file.exists(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          _handleLoadLoading();
          return config._placeholder?.call(context, data) ?? defaultPlaceholder;
        }
        if (!snapshot.data!) {
          _handleLoadFailed();
          return config._errorWidget?.call(context, data, 'File not found') ??
              defaultErrorWidget;
        }
        _handleLoadCompleted();
        return Image.file(
          file,
          width: config._width,
          height: config._height,
          fit: config._fit,
          errorBuilder: (context, error, stackTrace) {
            _handleLoadFailed();
            return config._errorWidget?.call(context, data, error) ?? defaultErrorWidget;
          },
        );
      },
    );
  }

  /// Base64解码函数，用于在后台线程执行
  static Uint8List _decodeBase64(String base64Data) {
    return base64Decode(base64Data);
  }

  /// 构建Base64图片
  ///
  /// @param context 上下文
  /// @param defaultPlaceholder 默认占位符
  /// @param defaultErrorWidget 默认错误占位符
  /// @return Widget Base64图片组件
  Widget _buildBase64Image(
    BuildContext context,
    Widget defaultPlaceholder,
    Widget defaultErrorWidget,
  ) {
    // 移除Base64前缀（如果有）
    var base64Data = data;
    if (base64Data.startsWith('data:image/')) {
      final commaIndex = base64Data.indexOf(',');
      if (commaIndex != -1) {
        base64Data = base64Data.substring(commaIndex + 1);
      }
    }

    return FutureBuilder<Uint8List>(
      future: compute(WImage._decodeBase64, base64Data),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          _handleLoadLoading();
          return config._placeholder?.call(context, data) ?? defaultPlaceholder;
        }
        if (snapshot.hasError) {
          _handleLoadFailed();
          return config._errorWidget?.call(context, data, snapshot.error) ?? defaultErrorWidget;
        }
        _handleLoadCompleted();
        return Image.memory(
          snapshot.data!,
          width: config._width,
          height: config._height,
          fit: config._fit,
          errorBuilder: (context, error, stackTrace) {
            _handleLoadFailed();
            return config._errorWidget?.call(context, data, error) ?? defaultErrorWidget;
          },
        );
      },
    );
  }

  /// 应用图片变换
  ///
  /// @param image 原始图片组件
  /// @return Widget 变换后的图片组件
  Widget _applyTransformations(Widget image) {
    // 如果没有任何变换，直接返回原始图片
    if (config._padding == null && 
        config._borderRadius == null && 
        config._border == null && 
        (config._boxShadow == null || config._boxShadow!.isEmpty) && 
        config._margin == null) {
      return image;
    }

    Widget transformedImage = image;

    // 应用内边距
    if (config._padding != null) {
      transformedImage = Padding(
        padding: config._padding!,
        child: transformedImage,
      );
    }

    // 应用圆角
    if (config._borderRadius != null) {
      transformedImage = ClipRRect(
        borderRadius: config._borderRadius!,
        child: transformedImage,
      );
    }

    // 合并应用边框、阴影和外边距
    if (config._border != null || 
        (config._boxShadow != null && config._boxShadow!.isNotEmpty) || 
        config._margin != null) {
      transformedImage = Container(
        margin: config._margin,
        decoration: BoxDecoration(
          border: config._border,
          boxShadow: config._boxShadow,
        ),
        child: transformedImage,
      );
    }

    return transformedImage;
  }
}

/// 图片配置类
///
/// 用于配置 WImage 组件的各种属性
/// 支持链式调用
class WImageConfig {
  /// 图片宽度
  double? _width;

  /// 图片高度
  double? _height;

  /// 图片适配模式
  BoxFit _fit = BoxFit.cover;

  /// 是否启用缓存
  bool _cacheEnabled = true;

  /// 加载中占位符
  Widget? Function(BuildContext, String)? _placeholder;

  /// 错误占位符
  Widget? Function(BuildContext, String, dynamic)? _errorWidget;

  /// 进度指示器构建器
  Widget? Function(BuildContext, String, DownloadProgress)? _progressIndicatorBuilder;

  /// 网络图片加载重试次数
  int _retryCount = 0;

  /// 网络图片加载重试间隔（毫秒）
  int _retryDelay = 1000;

  /// 圆角
  BorderRadius? _borderRadius;

  /// 边框
  Border? _border;

  /// 阴影
  List<BoxShadow>? _boxShadow;

  /// 外边距
  EdgeInsets? _margin;

  /// 内边距
  EdgeInsets? _padding;

  /// 构造函数
  WImageConfig();

  /// 构建图片组件
  ///
  /// @param data 图片路径
  /// @param onLoadStatusChanged 加载状态回调
  /// @param onLoadProgress 加载进度回调
  /// @return WImage 组件实例
  WImage buildImage(String data, {
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<double>? onLoadProgress,
  }) {
    return WImage(
      config: this,
      data: data,
      onLoadStatusChanged: onLoadStatusChanged,
      onLoadProgress: onLoadProgress,
    );
  }

  /// 构建文件图片组件
  ///
  /// @param file 文件对象
  /// @param onLoadStatusChanged 加载状态回调
  /// @param onLoadProgress 加载进度回调
  /// @return WImage 组件实例
  WImage buildFile(File file, {
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<double>? onLoadProgress,
  }) {
    return WImage(
      config: this,
      data: file.path,
      onLoadStatusChanged: onLoadStatusChanged,
      onLoadProgress: onLoadProgress,
    );
  }

  /// 构建Base64图片组件
  ///
  /// @param base64 Base64数据
  /// @param onLoadStatusChanged 加载状态回调
  /// @param onLoadProgress 加载进度回调
  /// @return WImage 组件实例
  WImage buildBase64(String base64, {
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<double>? onLoadProgress,
  }) {
    return WImage(
      config: this,
      data: base64,
      onLoadStatusChanged: onLoadStatusChanged,
      onLoadProgress: onLoadProgress,
    );
  }

  /// 设置图片宽度
  ///
  /// @param value 图片宽度
  /// @return WImageConfig 配置实例，用于链式调用
  set width(double? value) {
    _width = value;
  }

  /// 设置图片高度
  ///
  /// @param value 图片高度
  /// @return WImageConfig 配置实例，用于链式调用
  set height(double? value) {
    _height = value;
  }

  /// 设置图片尺寸
  ///
  /// @param width 图片宽度
  /// @param height 图片高度
  /// @return WImageConfig 配置实例，用于链式调用
  WImageConfig size(double? width, double? height) {
    _width = width;
    _height = height;
    return this;
  }

  /// 设置图片适配模式
  ///
  /// @param value 图片适配模式
  /// @return WImageConfig 配置实例，用于链式调用
  set fit(BoxFit value) {
    _fit = value;
  }

  /// 设置是否启用缓存
  ///
  /// @param value 是否启用缓存
  /// @return WImageConfig 配置实例，用于链式调用
  set cacheEnabled(bool value) {
    _cacheEnabled = value;
  }

  /// 设置加载中占位符
  ///
  /// @param placeholder 加载中占位符
  /// @return WImageConfig 配置实例，用于链式调用
  set placeholder(Widget placeholder) {
    _placeholder = (_, __) => placeholder;
  }

  /// 设置加载中占位符（函数形式）
  ///
  /// @param placeholder 加载中占位符构建函数
  /// @return WImageConfig 配置实例，用于链式调用
  set placeholderBuilder(Widget? Function(BuildContext, String) placeholder) {
    _placeholder = placeholder;
  }

  /// 设置错误占位符
  ///
  /// @param errorWidget 错误占位符
  /// @return WImageConfig 配置实例，用于链式调用
  set errorWidget(Widget errorWidget) {
    _errorWidget = (_, __, ___) => errorWidget;
  }

  /// 设置错误占位符（函数形式）
  ///
  /// @param errorWidget 错误占位符构建函数
  /// @return WImageConfig 配置实例，用于链式调用
  set errorWidgetBuilder(Widget? Function(BuildContext, String, dynamic) errorWidget) {
    _errorWidget = errorWidget;
  }

  /// 设置进度指示器构建器
  ///
  /// @param progressIndicatorBuilder 进度指示器构建器
  /// @return WImageConfig 配置实例，用于链式调用
  set progressIndicatorBuilder(
    Widget? Function(BuildContext, String, DownloadProgress) progressIndicatorBuilder,
  ) {
    _progressIndicatorBuilder = progressIndicatorBuilder;
  }

  /// 设置网络图片加载重试次数
  ///
  /// @param retryCount 重试次数
  /// @return WImageConfig 配置实例，用于链式调用
  set retryCount(int retryCount) {
    _retryCount = retryCount;
  }

  /// 设置网络图片加载重试间隔
  ///
  /// @param retryDelay 重试间隔（毫秒）
  /// @return WImageConfig 配置实例，用于链式调用
  set retryDelay(int retryDelay) {
    _retryDelay = retryDelay;
  }

  /// 设置圆角
  ///
  /// @param borderRadius 圆角
  /// @return WImageConfig 配置实例，用于链式调用
  set borderRadius(BorderRadius borderRadius) {
    _borderRadius = borderRadius;
  }

  /// 设置边框
  ///
  /// @param border 边框
  /// @return WImageConfig 配置实例，用于链式调用
  set border(Border border) {
    _border = border;
  }

  /// 设置阴影
  ///
  /// @param boxShadow 阴影列表
  /// @return WImageConfig 配置实例，用于链式调用
  set boxShadow(List<BoxShadow> boxShadow) {
    _boxShadow = boxShadow;
  }

  /// 设置外边距
  ///
  /// @param margin 外边距
  /// @return WImageConfig 配置实例，用于链式调用
  set margin(EdgeInsets margin) {
    _margin = margin;
  }

  /// 设置内边距
  ///
  /// @param padding 内边距
  /// @return WImageConfig 配置实例，用于链式调用
  set padding(EdgeInsets padding) {
    _padding = padding;
  }

  /// 设置圆形图片
  ///
  /// @param radius 半径
  /// @return WImageConfig 配置实例，用于链式调用
  WImageConfig circle(double radius) {
    _width = radius * 2;
    _height = radius * 2;
    _borderRadius = BorderRadius.circular(radius);
    return this;
  }

  /// 设置图片宽度适配
  ///
  /// @param width 图片宽度
  /// @return WImageConfig 配置实例，用于链式调用
  WImageConfig fitWidth(double width) {
    _fit = BoxFit.fitWidth;
    _width = width;
    return this;
  }

  /// 设置图片高度适配
  ///
  /// @param height 图片高度
  /// @return WImageConfig 配置实例，用于链式调用
  WImageConfig fitHeight(double height) {
    _fit = BoxFit.fitHeight;
    _height = height;
    return this;
  }

  /// 按原始比例缩放，确保图像完全在目标框内，可能留白
  ///
  /// @return WImageConfig 配置实例，用于链式调用
  WImageConfig fitContain() {
    _fit = BoxFit.contain;
    return this;
  }

  /// 按原始比例缩放，覆盖整个目标框，超出部分会被裁剪
  ///
  /// @return WImageConfig 配置实例，用于链式调用
  WImageConfig fitCover() {
    _fit = BoxFit.cover;
    return this;
  }

  /// 填充整个目标框，可能会拉伸图片
  ///
  /// @return WImageConfig 配置实例，用于链式调用
  WImageConfig fitFill() {
    _fit = BoxFit.fill;
    return this;
  }

  /// 不进行缩放，图片居中显示，超出部分会被裁剪
  ///
  /// @return WImageConfig 配置实例，用于链式调用
  WImageConfig fitNone() {
    _fit = BoxFit.none;
    return this;
  }

  /// 按原始比例缩放，使图片宽度或高度与目标框匹配
  ///
  /// @return WImageConfig 配置实例，用于链式调用
  WImageConfig fitScaleDown() {
    _fit = BoxFit.scaleDown;
    return this;
  }

  /// 图片居中显示
  ///
  /// @return WImageConfig 配置实例，用于链式调用
  WImageConfig fitCenter() {
    _fit = BoxFit.none;
    return this;
  }

  /// 构建 WImage 组件
  ///
  /// @param data 图片数据（网络URL、本地资源路径、文件路径或 Base64 数据）
  /// @param onLoadStatusChanged 加载状态回调
  /// @param onLoadProgress 加载进度回调
  /// @return Widget WImage 组件
  Widget build({
    required String data,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<double>? onLoadProgress,
  }) {
    return WImage(
      config: this,
      data: data,
      onLoadStatusChanged: onLoadStatusChanged,
      onLoadProgress: onLoadProgress,
    );
  }
}

/// 图片全局配置类
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

  /// 最大缓存数量
  int maxCacheSize = 100;

  /// 最大缓存内存（100MB）
  int maxCacheMemory = 100 * 1024 * 1024;

  /// 设置全局配置
  ///
  /// @param defaultPlaceholder 默认加载中占位符
  /// @param defaultErrorWidget 默认错误占位符
  /// @param maxCacheSize 最大缓存数量
  /// @param maxCacheMemory 最大缓存内存
  void setGlobalConfig({
    Widget? defaultPlaceholder,
    Widget? defaultErrorWidget,
    int? maxCacheSize,
    int? maxCacheMemory,
  }) {
    this.defaultPlaceholder = defaultPlaceholder;
    this.defaultErrorWidget = defaultErrorWidget;
    if (maxCacheSize != null) this.maxCacheSize = maxCacheSize;
    if (maxCacheMemory != null) this.maxCacheMemory = maxCacheMemory;
  }
}

/// 带重试机制的网络图片组件

