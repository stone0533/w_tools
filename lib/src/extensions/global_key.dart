import 'package:flutter/material.dart';

/// GlobalKey 扩展类，提供获取组件位置和大小的方法
extension WGlobalKeyExtension on GlobalKey {
  /// 获取组件的全局坐标
  ///
  /// @return 组件的全局坐标，如果组件不可见则返回 null
  Offset? offset() {
    RenderBox? renderBox = currentContext?.findRenderObject() as RenderBox?;
    return renderBox?.localToGlobal(Offset.zero);
  }

  /// 获取组件的边界矩形
  ///
  /// @return 组件的边界矩形，如果组件不可见则返回 null
  Rect? rect() {
    RenderBox? renderBox = currentContext?.findRenderObject() as RenderBox?;
    return renderBox?.paintBounds;
  }
}
