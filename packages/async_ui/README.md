# w_tools_async_ui

`w_tools_async` 的规范应用层：业务页面用少量固定入口，不再每页重复接线。

```text
单区块四态         → WAsyncSection
标准分页列表       → WAsyncPagedList
自定义滚动里的分页 → WAsyncPagedSliver
```

核心 `w_tools_async` 仍然只提供 Controller / State / Snapshot / 原语 View；
本包只负责“业务页面怎么写”，不包含执行组合子、全局 loading、toast、设计系统。

## 安装

```yaml
dependencies:
  w_tools_async_ui: ^2.0.0
```

要求 Flutter 3.38+、`w_tools_async >=7.4.0 <9.0.0`。

## 单区块

```dart
final gifts = WAsyncController.list<Gift>((_) => api.gifts());

@override
void initState() {
  super.initState();
  gifts.load();
}

@override
void dispose() {
  gifts.dispose();
  super.dispose();
}

@override
Widget build(BuildContext context) {
  return WAsyncSection<List<Gift>>(
    controller: gifts,
    builder: (context, data) => GiftList(data),
  );
}
```

`WAsyncSection` 默认把失败重试接到 `gifts.load`；loading / error 外观走
`WAsyncTheme`。设计稿口径的区块可以传 per-block builder 和自定义重试：

```dart
WAsyncSection<List<Gift>>(
  controller: gifts,
  onRetry: () => gifts.load(),
  loadingBuilder: (context) => const GiftSkeleton(),
  errorBuilder: (context, error, retry) => GiftError(retry: retry),
  errorBannerBuilder: (context, error, retry) => GiftErrorBanner(retry: retry),
  refreshingBuilder: (context) => const LinearProgressIndicator(),
  builder: (context, data) => GiftList(data),
  emptyBuilder: (context) => const GiftEmpty(),
)
```

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
    reloadRequests: reloadRequests, // 可选；程序化重载
    autoLoadThreshold: 200,         // 可选；距底部 200 触发 loadMore
    footerBuilder: (context, snapshot) => AppFooter(snapshot), // 可选
    refreshIndicatorStyle: const WAsyncRefreshIndicatorStyle(
      color: Color(0xFF00A86B),
      backgroundColor: Colors.white,
    ), // 可选；标准刷新头样式
  );
}
```

下拉刷新由 Flutter `RefreshIndicator` 提供；滚动接近底部时自动
`controller.loadMore()`。默认 footer 根据 `snapshot.footerStatus` 展示：

```text
loading  → 转圈
failed   → “重试”按钮
noMore   → “No more”
hidden / loadMore → 不显示
```

### 程序化刷新

```dart
final reloadRequests = ValueNotifier<int>(0);

WAsyncPagedList<Gift>(
  controller: gifts,
  itemBuilder: (context, gift) => GiftTile(gift),
  reloadRequests: reloadRequests,
);

// 换筛选 / 点“刷新”
reloadRequests.value++;
```

`reloadRequests` 会复用 `RefreshIndicator` 的刷新动画；刷新中再次触发时，
最新请求完成后才收起，不会由旧请求提前收尾。业务不需要持有外部刷新控制器。

### 刷新头样式

```dart
WAsyncPagedList<Gift>(
  controller: gifts,
  itemBuilder: (context, gift) => GiftTile(gift),
  refreshIndicatorStyle: const WAsyncRefreshIndicatorStyle(
    color: Color(0xFF00A86B),
    backgroundColor: Colors.white,
    strokeWidth: 2,
    displacement: 40,
    edgeOffset: 0,
    triggerMode: RefreshIndicatorTriggerMode.onEdge,
  ),
)
```

`WAsyncRefreshIndicatorStyle` 只映射 Flutter `RefreshIndicator` 的样式：

```text
颜色 / 背景 / 线宽 / 位移 / 边缘偏移 / 触发模式
```

不支持自定义刷新头、完成 / 失败文案或下拉动画；这些用
`WAsyncPagedSliver` + 自己的滚动壳。

### 自定义 footer

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

### 自定义刷新头 / 上拉壳

`WAsyncPagedList` 只提供标准 `RefreshIndicator` + 自动加载。需要完全自定义
下拉动画或 pull-up 手势时，用 `WAsyncPagedSliver` + 自己的滚动壳：

```dart
RefreshIndicator(
  onRefresh: gifts.refresh,
  child: CustomScrollView(
    slivers: [
      WAsyncPagedSliver<Gift>(
        controller: gifts,
        itemBuilder: (context, gift) => GiftTile(gift),
      ),
      SliverToBoxAdapter(child: AppFooter(controller: gifts)),
    ],
  ),
)
```

`WAsyncPagedSliver` 只负责四态和 ready 分支：

- 不包含刷新壳 / footer / 文案；
- header / footer 由页面自己的滚动壳负责；
- 错误重试可以传 `onRetry: gifts.refresh`，或在自建壳里走自己的刷新入口。

## 边界

- 不自动 load / refresh；页面 controller 自己负责首屏请求。
- 不持有 controller；`WAsyncPagedList` 不持有外部刷新控制器。
- 不包含已删除的执行组合子（`parallel` / `pool` / `serial` / `first` / `map`）；这些已被
  `Future.wait` / `WAsync.settle` / `Future.any` / for 替代。
- 不包含全局 loading / toast / 登录失效；这些是 app 层策略。
- 不 import 任何项目设计系统；空态 / 错误外观通过 `WAsyncTheme` 或 builder 注入。

## 示例

[`example/`](example/) 是一个可运行的最小应用：`WAsyncSection` 单区块 + `WAsyncPagedList`
分页列表；运行 `cd example && flutter run`，或 `flutter test` 跑 smoke test。
