import 'package:flutter/material.dart';

/// 步骤指示器组件
class WStep extends StatelessWidget {
  /// 当前步骤
  final int step;

  /// 总步骤数
  final int count;

  /// 背景构建器
  final Widget Function(Widget child) backgroundBuilder;

  /// 步骤项构建器
  final Widget Function(int index, int current) itemBuilder;

  /// 分割线构建器
  final Widget Function(int index, int current) dividerBuilder;

  /// 创建步骤指示器
  const WStep({
    super.key,
    this.step = 1,
    this.count = 3,
    required this.backgroundBuilder,
    required this.itemBuilder,
    required this.dividerBuilder,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];

    // 构建步骤项和分割线
    for (int i = 0; i < count; i++) {
      children.add(buildItem(i + 1));
      if (i + 1 < count) {
        children.add(Expanded(child: buildLine(i + 2)));
      }
    }

    // 使用背景构建器包装
    return backgroundBuilder(Row(children: children));
  }

  /// 构建分割线
  Widget buildLine(int index) {
    return dividerBuilder(index, step);
  }

  /// 构建步骤项
  Widget buildItem(int index) {
    return itemBuilder(index, step);
  }
}
