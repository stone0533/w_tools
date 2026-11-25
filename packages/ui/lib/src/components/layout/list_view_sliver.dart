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
    this.addAutomaticKeepAlives = false,
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
    this.addAutomaticKeepAlives = false,
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
    this.addAutomaticKeepAlives = false,
  }) : _kind = _WListViewKind.grid,
       itemExtent = null,
       separatorBuilder = null,
       overlap = 0,
       assert(itemCount >= 0);

  /// 叠压列表：每项按 [itemExtent] 的视觉高度绘制，向上叠压 [overlap]。
  ///
  /// 前 n-1 项的命中盒是 `itemExtent - overlap`（重叠部分由下一项接管），
  /// **最后一项按自然高度布局**，整张卡（含露出部分）都可点击；因此
  /// [itemBuilder] 返回的卡片应自撑高度，且视觉高度建议等于 [itemExtent]。
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
    this.addAutomaticKeepAlives = false,
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

  /// 是否启用 Flutter 的 `addAutomaticKeepAlives` 机制。
  ///
  /// 它只是允许子项请求保活；子项仍需 `WKeepAliveWrapper` /
  /// `AutomaticKeepAliveClientMixin` 才会真正保留状态。
  final bool addAutomaticKeepAlives;

  final _WListViewKind _kind;
  final double? itemExtent;
  final IndexedWidgetBuilder? separatorBuilder;
  final SliverGridDelegate? gridDelegate;
  final double overlap;

  /// 是否为重叠列表。
  bool get isOverlap => _kind == _WListViewKind.overlap;

  /// 是否展示 empty。
  bool get hasEmpty => itemCount == 0 && empty != null;

  /// 叠压列表里最后一项是否单独按自然高度布局。
  ///
  /// `OverflowBox` 只放大绘制，不放大命中盒；固定行高 + 溢出绘制会让
  /// 最后一项露出的底部变成点击死区。最后一项没有「下一项」遮挡，必须
  /// 让布局盒等于它的自然高度。
  bool get _isSplitOverlap => _kind == _WListViewKind.overlap && overlap > 0 && itemCount > 0;

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
      else if (_isSplitOverlap)
        ..._buildOverlapSlivers(context)
      else
        _buildListSliver(),
      if (footer != null) SliverToBoxAdapter(child: footer),
    ];

    return SliverPadding(
      padding: padding,
      sliver: SliverMainAxisGroup(slivers: slivers),
    );
  }

  /// 叠压列表：前 n-1 项仍按 `itemExtent - overlap` 的固定行高布局并溢出绘制，
  /// 最后一项单独用 `SliverToBoxAdapter` 按自然高度布局，命中盒 = 视觉盒。
  ///
  /// 这样最后一卡露出的底部可以点击；统一卡片高度 == [itemExtent] 时
  /// 滚动范围与旧实现一致。
  List<Widget> _buildOverlapSlivers(BuildContext context) {
    final step = itemExtent! - overlap;
    return <Widget>[
      if (itemCount > 1) _buildFixedOverlapSliver(itemCount - 1),
      SliverToBoxAdapter(
        child: IndexedSemantics(
          index: itemCount - 1,
          child: ConstrainedBox(
            // 与固定行高保持一致的下限：item 没有显式高度时不会塌成 0。
            constraints: BoxConstraints(minHeight: step),
            child: itemBuilder(context, itemCount - 1),
          ),
        ),
      ),
    ];
  }

  Widget _buildFixedOverlapSliver(int count) {
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
        childCount: count,
        addAutomaticKeepAlives: addAutomaticKeepAlives,
        addRepaintBoundaries: true,
        addSemanticIndexes: true,
      ),
    );
  }

  Widget _buildListSliver() {
    switch (_kind) {
      case _WListViewKind.grid:
        return SliverGrid.builder(
          itemCount: itemCount,
          itemBuilder: itemBuilder,
          gridDelegate: gridDelegate!,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: true,
          addSemanticIndexes: true,
        );
      case _WListViewKind.separated:
        return SliverList.separated(
          itemCount: itemCount,
          itemBuilder: itemBuilder,
          separatorBuilder: separatorBuilder!,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: true,
          addSemanticIndexes: true,
        );
      case _WListViewKind.overlap:
        // overlap == 0 时没有叠压，走普通固定行高即可（不拆最后一项）。
        return _buildFixedOverlapSliver(itemCount);
      case _WListViewKind.list:
        if (itemExtent != null) {
          return SliverFixedExtentList(
            itemExtent: itemExtent!,
            delegate: SliverChildBuilderDelegate(
              itemBuilder,
              childCount: itemCount,
              addAutomaticKeepAlives: addAutomaticKeepAlives,
              addRepaintBoundaries: true,
              addSemanticIndexes: true,
            ),
          );
        }
        return SliverList.builder(
          itemCount: itemCount,
          itemBuilder: itemBuilder,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: true,
          addSemanticIndexes: true,
        );
    }
  }
}
