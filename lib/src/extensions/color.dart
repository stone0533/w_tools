import 'package:flutter/material.dart';

/// 颜色扩展类，提供十六进制颜色转换功能
extension HexColor on Color {
  /// 从十六进制字符串创建颜色
  ///
  /// @param hexString 十六进制颜色字符串，可以是以下格式：
  /// - #RRGGBB
  /// - RRGGBB
  /// - #RGB
  /// - RGB
  /// @return 转换后的颜色对象
  static Color fromHex(String hexString) {
    String hex = hexString.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex'; // 默认透明度为1（FF）
    } else if (hex.length == 3) {
      hex = 'FF${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}'; // 简写形式
    }
    return Color(int.parse(hex, radix: 16));
  }

  /// 将颜色转换为十六进制字符串
  ///
  /// @param leadingHashSign 是否添加前缀 #，默认为 true
  /// @return 十六进制颜色字符串，格式为 #AARRGGBB
  String toHex({bool leadingHashSign = true}) =>
      '${leadingHashSign ? '#' : ''}'
      '${(a * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
      '${(r * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
      '${(g * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
      '${(b * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}';
}
