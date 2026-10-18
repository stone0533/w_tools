import 'package:flutter/material.dart';

/// SizedBox 工具类，提供便捷的创建方法
class WSizeBox {
  /// 创建指定高度的 SizedBox
  static SizedBox height(double height, {Widget? child}) {
    return SizedBox(height: height, child: child);
  }

  /// 创建指定宽度的 SizedBox
  static SizedBox width(double width, {Widget? child}) {
    return SizedBox(width: width, child: child);
  }

  /// 创建指定尺寸的 SizedBox
  static SizedBox size(double width, double height, Widget? child) {
    return SizedBox(width: width, height: height, child: child);
  }
}
