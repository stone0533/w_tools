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
  w_tools_async: ^7.0.1
```

要求 Flutter 3.38+。

从 6.x 升级：见 [docs/migrations/async-7.0.md](https://github.com/stone0533/w_tools/blob/main/docs/migrations/async-7.0.md)。

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
    _gifts = WAsyncController.list((_) => api.gifts());
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
`errorBannerBuilder` / `refreshingBuilder`；未传时回退到 `WAsyncTheme` 的默认视图。

滚动页面把滚动组件放进 `readyBuilder`：

```dart
WAsyncView<List<Gift>>(
  state: controller.state,
  readyBuilder: (context, gifts) => SmartRefresher(
    onRefresh: controller.load,
    child: ListView(...),
  ),
);
```

完整可运行示例：[`example/`](example/README.md)（四态、分页、Sliver、执行、真实场景）。

## 主要 API

| 场景 | 入口 |
| --- | --- |
| 页面区块四态 | `WAsyncController` / `WAsyncView` |
| 滚动页 | `WAsyncView`（滚动组件放进 `readyBuilder`） |
| `CustomScrollView` 的 sliver 四态 | `WAsyncStateSliver` |
| 分页 | `WAsyncPagedController` / `WAsyncPagedSnapshot` |
| 全局默认视图 / 文案 | `WAsyncTheme` / `WAsyncStrings` |
| 无 UI 执行，不抛异常 | `WAsync.tryRun` + `WAsyncResult` |
| 无 UI 执行，失败抛异常 | `WAsync.run` / `retry` / `timeout` |
| 独立区块并行，保留每个结果 | `WAsync.settle` |
| 让 loader 感知取消 | Controller 的 loader 接收 `WCancelToken` |
| 单区块本地替换 / 乐观更新 | `WAsyncController.replaceData` |
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
```

> `onError` 只是失败**通知**，不会吞异常。`run` / `retry` / `timeout` 失败仍会抛；
> `.then` 必须同时给 `onError` / `catchError`，否则会有 unhandled Future。

```dart
// 要保留 run 的抛异常语义：给 .then 传 onError
WAsync.run(() => api.gift(id), onError: (error) => log(error)).then(
  (gift) => use(gift),
  onError: (Object error, StackTrace stack) {
    // onError 已经提示过；这里只消费掉 Future 的异常
  },
);

// 或者不抛：tryRun + WAsyncResult
final result = await WAsync.tryRun(() => api.gift(id));
```

- 失败抛原始 error / stack；
- 取消抛 `WCancellationException`；
- `onError` / `onRetry` 自身异常会被忽略，不影响主流程；
- 只有 token 取消才算 `WAsyncCancelled`；任务自己抛 `WCancellationException` 仍算失败；
- 失败与取消同轮竞态：非 `Error` 按取消处理，`Error` 仍返回 failure。

不再提供 `WAsync.map` / `parallel` / `pool` / `serial` / `first`：并发直接用
`Future.wait` / `Future.any`，限流用 `settle(concurrency:)`。

## 独立区块并行

`settle` 只处理任务工厂，单个失败不会让整批抛错，结果顺序与输入一致：

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

`onError` 按失败任务逐个通知；共享的取消 token 会让未开始 / 进行中的任务以
`WAsyncCancelled` 结束。

## 重试与超时

```dart
final order = await WAsync.retry(
  () => api.createOrder(),
  retryCount: 3,
  retryDelayBuilder: (attempt) => Duration(milliseconds: 200 * (1 << (attempt - 1))),
  onRetry: (attempt, error, delay) => log('retry #$attempt in $delay'),
  retryIf: (error) => error is Exception,
);
```

- `retryCount` 是重试次数，总尝试 = `retryCount + 1`；
- `retryDelayBuilder` 优先于 `retryDelay`，返回负值抛 `ArgumentError`；
- `retryIf` 返回 false 时只尝试一次；`onRetry` 自身异常被忽略。

```dart
final gift = await WAsync.timeout(() => api.gift(id), const Duration(seconds: 5));
```

超时不会中止底层 Future，只是让等待提前结束。

## 取消

```dart
final token = WCancelToken();
final result = await WAsync.tryRun(
  () => api.fetch(cancelToken: token),
  cancelToken: token,
);
token.cancel('page disposed');
```

取消是协作式的：在开始、结束、重试等待等边界检查；不会中止已经开始执行的 Future。
令牌取消后不可复用。

## 四态状态

```dart
const WAsyncState.loading();          // 首次请求中
const WAsyncState.ready(data);        // 有数据
const WAsyncState.empty();            // 已加载但没有数据
const WAsyncState.failed(error);      // 失败
const WAsyncState.loading(previousData: old); // 刷新中，保留旧数据
const WAsyncState.failed(error, previousData: old); // 刷新失败，保留旧数据
```

```dart
state.isLoading; state.isReady; state.isEmpty; state.isFailed;
state.isRefreshing; // loading 且有旧数据
state.when(loading: ..., ready: ..., empty: ..., failed: ...);
```

`WAsyncState.list(list)` 把 null / 空列表转为 `empty`，不复制输入列表；需要不可变 data
用 `WAsyncController.list` 或 `List.unmodifiable`。相等性是字段浅比较，列表按引用比较。

## Controller

```dart
final controller = WAsyncController<Gift>((_) => api.gift(id));
await controller.load();
controller.replaceData(localGift); // 取消在飞 load，旧结果不写回
controller.state;                  // ValueListenable<WAsyncState<Gift>>
controller.dispose();
```

