# w_tools_async

w_tools 的异步层：执行、四态状态、Controller、分页与可复用异步视图。

```text
页面展示异步结果  → WAsyncController + WAsyncView
只执行、不要 UI   → WAsync + WAsyncResult
全 App 默认视图   → WAsyncTheme
```

选择执行入口：

```text
页面区块             → WAsyncController + WAsyncView
纯逻辑，想 try/catch → WAsync.run
纯逻辑，想显式分支   → WAsync.tryRun + WAsyncResult
```

## 安装

```yaml
dependencies:
  w_tools_async: ^6.6.0
```

要求 Flutter 3.38+。

## 快速开始

```dart
class GiftPage extends StatefulWidget {
  const GiftPage({super.key});

  @override
  State<GiftPage> createState() => _GiftPageState();
}

class _GiftPageState extends State<GiftPage> {
  late final WAsyncController<List<Gift>> _gifts;

  @override
  void initState() {
    super.initState();
    _gifts = WAsyncController.list(() => api.gifts());
    _gifts.load();
  }

  @override
  void dispose() {
    _gifts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WAsyncView<List<Gift>>(
      state: _gifts.state,
      onRetry: _gifts.load, // 可选；不传错误态不显示重试按钮
      readyBuilder: (context, gifts) => GiftList(gifts),
    );
  }
}
```

`WAsyncView` 自动处理：

```text
loading  → 转圈
empty    → WAsyncStrings.empty
failed   → 错误页（有 onRetry 才显示重试）
ready    → readyBuilder
```

单个 `WAsyncView` 还可覆盖 `loadingBuilder` / `emptyBuilder` / `errorBuilder` /
`errorBannerBuilder` / `refreshingBuilder`；`onRetryError` 用于观测自定义 retry 失败。
未传时回退到 `WAsyncTheme` 的默认视图。

`refreshingBuilder` / `errorBannerBuilder` 是**内容盒** overlay，不一定是视口：作为
`Scaffold.body` / `Expanded` 等紧约束时填满视口，作为 `Column` 子项 / `ListView` item
时只包住内容。需要固定到视口时，外层给有界高度，或用 `WAsyncStateBuilder` 自建滚动壳。

完整可运行示例：[`example/`](example/README.md)（四态、分页、Sliver、执行、真实场景）。

## 主要 API

| 场景 | 入口 |
| --- | --- |
| 页面区块四态 | `WAsyncController` / `WAsyncView` |
| 滚动页 / `SmartRefresher` | `WAsyncStateBuilder` |
| 滚动页复用全局默认视图 | `WAsyncThemeViews.of(context)` |
| `CustomScrollView` 的 sliver 四态 | `WAsyncStateSliver` |
| 分页 | `WAsyncPagedController` |
| 全局默认视图 / 文案 | `WAsyncTheme` / `WAsyncStrings` |
| 无 UI 执行，不抛异常 | `WAsync.tryRun` + `WAsyncResult` |
| 无 UI 执行，失败抛异常 | `WAsync.run` / `map` / `retry` / `timeout` |
| 并发执行 | `WAsync.parallel` / `pool` / `serial` / `first` |
| 独立区块并行，保留每个结果 | `WAsync.settle` |
| 并发活动回调 | `WAsyncActivity`（只传给 `WAsyncOptions`，不要手动 begin/end） |
| 让 loader 感知取消 | `WAsyncController.withToken` / `listWithToken` / `WAsyncPagedController.withToken` |
| 单区块本地替换 / 乐观更新 | `WAsyncController.replaceData` |
| 四态快照 | `WAsyncState` / `WAsyncStatus` |
| 观测自定义 retry 失败 | `WAsyncView.onRetryError` / `WAsyncStateSliver.onRetryError` |

## 执行结果

`tryRun` 不抛业务异常，返回显式结果：

```dart
final result = await WAsync.tryRun(() => api.gift(id));

switch (result) {
  case WAsyncSuccess(:final value):
    print(value);
  case WAsyncFailure(
    :final error,
    :final stackTrace,
    :final isProgrammingError,
  ):
    logger.e(error, stackTrace: stackTrace);
    if (isProgrammingError) throw error;

  case WAsyncCancelled(:final reason):
    print('cancelled: $reason');
}
```

需要失败直接抛异常时：

```dart
final gift = await WAsync.run(() => api.gift(id));
final name = await WAsync.map<String, String>(
  () => api.gift(id),
  onSuccess: (gift) => gift.name,
);
```

