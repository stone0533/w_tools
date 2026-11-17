# w_tools_async_ui

`w_tools_async` 的规范应用层：业务页面用少量固定入口，不再每页重复接线。

```text
单区块四态        → WAsyncSection
标准分页列表      → WAsyncPagedList
自定义滚动里的分页 → WAsyncPagedSliver
footer 文案       → WAsyncPagedStrings
```

核心 `w_tools_async` 仍然只提供 Controller / State / Snapshot / 原语 View；
本包只负责“业务页面怎么写”，不包含执行组合子、全局 loading、toast、设计系统。

## 安装

```yaml
dependencies:
  w_tools_async_ui: ^0.2.0
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
    strings: const WAsyncPagedStrings(
      failed: '加载失败',
      retry: '重试',
      noMore: '没有更多数据了',
      loadMore: '上拉加载更多',
    ),
  );
}
```

`WAsyncPagedList` 内部持有 `RefreshController`，统一处理下拉刷新、上拉加载、
footer 状态、重试和 generation；不要再在页面里拼 `footerStatus` /
`footerChanges` 两套参数。

## 自定义滚动

```dart
CustomScrollView(
  slivers: [
    WAsyncPagedSliver<Gift>(
      controller: gifts,
      itemBuilder: (context, gift) => GiftTile(gift),
    ),
  ],
)
```

`WAsyncPagedSliver` 不包含刷新壳；需要 NestedScrollView / overlap 卡片时用这个入口。
需要自定义 ready sliver / footer 时：

```dart
WAsyncPagedSliver<Gift>(
  controller: gifts,
  readySliverBuilder: (context, items) => WListViewSliver.overlap(...),
  footer: const SizedBox.shrink(), // 由外层 SmartRefresher 的 CustomFooter 负责
)
```

`WAsyncPagedList` 是标准壳，不提供 header/footer 覆盖；需要设计稿口径的刷新头 / footer 时，
用 `WAsyncPagedSliver` + 自己的 `SmartRefresher`。

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
