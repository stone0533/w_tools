import 'package:flutter/material.dart';
import 'package:flutter_picker_plus/picker.dart';

/// Picker 扩展类，提供日期选择器相关功能
extension WPicker on Picker {
  /// 创建年月日选择器
  ///
  /// @param yearSuffix 年份后缀
  /// @param monthSuffix 月份后缀
  /// @param daySuffix 日期后缀
  /// @param minValue 最小日期
  /// @param maxValue 最大日期
  /// @param value 当前选中日期
  /// @param textStyle 文本样式
  /// @param selectedTextStyle 选中文本样式
  /// @return Picker 实例
  static Picker ymdPicker({
    String? yearSuffix,
    String? monthSuffix,
    String? daySuffix,
    DateTime? minValue,
    DateTime? maxValue,
    DateTime? value,
    TextStyle? textStyle,
    TextStyle? selectedTextStyle,
  }) {
    return Picker(
      adapter: DateTimePickerAdapter(
        type: PickerDateTimeType.kYMD,
        isNumberMonth: true,
        yearSuffix: yearSuffix,
        monthSuffix: monthSuffix,
        daySuffix: daySuffix,
        maxValue: maxValue,
        minValue: minValue,
        value: value,
      ),
      hideHeader: true,
      textStyle: textStyle,
      selectedTextStyle: selectedTextStyle,
    );
  }
}
