import 'package:flutter/material.dart';

/// GlobalKey 扩展类，提供获取组件位置和大小的方法
extension WGlobalKeyExtension on GlobalKey {
  /// 获取组件在全局坐标系中的位置
  ///
  /// 组件不可见时返回 null。
  Offset? offset() {
    RenderBox? renderBox = currentContext?.findRenderObject() as RenderBox?;
    return renderBox?.localToGlobal(Offset.zero);
  }

  /// 获取组件在全局坐标系中的边界矩形
  ///
  /// 与 [offset] 同为全局坐标；组件不可见时返回 null。
  Rect? rect() {
    final RenderBox? renderBox = currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    return renderBox.localToGlobal(Offset.zero) & renderBox.size;
  }
}
