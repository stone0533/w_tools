# 分页列表：刷新 + 追加 + 错误

> 业务页面优先用 `w_tools_async_ui` 的 `WAsyncPagedList`：它内部处理刷新、上拉、
> generation 和 loadMore 收尾；header / footer 可直接覆盖。下面的原语组合用于
> 自定义滚动 / 库内部 / 设计系统。

用 `WAsyncPagedController` 管分页状态，`WAsyncStateSliver` 渲染四态，footer 读
`controller.snapshot`。测试用 [分页列表测试 recipe](paged-list-test.md) 的本地 harness，
不要每个项目重写 fake。

```dart
final controller = WAsyncPagedController<Gift>((page, token) async {
  final resp = await api.gifts(page: page, limit: 10, token: token);
  return WAsyncPage<Gift>(
    items: resp.list,
    hasMore: resp.total == null ? null : page * 10 < resp.total,
  );
});
final refreshController = RefreshController();
int _refreshId = 0;

@override
void initState() {
  super.initState();
  _refresh();
}

/// 所有 refresh 入口都走这里：只让最新一次收 header。
Future<void> _refresh() async {
  final id = ++_refreshId;
  await controller.refresh();
  if (id == _refreshId) {
    refreshController.refreshCompleted();
  }
}

@override
void dispose() {
  controller.dispose();
  refreshController.dispose();
  super.dispose();
}

@override
Widget build(BuildContext context) {
  return SmartRefresher(
    controller: refreshController,
    onRefresh: _refresh,
    onLoading: () async {
      await controller.loadMore();
      if (controller.snapshot.value.loadMoreError != null) {
        refreshController.loadFailed();
      } else {
        refreshController.loadComplete();
      }
    },
    child: CustomScrollView(
      slivers: [
        WAsyncStateSliver<List<Gift>>(
          state: controller.state,
          onRetry: _refresh,
          readySliverBuilder: (context, gifts) => SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => GiftTile(gifts[index]),
              childCount: gifts.length,
            ),
          ),
        ),
        SliverToBoxAdapter(child: _PagedFooter(controller)),
      ],
    ),
  );
}
```

要点：

- `WAsyncStateSliver` 始终返回同一个 `SliverMainAxisGroup`，滚动壳（`CustomScrollView`）不需要
  再包一层状态 builder；
- 追加下一页用 `controller.loadMore()`，失败看 `controller.snapshot.value.loadMoreError`，
  **不要**把整页替换成失败态；
- footer 只监听 `controller.snapshot`；最后一页返回空列表时 `snapshot.hasMore` 会变但
  `state` 不变，只按 `state` 重建的 footer 不会刷新；
- footer 状态读 `snapshot.footerStatus`，不要自己组合 `data == null` / `loadMoreError` / `hasMore`；
- `refresh()` 在飞时再次调用会取消旧请求并以新参数重发；`dispose()` 会取消在飞 token。

## SmartRefresher 组合：首屏、generation、footer

### 首屏用 `refresh()`，不要 `requestRefresh()`

首屏直接调上面的 `_refresh()`（内部 `controller.refresh()`），`WAsyncStateSliver` 会显示
居中的 loading。`refreshController.requestRefresh()` 只用于下拉手势；首屏调用它会出现
header spinner + sliver loading 两个转圈。

如果首屏一定要保留 header 动画，就让 sliver 不显示 loading（例如
`loadingBuilder: (_) => const SizedBox.shrink()`），只留一个转圈。

### 所有 refresh 入口走同一个 `_refresh`

下拉、筛选切换、错误页重试都调用同一个 `_refresh()`，不要有的地方直接
`controller.refresh()`。`_refresh` 用 `_refreshId` 记录代际，只有最新一次会
`refreshCompleted()`；被取代的旧 refresh 不会提前收掉新 header。

```dart
int _refreshId = 0;

Future<void> _refresh() async {
  final id = ++_refreshId;
  await controller.refresh();
  if (id == _refreshId) refreshController.refreshCompleted();
}
```

### footer：重试先 `requestLoading()`

用 SmartRefresher 自带 footer 时，footer 失败后直接调 `controller.loadMore()` 只会更新
`snapshot.footerStatus`，SmartRefresher 仍停在 `LoadStatus.failed`；重试按钮应先
`refreshController.requestLoading()`，由 `onLoading` 再执行 `loadMore()`：

```dart
SmartRefresher(
  controller: refreshController,
  onRefresh: _refresh,
  onLoading: () async {
    await controller.loadMore();
    if (controller.snapshot.value.loadMoreError != null) {
      refreshController.loadFailed();
    } else {
      refreshController.loadComplete();
    }
  },
  child: ...,
)
```

- 重试按钮：`onTap: refreshController.requestLoading`；
- 自建 footer（下面的 `_PagedFooter`）直接监听 `snapshot` 即可，不需要 `requestLoading`。

### 自建 footer

