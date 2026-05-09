import 'package:flutter/material.dart';

/// 颜色扩展类，提供十六进制颜色转换功能
extension HexColor on Color {
  /// 从十六进制字符串创建颜色
  ///
  /// @param hexString 十六进制颜色字符串，可以是以下格式：
  /// - #RRGGBBAA (带透明度)
  /// - #RRGGBB
  /// - RRGGBBAA
  /// - RRGGBB
  /// - #RGB (简写形式)
  /// - RGB (简写形式)
  /// @return 转换后的颜色对象
  /// @throws FormatException 如果输入格式无效
  static Color fromHex(String hexString) {
    String hex = hexString.replaceAll('#', '');
    
    if (hex.isEmpty) {
      throw FormatException('无效的颜色字符串: $hexString');
    }
    
    String alpha;
    String red;
    String green;
    String blue;
    
    switch (hex.length) {
      case 8:
        // AARRGGBB - 带透明度的完整格式
        alpha = hex.substring(0, 2);
        red = hex.substring(2, 4);
        green = hex.substring(4, 6);
        blue = hex.substring(6, 8);
        break;
      case 6:
        // RRGGBB - 默认不透明
        alpha = 'FF';
        red = hex.substring(0, 2);
        green = hex.substring(2, 4);
        blue = hex.substring(4, 6);
        break;
      case 4:
        // ARGB 简写形式
        alpha = '${hex[0]}${hex[0]}';
        red = '${hex[1]}${hex[1]}';
        green = '${hex[2]}${hex[2]}';
        blue = '${hex[3]}${hex[3]}';
        break;
      case 3:
        // RGB 简写形式
        alpha = 'FF';
        red = '${hex[0]}${hex[0]}';
        green = '${hex[1]}${hex[1]}';
        blue = '${hex[2]}${hex[2]}';
        break;
      default:
        throw FormatException('无效的颜色字符串格式: $hexString');
    }
    
    return Color(int.parse('$alpha$red$green$blue', radix: 16));
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
