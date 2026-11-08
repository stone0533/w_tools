part of 'image.dart';

/// 各来源的构建逻辑；与 `_WImageState` 同库，仅负责把 source 接到统一 Image 管线。
extension _WImageStateBuilders on _WImageState {
  /// 网络图片：CachedNetworkImageProvider + 统一 Image 管线
  ///
  /// 磁盘/内存缓存仍由 `cached_network_image` 的 provider 负责；
  /// 进度来自 `Image.loadingBuilder` 的 `ImageChunkEvent`。
  Widget _buildNetwork(WNetworkImageSource network) {
    final provider = _cachedProvider(
      'network:${network.key}:${options.memCacheWidth}x${options.memCacheHeight}',
      () => createNetworkImageProvider(network, options),
    );
    return _imageWidget(
      provider,
      errorFactory: (error) =>
          WImageError(widget.source.raw, WImageErrorKind.network, cause: error),
      applyDecodeSize: false,
      notifyProgressCompletion: true,
      retryOnError: true,
    );
  }

  /// 任意 provider（含 MemoryImage）
  Widget _buildProvider(WProviderImageSource source) {
    final provider = _cachedProvider(source.provider, () => source.provider);
    return _imageWidget(
      provider,
      errorFactory: (error) =>
          WImageError(widget.source.raw, WImageErrorKind.provider, cause: error),
    );
  }

  /// 本地资源：统一走 [AssetImage]（Flutter 自带 ImageCache，支持 2x/3x 变体）
  Widget _buildAsset(WAssetImageSource asset) {
    final provider = _cachedProvider(
      'asset:${asset.key}',
      () => createAssetImageProvider(asset),
    );
    return _imageWidget(
      provider,
      errorFactory: (error) => WImageError(widget.source.raw, WImageErrorKind.asset, cause: error),
    );
  }

  /// 本地文件：条件导入拿 provider，Web 返回 null → 不支持
  Widget _buildFile(BuildContext context, WFileImageSource source) {
    final provider = createFileImageProvider(source);
    if (provider == null) {
      _hasFrame = false;
      final error = WImageError(widget.source.raw, WImageErrorKind.unsupported);
      _load.fail(error);
      return _errorSlot(context, error);
    }
    final cached = _cachedProvider(
      'file:${widget.source.key}',
      () => provider,
    );
    return _imageWidget(
      cached,
      errorFactory: (error) => WImageError(widget.source.raw, WImageErrorKind.file, cause: error),
    );
  }

  /// Base64：小数据直接解码，大数据交给 isolate
  Widget _buildBase64() {
    return FutureBuilder<Uint8List>(
      future: _bytesFuture ??= decodeImageBase64(_value),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final error = WImageError(
            widget.source.raw,
            WImageErrorKind.decode,
            cause: snapshot.error,
          );
          _load.fail(error);
          return _errorSlot(context, error);
        }
        if (!snapshot.hasData) {
          _load.markLoading();
          return _placeholderFor(context);
        }
        final bytes = snapshot.data!;
        final provider = _cachedProvider(
          'base64:${identityHashCode(bytes)}',
          () => createMemoryImageProvider(bytes),
        );
        return _imageWidget(
          provider,
          errorFactory: (error) =>
              WImageError(widget.source.raw, WImageErrorKind.decode, cause: error),
        );
      },
    );
  }
}
