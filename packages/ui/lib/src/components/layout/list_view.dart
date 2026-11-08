import 'package:flutter/material.dart';

part 'list_view_sliver.dart';

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
    // 断言依赖 sliver 与滚动方向两个运行时参数，无法前移到 const 构造器。
    assert(
      !sliver.isOverlap || (scrollDirection == Axis.vertical && !reverse),
      'WListViewSliver.overlap 只支持垂直、非 reverse 列表',
    );
    assert(
      !(shrinkWrap && sliver.emptyFill && sliver.hasEmpty),
      'shrinkWrap: true 时不能使用 emptyFill: true',
    );
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
