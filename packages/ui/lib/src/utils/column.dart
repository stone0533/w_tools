import 'package:flutter/widgets.dart';

/// Column 便捷工厂
class WColumn {
  /// 创建主轴尺寸最小的 Column
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
  static Column left({
    required List<Widget> children,
    MainAxisSize mainAxisSize = MainAxisSize.max,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: mainAxisSize,
      children: children,
    );
  }

  /// 创建右对齐的 Column
  static Column right({
    required List<Widget> children,
    MainAxisSize mainAxisSize = MainAxisSize.max,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: mainAxisSize,
      children: children,
    );
  }
}
