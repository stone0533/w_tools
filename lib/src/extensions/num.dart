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
}
