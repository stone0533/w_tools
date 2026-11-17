import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:w_tools_async/w_tools_async.dart';

/// 标准分页列表。
///
/// 内部持有 [RefreshController] 和 [SmartRefresher]，统一处理：
/// - 下拉刷新；
/// - 上拉加载更多；
/// - footer 的五种状态；
/// - 刷新 generation（旧 refresh 不提前收新 header）；
/// - footer 重试；
/// - 追加失败只更新 footer，不替换列表。
///
/// [controller] 由页面持有；请在 `initState` / `onInit` 调
/// `controller.refresh()`，不要在这里自动发起首屏请求。
///
/// 标准壳不暴露 header / footer：需要设计稿口径的刷新头 / footer 或自定义
/// ready sliver 时，用 `WAsyncPagedSliver` + 自己的 `SmartRefresher`。
class WAsyncPagedList<T> extends StatefulWidget {
  const WAsyncPagedList({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.emptyBuilder,
    this.header,
    this.footer,
  });

  final WAsyncPagedController<T> controller;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final WidgetBuilder? emptyBuilder;

  /// 直接传给 [SmartRefresher.header]；为 null 时使用其默认 header。
  final Widget? header;

  /// 直接传给 [SmartRefresher.footer]；为 null 时使用其默认 footer。
  ///
  /// app 自定义 footer 时，建议监听 `controller.snapshot`，重试调用
  /// `controller.loadMore()`；不要依赖内部 `RefreshController`。
  final Widget? footer;

  @override
  State<WAsyncPagedList<T>> createState() => _WAsyncPagedListState<T>();
}

class _WAsyncPagedListState<T> extends State<WAsyncPagedList<T>> {
  final RefreshController _refreshController = RefreshController();
  int _refreshId = 0;

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final id = ++_refreshId;
    await widget.controller.refresh();
    if (!mounted || id != _refreshId) return;

    if (widget.controller.state.value.isFailed) {
      _refreshController.refreshFailed();
    } else {
      _refreshController.refreshCompleted();
    }
  }

  Future<void> _onLoading() async {
    await widget.controller.loadMore();
    if (!mounted) return;

    final snapshot = widget.controller.snapshot.value;
    if (snapshot.loadMoreError != null) {
      _refreshController.loadFailed();
    } else if (!snapshot.hasMore) {
      _refreshController.loadNoData();
    } else {
      _refreshController.loadComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
      controller: _refreshController,
      enablePullUp: true,
      onRefresh: _onRefresh,
      onLoading: _onLoading,
      header: widget.header,
      footer: widget.footer,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          WAsyncStateSliver<List<T>>(
            state: widget.controller.state,
            onRetry: () => unawaited(widget.controller.refresh()),
            emptyBuilder: widget.emptyBuilder,
            readySliverBuilder: (context, items) => SliverList.builder(
              itemCount: items.length,
              itemBuilder: (context, index) => widget.itemBuilder(context, items[index]),
            ),
          ),
        ],
      ),
    );
  }
}
