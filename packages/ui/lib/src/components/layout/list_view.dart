import 'package:flutter/material.dart';

/// 独立滚动视图。
///
/// 只负责把 [sliver] 放进 [CustomScrollView]；列表内容由 [WListViewSliver] 描述。
/// 需要嵌入 SmartRefresher / NestedScrollView 时，直接使用 [WListViewSliver]。
class WListView extends StatelessWidget {
  const WListView({
    super.key,
    required this.sliver,
    this.controller,
    this.physics,
    this.shrinkWrap = false,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
  });

  final WListViewSliver sliver;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final Axis scrollDirection;
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: controller,
      physics: physics,
      shrinkWrap: shrinkWrap,
      scrollDirection: scrollDirection,
      reverse: reverse,
      slivers: <Widget>[sliver],
    );
  }
}

enum _WListViewKind { list, separated, grid, overlap }

/// 列表内容 sliver。
///
/// 不持有 ScrollController，也不设置 physics；滚动由外层负责。
class WListViewSliver extends StatelessWidget {
  const WListViewSliver.list({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.itemExtent,
    this.padding = EdgeInsets.zero,
    this.header,
    this.footer,
    this.empty,
    this.keepAlive = false,
  })  : _kind = _WListViewKind.list,
        separatorBuilder = null,
        gridDelegate = null,
        overlap = 0,
        assert(itemCount >= 0),
        assert(itemExtent == null || itemExtent > 0);

  const WListViewSliver.separated({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.separatorBuilder,
    this.padding = EdgeInsets.zero,
    this.header,
    this.footer,
    this.empty,
    this.keepAlive = false,
  })  : _kind = _WListViewKind.separated,
        itemExtent = null,
        gridDelegate = null,
        overlap = 0,
        assert(itemCount >= 0);

  const WListViewSliver.grid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.gridDelegate,
    this.padding = EdgeInsets.zero,
    this.header,
    this.footer,
    this.empty,
    this.keepAlive = false,
  })  : _kind = _WListViewKind.grid,
        itemExtent = null,
        separatorBuilder = null,
        overlap = 0,
        assert(itemCount >= 0);

  const WListViewSliver.overlap({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required double itemExtent,
    required this.overlap,
    this.padding = EdgeInsets.zero,
    this.header,
    this.footer,
    this.empty,
    this.keepAlive = false,
  })  : _kind = _WListViewKind.overlap,
        // ignore: prefer_initializing_formals
        itemExtent = itemExtent,
        separatorBuilder = null,
        gridDelegate = null,
        assert(itemCount >= 0),
        assert(itemExtent > 0),
        assert(overlap >= 0),
        assert(overlap < itemExtent);

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry padding;
  final Widget? header;
  final Widget? footer;
  final Widget? empty;
  final bool keepAlive;

  final _WListViewKind _kind;
  final double? itemExtent;
  final IndexedWidgetBuilder? separatorBuilder;
  final SliverGridDelegate? gridDelegate;
  final double overlap;

  @override
  Widget build(BuildContext context) {
    final hasEmpty = itemCount == 0 && empty != null;
    final slivers = <Widget>[
      if (header != null) SliverToBoxAdapter(child: header),
      if (hasEmpty)
        header == null && footer == null
            ? SliverFillRemaining(
                hasScrollBody: false,
                child: empty,
              )
            : SliverToBoxAdapter(child: empty)
      else
        _buildListSliver(),
      if (!hasEmpty && _kind == _WListViewKind.overlap && overlap > 0)
        SliverToBoxAdapter(child: SizedBox(height: overlap)),
      if (footer != null) SliverToBoxAdapter(child: footer),
    ];

    return SliverPadding(
      padding: padding,
      sliver: SliverMainAxisGroup(slivers: slivers),
    );
  }

  Widget _buildListSliver() {
    switch (_kind) {
      case _WListViewKind.grid:
        return SliverGrid.builder(
          itemCount: itemCount,
          itemBuilder: itemBuilder,
          gridDelegate: gridDelegate!,
          addAutomaticKeepAlives: keepAlive,
          addRepaintBoundaries: true,
          addSemanticIndexes: true,
        );
      case _WListViewKind.separated:
        return SliverList.separated(
          itemCount: itemCount,
          itemBuilder: itemBuilder,
          separatorBuilder: separatorBuilder!,
          addAutomaticKeepAlives: keepAlive,
          addRepaintBoundaries: true,
          addSemanticIndexes: true,
        );
      case _WListViewKind.overlap:
        return SliverFixedExtentList(
          itemExtent: itemExtent! - overlap,
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return OverflowBox(
                maxHeight: double.infinity,
                alignment: Alignment.topCenter,
                child: itemBuilder(context, index),
              );
            },
            childCount: itemCount,
            addAutomaticKeepAlives: keepAlive,
            addRepaintBoundaries: true,
            addSemanticIndexes: true,
          ),
        );
      case _WListViewKind.list:
        if (itemExtent != null) {
          return SliverFixedExtentList(
            itemExtent: itemExtent!,
            delegate: SliverChildBuilderDelegate(
              itemBuilder,
              childCount: itemCount,
              addAutomaticKeepAlives: keepAlive,
              addRepaintBoundaries: true,
              addSemanticIndexes: true,
            ),
          );
        }
        return SliverList.builder(
          itemCount: itemCount,
          itemBuilder: itemBuilder,
          addAutomaticKeepAlives: keepAlive,
          addRepaintBoundaries: true,
          addSemanticIndexes: true,
        );
    }
  }
}
