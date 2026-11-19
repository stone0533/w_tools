# w_tools_async_ui 2.0 迁移

2.0 去掉 `pull_to_refresh` 依赖，`WAsyncPagedList` 改用 Flutter `RefreshIndicator`
+ 滚动阈值自动加载；`w_tools_async` 兼容 `>=7.4.0 <9.0.0`。

## 移除的 API

```text
WAsyncPagedList.refreshController
WAsyncPagedList.header
WAsyncPagedList.footer
```

不再依赖：

```text
pull_to_refresh / SmartRefresher / RefreshController
```

## 标准分页

旧：

```dart
WAsyncPagedList<Gift>(
  controller: gifts,
  itemBuilder: (context, gift) => GiftTile(gift),
  header: AppRefreshHeader(),
  footer: CustomFooter(...),
  refreshController: refreshController,
);
```

新：

```dart
WAsyncPagedList<Gift>(
  controller: gifts,
  itemBuilder: (context, gift) => GiftTile(gift),
  autoLoadThreshold: 200,
);
```

下拉刷新改为标准 `RefreshIndicator`；滚动接近底部自动 `controller.loadMore()`。

## 程序化刷新

旧：

```dart
refreshController.requestRefresh();
```

新：

```dart
final reloadRequests = ValueNotifier<int>(0);

WAsyncPagedList<Gift>(
  controller: gifts,
  itemBuilder: (context, gift) => GiftTile(gift),
  reloadRequests: reloadRequests,
);

reloadRequests.value++;
```

## 刷新头样式

标准壳支持 Flutter `RefreshIndicator` 的样式：

```dart
WAsyncPagedList<Gift>(
  controller: gifts,
  itemBuilder: (context, gift) => GiftTile(gift),
  refreshIndicatorStyle: const WAsyncRefreshIndicatorStyle(
    color: Color(0xFF00A86B),
    backgroundColor: Colors.white,
  ),
)
```

只支持颜色 / 背景 / 线宽 / 位移 / 触发模式；自定义刷新头、完成 / 失败文案
仍用 `WAsyncPagedSliver` + 自建滚动壳。

## 自定义 footer

旧：

```dart
footer: CustomFooter(
  builder: (context, _) => AppFooter(controller: gifts),
),
```

新：

```dart
footerBuilder: (context, snapshot) => AppFooter(snapshot),
```

## 自定义刷新头 / 上拉壳

`WAsyncPagedList` 不再接受自定义 header / footer。需要完全自定义时，用
`WAsyncPagedSliver` + 自己的 `RefreshIndicator` / `CustomScrollView`：

```dart
RefreshIndicator(
  onRefresh: gifts.refresh,
  child: CustomScrollView(
    slivers: [
      WAsyncPagedSliver<Gift>(
        controller: gifts,
        itemBuilder: (context, gift) => GiftTile(gift),
        onRetry: gifts.refresh,
      ),
      SliverToBoxAdapter(child: AppFooter(controller: gifts)),
    ],
  ),
)
```

## 行为变化

- 不再有 pull-up footer 手势；加载更多由滚动阈值自动触发。
- 刷新失败 / 加载失败由默认 footer 展示；失败后不会自动重试。
- `autoLoadThreshold: null` 可关闭自动加载。
- 首屏仍需页面自己调用 `controller.refresh()`。
