import 'package:flutter/material.dart';

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
  ScrollController? _internalController;

  ScrollController get _effectiveController {
    if (widget.controller != null) return widget.controller!;
    return _internalController ??= ScrollController();
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final needsScrollEvents = widget.onScroll != null;
    Widget scroll = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: needsScrollEvents ? _effectiveController : widget.controller,
      physics: widget.physics,
      child: Padding(
        padding: widget.padding ?? EdgeInsets.zero,
        child: Wrap(spacing: widget.spacing, children: widget.children),
      ),
    );

    final onScroll = widget.onScroll;
    if (onScroll == null) return scroll;

    return _ScrollListener(
      controller: _effectiveController,
      onScroll: onScroll,
      child: scroll,
    );
  }
}

class _ScrollListener extends StatefulWidget {
  const _ScrollListener({required this.controller, required this.onScroll, required this.child});

  final ScrollController controller;
  final ValueChanged<double> onScroll;
  final Widget child;

  @override
  State<_ScrollListener> createState() => _ScrollListenerState();
}

class _ScrollListenerState extends State<_ScrollListener> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_notify);
  }

  @override
  void didUpdateWidget(_ScrollListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_notify);
      widget.controller.addListener(_notify);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_notify);
    super.dispose();
  }

  void _notify() => widget.onScroll(widget.controller.offset);

  @override
  Widget build(BuildContext context) => widget.child;
}

/// 横向滚动的单选按钮行。
///
/// 选中项可自动滚动到视口内；[builder] 根据 `selected` 自行决定视觉。
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
    return SingleChildScrollView(
      key: _rowKey,
      scrollDirection: Axis.horizontal,
      controller: widget.scrollController,
      physics: widget.physics,
      child: Padding(
        padding: widget.padding ?? EdgeInsets.zero,
        child: Wrap(
          spacing: widget.spacing,
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
        ),
      ),
    );
  }
}
