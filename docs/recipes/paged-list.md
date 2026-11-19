# 分页列表

`WAsyncPagedList` 是标准分页壳：Flutter `RefreshIndicator` 下拉刷新 +
滚动阈值自动加载 + 内置 footer。

## 标准分页

```dart
final gifts = WAsyncPagedController<Gift>((page, token) async {
  final resp = await api.gifts(page: page, token: token);
  return WAsyncPage(
    items: resp.list,
    hasMore: resp.total > page * 20,
  );
});

@override
void initState() {
  super.initState();
  gifts.refresh();
}

@override
void dispose() {
  gifts.dispose();
  super.dispose();
}

@override
Widget build(BuildContext context) {
  return WAsyncPagedList<Gift>(
    controller: gifts,
    itemBuilder: (context, gift) => GiftTile(gift),
    autoLoadThreshold: 200,
  );
}
```

- 下拉刷新由 `RefreshIndicator` 负责；
- 距底部 `autoLoadThreshold` 像素时自动 `gifts.loadMore()`；
- 默认 footer 展示 loading / 失败重试 / 没有更多；
- 不自动发起首屏请求，页面负责 `gifts.refresh()`。

## 程序化刷新

```dart
final reloadRequests = ValueNotifier<int>(0);

WAsyncPagedList<Gift>(
  controller: gifts,
  itemBuilder: (context, gift) => GiftTile(gift),
  reloadRequests: reloadRequests,
);

// 换筛选
reloadRequests.value++;
```

- 刷新中再次触发时，最新请求完成后才收起刷新状态；
- 不需要外部刷新 controller。

## 自定义 footer

```dart
WAsyncPagedList<Gift>(
  controller: gifts,
  itemBuilder: (context, gift) => GiftTile(gift),
  footerBuilder: (context, snapshot) {
    return switch (snapshot.footerStatus) {
      WAsyncPagedFooterStatus.loading => const AppLoadingFooter(),
      WAsyncPagedFooterStatus.failed => AppFailedFooter(
          onRetry: gifts.loadMore,
        ),
      WAsyncPagedFooterStatus.noMore => const AppNoMoreFooter(),
      _ => const SizedBox.shrink(),
    };
  },
)
```

## 自定义滚动壳

需要 NestedScrollView、叠卡、完全自定义刷新头时，用
`WAsyncPagedSliver` + 自己的滚动壳：

```dart
RefreshIndicator(
  onRefresh: gifts.refresh,
  child: CustomScrollView(
    slivers: [
      WAsyncPagedSliver<Gift>.custom(
        controller: gifts,
        readySliverBuilder: (context, items) => WListViewSliver.overlap(...),
        onRetry: gifts.refresh,
      ),
      SliverToBoxAdapter(child: AppFooter(controller: gifts)),
    ],
  ),
)
```

## 边界

- `WAsyncPagedList` 不持有外部刷新 controller；
- 需要下拉动画定制时，不要重写整个分页状态机，只替换滚动壳；
- footer 失败后重试调 `controller.loadMore()`；
- 不要维护 `hasLoadedMorePage`，只读 `snapshot.footerStatus`；
- 不要在外层再包一层 `RefreshIndicator` / 刷新壳。
