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
- `controller.hasMore` 是普通 getter；footer 必须监听 `hasMoreListenable`——最后一页返回空列表时
  `hasMore` 会变但 `state` 不变，只按 `state` 重建的 footer 不会刷新；`isLoadingMore` / `loadMoreError`
  按需监听；
- 想在 footer 上区分「首屏还没翻过页」和「已翻过页、现在没有更多了」，用
  `controller.hasLoadedMoreThanOnePage`（或 `controller.page > controller.initialPage + 1`），
  不要用 `state.data.length` 变大去猜——失败路径上长度不变，猜出来的值会错；
- `refresh()` 在飞时再次调用会取消旧请求并以新参数重发；`dispose()` 会取消在飞 token。

## 切换筛选 / 搜索

```dart
onFilterChanged: (value) {
  filter = value;
  controller.refresh(); // 取消在飞请求，旧结果不写回
},
```

- 不需要在刷新期间禁用筛选；
- 被取代的 `refresh()` future 会随取消立即完成；要等最新结果就 await 最新一次调用；
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
