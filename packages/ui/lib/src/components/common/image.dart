import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'image_config.dart';
import 'image_retry_policy.dart';
import 'image_types.dart';

// 条件导入：默认 Web（没有文件系统），只有存在 dart:io 时才切到原生实现。
// 这里刻意用 dart.library.io 而不是 dart.library.html —— WASM 构建下
// dart.library.html 不可用，用 html 判断会落到原生分支并编译 dart:io。
import '_image_file_web.dart' if (dart.library.io) '_image_file_native.dart';

export 'image_config.dart';
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
  /// 图片配置
  final WImageConfig config;

  /// 图片数据（网络 URL、本地资源路径、文件路径或 Base64 数据）
  final String data;

  /// 显式指定的图片类型；null 表示按 [data] 自动判定
  final WImageType? type;

  /// 加载状态回调
  final ValueChanged<WImageLoadStatus>? onLoadStatusChanged;

  /// 类型化的进度回调（仅网络图片有值）
  final ValueChanged<WImageProgress>? onProgress;

  /// 图片控制器（手动重试）
  final WImageController? controller;

  /// 按 [data] 自动判定类型
  ///
  /// 判定规则见 [WImageType]；空串/纯空白渲染错误占位。
  WImage({
    Key? key,
    WImageConfig? config,
    required String data,
    WImageType? type,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) : this._(
          key: key,
          config: config,
          data: data,
          type: type,
          onLoadStatusChanged: onLoadStatusChanged,
          onProgress: onProgress,
          controller: controller,
        );

  /// 网络图片（`http` / `https`，或以 `//` 开头的协议相对地址）
  WImage.network(
    String data, {
    Key? key,
    WImageConfig? config,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) : this._(
          key: key,
          config: config,
          data: data,
          type: WImageType.network,
          onLoadStatusChanged: onLoadStatusChanged,
          onProgress: onProgress,
          controller: controller,
        );

  /// 本地资源图片（`assets/...` 或 `packages/<pkg>/...`）
  WImage.asset(
    String data, {
    Key? key,
    WImageConfig? config,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) : this._(
          key: key,
          config: config,
          data: data,
          type: WImageType.asset,
          onLoadStatusChanged: onLoadStatusChanged,
          onProgress: onProgress,
          controller: controller,
        );

  /// 本地文件图片（带不带 `file://` 前缀都可以）
  WImage.file(
    String data, {
    Key? key,
    WImageConfig? config,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) : this._(
          key: key,
          config: config,
          data: data,
          type: WImageType.file,
          onLoadStatusChanged: onLoadStatusChanged,
          onProgress: onProgress,
          controller: controller,
        );

  /// Base64 图片（可以带 `data:...;base64,` 前缀，也可以直接给 Base64 串）
  WImage.base64(
    String data, {
    Key? key,
    WImageConfig? config,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) : this._(
          key: key,
          config: config,
          data: data,
          type: WImageType.base64,
          onLoadStatusChanged: onLoadStatusChanged,
          onProgress: onProgress,
          controller: controller,
        );

  WImage._({
    super.key,
    WImageConfig? config,
    required this.data,
    required this.type,
    this.onLoadStatusChanged,
    this.onProgress,
    this.controller,
  }) : config = config ?? WImageConfig() {
    final c = this.config;
    assert(c.retryCount >= 0, 'retryCount 不能为负');
    assert(c.retryDelay >= 0, 'retryDelay 不能为负');
    assert(
      c.memCacheWidth == null || c.memCacheWidth! > 0,
      'memCacheWidth 必须大于 0',
    );
    assert(
      c.memCacheHeight == null || c.memCacheHeight! > 0,
      'memCacheHeight 必须大于 0',
    );
    assert(
      c.aspectRatio == null || c.aspectRatio! > 0,
      'aspectRatio 必须大于 0',
    );
    assert(c.width == null || c.width! >= 0, 'width 不能为负');
    assert(c.height == null || c.height! >= 0, 'height 不能为负');
  }

  @override
  State<WImage> createState() => _WImageState();
}

/// 加载 / 重试 / 进度的一次性状态
///
/// 从 `_WImageState` 抽出来：重试时机、去重与进度合并都可以脱离 widget 阅读。
/// 真正的回调仍留在 State（依赖 `mounted` 与 widget 回调）。
class _WImageLoadState {
  /// 上一次已通知的加载状态
  WImageLoadStatus? status;

  /// 已执行的重试次数
  int attempt = 0;

  /// 加载代际：数据变化 / 手动重试时 +1，用来丢弃过期的延迟重试
  int generation = 0;

  /// 是否有待执行的重试（避免 errorWidget 多次构建时重复调度）
  bool retryScheduled = false;

  /// 是否已经上报过进度 1.0
  bool completedProgressSent = false;

  /// 是否有待上报的进度（同一帧内的多次进度只上报最后一次）
  bool progressScheduled = false;
  WImageProgress? pendingProgress;

  /// 上一次见到的重试配置（config 可变，只能靠快照检测变化）
  int retryCountSeen = 0;
  int retryDelaySeen = 1000;

  /// 重置到初始状态
  void reset({required int retryCount, required int retryDelay}) {
    status = null;
    attempt = 0;
    generation++;
    retryScheduled = false;
    completedProgressSent = false;
    progressScheduled = false;
    pendingProgress = null;
    retryCountSeen = retryCount;
    retryDelaySeen = retryDelay;
  }

  /// 标记新状态；返回是否发生变化（用于去重）
  bool markStatus(WImageLoadStatus next) {
    if (status == next) return false;
    status = next;
    return true;
  }

  /// 重试配置变化时重置重试进度；返回是否发生了变化
  bool syncRetryConfig({required int retryCount, required int retryDelay}) {
    if (retryCount == retryCountSeen && retryDelay == retryDelaySeen) {
      return false;
    }
    retryCountSeen = retryCount;
    retryDelaySeen = retryDelay;
    attempt = 0;
    retryScheduled = false;
    completedProgressSent = false;
    return true;
  }

  /// 开始新一次尝试（自动重试或手动重试）
  void beginAttempt() {
    attempt++;
    status = null;
    completedProgressSent = false;
  }
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

  /// `file://` 前缀（避免每次调用都重新编译）
  static final RegExp _fileSchemePattern = RegExp(r'^file://');

  /// 重试抖动源（同屏多图不会在同一毫秒齐刷刷重试）
  static final Random _random = Random();

  /// 当前图片类型
  late WImageType _type;

  /// 规范化后的数据（trim、补 scheme、剥 data: 前缀、file:// 转路径）
  late String _value;

  /// Base64 解码的 Future 缓存
  Future<Uint8List>? _bytesFuture;

  /// 加载 / 重试 / 进度状态
  final _WImageLoadState _load = _WImageLoadState();

  WImageConfig get config => widget.config;

  @override
  void initState() {
    super.initState();
    _reset();
    widget.controller?._attach(this);
  }

  @override
  void didUpdateWidget(WImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    if (oldWidget.data != widget.data || oldWidget.type != widget.type) {
      _reset();
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    super.dispose();
  }

  void _reset() {
    _type = widget.type ?? _detectType(widget.data);
    _value = _normalize(widget.data, _type);
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

  /// 按内容判定类型
  ///
  /// 用 [Uri] 解析 scheme（大小写无关），而不是 `startsWith('http')`：
  /// `HTTPS://`、前导空格、`//` 协议相对地址都能识别。
  static WImageType _detectType(String raw) {
    final value = raw.trim();
    final uri = Uri.tryParse(value);
    final scheme = uri?.scheme.toLowerCase() ?? '';
    if ((scheme == 'http' || scheme == 'https') && (uri?.host.isNotEmpty ?? false)) {
      return WImageType.network;
    }
    if (scheme == 'file') return WImageType.file;
    if (value.startsWith('data:')) return WImageType.base64;
    // 协议相对地址：`//cdn.example.com/a.png`
    if (value.startsWith('//')) return WImageType.network;
    return WImageType.asset;
  }

  /// 规范化数据：所有分支统一使用 trim 后的值
  static String _normalize(String raw, WImageType type) {
    final value = raw.trim();
    switch (type) {
      case WImageType.network:
        return value.startsWith('//') ? 'https:$value' : value;
      case WImageType.file:
        return _filePathOf(value);
      case WImageType.base64:
        return _stripDataUriPrefix(value);
      case WImageType.asset:
        return value;
    }
  }

  /// `file://` URI → 文件系统路径
  static String _filePathOf(String value) {
    if (!value.startsWith('file:')) return value;
    final uri = Uri.tryParse(value);
    if (uri != null && uri.scheme == 'file') {
      try {
        return uri.toFilePath();
      } catch (_) {
        // 非法 file URI（例如 Windows 盘符写法）退回字符串处理
      }
    }
    return value.replaceFirst(_fileSchemePattern, '');
  }

  /// 剥掉 `data:[<mediatype>][;base64],` 前缀
  ///
  /// 不限于 `data:image/`：`data:application/octet-stream;base64,...` 同样是图片数据。
  static String _stripDataUriPrefix(String value) {
    if (!value.startsWith('data:')) return value;
    final comma = value.indexOf(',');
    if (comma < 0) return value;
    return value.substring(comma + 1);
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

    result = _applyTransformations(result);
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

  /// 构建默认占位符
  Widget _buildPlaceholder() {
    return _sizedSlot(
      WImageGlobalConfig().defaultPlaceholder ?? _fallbackPlaceholder,
    );
  }

  /// 构建默认错误占位符
  Widget _buildErrorWidget() {
    return _sizedSlot(
      WImageGlobalConfig().defaultErrorWidget ?? _fallbackErrorWidget,
    );
  }

  /// 图片加载中的占位（优先业务自定义）
  Widget _placeholderFor(BuildContext context) {
    return config.placeholderBuilder?.call(context, _value) ?? _buildPlaceholder();
  }

  /// 错误占位：业务自定义优先，其次默认错误占位
  Widget _errorSlot(BuildContext context, WImageError error) {
    return config.errorWidgetBuilder?.call(context, error.data, error) ?? _buildErrorWidget();
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
      httpHeaders: config.httpHeaders,
      cacheKey: config.cacheKey,
      progressIndicatorBuilder: hasProgress ? _networkProgress : null,
      placeholder: hasProgress ? null : _networkPlaceholder,
      errorWidget: _networkError,
      imageBuilder: (context, imageProvider) {
        _notifyStatus(WImageLoadStatus.completed);
        _notifyCompletedProgress();
        return _imageWidget(
          imageProvider,
          errorFactory: (error) => WImageNetworkError(widget.data, error),
          showPlaceholderWhileLoading: false,
          applyDecodeSize: false,
        );
      },
    );
  }

  /// 网络占位符
  Widget _networkPlaceholder(BuildContext context, String url) {
    _notifyStatus(WImageLoadStatus.loading);
    return config.placeholderBuilder?.call(context, url) ?? _buildPlaceholder();
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
      return builder(context, url, progress) ?? _buildPlaceholder();
    }
    return _buildPlaceholder();
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
    return _imageWidget(
      AssetImage(_value),
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
      frameBuilder: showPlaceholderWhileLoading
          ? (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) {
                _notifyStatus(WImageLoadStatus.completed);
                return child;
              }
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

  /// 应用图片变换
  Widget _applyTransformations(Widget image) {
    if (config.padding == null &&
        config.borderRadius == null &&
        config.border == null &&
        (config.boxShadow == null || config.boxShadow!.isEmpty) &&
        config.margin == null) {
      return image;
    }

    Widget transformedImage = image;

    // 先应用圆角裁剪（作用于图片本体 + padding 区域）
    final borderRadius = config.borderRadius;
    if (borderRadius != null) {
      transformedImage = ClipRRect(
        borderRadius: borderRadius,
        child: transformedImage,
      );
    }

    // 应用边框、阴影和外边距（顺序与 Container 一致：margin 在 decoration 外层）
    final border = config.border;
    final boxShadow = config.boxShadow;
    if (border != null || (boxShadow != null && boxShadow.isNotEmpty)) {
      transformedImage = DecoratedBox(
        decoration: BoxDecoration(border: border, boxShadow: boxShadow),
        child: transformedImage,
      );
    }
    final margin = config.margin;
    if (margin != null) {
      transformedImage = Padding(padding: margin, child: transformedImage);
    }

    // 最后应用内边距
    final padding = config.padding;
    if (padding != null) {
      transformedImage = Padding(padding: padding, child: transformedImage);
    }

    return transformedImage;
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
