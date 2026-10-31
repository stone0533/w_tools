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
  static Row top({
    required List<Widget> children,
    MainAxisSize mainAxisSize = MainAxisSize.max,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: mainAxisSize,
      children: children,
    );
  }

  /// 创建底部对齐的 Row
  static Row bottom({
    required List<Widget> children,
    MainAxisSize mainAxisSize = MainAxisSize.max,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: mainAxisSize,
      children: children,
    );
  }
}
