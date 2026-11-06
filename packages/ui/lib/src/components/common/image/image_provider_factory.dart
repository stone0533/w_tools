import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '_image_file_web.dart' if (dart.library.io) '_image_file_native.dart';
import 'image_config.dart';
import 'image_source.dart';

/// 由 WImage 与 WImageSource.resolve 共用的 provider 构造。
ImageProvider createNetworkImageProvider(
  WNetworkImageSource source,
  WImageLoadOptions options,
) {
  return CachedNetworkImageProvider(
    source.value,
    headers: source.headers,
    cacheKey: source.cacheKey,
    maxWidth: options.memCacheWidth,
    maxHeight: options.memCacheHeight,
  );
}

ImageProvider createAssetImageProvider(WAssetImageSource source) {
  return AssetImage(source.value, package: source.package);
}

ImageProvider? createFileImageProvider(WFileImageSource source) {
  return buildFileImageProvider(source.value);
}

ImageProvider createMemoryImageProvider(Uint8List bytes) => MemoryImage(bytes);
