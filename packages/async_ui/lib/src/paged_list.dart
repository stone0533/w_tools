import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:w_tools_async/w_tools_async.dart';

import 'refresh_indicator_style.dart';

/// 标准分页列表。
///
/// 使用 Flutter [RefreshIndicator] 做下拉刷新，滚动接近底部时自动调用
/// [WAsyncPagedController.loadMore]；footer 根据
/// [WAsyncPagedController.snapshot] 展示 loading / 失败重试 / 没有更多。
///
/// [controller] 由页面持有；请在 `initState` / `onInit` 调
/// `controller.refresh()`，不要在这里自动发起首屏请求。controller 应在页面生命周期
/// 内保持稳定；本组件不支持运行中替换 controller。
///
/// 标准壳的 loading / error / errorBanner 走 `WAsyncTheme`；需要 per-list 定制时
/// 用 [WAsyncPagedSliver] + 自己的滚动壳。
///
/// 程序化刷新用 [reloadRequests]：每次递增触发一次重载。
///
/// 需要完全自定义刷新头 / 上拉壳时，用 [WAsyncPagedSliver] + 自己的滚动壳。
class WAsyncPagedList<T> extends StatefulWidget {
  const WAsyncPagedList({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.emptyBuilder,
    this.reloadRequests,
    this.autoLoadThreshold = 200,
    this.footerBuilder,
    this.refreshIndicatorStyle,
    this.resetScrollOnReload = true,
    this.headerSlivers = const <Widget>[],
    this.sliverPadding = EdgeInsets.zero,
  }) : assert(
         autoLoadThreshold == null || autoLoadThreshold >= 0,
         'autoLoadThreshold 不能为负数',
       );

  final WAsyncPagedController<T> controller;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final WidgetBuilder? emptyBuilder;

  /// 程序化重载入口；每次 `value++` 触发一次刷新。
  ///
  /// 业务不需要持有外部刷新控制器。列表有内容时复用
  /// [RefreshIndicator.show] 的动画；没有内容（首屏未回 / 空结果 / 首屏失败）
  /// 时只保留居中 loading，不叠下拉圈。页面未挂载时直接刷新 controller。
  final ValueListenable<int>? reloadRequests;

  /// 距离底部多少像素时自动触发 [WAsyncPagedController.loadMore]。
  ///
  /// `null` 表示关闭自动加载；默认 200。不能为负数。
  final double? autoLoadThreshold;

  /// 自定义 footer；不传时使用内置的 loading / 失败重试 / 没有更多。
  final Widget Function(BuildContext context, WAsyncPagedSnapshot<T> snapshot)? footerBuilder;

  /// 标准 [RefreshIndicator] 的样式；null 时使用 Flutter 默认样式。
  ///
  /// 只支持颜色 / 背景 / 线宽 / 位移 / 触发模式，不支持自定义刷新头动画或
  /// 完成 / 失败文案；这些用 `WAsyncPagedSliver` 自建壳。
  final WAsyncRefreshIndicatorStyle? refreshIndicatorStyle;

  /// 程序化 reload 时是否回到列表顶部；默认 true。
  final bool resetScrollOnReload;

  /// 列表前面的自定义 sliver，例如跟随滚动的搜索头。
  final List<Widget> headerSlivers;

  /// 内容 sliver 的 padding；footer / header 不受影响。
  final EdgeInsets sliverPadding;

  @override
  State<WAsyncPagedList<T>> createState() => _WAsyncPagedListState<T>();
}

class _WAsyncPagedListState<T> extends State<WAsyncPagedList<T>> {
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();
  final ScrollController _scrollController = ScrollController();
  ValueListenable<int>? _reloadRequests;
  ValueListenable<WAsyncPagedSnapshot<T>>? _snapshot;

  int _refreshId = 0;
  bool _autoLoadCheckScheduled = false;
  Future<void>? _refreshFuture;
  Future<void>? _activeRefresh;
  bool _autoLoadInFlight = false;
  bool _refreshRequested = false;
  bool _ignoreNextIndicatorRefresh = false;

