import 'package:flutter/material.dart';

import '../utils/assets.dart';
import 'color.dart';

/// String 扩展（纯 Dart 工具 + hex→Color + 图片快捷构造）
extension WStringExtension on String {
  /// 将字符串转换为 int
  int? toInt() => int.tryParse(this);

  /// 将字符串转换为 double
  double? toDouble() => double.tryParse(this);

  /// 将字符串转换为 num
  num? toNum() => num.tryParse(this);

  /// 删除全部空格
  String trimAll() => replaceAll(RegExp(r'\s+'), '');

  /// 将十六进制字符串转换为颜色（如 '#FF0000' → Colors.red）
  Color toColor() => WHexColor.fromHex(this);

  /// 文件名对应的完整资产图片路径
  ///
  /// 前置路径由 [WAssets.imagePath] 配置，默认 `assets/images/`
  /// ```dart
  /// 'logo.png'.assetImagePath; // → 'assets/images/logo.png'
  /// ```
  String get assetImagePath => '${WAssets.imagePath}$this';
}