> `WAsyncOptions.onError` 只是失败**通知**，不会吞异常。`run` / `map` / `retry` /
> `timeout` 失败仍会抛；`.then` 必须同时给 `onError` / `catchError`，否则会有
> unhandled Future。不需要抛异常的调用方直接用 `WAsync.tryRun`。

```dart
// 要保留 run 的抛异常语义：给 .then 传 onError
WAsync.run(() => api.gift(id), options: options).then(
  (gift) => use(gift),
  onError: (Object error, StackTrace stack) {
    // options.onError 已经提示过；这里只消费掉 Future 的异常
  },
);

// 或者不抛：tryRun + WAsyncResult
final result = await WAsync.tryRun(() => api.gift(id), options: options);
switch (result) {
  case WAsyncSuccess(:final value): use(value);
  case WAsyncFailure(:final error): log(error);
  case WAsyncCancelled(): log('cancelled');
}
```

- 失败抛原始 error / stack；
- 取消抛 `WCancellationException`；
- `WAsync` 不再用 `null` 表示失败或取消；
- `onSuccess` / `map` 的映射异常由调用方处理，不会回调 `options.onError`；
- 只有 token 取消才算 `WAsyncCancelled`；任务自己抛 `WCancellationException` 仍算失败；
- `onRetry == null` 时 `errorBuilder` / `errorBannerBuilder` 仍会收到 `null` 的 retry；
  由 builder 自己决定是否渲染按钮。

并发组合器的边界：

- `parallel` 是 **all-or-nothing**：任一失败整体抛错，其余 Future 会继续执行但结果拿不到，
  不会自动取消；`eagerError: false` 仍会抛，不会返回部分结果。独立区块先用 `WAsync.tryRun` 包每个 Future；
- `onError` 只是通知，不会把失败变成成功；不要用空实现吞掉诊断；
- `first` 返回最先完成的结果，不会取消落败者；
- `pool` 只上报第一个错误，其余错误被忽略。

