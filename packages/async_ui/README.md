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
  w_tools_async_ui: ^1.1.0
```

要求 Flutter 3.38+。

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
    // 可选：直接传 SmartRefresher 的 header / footer。
    header: const AppRefreshHeader(),
    footer: CustomFooter(
      builder: (context, _) => ValueListenableBuilder(
        valueListenable: gifts.snapshot,
        builder: (context, snapshot, _) => AppFooter(
          status: snapshot.footerStatus,
          onRetry: gifts.loadMore,
        ),
      ),
    ),
    refreshController: refreshController, // 可选；外部持有 / dispose
  );
}
```

需要带动画的程序化刷新时，传入外部 `RefreshController`：

```dart
final refreshController = RefreshController();

WAsyncPagedList<Gift>(
  controller: gifts,
  itemBuilder: (context, gift) => GiftTile(gift),
  refreshController: refreshController,
);

refreshController.requestRefresh(); // 有下拉 header 动画
if (refreshController.isRefresh) {
  // 刷新在飞，避免重复 requestRefresh
}
```

`WAsyncPagedList` 内部持有 `RefreshController`，统一处理下拉刷新、上拉加载、
generation 和 `loadFailed / loadNoData / loadComplete`。

- `header` / `footer` 原样转给 `SmartRefresher`；
- 不传时使用 `SmartRefresher` 的默认 header / footer；
- `refreshController` 可选；外部传入时由 app dispose，不传时组件内部创建并 dispose；
- app 自定义 footer 时，读 `controller.snapshot`，重试调用 `controller.loadMore()`；
  不要依赖内部 `RefreshController`；
- 不要再在页面里拼 `footerStatus` / `footerChanges` 两套参数。

## 自定义滚动

```dart
CustomScrollView(
  slivers: [
    WAsyncPagedSliver<Gift>(
      controller: gifts,
      itemBuilder: (context, gift) => GiftTile(gift),
    ),
    SliverToBoxAdapter(
      child: AppFooter(controller: gifts),
    ),
  ],
)
```

需要 NestedScrollView / overlap 卡片时用 `.custom`：

```dart
WAsyncPagedSliver<Gift>.custom(
  controller: gifts,
  readySliverBuilder: (context, items) => WListViewSliver.overlap(...),
  onRetry: refreshController.requestRefresh, // 错误重试走页面 header
)
```

`WAsyncPagedSliver` 只负责四态和 ready 分支：

- 不包含 `SmartRefresher` / `RefreshController`；
- 不包含 footer / 文案；
- header / footer 由页面自己的滚动壳负责；
- 自建滚动壳的错误重试传 `onRetry: refreshController.requestRefresh`。

## 边界

- 不自动 load / refresh；页面 controller 自己负责首屏请求。
- 不持有 controller；`WAsyncPagedList` 只持有内部的 `RefreshController`。
- 不包含已删除的执行组合子（`parallel` / `pool` / `serial` / `first` / `map`）；这些已被
  `Future.wait` / `WAsync.settle` / `Future.any` / for 替代。
- 不包含全局 loading / toast / 登录失效；这些是 app 层策略。
- 不 import 任何项目设计系统；空态 / 错误外观通过 `WAsyncTheme` 或 builder 注入。

## 示例

[`example/`](example/) 是一个可运行的最小应用：`WAsyncSection` 单区块 + `WAsyncPagedList`
分页列表；运行 `cd example && flutter run`，或 `flutter test` 跑 smoke test。
