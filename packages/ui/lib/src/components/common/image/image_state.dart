part of 'image.dart';

/// WImage 内部 Image 的 key：同一个 State 的同一轮尝试保持稳定（换 source 时
/// 复用元素以支持 gaplessPlayback），重试时 attempt 变化触发重建。
class _WImageAttemptKey extends LocalKey {
  const _WImageAttemptKey(this.owner, this.attempt);

  final Object owner;
  final int attempt;

  @override
  bool operator ==(Object other) =>
      other is _WImageAttemptKey && identical(other.owner, owner) && other.attempt == attempt;

  @override
  int get hashCode => Object.hash(identityHashCode(owner), attempt);
}

class _WImageState extends State<WImage> {
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

  /// 是否已有可复用的上一帧（gaplessPlayback）
  bool _hasFrame = false;

  /// 上一次用于驱动重建的快照（progress-only 变化不重建）
  WImageLoadSnapshot? _lastSnapshot;

  /// 加载 / 重试 / 进度状态
  late final WImageLoader _load;

  /// 供 controller 读取的状态
  WImageLoader get loader => _load;

  WImageStyle get style => widget.style;
  WImageLoadOptions get options => widget.options;

  @override
  void initState() {
    super.initState();
    style.validate();
    options.validate();
    _load = WImageLoader(
      retryCount: options.retryCount,
      retryDelay: options.retryDelay,
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
    _lastSnapshot = _load.state.value;
    _load.state.addListener(_handleLoadStateChanged);
    widget.controller?._attach(this);
  }

  bool _rebuildScheduled = false;

  /// 只重建真正影响 WImage 树的状态；进度变化由内部 Image.loadingBuilder 自己处理。
  void _handleLoadStateChanged() {
    final next = _load.state.value;
    final previous = _lastSnapshot;
    _lastSnapshot = next;
    if (previous != null &&
        previous.status == next.status &&
        previous.attempt == next.attempt &&
        previous.retryScheduled == next.retryScheduled &&
        identical(previous.error, next.error)) {
      return;
    }
    _scheduleRebuild();
  }

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
    options.validate();
    _load.syncRetryConfig(
      retryCount: options.retryCount,
      retryDelay: options.retryDelay,
    );
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    if (oldWidget.style != widget.style ||
        oldWidget.options != widget.options ||
        oldWidget.slots != widget.slots) {
      _lastFrame = null;
    }
    if (oldWidget.style.width != widget.style.width ||
        oldWidget.style.height != widget.style.height ||
        oldWidget.style.aspectRatio != widget.style.aspectRatio) {
      // 尺寸配置变化时允许重新检查；fit/颜色等变化不重复提示。
      _sizeHintScheduled = false;
    }
    if (oldWidget.options.gaplessPlayback && !options.gaplessPlayback) {
      _hasFrame = false;
    }
    if (oldWidget.source != widget.source) {
      _reset();
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _load.state.removeListener(_handleLoadStateChanged);
    _load.dispose();
    super.dispose();
  }

  void _reset() {
    _value = widget.source.value;
    _bytesFuture = null;
    _providerCache = null;
    _providerKey = null;
    _lastFrame = null;
    if (!options.gaplessPlayback) _hasFrame = false;
    _load.reset(
      retryCount: options.retryCount,
      retryDelay: options.retryDelay,
    );
    // source 切换时 attempt 会归零；这不算一次“重试”，不要清掉 gapless 上一帧。
    _seenAttempt = _load.attempt;
  }

  int _seenAttempt = 0;

  @override
  Widget build(BuildContext context) {
    assert(() {
      style.validate();
      options.validate();
      return true;
    }());
    if (_load.attempt != _seenAttempt) {
      _seenAttempt = _load.attempt;
      _bytesFuture = null;
      _providerCache = null;
      _providerKey = null;
      _lastFrame = null;
      _hasFrame = false;
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
    _sizeHintScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      debugCheckWImageSizeHint(context);
    });
  }

