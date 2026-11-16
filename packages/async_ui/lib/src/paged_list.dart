import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:w_tools_async/w_tools_async.dart';

import 'paged_footer.dart';
import 'paged_strings.dart';

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
class WAsyncPagedList<T> extends StatefulWidget {
  const WAsyncPagedList({
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
      footer: CustomFooter(
        builder: (context, _) => AnimatedBuilder(
          animation: widget.controller.snapshot,
          builder: (context, _) => WAsyncPagedFooter(
            status: widget.controller.snapshot.value.footerStatus,
            strings: widget.strings,
            onRetry: () => _refreshController.requestLoading(),
          ),
        ),
      ),
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
