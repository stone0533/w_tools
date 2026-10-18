import 'package:flutter/widgets.dart';

/// Row 便捷工厂
class WRow {
  /// 创建主轴尺寸最小的 Row
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
  static Row top({required List<Widget> children}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  /// 创建底部对齐的 Row
  static Row bottom({required List<Widget> children}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: children,
    );
  }

  /// 创建包含图标、间距和文本的 Row
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