  Widget _buildContent(BuildContext context) {
    Widget result;
    if (_value.isEmpty) {
      _hasFrame = false;
      _load.fail(WImageError(widget.source.raw, WImageErrorKind.empty));
      result = _errorSlot(
        context,
        _load.error ?? WImageError(widget.source.raw, WImageErrorKind.empty),
      );
    } else {
      result = switch (widget.source) {
        WNetworkImageSource source => _buildNetwork(source),
        WAssetImageSource source => _buildAsset(source),
        WFileImageSource source => _buildFile(context, source),
        WBase64ImageSource() => _buildBase64(),
        WProviderImageSource source => _buildProvider(source),
      };
    }

    final aspectRatio = style.aspectRatio;
    if (aspectRatio != null && aspectRatio > 0) {
      // 比例作用于图片内容；padding / margin 在 WImageFrame 外层叠加。
      result = AspectRatio(aspectRatio: aspectRatio, child: result);
    }
    return WImageFrame(style: style, child: result);
  }

  /// 合并单图 slots 与主题 slots：单图非空字段优先，错误占位在
  /// showRetryButton=true 时不再继承主题的错误 builder。
  WImageSlots? _mergedSlots;
  WImageSlots? _mergedThemeSlots;
  WImageSlots? _mergedOwnSlots;

  WImageSlots _slotsFor(BuildContext context) {
    final theme = WImageTheme.maybeOf(context) ?? const WImageSlots();
    if (_mergedSlots != null &&
        identical(theme, _mergedThemeSlots) &&
        identical(widget.slots, _mergedOwnSlots)) {
      return _mergedSlots!;
    }
    _mergedThemeSlots = theme;
    _mergedOwnSlots = widget.slots;
    _mergedSlots = mergeImageSlots(own: widget.slots, theme: theme);
    return _mergedSlots!;
  }

  /// 图片加载中的占位（优先业务自定义）
  Widget _placeholderFor(BuildContext context) {
    return buildImagePlaceholder(
      context: context,
      slots: _slotsFor(context),
      style: style,
      data: _value,
    );
  }

  /// 错误占位：业务 builder > 固定 Widget > 内置重试视图 > 兜底
  Widget _errorSlot(BuildContext context, WImageError error) {
    return buildImageErrorSlot(
      context: context,
      slots: _slotsFor(context),
      style: style,
      error: error,
      onRetry: _load.retryNow,
    );
  }

  ImageProvider _cachedProvider(Object key, ImageProvider Function() create) {
    if (_providerKey == key && _providerCache != null) return _providerCache!;
    final provider = create();
    _providerKey = key;
    _providerCache = provider;
    return provider;
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
  }) {
    final effectiveProvider = applyDecodeSize
        ? ResizeImage.resizeIfNeeded(
            options.memCacheWidth,
            options.memCacheHeight,
            provider,
          )
        : provider;
    return Image(
      // 同一个 State + 同一个 attempt 保持 key 稳定：换 source 时复用 Image
      // 元素，gaplessPlayback 才能保留上一帧；重试时 attempt 变化，强制重建。
      key: _WImageAttemptKey(this, _load.attempt),
      image: effectiveProvider,
      width: style.width,
      height: style.height,
      fit: style.fit,
      filterQuality: style.filterQuality,
      alignment: style.alignment,
      gaplessPlayback: options.gaplessPlayback,
      semanticLabel: style.semanticLabel,
      excludeFromSemantics: style.excludeFromSemantics,
      frameBuilder: (showPlaceholderWhileLoading || notifyCompletion)
          ? (context, child, frame, wasSynchronouslyLoaded) {
              final done = wasSynchronouslyLoaded || frame != null;
              if (done) {
                _hasFrame = true;
                _lastFrame = child;
                if (notifyCompletion) {
                  _load.handleCompleted(notifyProgress: notifyProgressCompletion);
                }
                return child;
              }
              if (!showPlaceholderWhileLoading) return child;
              _load.markLoading();
              if (options.gaplessPlayback && _hasFrame) return child;
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
        final builder = _slotsFor(context).progressBuilder;
        return builder?.call(context, _value, progress) ?? _placeholderFor(context);
      },
      errorBuilder: (context, error, stackTrace) {
        if (_load.status == WImageLoadStatus.completed) {
          return _lastFrame ?? const SizedBox.shrink();
        }
        // 错误占位会替换 Image；之后换回有效 source 时不要再拿旧帧，
        // 否则 frameBuilder 会返回空 RawImage，表现为整块空白。
        _hasFrame = false;
        final typed = errorFactory(error);
        _load.handleError(error, typed, retry: retryOnError);
        if (_load.retryScheduled) return _placeholderFor(context);
        return _errorSlot(context, _load.error ?? typed);
      },
    );
  }
}
