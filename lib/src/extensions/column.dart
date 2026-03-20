import 'package:flutter/widgets.dart';

/// Column 扩展，提供常用的布局辅助方法
extension WColumnExtension on Column {
  /// 将 Column 包装在 IntrinsicHeight 中
  ///
  /// 当 Column 中包含需要垂直空间的组件（如 VerticalDivider）时，使用此方法可以确保组件正确显示
  ///
  /// @return 包装在 IntrinsicHeight 中的 Column 组件
  Widget withIntrinsicHeight() {
    return IntrinsicHeight(
      child: this,
    );
  }
}

class WColumn {
  /// 创建主轴尺寸最小的 Column
  ///
  /// @param crossAxisAlignment 交叉轴对齐方式
  /// @param children 子组件列表
  /// @return 主轴尺寸最小的 Column 组件
  static Column min({
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  /// 创建左对齐的 Column
  ///
  /// @param children 子组件列表
  /// @return 左对齐的 Column 组件
  static Column left({required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  /// 创建右对齐的 Column
  ///
  /// @param children 子组件列表
  /// @return 右对齐的 Column 组件
  static Column right({required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: children,
    );
  }
}


