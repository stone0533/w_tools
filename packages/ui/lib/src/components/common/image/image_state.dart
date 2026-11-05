part of 'image.dart';

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

  /// debug 下“无尺寸 + 无界父级”提示是否已排过（每个 State 只提示一次）
  bool _sizeHintScheduled = false;

  /// 加载 / 重试 / 进度状态
  late final WImageLoader _load;

  /// 供 controller 读取的状态
  WImageLoader get loader => _load;

  WImageStyle get style => widget.style;
  WImageLoadConfig get config => widget.config;

  @override
  void initState() {
    super.initState();
    style.validate();
    config.validate();
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
    style.validate();
    config.validate();
    _load.syncRetryConfig(
      retryCount: config.retryCount,
      retryDelay: config.retryDelay,
    );
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    if (oldWidget.style != widget.style || oldWidget.config != widget.config) {
      _lastFrame = null;
    }
    if (oldWidget.style != widget.style) {
      // 尺寸配置可能从“有”变“无”，允许重新检查
      _sizeHintScheduled = false;
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
      style.validate();
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
    _debugScheduleSizeHint();
    return _buildContent(context);
  }

  /// debug-only：无尺寸 + 父级无界时，加载前占位是 0 尺寸（表现为空白）。
  ///
  /// 只在首次布局后检查一次；用 debugPrint 而不是断言，避免误伤
  /// `IntrinsicHeight` / 故意 0 尺寸的调用方，也不影响 release。
  void _debugScheduleSizeHint() {
    if (!kDebugMode || _sizeHintScheduled) return;
    if (style.width != null || style.height != null || style.aspectRatio != null) {
      return;
    }
    _sizeHintScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _debugCheckSizeHint());
  }

  void _debugCheckSizeHint() {
    if (!mounted) return;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final constraints = renderObject.constraints;
    final unboundedWidth = constraints.maxWidth.isInfinite;
    final unboundedHeight = constraints.maxHeight.isInfinite;
    if (!unboundedWidth && !unboundedHeight) return;
    final axis = unboundedWidth && unboundedHeight ? '宽高' : (unboundedWidth ? '宽度' : '高度');
    debugPrint(
      '[w_tools_ui] WImage 没有 width/height/aspectRatio，且父级在$axis轴上无界：'
      '加载前占位是 0 尺寸，会表现为空白。请给 WImageStyle 设置尺寸或 aspectRatio，'
      '或用 SizedBox / Expanded / AspectRatio 约束。',
    );
  }

  Widget _buildContent(BuildContext context) {
    Widget result;
    if (_value.isEmpty) {
      _load.fail(WImageError(widget.data, WImageErrorKind.empty));
      result = _errorSlot(context, _load.error ?? WImageError(widget.data, WImageErrorKind.empty));
    } else {
      result = switch (_type) {
        WImageType.network => _buildNetwork(),
        WImageType.asset => _buildAsset(),
        WImageType.file => _buildFile(context),
        WImageType.base64 => _buildBase64(),
        WImageType.provider => _buildProvider(),
      };
    }

    result = WImageFrame(style: style, child: result);
    final aspectRatio = style.aspectRatio;
    if (aspectRatio != null && aspectRatio > 0) {
      return AspectRatio(aspectRatio: aspectRatio, child: result);
    }
    return result;
  }

  /// 给占位/错误占位加尺寸约束（配置了宽高时）
  Widget _sizedSlot(Widget child) {
    if (style.width == null && style.height == null) return child;
    return SizedBox(width: style.width, height: style.height, child: child);
  }

  /// 构建默认占位符（defaults 优先，其次内置兜底）
  Widget _buildPlaceholder(BuildContext context) {
    final themed = WImageDefaultsScope.maybeOf(context)?.placeholderBuilder?.call(context, _value);
    return _sizedSlot(themed ?? _fallbackPlaceholder);
  }

  /// 构建默认错误占位符（defaults 优先，其次内置兜底）
  Widget _buildErrorWidget(BuildContext context, WImageError error) {
    final themed = WImageDefaultsScope.maybeOf(
      context,
    )?.errorWidgetBuilder?.call(context, _value, error);
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

  /// 错误占位：业务 builder > 固定 Widget > 内置重试视图 > defaults/兜底
  Widget _errorSlot(BuildContext context, WImageError error) {
    final builder = config.errorWidgetBuilder;
    if (builder != null) {
      return builder(context, error.data, error) ?? _buildErrorWidget(context, error);
    }
    if (config.errorWidget != null) return config.errorWidget!;
    if (config.showRetryButton) {
      final canRetry = const {
        WImageErrorKind.network,
        WImageErrorKind.provider,
        WImageErrorKind.file,
      }.contains(error.kind);
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
    return _buildErrorWidget(context, error);
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
      errorFactory: (error) => WImageError(widget.data, WImageErrorKind.network, cause: error),
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
      errorFactory: (error) => WImageError(widget.data, WImageErrorKind.provider, cause: error),
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
      errorFactory: (error) => WImageError(widget.data, WImageErrorKind.asset, cause: error),
    );
  }

  /// 本地文件：条件导入拿 provider，Web 返回 null → 不支持
  Widget _buildFile(BuildContext context) {
    final provider = buildFileImageProvider(_value);
    if (provider == null) {
      final error = WImageError(widget.data, WImageErrorKind.unsupported);
      _load.fail(error);
      return _errorSlot(context, error);
    }
    final cached = _cachedProvider(
      'file:${widget.source.key}',
      () => provider,
    );
    return _imageWidget(
      cached,
      errorFactory: (error) => WImageError(widget.data, WImageErrorKind.file, cause: error),
    );
  }

  /// Base64：小数据直接解码，大数据交给 isolate
  Widget _buildBase64() {
    return FutureBuilder<Uint8List>(
      future: _bytesFuture ??= _decodeBase64(_value),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final error = WImageError(widget.data, WImageErrorKind.decode, cause: snapshot.error);
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
          errorFactory: (error) => WImageError(widget.data, WImageErrorKind.decode, cause: error),
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
      width: style.width,
      height: style.height,
      fit: style.fit,
      filterQuality: style.filterQuality,
      alignment: style.alignment,
      gaplessPlayback: config.gaplessPlayback,
      semanticLabel: style.semanticLabel,
      excludeFromSemantics: style.excludeFromSemantics,
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
        final builder = progressBuilder ?? WImageDefaultsScope.maybeOf(context)?.progressBuilder;
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