  @override
  void initState() {
    super.initState();
    _bindReloadRequests();
    _snapshot = widget.controller.snapshot;
    _snapshot!.addListener(_onSnapshotChanged);
  }

  void _onSnapshotChanged() {
    _scheduleAutoLoadCheck();
  }

  void _bindReloadRequests() {
    _reloadRequests = widget.reloadRequests;
    _reloadRequests?.addListener(_onReloadRequested);
  }

  void _unbindReloadRequests() {
    _reloadRequests?.removeListener(_onReloadRequested);
    _reloadRequests = null;
  }

  Future<void> _startRefresh() {
    _refreshRequested = true;
    return _refreshFuture ??= _drainRefresh();
  }

  Future<void> _onRefresh() {
    // reloadRequests 已经直接启动过数据刷新；show() 触发的 onRefresh
    // 只负责让 indicator 收尾，不能再发一次 page1。
    if (_ignoreNextIndicatorRefresh) {
      _ignoreNextIndicatorRefresh = false;
      return _refreshFuture ?? Future<void>.value();
    }
    // 没有内容可保留时（首屏未回 / 空结果 / 首屏失败），居中 loading 已经是
    // 反馈；让下拉头提前收尾，否则整个请求期间会同时有两个加载提示。
    if (_hasContent) return _startRefresh();
    unawaited(_startRefresh());
    return Future<void>.value();
  }

  /// 上一次成功的列表内容是否存在。
  ///
  /// `false` 表示首屏还没回来、结果是空的、或首屏就失败了 —— 这三种情况下
  /// `WAsyncStateSliver` 没有内容可保留，会渲染居中 loading。
  bool get _hasContent => widget.controller.state.value.data != null;

  Future<void> _drainRefresh() async {
    try {
      while (mounted) {
        final id = ++_refreshId;
        final active = _activeRefresh ??= widget.controller.refresh();
        await active;

        if (id == _refreshId && identical(_activeRefresh, active)) {
          break;
        }
      }
    } finally {
      _refreshRequested = false;
      _refreshFuture = null;
      _activeRefresh = null;
    }
  }

  void _onRetry() {
    _onReloadRequested();
  }

  void _onReloadRequested() {
    if (!mounted) return;

    final state = _refreshKey.currentState;

    if (state == null) {
      unawaited(widget.controller.refresh());
      return;
    }

    if (widget.resetScrollOnReload && _scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }

    // RefreshIndicator 在 refreshing / snap 时 show() 会静默忽略；
    // 已有刷新时直接替换 controller 请求，由 _drainRefresh 等最新请求。
    if (_refreshRequested) {
      _refreshId++;
      _activeRefresh = widget.controller.refresh();
      return;
    }

    // 没有内容可保留时不要下拉圈：居中 loading 是唯一反馈，叠两个圈会
    // 让用户以为加载了两次（empty → 换筛选、首屏未回 → 换筛选）。
    if (!_hasContent) {
      _startRefresh();
      return;
    }

    // 不等待 show() 的 onRefresh：立即刷新数据，让 show() 只负责动画。
    // ignore 标记保证 indicator 回调不会再次刷新 page1。
    _ignoreNextIndicatorRefresh = true;
    _startRefresh();
    state.show();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    if (notification is ScrollStartNotification && notification.dragDetails != null) {
      // show() 被忽略后，用户手动下拉仍应能正常刷新。
      _ignoreNextIndicatorRefresh = false;
    }
    if (notification is ScrollEndNotification) {
      _scheduleAutoLoadCheck();
    }
    return false;
  }

