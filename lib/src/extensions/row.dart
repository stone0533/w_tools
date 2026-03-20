import 'package:flutter/widgets.dart';

/// Row 扩展，提供常用的布局辅助方法
extension WRowExtension on Row {
  /// 将 Row 包装在 IntrinsicHeight 中
  ///
  /// 当 Row 中包含需要垂直空间的组件（如 VerticalDivider）时，使用此方法可以确保组件正确显示
  ///
  /// @return 包装在 IntrinsicHeight 中的 Row 组件
  Widget withIntrinsicHeight() {
    return IntrinsicHeight(
      child: this,
    );
  }
}

class WRow {
  /// 创建主轴尺寸最小的 Row
  ///
  /// @param crossAxisAlignment 交叉轴对齐方式
  /// @param children 子组件列表
  /// @return 主轴尺寸最小的 Row 组件
  static Row min({
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    required List<Widget> children,
  }) {
    return Row(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  /// 创建顶部对齐的 Row
  ///
  /// @param children 子组件列表
  /// @return 顶部对齐的 Row 组件
  static Row top({required List<Widget> children}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  /// 创建底部对齐的 Row
  ///
  /// @param children 子组件列表
  /// @return 底部对齐的 Row 组件
  static Row bottom({required List<Widget> children}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: children,
    );
  }

  /// 创建包含图标、间距和文本的 Row
  ///
  /// @param icon 图标组件
  /// @param text 文本组件
  /// @param spacing 图标和文本之间的间距
  /// @return 包含图标、间距和文本的 Row 组件
  static Row iconWithText({
    required Widget icon,
    required double spacing,
    required Widget text,
  }) {
    return Row(
      children: [
        icon,
        SizedBox(width: spacing),
        text,
      ],
    );
  }
}


