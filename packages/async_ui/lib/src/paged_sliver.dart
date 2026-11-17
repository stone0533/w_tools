import 'dart:async';

import 'package:flutter/material.dart';
import 'package:w_tools_async/w_tools_async.dart';

import 'paged_footer.dart';
import 'paged_strings.dart';

/// 自定义滚动壳里的分页内容。
///
/// 返回一个 [SliverMainAxisGroup]：列表四态 + 可选 footer。
/// 不包含 `SmartRefresher` / `RefreshController`；下拉刷新、上拉加载由页面
/// 自己的滚动壳负责。标准页面优先用 [WAsyncPagedList]。
///
/// 需要叠卡 / 自定义 ready sliver 时传 [readySliverBuilder]；
/// 需要由自己的 `CustomFooter` 管理 footer 时传
/// `footer: const SizedBox.shrink()`，避免内部 footer 重复。
class WAsyncPagedSliver<T> extends StatelessWidget {
  const WAsyncPagedSliver({
    super.key,
    required this.controller,
    this.itemBuilder,
    this.readySliverBuilder,
    this.emptyBuilder,
    this.footer,
    this.strings = const WAsyncPagedStrings(),
  }) : assert(
         (itemBuilder != null) != (readySliverBuilder != null),
         'itemBuilder 与 readySliverBuilder 必须二选一',
       );

  final WAsyncPagedController<T> controller;

  /// 普通列表项构建器；与 [readySliverBuilder] 二选一。
  final Widget Function(BuildContext context, T item)? itemBuilder;

  /// 自定义 ready sliver；与 [itemBuilder] 二选一，必须返回 sliver。
  final Widget Function(BuildContext context, List<T> items)? readySliverBuilder;

  final WidgetBuilder? emptyBuilder;

  /// 覆盖内部 footer；传 `SizedBox.shrink()` 可关闭内部 footer。
  final Widget? footer;
  final WAsyncPagedStrings strings;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        WAsyncStateSliver<List<T>>(
          state: controller.state,
          onRetry: () => unawaited(controller.refresh()),
          emptyBuilder: emptyBuilder,
          readySliverBuilder:
              readySliverBuilder ??
              (context, items) => SliverList.builder(
                itemCount: items.length,
                itemBuilder: (context, index) => itemBuilder!(context, items[index]),
              ),
        ),
        SliverToBoxAdapter(
          child:
              footer ??
              AnimatedBuilder(
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
