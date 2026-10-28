import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'image_config.dart';
import 'image_frame.dart';
import 'image_load_state.dart';
import 'image_source.dart';
import 'image_style.dart';
import 'image_theme.dart';
import 'image_retry_policy.dart';
import 'image_types.dart';

// 条件导入：默认 Web（没有文件系统），只有存在 dart:io 时才切到原生实现。
// 这里刻意用 dart.library.io 而不是 dart.library.html —— WASM 构建下
// dart.library.html 不可用，用 html 判断会落到原生分支并编译 dart:io。
import '_image_file_web.dart' if (dart.library.io) '_image_file_native.dart';

export 'image_config.dart';
export 'image_frame.dart';
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

  /// 是否已绑定到 [WImage]
  bool get isAttached => _state != null;

  /// 手动重新加载
  ///
  /// 触发一次新的请求；组件未挂载时是空操作。
  void retry() => _state?._retryNow();

  void _attach(_WImageState state) {
    _state = state;
  }

  void _detach(_WImageState state) {
    if (identical(_state, state)) _state = null;
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

  /// 旧的配置视图（返回重命名前的配置副本）
  WImageConfig get config => style.toConfig();

  /// 调用方传入的原始值（未 trim / 未规范化）
  String get data => source.raw;

  /// 显式类型；默认构造自动判定时为 null（历史语义）
  final WImageType? type;

  /// 按字符串自动判定来源（兼容入口；新代码建议用 [WImage.source]）
  factory WImage({
    Key? key,
    WImageConfig? config,
    WImageStyle? style,
    required String data,
    WImageType? type,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    var source = WImageSource.parse(data, type: type);
    if (source is WNetworkImageSource) {
      source = WNetworkImageSource(
        source.raw,
        headers: source.headers ?? config?.httpHeaders,
        cacheKey: source.cacheKey ?? config?.cacheKey,
      );
    }
    return WImage._(
      key: key,
      type: type,
      source: source,
      style: style ?? WImageStyle.fromConfig(config ?? WImageConfig()),
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
      controller: controller,
    );
  }

  /// 显式来源 + 不可变样式（推荐的新入口）
  factory WImage.source({
    Key? key,
    required WImageSource source,
    WImageStyle? style,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    return WImage._(
      key: key,
      type: source.type,
      source: source,
      style: style ?? WImageStyle(),
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
      controller: controller,
    );
  }

  /// 网络图片（`http` / `https`，或以 `//` 开头的协议相对地址）
  factory WImage.network(
    String data, {
    Key? key,
    WImageConfig? config,
    WImageStyle? style,
    Map<String, String>? headers,
    String? cacheKey,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    return WImage.source(
      key: key,
      source: WImageSource.network(
        data,
        headers: headers ?? config?.httpHeaders,
        cacheKey: cacheKey ?? config?.cacheKey,
      ),
      style: style ?? WImageStyle.fromConfig(config ?? WImageConfig()),
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
      controller: controller,
    );
  }

  /// 本地资源图片（`assets/...` 或 `packages/<pkg>/...`）
  factory WImage.asset(
    String data, {
    Key? key,
    WImageConfig? config,
    WImageStyle? style,
    String? package,
    bool prefix = false,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    return WImage.source(
      key: key,
      source: WImageSource.asset(data, package: package, prefix: prefix),
      style: style ?? WImageStyle.fromConfig(config ?? WImageConfig()),
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
      controller: controller,
    );
  }

  /// 本地文件图片（带不带 `file://` 前缀都可以）
  factory WImage.file(
    String data, {
    Key? key,
    WImageConfig? config,
    WImageStyle? style,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    return WImage.source(
      key: key,
      source: WImageSource.file(data),
      style: style ?? WImageStyle.fromConfig(config ?? WImageConfig()),
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
      controller: controller,
    );
  }

  /// Base64 图片（可以带 `data:...;base64,` 前缀，也可以直接给 Base64 串）
  factory WImage.base64(
    String data, {
    Key? key,
    WImageConfig? config,
    WImageStyle? style,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    return WImage.source(
      key: key,
      source: WImageSource.base64(data),
      style: style ?? WImageStyle.fromConfig(config ?? WImageConfig()),
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

  /// 重试抖动源（同屏多图不会在同一毫秒齐刷刷重试）
  static final Random _random = Random();

  /// 当前图片类型
  late WImageType _type;

  /// 规范化后的数据（trim、补 scheme、剥 data: 前缀、file:// 转路径）
  late String _value;

  /// Base64 解码的 Future 缓存
  Future<Uint8List>? _bytesFuture;

  /// 加载 / 重试 / 进度状态
  final WImageLoadState _load = WImageLoadState();

  WImageStyle get config => widget.style;

  @override
  void initState() {
    super.initState();
    widget.config.validate();
    _reset();
    widget.controller?._attach(this);
  }

  @override
  void didUpdateWidget(WImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.config.validate();
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    if (oldWidget.source != widget.source) {
      _reset();
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    super.dispose();
  }

  void _reset() {
    _type = widget.source.type;
    _value = widget.source.value;
    _bytesFuture = null;
    _load.reset(
      retryCount: config.retryCount,
      retryDelay: config.retryDelay,
    );
  }

  /// 重试配置变化时重置重试进度（config 是可变的，只能在 build 时对比快照）
  void _syncRetryConfig() {
    _load.syncRetryConfig(
      retryCount: config.retryCount,
      retryDelay: config.retryDelay,
    );
  }

  /// 通知加载状态（同一状态只通知一次，且组件已卸载时不回调）
  void _notifyStatus(WImageLoadStatus status) {
    if (!_load.markStatus(status)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onLoadStatusChanged?.call(status);
    });
  }

  /// 上报下载进度（延迟到帧结束后，避免在 build 阶段回调业务代码）
  void _notifyProgress(WImageProgress progress) {
    _load.pendingProgress = progress;
    if (_load.progressScheduled) return;
    _load.progressScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load.progressScheduled = false;
      if (!mounted) return;
      final pending = _load.pendingProgress;
      if (pending == null) return;
      widget.onProgress?.call(pending);
    });
  }

  /// 完成时补一次 1.0（只补一次，重复 build 不会重复回调）
  void _notifyCompletedProgress() {
    if (_load.completedProgressSent) return;
    _load.completedProgressSent = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onProgress?.call(const WImageProgress(downloadedBytes: 1, totalBytes: 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(() {
      config.validate();
      return true;
    }());
    _syncRetryConfig();

    Widget result;
    if (_value.isEmpty) {
      _notifyStatus(WImageLoadStatus.failed);
      result = _errorSlot(context, WImageEmptyError(widget.data));
    } else {
      result = switch (_type) {
        WImageType.network => _buildNetwork(),
        WImageType.asset => _buildAsset(),
        WImageType.file => _buildFile(context),
        WImageType.base64 => _buildBase64(),
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
    return _sizedSlot(
      themed ?? WImageGlobalConfig().defaultPlaceholder ?? _fallbackPlaceholder,
    );
  }

  /// 构建默认错误占位符（theme 优先，其次全局配置/内置兜底）
  Widget _buildErrorWidget(BuildContext context) {
    final themed = WImageTheme.maybeOf(context)?.defaultErrorWidget;
    return _sizedSlot(
      themed ?? WImageGlobalConfig().defaultErrorWidget ?? _fallbackErrorWidget,
    );
  }

  /// 图片加载中的占位（优先业务自定义）
  Widget _placeholderFor(BuildContext context) {
    return config.placeholderBuilder?.call(context, _value) ?? _buildPlaceholder(context);
  }

  /// 错误占位：业务自定义优先，其次默认错误占位
  Widget _errorSlot(BuildContext context, WImageError error) {
    return config.errorWidgetBuilder?.call(context, error.data, error) ??
        _buildErrorWidget(context);
  }

  /// 是否还有自动重试次数
  bool get _hasRetries => _load.attempt < config.retryCount;

  /// 延迟重试（同一时刻只允许一个待执行的重试）
  void _scheduleRetry() {
    if (_load.retryScheduled) return;
    _load.retryScheduled = true;
    final generation = _load.generation;
    final delay = retryDelayFor(
      _load.attempt,
      base: Duration(milliseconds: config.retryDelay),
      random: _random,
    );
    Future<void>.delayed(delay, () {
      if (!mounted || generation != _load.generation) return;
      setState(() {
        _load.beginAttempt();
        _load.retryScheduled = false;
      });
    });
  }

  /// 手动重试（由 [WImageController.retry] 触发）
  ///
  /// 对四种来源都有效：换 attempt key 会重建 Image，base64 会清掉解码缓存。
  void _retryNow() {
    if (!mounted) return;
    setState(() {
      _load.beginAttempt();
      _load.generation++;
      _load.retryScheduled = false;
      _load.pendingProgress = null;
      _bytesFuture = null;
    });
  }

  /// 网络图片：直接构建 [CachedNetworkImage]
  ///
  /// 重试、进度与状态都在本 State 内处理，不再经过额外的包装组件。
  Widget _buildNetwork() {
    final network = widget.source as WNetworkImageSource;
    final hasProgress = config.progressBuilder != null;
    return CachedNetworkImage(
      // 换 key 才会真正重新发起请求（同一 provider 重建不会重新拉取）
      key: ValueKey('$_value#attempt=${_load.attempt}'),
      imageUrl: _value,
      width: config.width,
      height: config.height,
      fit: config.fit,
      alignment: config.alignment,
      filterQuality: config.filterQuality,
      memCacheWidth: config.memCacheWidth,
      memCacheHeight: config.memCacheHeight,
      httpHeaders: network.headers,
      cacheKey: network.cacheKey,
      progressIndicatorBuilder: hasProgress ? _networkProgress : null,
      placeholder: hasProgress ? null : _networkPlaceholder,
      errorWidget: _networkError,
      imageBuilder: (context, imageProvider) {
        return _imageWidget(
          imageProvider,
          errorFactory: (error) => WImageNetworkError(widget.data, error),
          showPlaceholderWhileLoading: false,
          applyDecodeSize: false,
          notifyProgressCompletion: true,
        );
      },
    );
  }

  /// 网络占位符
  Widget _networkPlaceholder(BuildContext context, String url) {
    _notifyStatus(WImageLoadStatus.loading);
    return config.placeholderBuilder?.call(context, url) ?? _buildPlaceholder(context);
  }

  /// 网络进度：新签名优先，其次旧签名
  Widget _networkProgress(
    BuildContext context,
    String url,
    DownloadProgress downloadProgress,
  ) {
    final progress = WImageProgress(
      downloadedBytes: downloadProgress.downloaded,
      totalBytes: downloadProgress.totalSize,
    );
    _notifyStatus(WImageLoadStatus.loading);
    _notifyProgress(progress);

    final builder = config.progressBuilder;
    if (builder != null) {
      return builder(context, url, progress) ?? _buildPlaceholder(context);
    }
    return _buildPlaceholder(context);
  }

  /// 网络错误：可重试就先重试，否则渲染错误占位
  Widget _networkError(BuildContext context, String url, Object error) {
    if (_hasRetries && isRetryableNetworkError(error)) {
      _scheduleRetry();
      return _networkPlaceholder(context, url);
    }
    _notifyStatus(WImageLoadStatus.failed);
    return _errorSlot(context, WImageNetworkError(widget.data, error));
  }

  /// 本地资源：统一走 [AssetImage]（Flutter 自带 ImageCache，支持 2x/3x 变体）
  Widget _buildAsset() {
    final asset = widget.source as WAssetImageSource;
    return _imageWidget(
      AssetImage(asset.value, package: asset.package),
      errorFactory: (error) => WImageAssetError(widget.data, error),
    );
  }

  /// 本地文件：条件导入拿 provider，Web 返回 null → 不支持
  Widget _buildFile(BuildContext context) {
    final provider = buildFileImageProvider(_value);
    if (provider == null) {
      _notifyStatus(WImageLoadStatus.failed);
      return _errorSlot(context, WImageUnsupportedError(widget.data, 'file://'));
    }
    return _imageWidget(
      provider,
      errorFactory: (error) => WImageFileError(widget.data, error),
    );
  }

  /// Base64：小数据直接解码，大数据交给 isolate
  Widget _buildBase64() {
    return FutureBuilder<Uint8List>(
      future: _bytesFuture ??= _decodeBase64(_value),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          _notifyStatus(WImageLoadStatus.failed);
          return _errorSlot(context, WImageDecodeError(widget.data, snapshot.error));
        }
        if (!snapshot.hasData) {
          _notifyStatus(WImageLoadStatus.loading);
          return _placeholderFor(context);
        }
        return _imageWidget(
          MemoryImage(snapshot.data!),
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
                if (notifyCompletion) {
                  _notifyStatus(WImageLoadStatus.completed);
                  if (notifyProgressCompletion) _notifyCompletedProgress();
                }
                return child;
              }
              if (!showPlaceholderWhileLoading) return child;
              _notifyStatus(WImageLoadStatus.loading);
              return _placeholderFor(context);
            }
          : null,
      errorBuilder: (context, error, stackTrace) {
        _notifyStatus(WImageLoadStatus.failed);
        return _errorSlot(context, errorFactory(error));
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

/// [WImageConfig] 的构建便利方法
extension WImageConfigBuild on WImageConfig {
  /// 构建 WImage 组件
  WImage build({
    required String data,
    Key? key,
    WImageType? type,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    return WImage(
      key: key,
      config: this,
      data: data,
      type: type,
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
      controller: controller,
    );
  }

  /// 构建文件图片组件（通过路径字符串）
  WImage buildFilePath(
    String filePath, {
    Key? key,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    return WImage.file(
      filePath,
      key: key,
      config: this,
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
      controller: controller,
    );
  }

  /// 构建 Base64 图片组件
  ///
  /// 可以带 `data:...;base64,` 前缀，也可以直接给 Base64 串。
  WImage buildBase64(
    String base64, {
    Key? key,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    return WImage.base64(
      base64,
      key: key,
      config: this,
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
      controller: controller,
    );
  }
}
