import 'package:flutter/material.dart';

/// 颜色扩展：Flutter 的 `AARRGGBB` 与 CSS / Figma 的 `RRGGBBAA` 两套字节序。
///
/// - [fromHex] / [toHex]：`AARRGGBB`（与 `Color(0xAARRGGBB)` 一致，alpha 在前）；
/// - [fromCssHex] / [toCssHex]：`RRGGBBAA`（CSS / Figma 复制出来的 8 位颜色）。
///
/// 8 位字符串无法自动判断字节序，所以两套入口必须显式选；从设计稿复制颜色时
/// 用 CSS 版本，不要拿 [fromHex] 猜。
/// ```dart
/// WColorExtension.fromHex('#80FF5733');    // AARRGGBB：alpha=0x80
/// WColorExtension.fromCssHex('#FF573380'); // RRGGBBAA：alpha=0x80
/// ```
extension WColorExtension on Color {
  /// 从十六进制字符串创建颜色
  ///
  /// 支持以下格式：
  /// - #AARRGGBB（带透明度，alpha 在前，与 `Color(0xAARRGGBB)` 一致）
  /// - #RRGGBB
  /// - AARRGGBB
  /// - RRGGBB
  /// - #ARGB（简写形式）
  /// - RGB（简写形式）
  ///
  /// 输入格式无效时抛出 [FormatException]。
  static Color fromHex(String hexString) {
    var hex = hexString.trim();
    if (hex.startsWith('#')) {
      hex = hex.substring(1);
    }
    if (hex.contains('#')) {
      throw FormatException('无效的颜色字符串: $hexString');
    }

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

  /// 从 CSS / Figma 的 `RRGGBBAA` 创建颜色（6 位视为不透明）。
  ///
  /// 8 位时前 6 位是 RGB、最后 2 位是 alpha；与 [fromHex] 的顺序相反。
  static Color fromCssHex(String hexString) {
    var hex = hexString.trim();
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (hex.isEmpty || hex.contains('#') || (hex.length != 6 && hex.length != 8)) {
      throw FormatException('无效的 CSS 颜色字符串: $hexString');
    }
    final alpha = hex.length == 8 ? hex.substring(6, 8) : 'FF';
    final rgb = hex.substring(0, 6);
    return Color(int.parse('$alpha$rgb', radix: 16));
  }

  /// 将颜色转换为 CSS / Figma 的 `#RRGGBBAA`。
  ///
  /// - [leadingHashSign]：是否添加前缀 #，默认为 true
  String toCssHex({bool leadingHashSign = true}) =>
      '${leadingHashSign ? '#' : ''}'
      '${(r * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
      '${(g * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
      '${(b * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
      '${(a * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}';

  /// 将颜色转换为十六进制字符串
  ///
  /// - [leadingHashSign]：是否添加前缀 #，默认为 true
  /// 返回：十六进制颜色字符串，格式为 #AARRGGBB（CSS 顺序用 [toCssHex]）
  String toHex({bool leadingHashSign = true}) =>
      '${leadingHashSign ? '#' : ''}'
      '${(a * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
      '${(r * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
      '${(g * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
      '${(b * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}';
}
