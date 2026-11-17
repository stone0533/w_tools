import 'dart:async';

import 'package:flutter/material.dart';
import 'package:w_tools_async/w_tools_async.dart';

/// 自定义滚动壳里的分页内容。
///
/// 只负责四态和 ready 分支；不包含 `SmartRefresher` / `RefreshController`，
/// 也不包含 footer。header / footer 由调用方自己的滚动壳负责。
///
/// 标准页面优先用 [WAsyncPagedList]。
class WAsyncPagedSliver<T> extends StatelessWidget {
  /// 标准列表：ready 分支用 [itemBuilder]。
  const WAsyncPagedSliver({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.emptyBuilder,
    this.onRetry,
  }) : readySliverBuilder = null;

  /// 自定义 ready sliver：叠卡、瀑布流、特殊布局。
  ///
  /// 必须返回 sliver；四态处理与 [WAsyncPagedSliver] 默认构造一致。
  const WAsyncPagedSliver.custom({
    super.key,
    required this.controller,
    required this.readySliverBuilder,
    this.emptyBuilder,
    this.onRetry,
  }) : itemBuilder = null;

  final WAsyncPagedController<T> controller;

  /// 标准列表模式非空；[WAsyncPagedSliver.custom] 时为 null。
  final Widget Function(BuildContext context, T item)? itemBuilder;

  /// [WAsyncPagedSliver.custom] 非空；标准列表模式为 null。
  final Widget Function(BuildContext context, List<T> items)? readySliverBuilder;

  final WidgetBuilder? emptyBuilder;

  /// 错误态重试；为 null 时使用 [WAsyncPagedController.refresh]。
  ///
  /// 自建 `SmartRefresher` 时传 `refreshController.requestRefresh`，
  /// 让重试走页面刷新头。
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return WAsyncStateSliver<List<T>>(
      state: controller.state,
      onRetry: onRetry ?? () => unawaited(controller.refresh()),
      emptyBuilder: emptyBuilder,
      readySliverBuilder:
          readySliverBuilder ??
          (context, items) => SliverList.builder(
            itemCount: items.length,
            itemBuilder: (context, index) => itemBuilder!(context, items[index]),
          ),
    );
  }
}