```dart
class _PagedFooter extends StatelessWidget {
  const _PagedFooter(this.controller);

  final WAsyncPagedController<Gift> controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller.snapshot,
      builder: (context, _) {
        final footer = controller.snapshot.value;
        return switch (footer.footerStatus) {
          WAsyncPagedFooterStatus.hidden => const SizedBox.shrink(),
          WAsyncPagedFooterStatus.loading => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          WAsyncPagedFooterStatus.failed => TextButton(
            onPressed: controller.loadMore,
            child: const Text('加载失败，重试'),
          ),
          WAsyncPagedFooterStatus.noMore => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: Text('没有更多数据了')),
          ),
          WAsyncPagedFooterStatus.loadMore => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: Text('上拉加载更多')),
          ),
        };
      },
    );
  }
}
```

把它放进 `SliverToBoxAdapter`；SmartRefresher 的 `CustomFooter` 只做
`LoadStatus -> 视图` 的薄适配，不要把这个状态机塞进 UI 包。

`footerStatus` 已经处理了「首屏到底不显示、翻过页才显示没有更多、追加失败可重试」三种边界。

当前没有 `WPagedFooter`：如果 3+ 个项目仍在复制这段，再考虑在 `w_tools_ui`
加一个**纯展示**组件（不依赖 `pull_to_refresh` / `w_tools_async`）。

### 抽成项目壳：只传 snapshot

如果项目里多个列表共用壳，壳只接收分页快照，不要同时传
`footerStatus` + `footerChanges` 两个入口：

```dart
class AppPagedSliverList<T> extends StatelessWidget {
  const AppPagedSliverList({
    super.key,
    required this.state,
    required this.snapshot,
    required this.refreshController,
    required this.onRefresh,
    required this.onLoading,
    required this.itemBuilder,
    this.onRetryLoadMore,
  });

  final ValueListenable<WAsyncState<List<T>>> state;
  final ValueListenable<WAsyncPagedSnapshot<T>> snapshot;
  final RefreshController refreshController;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoading;
  final Future<void> Function()? onRetryLoadMore;
  final Widget Function(BuildContext context, T item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
      controller: refreshController,
      onRefresh: onRefresh,
      onLoading: onLoading,
      child: CustomScrollView(
        slivers: [
          WAsyncStateSliver<List<T>>(
            state: state,
            onRetry: onRefresh,
            readySliverBuilder: (context, items) => SliverList.builder(
              itemCount: items.length,
              itemBuilder: (context, index) => itemBuilder(context, items[index]),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: snapshot,
              builder: (context, _) => _FooterStatus(
                status: snapshot.value.footerStatus,
                onRetry: onRetryLoadMore,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterStatus extends StatelessWidget {
  const _FooterStatus({required this.status, this.onRetry});

  final WAsyncPagedFooterStatus status;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) => switch (status) {
    WAsyncPagedFooterStatus.hidden => const SizedBox.shrink(),
    WAsyncPagedFooterStatus.loading => const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    ),
    WAsyncPagedFooterStatus.failed => TextButton(
      onPressed: onRetry == null ? null : () => onRetry!(),
      child: const Text('重试'),
    ),
    WAsyncPagedFooterStatus.noMore => const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: Text('没有更多')),
    ),
    WAsyncPagedFooterStatus.loadMore => const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: Text('上拉加载更多')),
    ),
  };
}
```

要点：壳只读 `snapshot`，不要同时收 `footerStatus` 和 `footerChanges`；也不要在
controller 里维护 `hasLoadedMorePage`。`footerStatus` 已经区分首屏到底（`hidden`）和
翻页后到底（`noMore`）。

### `isRefreshing` 与 `isLoading`

`state.isRefreshing` 只表示「有旧数据时的刷新」；首屏 / 重试用 `state.isLoading`。
切换筛选不需要先判断 `isRefreshing`：直接 `_refresh()`，被取代的刷新会被取消。

## 切换筛选 / 搜索

```dart
onFilterChanged: (value) {
  filter = value;
  _refresh(); // 取消在飞请求，旧结果不写回；只让最新一次收 header
},
```

- 不需要在刷新期间禁用筛选；
- 被取代的 `refresh()` future 会随取消立即完成；这正是 `_refreshId` 守卫存在的原因；
- 不要直接调 `controller.refresh()`，否则 generation 不会更新，旧的下拉刷新可能提前收 header。

## 详情返回置顶 / 乐观更新

```dart
void onDetailReturn(Gift updated) {
  final items = List<Gift>.of(controller.state.value.data ?? const <Gift>[]);
  items
    ..removeWhere((gift) => gift.id == updated.id)
    ..insert(0, updated);
  controller.replaceData(items); // 取消在飞请求，hasMore 默认继承
  // 需要服务端校准再 controller.refresh();
}
```

- `replaceData([])` 进入 empty，默认 `hasMore = false`；需要继续分页显式 `hasMore: true`；
- 首次加载前注入数据时默认视为第一页，下一次 `loadMore` 从构造参数 `initialPage` + 1 开始。

## 刷新失败的错误条

- sliver 版本：failed + 旧数据的错误条在列表上方，ready 子树不重建；
- `WAsyncView` 版本：宽高都有界时错误条在内容盒底部占位；无界时是 overlay；
- 长列表滚动很深时，顶部错误条仍可能在视口外：用 `onError` 弹 toast，或在滚动壳外叠加
  常驻错误条。
