import 'package:flutter/material.dart';

import '../components/common/image.dart';
import '../utils/assets.dart';
import 'color.dart';

/// String 扩展（纯 Dart 工具方法 + hex→Color 转换）
extension WStringExtension on String {
  /// 将字符串转换为 int
  int? toInt() => int.tryParse(this);

  /// 将字符串转换为 double
  double? toDouble() => double.tryParse(this);

  /// 将字符串转换为 num
  num? toNum() => num.tryParse(this);

  /// 删除全部空格
  String trimAll() => replaceAll(RegExp(r"\s+|\s+\b|\b\s"), '');

  /// 将十六进制字符串转换为颜色（如 '#FF0000' → Colors.red）
  Color toColor() => HexColor.fromHex(this);

  /// 文件名对应的完整资产图片路径
  ///
  /// 前置路径由 [WAssets.imagePath] 配置，默认 `assets/images/`
  /// ```dart
  /// 'logo.png'.assetImagePath; // → 'assets/images/logo.png'
  /// ```
  String get assetImagePath => '${WAssets.imagePath}$this';
}

/// String 扩展（ui 组件相关，依赖 WImage）
extension WUiStringExtension on String {
  /// 将字符串转换为 [WImage] 组件。
  ///
  /// 默认按内容自动判定类型（`http(s)` / `//` → 网络，`file:` → 文件，
  /// `data:` → Base64，其余 → 本地资源）；需要确定性时传 [type]，
  /// 或使用 [toAssetImage] / [toBase64Image] / [toFileImage] / [toNetworkImage]。
  ///
  /// 尺寸优先级：显式 `width` / `height` 优先，[size] 只作为缺省宽高的 fallback。
  /// [config] 会被复制，方法内的覆盖不会修改调用方传入的配置。
  ///
  /// ```dart
  /// 'https://a.com/logo.png'.toImage(width: 40);
  /// 'logo.png'.assetImagePath.toImage(type: WImageType.asset);
  /// 'iVBORw0KG...'.toBase64Image();
  /// ```
  WImage toImage({
    Key? key,
    WImageConfig? config,
    WImageType? type,
    double? width,
    double? height,
    double? size,
    BoxFit? fit,
    String? semanticLabel,
    WImageController? controller,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
  }) {
    final c = (config ?? WImageConfig()).copy();
    if (width != null || size != null) c.width = width ?? size;
    if (height != null || size != null) c.height = height ?? size;
    if (fit != null) c.fit = fit;
    if (semanticLabel != null) c.semanticLabel = semanticLabel;

    return WImage(
      key: key,
      config: c,
      data: this,
      type: type,
      controller: controller,
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
    );
  }

  /// 本地资源图片。
  ///
  /// [prefix] 为 true（默认）时自动拼 [WAssets.imagePath]：
  /// `'logo.png'.toAssetImage()` → `assets/images/logo.png`。
  /// 如果传入的已经是完整路径（`assets/...` / `packages/...`），用 `prefix: false`。
  WImage toAssetImage({bool prefix = true, Key? key, WImageConfig? config}) {
    final data = prefix ? assetImagePath : this;
    return data.toImage(type: WImageType.asset, key: key, config: config);
  }

  /// Base64 图片（可带 `data:...;base64,` 前缀，也可直接给 Base64 串）
  WImage toBase64Image({Key? key, WImageConfig? config}) {
    return toImage(type: WImageType.base64, key: key, config: config);
  }

  /// 本地文件图片（带不带 `file://` 前缀都可以）
  WImage toFileImage({Key? key, WImageConfig? config}) {
    return toImage(type: WImageType.file, key: key, config: config);
  }

  /// 网络图片（`http` / `https`，或以 `//` 开头的协议相对地址）
  WImage toNetworkImage({Key? key, WImageConfig? config}) {
    return toImage(type: WImageType.network, key: key, config: config);
  }
}