- loader 统一接收 `WCancelToken`；不需要取消时写 `(_) => ...`；
- `load()` 会取消上一次请求，旧请求返回后不会覆盖新状态；
- `WAsyncController.list` 额外保留空列表 → empty、`state.data` unmodifiable；
- `onError` 只是失败兜底通知，四态由 Controller 维护；
- `replaceData` 之后需要服务端为准时再 `load()`。

## 分页

```dart
final controller = WAsyncPagedController<Gift>((page, token) async {
  final resp = await api.gifts(page: page, token: token);
  return WAsyncPage<Gift>(
    items: resp.list,
    hasMore: resp.total == null ? null : page * 20 < resp.total,
  );
});
await controller.refresh();
await controller.loadMore();
```

- `hasMore` 为 null 时「本页非空即还有更多」；
- `loadMore` 失败只写 `snapshot.loadMoreError`，不会清空已有列表；
- 刷新在飞时再次 `refresh()` 会取消旧请求，旧结果不写回；
- `replaceData(data, {bool? hasMore})` 会取消在飞 refresh / loadMore；
- `WAsyncPagedController.list` 是「本页非空即有更多」的便捷构造。

看分页状态只读 `snapshot`：

```dart
final footer = controller.snapshot.value;
footer.state;          // 喂给 WAsyncView
footer.footerStatus;   // hidden / loading / failed / noMore / loadMore
footer.loadMoreError;
footer.hasMore;
footer.isLoadingMore;

AnimatedBuilder(
  animation: controller.snapshot,
  builder: (context, _) {
    final status = controller.snapshot.value.footerStatus;
    return switch (status) {
      WAsyncPagedFooterStatus.hidden => const SizedBox.shrink(),
      WAsyncPagedFooterStatus.loading => const Text('加载中'),
      WAsyncPagedFooterStatus.failed => TextButton(
          onPressed: controller.loadMore,
          child: const Text('重试'),
        ),
      WAsyncPagedFooterStatus.noMore => const Text('没有更多'),
      WAsyncPagedFooterStatus.loadMore => TextButton(
          onPressed: controller.loadMore,
          child: const Text('加载更多'),
        ),
    };
  },
);
```

派生规则：

- 还没有数据（首屏 loading / empty / 整页 failed）→ `hidden`；
- `loadMoreError` 非空 → `failed`；
- 正在追加 → `loading`；
- 没有更多：成功翻过页 → `noMore`，第一页就到底 → `hidden`；
- 其余 → `loadMore`。

`controller.state` 是只读 adapter，直接传给 `WAsyncView`；footer 变化不会触发
`readyBuilder` 重建。

## Sliver

```dart
CustomScrollView(
  slivers: [
    WAsyncStateSliver<List<Gift>>(
      state: controller.state,
      onRetry: controller.load,
      readySliverBuilder: (context, gifts) => SliverList.builder(...),
    ),
  ],
);
```

- `readySliverBuilder` 必须返回 sliver；
- loading / empty / failed 用 `SliverFillRemaining`；
- failed + 旧数据时错误条在列表上方；ready 子树保持同一 element；
- refreshing 默认不额外加进度，交给外层 `SmartRefresher`。

## 主题

```dart
WAsyncTheme(
  strings: const WAsyncStrings(empty: '暂无数据', retry: '重试'),
  loadingBuilder: (_) => const AppLoadingView(),
  emptyBuilder: (_) => const AppEmptyView(),
  errorBuilder: (context, error, retry) => AppRetryView(retry),
  errorBannerBuilder: (context, error, retry) => AppErrorBanner(retry),
  refreshingBuilder: (_) => const LinearProgressIndicator(),
  child: app,
);
```

同一组 builder 同时作用于 `WAsyncView` 与 `WAsyncStateSliver`；builder 必须返回**非滚动**
Widget（不是 sliver，也不要返回 `ListView` / `CustomScrollView`），sliver 组件会自己包
`SliverFillRemaining` / `SliverToBoxAdapter`。需要滚动内容时用 `readyBuilder` /
`readySliverBuilder`，不要塞进 loading / error。
显式 builder 优先于主题；包内默认视图带 `liveRegion`，自定义视图要自己保留语义。

默认错误视图只显示标题，**不渲染异常原文**；错误详情走 `onError` / 日志，或自定义
`errorBuilder` / `errorBannerBuilder` 展示（自己确认脱敏，不要在 UI 里直接 `'$error'`）。

```dart
final controller = WAsyncController<Gift>(
  (_) => api.gift(),
  onError: (error) => logger.e(error), // 详情只进日志，不上屏
);
```

## 行为约定

- `WAsyncView` 的 refreshing / errorBanner：宽高都有界时占固定槽，内容让位；普通内容保持
  自身高度，滚动内容拿满可用高度；任一维无界（`Column` 子项 / `ListView` item / `Row`）时
  是内容盒 overlay；需要固定到视口请外层给有界高度。
- `WAsyncView` 的 `state` 是 `ValueListenable`，不是 `Rx`：页面里其它 Rx 状态（筛选条件、
  倒计时）上的 `Obx` 仍需保留。
- `WAsyncState` 是状态载体，`WAsyncStatus` 是封闭枚举，`WAsyncResult` 是执行结果，
  `WAsyncPagedSnapshot` 是分页快照，四者不要混用。
- 默认 loading / empty / error 视图带 `liveRegion`；显式 / theme builder 不自动加语义。
- 错误详情走日志 / `onError`，不要直接展示给终端用户。
