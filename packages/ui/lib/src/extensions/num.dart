import 'package:flutter/material.dart';

/// num 扩展类，提供便捷的 SizedBox 创建方法和其他实用方法
extension WNumExtension on num {
  /// 创建指定高度的 SizedBox
  ///
  /// 返回：指定高度的 SizedBox 实例
  SizedBox get heightBox => SizedBox(height: toDouble());

  /// 创建指定宽度的 SizedBox
  ///
  /// 返回：指定宽度的 SizedBox 实例
  SizedBox get widthBox => SizedBox(width: toDouble());

  /// 创建指定宽高的 SizedBox
  ///
  /// 返回：指定宽高的 SizedBox 实例
  SizedBox get squareBox => SizedBox(width: toDouble(), height: toDouble());

  /// 创建指定边距的 EdgeInsets
  ///
  /// 返回：指定边距的 EdgeInsets 实例
  EdgeInsets get allPadding => EdgeInsets.all(toDouble());

  /// 创建指定水平边距的 EdgeInsets
  ///
  /// 返回：指定水平边距的 EdgeInsets 实例
  EdgeInsets get horizontalPadding => EdgeInsets.symmetric(horizontal: toDouble());

  /// 创建指定垂直边距的 EdgeInsets
  ///
  /// 返回：指定垂直边距的 EdgeInsets 实例
  EdgeInsets get verticalPadding => EdgeInsets.symmetric(vertical: toDouble());

  /// 创建指定圆角的 BorderRadius
  ///
  /// 返回：指定圆角的 BorderRadius 实例
  BorderRadius get borderRadius => BorderRadius.circular(toDouble());

  /// 创建指定宽度的 BorderSide
  ///
  /// - [color]：边框颜色，默认为 Colors.grey
  /// 返回：指定宽度的 BorderSide 实例
  BorderSide borderSide({Color color = Colors.grey}) => BorderSide(width: toDouble(), color: color);

  /// 转换为带千分位分隔符的字符串
  ///
  /// 科学计数法（如 `1e+21`、`1.5e-7`）会先展开为普通十进制再分组；
  /// `NaN` / `Infinity` 原样返回。
  String get toThousand {
    final str = _expandScientificNotation(toString());
    if (str == 'NaN' || str == 'Infinity' || str == '-Infinity') {
      return str;
    }

    String group(String integerPart) {
      return integerPart.replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m.group(1)},',
      );
    }

    final dotIndex = str.indexOf('.');
    if (dotIndex == -1) {
      return group(str);
    }
    return '${group(str.substring(0, dotIndex))}${str.substring(dotIndex)}';
  }

  /// 转换为带货币符号的字符串
  ///
  /// 科学计数法（如 `1e+21`、`1.5e-7`）会先展开为普通十进制再分组；
  /// `NaN` / `Infinity` 原样返回（不添加符号）。
  String toCurrency({
    String symbol = '',
    String thousandSeparator = ',',
    String decimalSeparator = '.',
  }) {
    final str = _expandScientificNotation(toString());
    if (str == 'NaN' || str == 'Infinity' || str == '-Infinity') {
      return str;
    }

    String group(String integerPart) {
      return integerPart.replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m.group(1)}$thousandSeparator',
      );
    }

    final dotIndex = str.indexOf('.');
    if (dotIndex == -1) {
      return '$symbol${group(str)}';
    }
    return '$symbol${group(str.substring(0, dotIndex))}'
        '$decimalSeparator${str.substring(dotIndex + 1)}';
  }

  /// 转换为百分比格式的字符串
  String get toPercent => '${(this * 100).toString()}%';

  /// 转换为百分比格式的字符串（保留指定小数位数）
  String toPercentWithFixed(int fractionDigits) =>
      '${(this * 100).toStringAsFixed(fractionDigits)}%';

  /// 将数字转换为带前导零的字符串
  String toPadLeft(int length) => toString().padLeft(length, '0');
}

/// 将科学计数法字符串展开为普通十进制字符串
///
/// 例如 `1e+21` → `1000000000000000000000`，`1.5e-7` → `0.00000015`；
/// 非科学计数法字符串原样返回。
String _expandScientificNotation(String value) {
  final match = RegExp(r'^([+-]?)(\d+)(?:\.(\d+))?[eE]([+-]?\d+)$').firstMatch(value);
  if (match == null) {
    return value;
  }

  final sign = match.group(1) ?? '';
  final integerDigits = match.group(2)!;
  final fractionDigits = match.group(3) ?? '';
  final exponent = int.parse(match.group(4)!);

  final digits = '$integerDigits$fractionDigits';
  final decimalPosition = integerDigits.length + exponent;

  if (decimalPosition <= 0) {
    final zeros = '0' * -decimalPosition;
    return '${sign}0.$zeros$digits';
  }
  if (decimalPosition >= digits.length) {
    final zeros = '0' * (decimalPosition - digits.length);
    return '$sign$digits$zeros';
  }
  return '$sign${digits.substring(0, decimalPosition)}.${digits.substring(decimalPosition)}';
}
