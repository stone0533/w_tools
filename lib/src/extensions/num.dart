import 'package:flutter/material.dart';

/// num 扩展类，提供便捷的 SizedBox 创建方法和其他实用方法
extension WNumExtension on num {
  /// 创建指定高度的 SizedBox
  ///
  /// @return 指定高度的 SizedBox 实例
  SizedBox get heightBox => SizedBox(height: toDouble());

  /// 创建指定宽度的 SizedBox
  ///
  /// @return 指定宽度的 SizedBox 实例
  SizedBox get widthBox => SizedBox(width: toDouble());

  /// 创建指定宽高的 SizedBox
  ///
  /// @return 指定宽高的 SizedBox 实例
  SizedBox get squareBox => SizedBox(width: toDouble(), height: toDouble());

  /// 创建指定边距的 EdgeInsets
  ///
  /// @return 指定边距的 EdgeInsets 实例
  EdgeInsets get allPadding => EdgeInsets.all(toDouble());

  /// 创建指定水平边距的 EdgeInsets
  ///
  /// @return 指定水平边距的 EdgeInsets 实例
  EdgeInsets get horizontalPadding => EdgeInsets.symmetric(horizontal: toDouble());

  /// 创建指定垂直边距的 EdgeInsets
  ///
  /// @return 指定垂直边距的 EdgeInsets 实例
  EdgeInsets get verticalPadding => EdgeInsets.symmetric(vertical: toDouble());

  /// 创建指定圆角的 BorderRadius
  ///
  /// @return 指定圆角的 BorderRadius 实例
  BorderRadius get borderRadius => BorderRadius.circular(toDouble());

  /// 创建指定宽度的 BorderSide
  ///
  /// @param color 边框颜色，默认为 Colors.grey
  /// @return 指定宽度的 BorderSide 实例
  BorderSide borderSide({Color color = Colors.grey}) => BorderSide(width: toDouble(), color: color);

  /// 转换为带千分位分隔符的字符串
  String get toThousand {
    String str = toString();
    if (str.contains('.')) {
      List<String> parts = str.split('.');
      String integerPart = parts[0];
      String decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

      RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      String formattedInteger = integerPart.replaceAllMapped(reg, (Match m) => '${m.group(1)},');
      return '$formattedInteger$decimalPart';
    } else {
      RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      return str.replaceAllMapped(reg, (Match m) => '${m.group(1)},');
    }
  }

  /// 转换为带货币符号的字符串
  String toCurrency({
    String symbol = '',
    String thousandSeparator = ',',
    String decimalSeparator = '.',
  }) {
    String str = toString();
    String result = '';

    if (str.contains('.')) {
      List<String> parts = str.split('.');
      String integerPart = parts[0];
      String decimalPart = parts[1];

      RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      String formattedInteger = integerPart.replaceAllMapped(
        reg,
        (Match m) => '${m.group(1)}$thousandSeparator',
      );
      result = '$symbol$formattedInteger$decimalSeparator$decimalPart';
    } else {
      RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      result =
          '$symbol${str.replaceAllMapped(reg, (Match m) => '${m.group(1)}$thousandSeparator')}';
    }

    return result;
  }

  /// 转换为百分比格式的字符串
  String get toPercent => '${(this * 100).toString()}%';

  /// 转换为百分比格式的字符串（保留指定小数位数）
  String toPercentWithFixed(int fractionDigits) =>
      '${(this * 100).toStringAsFixed(fractionDigits)}%';

  /// 将数字转换为带前导零的字符串
  ///
  /// 示例:
  /// ```dart
  /// 1.toPadLeft(2); // "01"
  /// 5.toPadLeft(3); // "005"
  /// 123.toPadLeft(2); // "123"
  /// 45.toPadLeft(4); // "0045"
  /// ```
  String toPadLeft(int length) => toString().padLeft(length, '0');
}
