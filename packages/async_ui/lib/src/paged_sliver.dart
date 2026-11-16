import 'dart:async';

import 'package:flutter/material.dart';
import 'package:w_tools_async/w_tools_async.dart';

import 'paged_footer.dart';
import 'paged_strings.dart';

/// 自定义滚动壳里的分页内容。
///
/// 返回一个 [SliverMainAxisGroup]：列表四态 + footer。
/// 不包含 `SmartRefresher` / `RefreshController`；下拉刷新、上拉加载由页面
/// 自己的滚动壳负责。标准页面优先用 [WAsyncPagedList]。
class WAsyncPagedSliver<T> extends StatelessWidget {
  const WAsyncPagedSliver({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.emptyBuilder,
    this.strings = const WAsyncPagedStrings(),
  });

  final WAsyncPagedController<T> controller;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final WidgetBuilder? emptyBuilder;
  final WAsyncPagedStrings strings;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        WAsyncStateSliver<List<T>>(
          state: controller.state,
          onRetry: () => unawaited(controller.refresh()),
          emptyBuilder: emptyBuilder,
          readySliverBuilder: (context, items) => SliverList.builder(
            itemCount: items.length,
            itemBuilder: (context, index) => itemBuilder(context, items[index]),
          ),
        ),
        SliverToBoxAdapter(
          child: AnimatedBuilder(
            animation: controller.snapshot,
            builder: (context, _) => WAsyncPagedFooter(
              status: controller.snapshot.value.footerStatus,
              strings: strings,
              onRetry: () => unawaited(controller.loadMore()),
            ),
          ),
        ),
      ],
    );
  }
}
