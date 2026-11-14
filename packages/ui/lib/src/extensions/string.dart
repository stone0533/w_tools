import 'package:flutter/material.dart';

import 'color.dart';

/// String 扩展（只剩 hex→Color）。
///
/// 数字转换 / 去空格 / trim 直接用 Dart 原生 API；资源路径由
/// `WImageSource.asset('完整路径')` 显式传入（12.0 删除了全局前缀）。
extension WStringExtension on String {
  /// 将 AARRGGBB 十六进制字符串转换为颜色（如 '#80FF5733' → alpha=0x80）
  Color toColor() => WColorExtension.fromHex(this);

  /// 将 CSS / Figma 的 RRGGBBAA 字符串转换为颜色（如 '#FF573380' → alpha=0x80）
  Color toCssColor() => WColorExtension.fromCssHex(this);
}
