import 'package:flutter/material.dart';

import 'horizontal_scroller.dart';

/// 横向滚动的操作按钮行（无选中语义）。
///
/// 用于工具栏 / 筛选 Chip / 快捷操作等只关心点击的场景；
/// 需要「单选高亮」时用 [WSelectableRow]。
class WActionRow extends StatefulWidget {
  const WActionRow({
    super.key,
    required this.children,
    this.padding,
    this.spacing = 8,
    this.physics,
    this.controller,
    this.onScroll,
  });

  /// 子项（通常是按钮 / Chip）
  final List<Widget> children;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 子项间距
  final double spacing;

  /// 滚动物理特性
  final ScrollPhysics? physics;

  /// 可选滚动控制器（需要外部控制滚动位置时传）
  final ScrollController? controller;

  /// 滚动回调（偏移量）
  ///
  /// 未传 [controller] 时会自建一个内部 controller 来接收滚动事件。
  final ValueChanged<double>? onScroll;

  @override
  State<WActionRow> createState() => _WActionRowState();
}

class _WActionRowState extends State<WActionRow> {
  @override
  Widget build(BuildContext context) {
    return WActionRowScrollView(
      padding: widget.padding,
      spacing: widget.spacing,
      physics: widget.physics,
      controller: widget.controller,
      onScroll: widget.onScroll,
      children: widget.children,
    );
  }
}