独立区块的完整写法见 [独立区块并行](https://github.com/stone0533/w_tools/blob/main/docs/recipes/parallel-sections.md)。

不想手写 `tryRun` 包装时用 `WAsync.settle`：

```dart
final results = await WAsync.settle<HomeSection>([
  () => api.banners(),
  () => api.columns(),
  () => api.notices(),
], concurrency: 3);

for (final result in results) {
  switch (result) {
    case WAsyncSuccess(:final value): use(value);
    case WAsyncFailure(:final error): log(error);
    case WAsyncCancelled(): break;
  }
}
```

`settle` 不会因为单个失败抛错，结果顺序与输入一致；`options.activity` 按任务计数，
需要整批 activity 时用 `parallel` + `WAsyncOptions(activity:)`。

重试支持退避与 attempt 观测：

```dart
await WAsync.retry(
  () => api.submit(),
  retryCount: 3,
  retryDelayBuilder: (attempt) =>
      Duration(milliseconds: 200 * (1 << (attempt - 1))),
  onRetry: (attempt, error, delay) =>
      log('retry #$attempt in $delay: $error'),
);
```

`retryCount` 是重试次数，总尝试 = `retryCount + 1`；`onRetry` 自身异常会被忽略。

取消与失败在同一轮竞态时，非 `Error` 的失败按取消处理；`Error` 仍返回
`WAsyncFailure`，避免把 TypeError / StateError 吞成取消。

自定义重试失败时，View 默认用 `FlutterError.reportError` 上报；需要自己记录时传：

```dart
WAsyncView(
  // ...
  onRetryError: (error, stackTrace) => logger.e(error, stackTrace: stackTrace),
)
```

## Controller

```dart
class GiftPage extends StatefulWidget {
  const GiftPage({super.key});

  @override
  State<GiftPage> createState() => _GiftPageState();
}

class _GiftPageState extends State<GiftPage> {
  late final WAsyncController<List<Gift>> _gifts;

  @override
  void initState() {
    super.initState();
    _gifts = WAsyncController.list(() => api.gifts());
    _gifts.load();
  }

  @override
  void dispose() {
    _gifts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WAsyncView<List<Gift>>(
      state: _gifts.state,
      onRetry: _gifts.load,
      readyBuilder: (context, gifts) => GiftList(gifts),
    );
  }
}
```

每个独立区块一个 Controller。

Controller 只接 `onError`；不再接受 `WAsyncOptions` / `activity`。控制器自己维护四态。

`WAsyncController.list` 与 `WAsyncPagedController` 的 `state.data` 是 unmodifiable 列表；
泛型 `WAsyncController` 仍原样保存 loader 的返回值（无法通用地包一层）。

列表 + 感知取消用 `listWithToken`，保留 empty / unmodifiable 语义：

```dart
final controller = WAsyncController.listWithToken(
  (token) => api.gifts(cancelToken: token),
);
```

本地替换 / 乐观更新用 `replaceData`；它会取消在飞 `load`，旧结果不会覆盖本地修改：

```dart
final items = List<Gift>.of(controller.state.value.data ?? const <Gift>[]);
items
  ..removeWhere((gift) => gift.id == updated.id)
  ..insert(0, updated);
controller.replaceData(items);
// 需要服务端校准再 controller.load();
```

## 取消

控制器默认不接收 token；需要请求层感知取消时用 `withToken` / `listWithToken`：

```dart
final controller = WAsyncController.withToken(
  (token) => api.gifts(cancelToken: token),
);
```

`load()` 被新请求取代或 `dispose()` 时 token 会被取消；取消是协作式的，底层 Future 是否中止由 loader 决定。

分页同理：

```dart
WAsyncPagedController.withToken((page, token) => api.gifts(page, token));
```

`refresh()` 被新的 `refresh()` 取代时也会取消旧 token；旧结果不会写回 `state`。
被取代的 `refresh()` future 会随取消立即完成，要等最新结果就 await 最新一次调用。

## 分页

```dart
final controller = WAsyncPagedController<Gift>((page) => api.gifts(page: page));

await controller.refresh();
await controller.loadMore();
```

第一页不足一页、或服务端返回 `total` 时，用 `withPage` 显式给出 `hasMore`，
避免多发一次空页请求：

```dart
final controller = WAsyncPagedController<Gift>.withPage((page) async {
  final resp = await api.gifts(page: page, limit: 10);
  return WAsyncPage(
    items: resp.list,
    hasMore: resp.total == null
        ? resp.list.length >= 10
        : page * 10 < resp.total!,
  );
});
```

- `hasMore: false` 后 `loadMore()` 直接返回，不再请求下一页；
- 旧构造 `WAsyncPagedController((page) => Future<List<T>>)` 行为不变：
  本页非空仍视为有更多；需要精确控制时用 `withPage` / `withPageToken`。

监听：

```text
controller.state
controller.isLoadingMore
controller.loadMoreError
controller.hasMoreListenable
```

footer 想只挂一个监听时用 `controller.changes`（合并以上四个）；需要细粒度重建时仍用上面的单项。
footer 展示状态直接读 `controller.footerStatus`：

```dart
switch (controller.footerStatus) {
  case WAsyncPagedFooterStatus.hidden: // 首屏 / empty / 第一页就到底
  case WAsyncPagedFooterStatus.loading: // 正在追加
  case WAsyncPagedFooterStatus.failed: // 追加失败，可重试
  case WAsyncPagedFooterStatus.noMore: // 已翻过页且没有更多
  case WAsyncPagedFooterStatus.loadMore: // 可继续加载
}
```

它是普通 getter，不通知；footer 仍用 `changes` 重建。

`loadMore` 失败只写 `loadMoreError`，不会清空已有列表。

分页追加使用 chunked 不可变列表（结构共享）：每页只复制最后一个 chunk（≤256）和外层
chunk 引用，旧 `state.data` 与新增量共享前缀，十万级也不会整表复制。

最后一页返回空列表时 `hasMore` 会变成 `false`，但 `state` 不变；只按 `state` 重建的
footer 必须额外监听 `hasMoreListenable`，否则按钮会一直停在「加载更多」。

页号也直接可读：`controller.page` 是**下一次 `loadMore` 将请求的页码**（首屏完成前等于
`initialPage`）；`controller.hasLoadedMoreThanOnePage` 表示已成功追加过第二页，
用来区分「首屏还没翻过页」和「已翻过页、现在没有更多了」。

`initial: WAsyncState.ready([])` 视为没有更多：不会请求 `initialPage + 1`。

切换筛选 / 搜索时直接再调 `refresh()`：在飞请求会被取消，旧结果不会写回。
如果这次刷新不是由 `SmartRefresher` 手势触发，sliver 默认不显示进度；需要时传
`refreshingSliverBuilder` 或由页面自己显示 loading。

```dart
onFilterChanged: (value) {
  filter = value;
  controller.refresh(); // 用 SmartRefresher 时改成与下拉共用的 _refresh
},
```

本地替换 / 乐观更新用 `replaceData`：它会取消在飞 `refresh` / `loadMore`，避免旧结果覆盖
本地修改；`page` / `hasMore` 默认沿用当前值，空列表默认没有更多。需要服务端校准时再
`refresh()`。

```dart
// 详情返回后把刚看过的项置顶
final items = List<Gift>.of(controller.state.value.data ?? const <Gift>[]);
items
  ..removeWhere((gift) => gift.id == updated.id)
  ..insert(0, updated);
controller.replaceData(items);
```

### SmartRefresher 组合

分页 + `SmartRefresher` 的完整接线（首屏、下拉、筛选、footer 重试）见
[`docs/recipes/paged-list.md`](https://github.com/stone0533/w_tools/blob/main/docs/recipes/paged-list.md)。

首屏调 `refresh()`，不要 `requestRefresh()`；否则 header 和 sliver loading 会同时转圈。
下拉、筛选切换、重试都走同一个带 generation 的 `_refresh`，只让最新一次
`refreshCompleted()`：

```dart
int _refreshId = 0;

Future<void> _refresh() async {
  final id = ++_refreshId;
  await controller.refresh();
  if (id == _refreshId) refreshController.refreshCompleted();
}
```

SmartRefresher 自带 footer 的重试先 `requestLoading()`，`onLoading` 里再 `loadMore()`。
`state.isRefreshing` 只表示有旧数据时的刷新；首屏 / 重试用 `state.isLoading`。

## 全局默认视图与文案

```dart
WAsyncTheme(
  strings: const WAsyncStrings(
    empty: '暂无数据',
    errorTitle: '加载失败',
    retry: '重试',
    loading: '加载中',
  ),
  errorBuilder: (context, error, retry) => AppRetryView(error, retry),
  errorBannerBuilder: (context, error, retry) => AppErrorBanner(error, retry),
  loadingBuilder: (_) => const AppLoadingView(),
  emptyBuilder: (_) => const AppEmptyView(),
  child: MaterialApp(...),
)
```

推荐放在 App 根节点。`WAsyncTheme` 的普通 builder 只作用于 `WAsyncView`；自建滚动壳用 `WAsyncThemeViews` 复用：

默认 loading / empty / error 视图带 `liveRegion`，状态变化会被读屏播报；显式 / theme
builder 不会自动加语义，自定义视图需要自行保留 `Semantics`。

```dart
final views = WAsyncThemeViews.of(context);

WAsyncStateBuilder<List<Gift>>(
  state: controller.state,
  builder: (context, state) => SmartRefresher(
    onRefresh: controller.load,
    child: CustomScrollView(
      slivers: [
        ...state.when(
          loading: () => [SliverFillRemaining(child: views.loading(context))],
          empty: () => [SliverFillRemaining(child: views.empty(context))],
          failed: (error) => [
            SliverFillRemaining(
              child: views.error(context, error, controller.load),
            ),
          ],
          ready: (gifts) => [SliverList.builder(...)],
        ),
      ],
    ),
  ),
);
```

## Sliver

```dart
WAsyncStateSliver<List<Gift>>(
  state: controller.state,
  onRetry: controller.load, // 可选
  readySliverBuilder: (context, gifts) => SliverList.builder(...),
)
```

- 失败 + 旧数据：错误条在列表上方，ready 子树不因错误条出现/消失而重建；
- 刷新 + 旧数据：默认不额外加进度，避免和 `SmartRefresher` 重复；
- `onRetry == null`：不显示重试按钮；自定义 error / banner builder 仍会收到 `null`，
  需自行决定是否渲染按钮；
- 长列表滚动很深时错误条仍可能在视口外；需要常驻提示时用 `controller.onError`
  弹 toast，或用 `WAsyncStateBuilder` 在滚动壳外叠加错误条。

## 约定

- Controller 会把所有异常（含 `Error`）转为 `failed`，并回调 `WAsyncOptions.onError`；
- `WAsyncActivity` 只做并发活动计数，不是加载视图；
- 同一批并行任务可以共享 `WAsyncActivity`；不要用它合并多个独立区块。
- `WAsyncOptions.activity` 只用于 `WAsync` 直接执行；Controller 只接 `onError`；
- 默认文案来自 `WAsyncStrings`，项目应注入自己的本地化文案；
- `WAsyncState.status` 的类型是 `WAsyncStatus`（loading / ready / empty / failed）；优先 `when`，需要分支时直接 switch。
- 取消不会中止底层 Future，只是让等待尽快结束。

## 历史迁移

升级前先看 [`docs/migrations/`](https://github.com/stone0533/w_tools/blob/main/docs/migrations/README.md)：
每个包的 breaking 变更都有「旧 → 新」对照，不只是变更清单。
