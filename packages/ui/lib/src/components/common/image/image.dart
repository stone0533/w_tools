import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'image_error_view.dart';
import 'image_frame.dart';
import 'image_loader.dart';
import 'image_source.dart';
import 'image_style.dart';
import 'image_theme.dart';
import 'image_types.dart';

// 条件导入：默认 Web（没有文件系统），只有存在 dart:io 时才切到原生实现。
// 这里刻意用 dart.library.io 而不是 dart.library.html —— WASM 构建下
// dart.library.html 不可用，用 html 判断会落到原生分支并编译 dart:io。
import '_image_file_web.dart' if (dart.library.io) '_image_file_native.dart';

export 'image_frame.dart';
export 'image_cache_policy.dart';
export 'image_error_view.dart';
export 'image_loader.dart';
export 'image_source.dart';
export 'image_style.dart';
export 'image_theme.dart';
export 'image_types.dart';

/// 图片控制器
///
/// 目前只提供手动重试：在 `errorWidget` 里放一个按钮，点击调用 [retry]
/// 立即重新发起请求（不等自动重试的退避时间）。
class WImageController {
  _WImageState? _state;
  WImageLoader? _loader;
  ValueListenable<WImageLoadSnapshot>? _lastState;

  /// 是否已绑定到 [WImage]
  bool get isAttached => _state != null;

  /// 加载状态。
  ///
  /// 首次绑定后保持同一 [ValueListenable]；WImage 卸载后仍可安全监听/移除监听，
  /// 只是不再更新。
  ValueListenable<WImageLoadSnapshot>? get state => _loader?.state ?? _lastState;

  /// 手动重新加载
  ///
  /// 触发一次新的请求；组件未挂载时是空操作。
  void retry() => _loader?.retryNow();

  void _attach(_WImageState state) {
    assert(
      _state == null || identical(_state, state),
      'WImageController 不能同时绑定多个 WImage；请为每张图使用独立 controller',
    );
    if (identical(_state, state)) return;
    _state = state;
    _loader = state.loader;
    _lastState = _loader!.state;
  }

  void _detach(_WImageState state) {
    if (identical(_state, state)) {
      _state = null;
      _loader = null;
      // 保留 _lastState：外部持有的 ValueListenable 仍然有效，只是不再更新。
    }
  }
}

/// 图片组件
///
/// 默认按 `data` 自动判定类型（网络 URL、本地资源、`file://` 路径、`data:` Base64）；
/// 需要确定性时用命名构造：[WImage.network] / [WImage.asset] / [WImage.file] /
/// [WImage.base64]，它们跳过判定，也不会被“看起来像 URL 的 asset 名”影响。
///
/// 提供占位符、错误处理、加载进度、网络重试（自动 + 手动）与图片变换
/// （圆角、边框、阴影、margin/padding）。
class WImage extends StatefulWidget {
  /// 图片来源
  final WImageSource source;

  /// 不可变样式
  final WImageStyle style;

  /// 加载状态回调
  final ValueChanged<WImageLoadStatus>? onLoadStatusChanged;

  /// 类型化的进度回调（仅网络图片有值）
  final ValueChanged<WImageProgress>? onProgress;

  /// 图片控制器（手动重试）
  final WImageController? controller;

  /// 调用方传入的原始值（未 trim / 未规范化）
  String get data => source.raw;

  /// 显式类型；默认构造自动判定时为 null（历史语义）
  final WImageType? type;

