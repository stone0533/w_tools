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
    this.refreshController,
  });

  final WAsyncPagedController<T> controller;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final WidgetBuilder? emptyBuilder;

  /// 可选的刷新控制器；传入时由调用方持有 / dispose。
  ///
  /// 不传时组件内部创建并 dispose。传入后可以：
  /// `requestRefresh()` 触发带动画的下拉刷新，或读 `isRefresh` 防重复请求。
  final RefreshController? refreshController;

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
  late RefreshController _refreshController;
  bool _ownsRefreshController = false;
  int _refreshId = 0;

  @override
  void initState() {
    super.initState();
    _attachRefreshController(widget.refreshController);
  }

  void _attachRefreshController(RefreshController? provided) {
    _ownsRefreshController = provided == null;
    _refreshController = provided ?? RefreshController();
  }

  @override
  void didUpdateWidget(covariant WAsyncPagedList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshController != widget.refreshController) {
      if (_ownsRefreshController) _refreshController.dispose();
      _attachRefreshController(widget.refreshController);
    }
  }

  @override
  void dispose() {
    if (_ownsRefreshController) _refreshController.dispose();
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
            onRetry: () => _refreshController.requestRefresh(),
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
