# 分页列表：刷新 + 追加 + 错误

用 `WAsyncPagedController` 管分页状态，`WAsyncStateBuilder` 只负责渲染滚动壳。

```dart
final controller = WAsyncPagedController<Gift>.withPage((page) async {
  final resp = await api.gifts(page: page, limit: 10);
  return WAsyncPage(
    items: resp.list,
    hasMore: resp.total == null ? resp.list.length >= 10 : page * 10 < resp.total!,
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
  return WAsyncStateBuilder<List<Gift>>(
    state: controller.state,
    builder: (context, state) => SmartRefresher(
      controller: refreshController,
      onRefresh: _refresh,
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
          const SliverToBoxAdapter(child: _Footer()),
        ],
      ),
    ),
  );
}
```

要点：

- `builder` 必须始终返回同一个 `SmartRefresher + CustomScrollView`，四态只作为 slivers；
- 追加下一页用 `controller.loadMore()`，失败看 `controller.loadMoreError`，**不要**把整页替换成失败态；
- `controller.hasMore` 是普通 getter；footer 必须监听 `hasMoreListenable`——最后一页返回空列表时
  `hasMore` 会变但 `state` 不变，只按 `state` 重建的 footer 不会刷新；`isLoadingMore` / `loadMoreError`
  按需监听；
- 想在 footer 上区分「首屏还没翻过页」和「已翻过页、现在没有更多了」，用
  `controller.hasLoadedMoreThanOnePage`（或 `controller.page > controller.initialPage + 1`），
  不要用 `state.data.length` 变大去猜——失败路径上长度不变，猜出来的值会错；
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
`isLoadingMore`，footer 仍停在 `LoadStatus.failed`；重试按钮应先
`refreshController.requestLoading()`，由 `onLoading` 再执行 `loadMore()`：

```dart
SmartRefresher(
  controller: refreshController,
  onRefresh: _refresh,
  onLoading: () async {
    await controller.loadMore();
    if (controller.loadMoreError.value != null) {
      refreshController.loadFailed();
    } else {
      refreshController.loadComplete();
    }
  },
  footer: ..., // SmartRefresher 自带 footer 或自建 footer
  child: ...,
)
```

- 重试按钮：`onTap: refreshController.requestLoading`；
- `loadMoreError` / `hasMore` / `isLoadingMore` 仍是唯一状态源；
- 自建 footer（上面的 `_Footer`）直接监听 controller 的 listenable 即可，不需要
  `requestLoading`。

### 自建 footer：首屏到底不提示“上拉 / 没有更多”

不依赖 `pull_to_refresh` 的纯展示 footer，用 `changes` 合并监听：

```dart
class _PagedFooter extends StatelessWidget {
  const _PagedFooter(this.controller);

  final WAsyncPagedController<Gift> controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller.changes,
      builder: (context, _) {
        final error = controller.loadMoreError.value;
        if (error != null) {
          return TextButton(
            onPressed: controller.loadMore,
            child: const Text('加载失败，重试'),
          );
        }
        if (controller.isLoadingMore.value) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!controller.hasMore) {
          // 第一页就到底：不显示“上拉加载”，也不显示“没有更多”。
          return controller.hasLoadedMoreThanOnePage
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: Text('没有更多数据了')),
                )
              : const SizedBox.shrink();
        }
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('上拉加载更多')),
        );
      },
    );
  }
}
```

把它放进 `SliverToBoxAdapter`；SmartRefresher 的 `CustomFooter` 只做
`LoadStatus -> 视图` 的薄适配，不要把这个状态机塞进 UI 包。

当前没有 `WPagedFooter`：如果 3+ 个项目仍在复制这段，再考虑在 `w_tools_ui`
加一个**纯展示**组件（不依赖 `pull_to_refresh` / `w_tools_async`）。

### `isRefreshing` 与 `isLoading`

`state.isRefreshing` 只表示「有旧数据时的刷新」；首屏 / 重试用 `state.isLoading`。
切换筛选不需要先判断 `isRefreshing`：直接 `_refresh()`，6.2.0 会取消旧请求。

## 切换筛选 / 搜索

```dart
onFilterChanged: (value) {
  filter = value;
  _refresh(); // 取消在飞请求，旧结果不写回；只让最新一次收 header
},
```

- 不需要在刷新期间禁用筛选；
- 被取代的 `refresh()` future 会随取消立即完成；这正是 `_refreshId` 守卫存在的原因；
- 不要直接调 `controller.refresh()`，否则 generation 不会更新，旧的下拉刷新可能提前收 header；
- 非 `SmartRefresher` 手势触发的刷新，sliver 默认不显示进度；传 `refreshingSliverBuilder`
  或由页面自己显示 loading。

## 详情返回置顶 / 乐观更新

```dart
void onDetailReturn(Gift updated) {
  final items = List<Gift>.of(controller.state.value.data ?? const <Gift>[]);
  items
    ..removeWhere((gift) => gift.id == updated.id)
    ..insert(0, updated);
  controller.replaceData(items); // 取消在飞请求，page/hasMore 默认继承
  // 需要服务端校准再 controller.refresh();
}
```

- `replaceData([])` 进入 empty，默认 `hasMore = false`；需要继续分页显式 `hasMore: true`；
- 首次加载前注入数据时默认视为第一页，下一次 `loadMore` 从 `initialPage + 1` 开始。

## 刷新失败的错误条

- sliver 版本：failed + 旧数据的错误条在列表上方，ready 子树不重建；
- `WAsyncView` 版本：错误条是视口底部 overlay，始终可见；
- 长列表滚动很深时，顶部错误条仍可能在视口外：用 `controller.onError` 弹 toast，或用
  `WAsyncStateBuilder` 在滚动壳外叠加常驻错误条。
