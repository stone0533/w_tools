import 'package:flutter/material.dart';

/// SizedBox 扩展类，提供便捷的高度和宽度创建方法
extension WSizeBox on SizedBox {
  /// 创建指定高度的 SizedBox
  ///
  /// @param height 高度值
  /// @return 指定高度的 SizedBox 实例
  static SizedBox height(double height, {Widget? child}) {
    return SizedBox(height: height, child: child);
  }

  /// 创建指定宽度的 SizedBox
  ///
  /// @param width 宽度值
  /// @return 指定宽度的 SizedBox 实例
  static SizedBox width(double width, {Widget? child}) {
    return SizedBox(width: width, child: child);
  }

  /// 创建指定尺寸的 SizedBox
  ///
  /// @param width 宽度值
  /// @param height 高度值
  /// @return 指定尺寸的 SizedBox 实例
  static SizedBox size(double width, double height, Widget? child) {
    return SizedBox(width: width, height: height, child: child);
  }
}

/// 便捷常量，用于创建指定高度的 SizedBox
const h = WSizeBox.height;

/// 便捷常量，用于创建指定宽度的 SizedBox
const w = WSizeBox.width;

/// 便捷常量，用于创建指定尺寸的 SizedBox
const s = WSizeBox.size;