  /// 按字符串自动判定来源（便利入口；新代码建议用 [WImage.source]）
  factory WImage({
    Key? key,
    WImageStyle style = const WImageStyle(),
    required String data,
    WImageType? type,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    assert(
      type != WImageType.provider,
      'provider 来源请使用 WImage.provider(...) / WImage.memory(...)',
    );
    return WImage._(
      key: key,
      type: type,
      source: WImageSource.parse(data, type: type),
      style: style,
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
      controller: controller,
    );
  }

  /// 显式来源 + 不可变样式（推荐入口）
  factory WImage.source({
    Key? key,
    required WImageSource source,
    WImageStyle style = const WImageStyle(),
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    return WImage._(
      key: key,
      type: source.type,
      source: source,
      style: style,
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
      controller: controller,
    );
  }

  /// 网络图片（`http` / `https`，或以 `//` 开头的协议相对地址）
  factory WImage.network(
    String data, {
    Key? key,
    WImageStyle style = const WImageStyle(),
    Map<String, String>? headers,
    String? cacheKey,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    return WImage.source(
      key: key,
      source: WImageSource.network(data, headers: headers, cacheKey: cacheKey),
      style: style,
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
      controller: controller,
    );
  }

  /// 本地资源图片（`assets/...` 或 `packages/<pkg>/...`）
  factory WImage.asset(
    String data, {
    Key? key,
    WImageStyle style = const WImageStyle(),
    String? package,
    bool prefix = false,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    return WImage.source(
      key: key,
      source: WImageSource.asset(data, package: package, prefix: prefix),
      style: style,
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
      controller: controller,
    );
  }

  /// 本地文件图片（带不带 `file://` 前缀都可以）
  factory WImage.file(
    String data, {
    Key? key,
    WImageStyle style = const WImageStyle(),
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    return WImage.source(
      key: key,
      source: WImageSource.file(data),
      style: style,
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
      controller: controller,
    );
  }

  /// Base64 图片（可以带 `data:...;base64,` 前缀，也可以直接给 Base64 串）
  factory WImage.base64(
    String data, {
    Key? key,
    WImageStyle style = const WImageStyle(),
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    return WImage.source(
      key: key,
      source: WImageSource.base64(data),
      style: style,
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
      controller: controller,
    );
  }

  /// 头像：正方形 + 全圆角
  factory WImage.avatar(
    String data, {
    Key? key,
    double size = 40,
    WImageStyle? style,
    WImageType? type,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    assert(
      style == null || size == 40,
      '传了 style 时 size 会被忽略；需要自定义请直接写 WImageStyle',
    );
    return WImage(
      key: key,
      data: data,
      type: type,
      style: style ?? WImageStyle.avatar(size),
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
      controller: controller,
    );
  }

  /// 缩略图：正方形 + 解码尺寸上限
  factory WImage.thumbnail(
    String data, {
    Key? key,
    double width = 80,
    double? height,
    int? cacheSize,
    WImageStyle? style,
    WImageType? type,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    assert(
      style == null || (width == 80 && height == null && cacheSize == null),
      '传了 style 时 width/height/cacheSize 会被忽略',
    );
    return WImage(
      key: key,
      data: data,
      type: type,
      style: style ?? WImageStyle.thumbnail(width, height: height, cacheSize: cacheSize),
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
      controller: controller,
    );
  }

  /// 封面图：固定比例 + 可选圆角
  factory WImage.cover(
    String data, {
    Key? key,
    double? aspectRatio = 16 / 9,
    double? radius,
    WImageStyle? style,
    WImageType? type,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    assert(
      style == null || (aspectRatio == 16 / 9 && radius == null),
      '传了 style 时 aspectRatio/radius 会被忽略',
    );
    return WImage(
      key: key,
      data: data,
      type: type,
      style: style ?? WImageStyle.cover(aspectRatio: aspectRatio, radius: radius),
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
      controller: controller,
    );
  }

  /// 资源图片：默认拼 `WAssets.imagePath`
  factory WImage.assetImage(
    String name, {
    Key? key,
    String? package,
    WImageStyle style = const WImageStyle(),
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    return WImage.asset(
      name,
      key: key,
      package: package,
      prefix: true,
      style: style,
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
      controller: controller,
    );
  }

  /// 任意 [ImageProvider]（高级入口）
  factory WImage.provider(
    ImageProvider provider, {
    Key? key,
    WImageStyle style = const WImageStyle(),
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    return WImage.source(
      key: key,
      source: WImageSource.provider(provider),
      style: style,
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
      controller: controller,
    );
  }

  /// 内存字节（内部转成 `MemoryImage`）
  factory WImage.memory(
    Uint8List bytes, {
    Key? key,
    WImageStyle style = const WImageStyle(),
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    return WImage.provider(
      MemoryImage(bytes),
      key: key,
      style: style,
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
      controller: controller,
    );
  }

  WImage._({
    super.key,
    required this.type,
    required this.source,
    required this.style,
    this.onLoadStatusChanged,
    this.onProgress,
    this.controller,
  }) {
    style.validate();
  }

  @override
  State<WImage> createState() => _WImageState();
}

/// WImage 的状态类
///
/// 类型判定与数据规范化只在 `initState` / `didUpdateWidget` 做一次，不再使用
/// 跨实例的全局缓存。
class _WImageState extends State<WImage> {
  /// 缓存的默认占位符
  static final Widget _fallbackPlaceholder = Container(color: Colors.grey[200]);

  /// 缓存的默认错误占位符
  static final Widget _fallbackErrorWidget = Container(
    color: Colors.grey[200],
    child: const Icon(Icons.error),
  );

  /// 解码后小于该字节数的 Base64 直接在主 isolate 解码
  /// （`compute` 起 isolate 的开销更大；Web 上 `compute` 也仍在主线程）
  static const int _inlineDecodeMaxBytes = 64 * 1024;

  /// 当前图片类型
  late WImageType _type;

  /// 规范化后的数据（trim、补 scheme、剥 data: 前缀、file:// 转路径）
  late String _value;

  /// Base64 解码的 Future 缓存
  Future<Uint8List>? _bytesFuture;

  /// 上一次构建的 provider（避免每次 build 重新 new）
  ImageProvider? _providerCache;
  Object? _providerKey;
  Widget? _lastFrame;

  /// 加载 / 重试 / 进度状态
  late final WImageLoader _load;

  /// 供 controller 读取的状态
  WImageLoader get loader => _load;

  WImageStyle get config => widget.style;

  @override
  void initState() {
    super.initState();
    widget.style.validate();
    _load = WImageLoader(
      retryCount: config.retryCount,
      retryDelay: config.retryDelay,
      onStatus: (status) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onLoadStatusChanged?.call(status);
        });
      },
      onProgress: (progress) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onProgress?.call(progress);
        });
      },
    );
    _reset();
    _load.state.addListener(_scheduleRebuild);
    widget.controller?._attach(this);
  }

  bool _rebuildScheduled = false;

  void _scheduleRebuild() {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      if (_rebuildScheduled) return;
      _rebuildScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _rebuildScheduled = false;
        if (mounted) setState(() {});
      });
      return;
    }
    setState(() {});
  }

  @override
  void didUpdateWidget(WImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.style.validate();
    _load.syncRetryConfig(
      retryCount: config.retryCount,
      retryDelay: config.retryDelay,
    );
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    if (oldWidget.style != widget.style) {
      _lastFrame = null;
    }
    if (oldWidget.source != widget.source) {
      _reset();
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _load.state.removeListener(_scheduleRebuild);
    _load.dispose();
    super.dispose();
  }

  void _reset() {
    _type = widget.source.type;
    _value = widget.source.value;
    _bytesFuture = null;
    _providerCache = null;
    _providerKey = null;
    _lastFrame = null;
    _load.reset(
      retryCount: config.retryCount,
      retryDelay: config.retryDelay,
    );
  }

  int _seenAttempt = 0;

  @override
  Widget build(BuildContext context) {
    assert(() {
      config.validate();
      return true;
    }());
    if (_load.attempt != _seenAttempt) {
      _seenAttempt = _load.attempt;
      _bytesFuture = null;
      _providerCache = null;
      _providerKey = null;
      _lastFrame = null;
    }
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    Widget result;
    if (_value.isEmpty) {
      _load.fail(WImageEmptyError(widget.data));
      result = _errorSlot(context, _load.error ?? WImageEmptyError(widget.data));
    } else {
      result = switch (_type) {
        WImageType.network => _buildNetwork(),
        WImageType.asset => _buildAsset(),
        WImageType.file => _buildFile(context),
        WImageType.base64 => _buildBase64(),
        WImageType.provider => _buildProvider(),
      };
    }

    result = WImageFrame(style: config, child: result);
    final aspectRatio = config.aspectRatio;
    if (aspectRatio != null && aspectRatio > 0) {
      return AspectRatio(aspectRatio: aspectRatio, child: result);
    }
    return result;
  }

  /// 给占位/错误占位加尺寸约束（配置了宽高时）
  Widget _sizedSlot(Widget child) {
    if (config.width == null && config.height == null) return child;
    return SizedBox(width: config.width, height: config.height, child: child);
  }

  /// 构建默认占位符（theme 优先，其次全局配置/内置兜底）
  Widget _buildPlaceholder(BuildContext context) {
    final themed = WImageTheme.maybeOf(context)?.defaultPlaceholder;
    return _sizedSlot(themed ?? _fallbackPlaceholder);
  }

  /// 构建默认错误占位符（theme 优先，其次全局配置/内置兜底）
  Widget _buildErrorWidget(BuildContext context) {
    final themed = WImageTheme.maybeOf(context)?.defaultErrorWidget;
    return _sizedSlot(themed ?? _fallbackErrorWidget);
  }

  /// 图片加载中的占位（优先业务自定义）
  Widget _placeholderFor(BuildContext context) {
    final builder = config.placeholderBuilder;
    if (builder != null) {
      return builder(context, _value) ?? _buildPlaceholder(context);
    }
    return config.placeholder ?? _buildPlaceholder(context);
  }

  /// 错误占位：业务 builder > 固定 Widget > 内置重试视图 > theme/兜底
  Widget _errorSlot(BuildContext context, WImageError error) {
    final builder = config.errorWidgetBuilder;
    if (builder != null) {
      return builder(context, error.data, error) ?? _buildErrorWidget(context);
    }
    if (config.errorWidget != null) return config.errorWidget!;
    if (config.showRetryButton) {
      final canRetry =
          error is WImageNetworkError || error is WImageProviderError || error is WImageFileError;
      return _sizedSlot(
        WImageErrorView(
          error: error,
          onRetry: canRetry ? _load.retryNow : null,
          retryLabel: config.retryLabel,
          // 实际尺寸交给 WImageErrorView 的 LayoutBuilder 判断；
          // compact/showAction 仅保留为调用方显式覆盖参数。
        ),
      );
    }
    return _buildErrorWidget(context);
  }

  ImageProvider _cachedProvider(Object key, ImageProvider Function() create) {
    if (_providerKey == key && _providerCache != null) return _providerCache!;
    final provider = create();
    _providerKey = key;
    _providerCache = provider;
    return provider;
  }

  /// 网络图片：CachedNetworkImageProvider + 统一 Image 管线
  ///
  /// 磁盘/内存缓存仍由 `cached_network_image` 的 provider 负责；
  /// 进度来自 `Image.loadingBuilder` 的 `ImageChunkEvent`。
  Widget _buildNetwork() {
    final network = widget.source as WNetworkImageSource;
    final provider = _cachedProvider(
      'network:${network.key}:${config.memCacheWidth}x${config.memCacheHeight}',
      () => CachedNetworkImageProvider(
        _value,
        headers: network.headers,
        cacheKey: network.cacheKey,
        maxWidth: config.memCacheWidth,
        maxHeight: config.memCacheHeight,
      ),
    );
    return _imageWidget(
      provider,
      errorFactory: (error) => WImageNetworkError(widget.data, error),
      applyDecodeSize: false,
      notifyProgressCompletion: true,
      retryOnError: true,
      progressBuilder: config.progressBuilder,
    );
  }

  /// 任意 provider（含 MemoryImage）
  Widget _buildProvider() {
    final source = widget.source as WProviderImageSource;
    final provider = _cachedProvider(source.provider, () => source.provider);
    return _imageWidget(
      provider,
      errorFactory: (error) => WImageProviderError(widget.data, error),
    );
  }

  /// 本地资源：统一走 [AssetImage]（Flutter 自带 ImageCache，支持 2x/3x 变体）
  Widget _buildAsset() {
    final asset = widget.source as WAssetImageSource;
    final provider = _cachedProvider(
      'asset:${asset.key}:${config.memCacheWidth}x${config.memCacheHeight}',
      () => AssetImage(asset.value, package: asset.package),
    );
    return _imageWidget(
      provider,
      errorFactory: (error) => WImageAssetError(widget.data, error),
    );
  }

  /// 本地文件：条件导入拿 provider，Web 返回 null → 不支持
  Widget _buildFile(BuildContext context) {
    final provider = buildFileImageProvider(_value);
    if (provider == null) {
      final error = WImageUnsupportedError(widget.data, 'file://');
      _load.fail(error);
      return _errorSlot(context, error);
    }
    final cached = _cachedProvider(
      'file:${widget.source.key}',
      () => provider,
    );
    return _imageWidget(
      cached,
      errorFactory: (error) => WImageFileError(widget.data, error),
    );
  }

  /// Base64：小数据直接解码，大数据交给 isolate
  Widget _buildBase64() {
    return FutureBuilder<Uint8List>(
      future: _bytesFuture ??= _decodeBase64(_value),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final error = WImageDecodeError(widget.data, snapshot.error);
          _load.fail(error);
          return _errorSlot(context, error);
        }
        if (!snapshot.hasData) {
          _load.markLoading();
          return _placeholderFor(context);
        }
        final bytes = snapshot.data!;
        final provider = _cachedProvider(
          'base64:${identityHashCode(bytes)}:${config.memCacheWidth}x${config.memCacheHeight}',
          () => MemoryImage(bytes),
        );
        return _imageWidget(
          provider,
          errorFactory: (error) => WImageDecodeError(widget.data, error),
        );
      },
    );
  }

  /// 统一的 Image 构建：所有来源的宽高/适配/解码/语义参数只在这里维护
  ///
  /// `key` 携带 attempt：手动/自动重试时换 key，让 `Image` 重新解析 provider。
  Widget _imageWidget(
    ImageProvider provider, {
    required WImageError Function(Object error) errorFactory,
    bool showPlaceholderWhileLoading = true,
    bool applyDecodeSize = true,
    bool notifyCompletion = true,
    bool notifyProgressCompletion = false,
    bool retryOnError = false,
    Widget? Function(BuildContext, String, WImageProgress)? progressBuilder,
  }) {
    final effectiveProvider = applyDecodeSize
        ? ResizeImage.resizeIfNeeded(
            config.memCacheWidth,
            config.memCacheHeight,
            provider,
          )
        : provider;
    return Image(
      key: ValueKey('$_value#attempt=${_load.attempt}'),
      image: effectiveProvider,
      width: config.width,
      height: config.height,
      fit: config.fit,
      filterQuality: config.filterQuality,
      alignment: config.alignment,
      gaplessPlayback: config.gaplessPlayback,
      semanticLabel: config.semanticLabel,
      excludeFromSemantics: config.excludeFromSemantics,
      frameBuilder: (showPlaceholderWhileLoading || notifyCompletion)
          ? (context, child, frame, wasSynchronouslyLoaded) {
              final done = wasSynchronouslyLoaded || frame != null;
              if (done) {
                _lastFrame = child;
                if (notifyCompletion) {
                  _load.handleCompleted(notifyProgress: notifyProgressCompletion);
                }
                return child;
              }
              if (!showPlaceholderWhileLoading) return child;
              _load.markLoading();
              return _placeholderFor(context);
            }
          : null,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        if (_load.status == WImageLoadStatus.completed || _load.status == WImageLoadStatus.failed) {
          return child;
        }
        final progress = WImageProgress(
          downloadedBytes: loadingProgress.cumulativeBytesLoaded,
          totalBytes: loadingProgress.expectedTotalBytes,
        );
        _load.handleProgress(progress);
        final builder = progressBuilder ?? WImageTheme.maybeOf(context)?.defaultProgressBuilder;
        return builder?.call(context, _value, progress) ?? _placeholderFor(context);
      },
      errorBuilder: (context, error, stackTrace) {
        if (_load.status == WImageLoadStatus.completed) {
          return _lastFrame ?? const SizedBox.shrink();
        }
        final typed = errorFactory(error);
        _load.handleError(error, typed, retry: retryOnError);
        if (_load.retryScheduled) return _placeholderFor(context);
        return _errorSlot(context, _load.error ?? typed);
      },
    );
  }

  /// Base64 解码（小数据同步，大数据 isolate）
  static Uint8List _decodeBase64Sync(String data) => base64Decode(data);

  Future<Uint8List> _decodeBase64(String value) {
    // Base64 文本长度 × 3/4 ≈ 解码后的字节数
    final estimatedBytes = value.length * 3 ~/ 4;
    if (estimatedBytes <= _inlineDecodeMaxBytes) {
      return Future<Uint8List>.sync(() => _decodeBase64Sync(value));
    }
    return compute(_decodeBase64Sync, value);
  }
}
