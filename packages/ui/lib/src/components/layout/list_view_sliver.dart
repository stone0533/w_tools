part of 'list_view.dart';

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
    this.emptyFill = false,
    this.keepAlive = false,
  }) : _kind = _WListViewKind.list,
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
    this.emptyFill = false,
    this.keepAlive = false,
  }) : _kind = _WListViewKind.separated,
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
    this.emptyFill = false,
    this.keepAlive = false,
  }) : _kind = _WListViewKind.grid,
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
    this.emptyFill = false,
    this.keepAlive = false,
  }) : _kind = _WListViewKind.overlap,
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

  /// [empty] 是否填满剩余视口。
  ///
  /// 仅在无 header/footer 时生效；`shrinkWrap: true` 时必须为 false。
  /// 直接放进 `CustomScrollView` 时同样受此限制。
  final bool emptyFill;

  final bool keepAlive;

  final _WListViewKind _kind;
  final double? itemExtent;
  final IndexedWidgetBuilder? separatorBuilder;
  final SliverGridDelegate? gridDelegate;
  final double overlap;

  /// 是否为重叠列表。
  bool get isOverlap => _kind == _WListViewKind.overlap;

  /// 是否展示 empty。
  bool get hasEmpty => itemCount == 0 && empty != null;

  @override
  Widget build(BuildContext context) {
    final hasEmpty = this.hasEmpty;
    final slivers = <Widget>[
      if (header != null) SliverToBoxAdapter(child: header),
      if (hasEmpty)
        emptyFill && header == null && footer == null
            ? SliverFillRemaining(
                hasScrollBody: false,
                child: empty,
              )
            : SliverToBoxAdapter(child: empty)
      else
        _buildListSliver(),
      if (!hasEmpty && _kind == _WListViewKind.overlap && overlap > 0 && itemCount > 0)
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
