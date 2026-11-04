# w_tools_async

w_tools 的异步层：执行、四态状态、Controller、分页与可复用异步视图。

```text
页面展示异步结果  → WAsyncController + WAsyncView
只执行、不要 UI   → WAsync + WAsyncResult
全 App 默认视图   → WAsyncTheme
```

## 安装

```yaml
dependencies:
  w_tools_async: ^5.0.0
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
| 并发活动回调 | `WAsyncActivity`（只传给 `WAsyncOptions`，不要手动 begin/end） |
| 让 loader 感知取消 | `WAsyncController.withToken` / `WAsyncPagedController.withToken` |
| 四态快照 | `WAsyncState` / `WAsyncStatus` |

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

- 失败抛原始 error / stack；
- 取消抛 `WCancellationException`；
- `WAsync` 不再用 `null` 表示失败或取消。

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

## 取消

控制器默认不接收 token；需要请求层感知取消时用 `withToken`：

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

## 分页

```dart
final controller = WAsyncPagedController<Gift>((page) => api.gifts(page: page));

await controller.refresh();
await controller.loadMore();
```

监听：

```text
controller.state
controller.isLoadingMore
controller.loadMoreError
controller.hasMoreListenable
```

`loadMore` 失败只写 `loadMoreError`，不会清空已有列表。

## 全局默认视图与文案

```dart
WAsyncTheme(
  strings: const WAsyncStrings(
    empty: '暂无数据',
    errorTitle: '加载失败',
    retry: '重试',
  ),
  errorBuilder: (context, error, retry) => AppRetryView(error, retry),
  errorBannerBuilder: (context, error, retry) => AppErrorBanner(error, retry),
  loadingBuilder: (_) => const AppLoadingView(),
  emptyBuilder: (_) => const AppEmptyView(),
  child: MaterialApp(...),
)
```

推荐放在 App 根节点。`WAsyncTheme` 的普通 builder 只作用于 `WAsyncView`；自建滚动壳用 `WAsyncThemeViews` 复用：

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

- 失败 + 旧数据：保留 ready sliver，追加错误条；
- 刷新 + 旧数据：默认不额外加进度，避免和 `SmartRefresher` 重复；
- `onRetry == null`：不显示重试按钮，也不调用要求 retry 的自定义 error / banner builder。

## 约定

- Controller 会把所有异常（含 `Error`）转为 `failed`，并回调 `WAsyncOptions.onError`；
- `WAsyncActivity` 只做并发活动计数，不是加载视图；
- `WAsyncOptions.activity` 只用于 `WAsync` 直接执行；Controller 自己维护四态，传了会断言；
- 默认文案来自 `WAsyncStrings`，项目应注入自己的本地化文案；
- 取消不会中止底层 Future，只是让等待尽快结束。
