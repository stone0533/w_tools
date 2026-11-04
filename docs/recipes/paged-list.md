# 分页列表：刷新 + 追加 + 错误

用 `WAsyncPagedController` 管分页状态，`WAsyncStateBuilder` 只负责渲染滚动壳。

```dart
final controller = WAsyncPagedController<Gift>((page) => api.gifts(page: page));
final refreshController = RefreshController();

@override
void initState() {
  super.initState();
  controller.refresh();
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
      onRefresh: () async {
        await controller.refresh();
        refreshController.refreshCompleted();
      },
      child: CustomScrollView(
        slivers: [
          WAsyncStateSliver<List<Gift>>(
            state: controller.state,
            onRetry: controller.refresh,
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
- `controller.hasMore` 是普通 getter，footer 需要监听 `state` / `isLoadingMore` / `loadMoreError`；
- `dispose()` 会取消上一次 `refresh()` 的 token。
