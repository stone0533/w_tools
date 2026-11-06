import 'package:flutter/material.dart';

import 'horizontal_scroller.dart';

class WSelectableRow extends StatefulWidget {
  const WSelectableRow({
    super.key,
    required this.itemCount,
    required this.builder,
    required this.selectedIndex,
    required this.onSelected,
    this.padding,
    this.spacing = 8,
    this.physics,
    this.scrollToSelected = true,
    this.scrollController,
  });

  /// 项数
  final int itemCount;

  /// 子项构建器
  final Widget Function(BuildContext context, int index, bool selected) builder;

  /// 当前选中索引（null 表示无选中）
  final int? selectedIndex;

  /// 选中变化回调
  final ValueChanged<int> onSelected;

  final EdgeInsetsGeometry? padding;
  final double spacing;
  final ScrollPhysics? physics;

  /// 选中变化时是否自动滚动到视口内
  final bool scrollToSelected;

  /// 可选滚动控制器
  final ScrollController? scrollController;

  @override
  State<WSelectableRow> createState() => _WSelectableRowState();
}

class _WSelectableRowState extends State<WSelectableRow> {
  final GlobalKey _rowKey = GlobalKey();
  final List<GlobalKey> _itemKeys = [];

  @override
  void initState() {
    super.initState();
    _syncKeys();
    _scheduleEnsureVisible();
  }

  @override
  void didUpdateWidget(WSelectableRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount) _syncKeys();
    if (oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.scrollToSelected != widget.scrollToSelected) {
      _scheduleEnsureVisible();
    }
  }

  void _syncKeys() {
    _itemKeys
      ..clear()
      ..addAll(List.generate(widget.itemCount, (_) => GlobalKey()));
  }

  void _scheduleEnsureVisible() {
    if (!widget.scrollToSelected || widget.selectedIndex == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final index = widget.selectedIndex;
      if (index == null || index < 0 || index >= _itemKeys.length) return;
      final itemContext = _itemKeys[index].currentContext;
      if (itemContext == null) return;
      Scrollable.ensureVisible(
        itemContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return WActionRowScrollView(
      scrollViewKey: _rowKey,
      padding: widget.padding,
      spacing: widget.spacing,
      physics: widget.physics,
      controller: widget.scrollController,
      children: List.generate(widget.itemCount, (index) {
        final selected = widget.selectedIndex == index;
        return KeyedSubtree(
          key: _itemKeys[index],
          child: Semantics(
            button: true,
            selected: selected,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.onSelected(index),
              child: widget.builder(context, index, selected),
            ),
          ),
        );
      }),
    );
  }
}
