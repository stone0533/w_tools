import 'package:flutter/material.dart';

import '../utils/assets.dart';
import 'color.dart';
import '../components/common/image.dart';

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
  /// 将字符串转换为 WImage 组件
  WImage toImage({
    double? width,
    double? height,
    double? size,
    BoxFit? fit,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<double>? onLoadProgress,
  }) {
    final config = WImageConfig()
      ..width = size ?? width
      ..height = size ?? height;

    if (fit != null) {
      config.fit = fit;
    }

    return WImage(
      config: config,
      data: this,
      onLoadStatusChanged: onLoadStatusChanged,
      onLoadProgress: onLoadProgress,
    );
  }
}