  void _scheduleAutoLoadCheck() {
    if (_autoLoadCheckScheduled || !mounted) return;
    _autoLoadCheckScheduled = true;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _autoLoadCheckScheduled = false;
      if (!mounted || !_scrollController.hasClients) return;
      _maybeAutoLoad(_scrollController.position.extentAfter);
    });
  }

  void _maybeAutoLoad(double extentAfter) {
    if (!mounted) return;
    // reloadRequests / 下拉刷新在 snap 前已经置位，但 snapshot 仍是 ready；
    // 这里必须提前挂起 autoLoad，否则会先发旧页码再被 refresh 取消。
    if (_refreshRequested || _refreshFuture != null) return;

    final threshold = widget.autoLoadThreshold;
    if (threshold == null || extentAfter > threshold) return;

    final snapshot = widget.controller.snapshot.value;
    if (snapshot.isLoadingMore ||
        !snapshot.hasMore ||
        snapshot.loadMoreError != null ||
        snapshot.state.isLoading ||
        snapshot.state.isRefreshing ||
        snapshot.state.isFailed ||
        _autoLoadInFlight) {
      return;
    }

    _autoLoadInFlight = true;
    unawaited(
      widget.controller.loadMore().whenComplete(() {
        _autoLoadInFlight = false;
        _scheduleAutoLoadCheck();
      }),
    );
  }

  Widget _footer(BuildContext context, WAsyncPagedSnapshot<T> snapshot) {
    final builder = widget.footerBuilder;
    if (builder != null) return builder(context, snapshot);

    final strings = WAsyncTheme.maybeOf(context)?.strings ?? const WAsyncStrings();

    switch (snapshot.footerStatus) {
      case WAsyncPagedFooterStatus.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      case WAsyncPagedFooterStatus.failed:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(strings.errorTitle),
              TextButton(
                onPressed: widget.controller.loadMore,
                child: Text(strings.retry),
              ),
            ],
          ),
        );
      case WAsyncPagedFooterStatus.noMore:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(child: Text(strings.noMore)),
        );
      case WAsyncPagedFooterStatus.loadMore:
        if (widget.autoLoadThreshold != null) {
          return const SizedBox.shrink();
        }
        return Center(
          child: TextButton(
            onPressed: widget.controller.loadMore,
            child: Text(strings.loadMore),
          ),
        );
      case WAsyncPagedFooterStatus.hidden:
        return const SizedBox.shrink();
    }
  }

  @override
  void didUpdateWidget(covariant WAsyncPagedList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadRequests != widget.reloadRequests) {
      _unbindReloadRequests();
      _bindReloadRequests();
    }
    if (oldWidget.controller != widget.controller) {
      _snapshot?.removeListener(_onSnapshotChanged);
      _snapshot = widget.controller.snapshot;
      _snapshot!.addListener(_onSnapshotChanged);
    }
  }

  @override
  void dispose() {
    _unbindReloadRequests();
    _snapshot?.removeListener(_onSnapshotChanged);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scheduleAutoLoadCheck();

    final refreshStyle = widget.refreshIndicatorStyle;

    return RefreshIndicator(
      key: _refreshKey,
      color: refreshStyle?.color,
      backgroundColor: refreshStyle?.backgroundColor,
      strokeWidth: refreshStyle?.strokeWidth ?? 2,
      displacement: refreshStyle?.displacement ?? 40,
      edgeOffset: refreshStyle?.edgeOffset ?? 0,
      triggerMode: refreshStyle?.triggerMode ?? RefreshIndicatorTriggerMode.onEdge,
      onRefresh: _onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            ...widget.headerSlivers,
            SliverPadding(
              padding: widget.sliverPadding,
              sliver: WAsyncStateSliver<List<T>>(
                state: widget.controller.state,
                onRetry: _onRetry,
                emptyBuilder: widget.emptyBuilder,
                readySliverBuilder: (context, items) => SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) => widget.itemBuilder(context, items[index]),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: ValueListenableBuilder<WAsyncPagedSnapshot<T>>(
                valueListenable: widget.controller.snapshot,
                builder: (context, snapshot, _) => _footer(context, snapshot),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
