# Async 模块

`w_tools_async` 负责异步执行、四态状态、Controller、分页与异步视图。

- 页面区块：`WAsyncController` + `WAsyncView`。
- 纯执行：`WAsync.tryRun` / `WAsync.run` / `WAsync.retry` / `WAsync.timeout` / `WAsync.settle`。
- 分页：`WAsyncPagedController` + `WAsyncPagedSnapshot`。
- 全局默认视图：`WAsyncTheme`。

## 快速判断

| 需求 | 入口 |
| --- | --- |
| 页面区块四态 | `WAsyncController` + `WAsyncView` |
| 滚动页 | `WAsyncView`（滚动组件放进 `readyBuilder`） |
| Sliver | `WAsyncStateSliver` |
| 分页 | `WAsyncPagedController` |
| 分页 footer 状态 | `WAsyncPagedSnapshot.footerStatus` |
| 纯执行，不抛异常 | `WAsync.tryRun` |
| 纯执行，失败抛异常 | `WAsync.run` |
| 重试 / 超时 | `WAsync.retry` / `WAsync.timeout` |
| 独立区块并行，保留每个结果 | `WAsync.settle` |
| 全局默认 loading / empty / error | `WAsyncTheme` / `WAsyncStrings` |

## 模块结构

```text
lib/src/task/
  async_task.dart       # WAsync 执行入口
  async_result.dart     # WAsyncResult / Success / Failure / Cancelled
  cancel_token.dart     # WCancelToken / WCancellationException
lib/src/state/
  async_state.dart      # WAsyncState / WAsyncStatus
  async_controller.dart # WAsyncController
  async_paged_controller.dart # WAsyncPagedController / WAsyncPage / WAsyncPagedSnapshot
lib/src/view/
  async_view.dart       # WAsyncView
  async_state_sliver.dart # WAsyncStateSliver
  async_theme.dart      # WAsyncTheme
  async_theme_views.dart # 默认视图解析（内部）
  async_strings.dart / async_error_view.dart / async_error_banner.dart
```

## 1. WAsync

`WAsync` 不依赖 Widget；没有 UI 状态时直接用。

### 执行入口

| 方法 | 语义 |
| --- | --- |
| `tryRun` | 返回 `WAsyncResult`，不抛业务异常 |
| `run` | 返回成功值；失败抛原始异常 |
| `retry` | 重试后返回成功值；最终失败抛异常 |
| `timeout` | 超时抛 `TimeoutException` |
| `settle` | 并发执行任务工厂，单个失败不抛错，每个结果按输入顺序返回 |

普通并发直接用 `Future.wait` / `Future.any`；本包只保留和「多区块页面」直接相关的入口。

参数错误（`concurrency < 1`、负数的 `retryCount` / `retryDelay` / `timeout`）以失败的
Future 返回 `ArgumentError`。

### 结果

```dart
final result = await WAsync.tryRun(() => api.gift(id));
switch (result) {
  case WAsyncSuccess(:final value): use(value);
  case WAsyncFailure(:final error, :final stackTrace): log(error, stackTrace);
  case WAsyncCancelled(:final reason): log('cancelled: $reason');
}
```

- `WAsyncFailure.isProgrammingError` 区分 `Error`（TypeError / StateError）与业务异常；
- `onError` 只是失败通知，不改变返回值，也不会吞 `run` / `retry` / `timeout` 的异常；
- `onError` / `onRetry` 自身抛错会被忽略，不影响主流程。

### 取消

`WCancelToken` 是协作式取消：在开始、结束、重试等待等边界检查；不会中止已经开始执行的
Future。取消后不可复用。

取消与失败在同一轮竞态时，非 `Error` 的失败按取消处理；`Error` 仍返回 `WAsyncFailure`，
避免把编程错误吞成取消。完整示例见 [README 的「取消」](../../packages/async/README.md#取消)。

### 示例

```dart
final value = await WAsync.run(() => api.fetch());
final results = await WAsync.settle<Section>([
  () => api.banners(),
  () => api.columns(),
]);
await WAsync.retry(
  () => api.submit(),
  retryCount: 3,
  retryDelayBuilder: (attempt) => Duration(milliseconds: 200 * (1 << (attempt - 1))),
);
```

## 2. WAsyncState

四态快照：`loading` / `ready` / `empty` / `failed`。约定：

- 首次请求发出前是 `loading`，不能用 `empty` 占位；
- 请求成功但结果为空才是 `empty`；
- 请求失败是 `failed`，与「没有数据」是两种状态；
- 已有数据时刷新失败用 `failed` + `previousData` 保留旧数据。

```dart
state.when(
  loading: () => ...,
  ready: (data) => ...,
  empty: () => ...,
  failed: (error) => ...,
);
state.status; state.data; state.error;
state.isRefreshing; // loading 且有旧数据
```

`WAsyncState.list(items)` 把 null / 空列表转为 `empty`，但不复制、不包装输入列表；
需要不可变 data 用 `WAsyncController.list` 或 `List.unmodifiable`。
相等性是字段浅比较，列表按引用比较。

## 3. Controller

### WAsyncController

一个区块一个 Controller。loader 统一接收 `WCancelToken`；不需要取消时写 `(_) => ...`。

```dart
final controller = WAsyncController<List<Gift>>((_) => api.gifts());
await controller.load();
controller.replaceData(const [Gift('local')]);
controller.dispose();
```

- `load()` 会取消上一次请求；旧请求返回后不会覆盖新状态；
- `state.data` 为列表时，`WAsyncController.list` 会包成 unmodifiable；
- `replaceData` 会取消在飞 `load`，旧结果不写回；
- `onError` 只是失败兜底通知，四态仍由 Controller 维护。

### WAsyncPagedController

loader 统一返回 `WAsyncPage`：

```dart
final paged = WAsyncPagedController<Gift>((page, token) async {
  final resp = await api.gifts(page: page, token: token);
  return WAsyncPage<Gift>(
    items: resp.list,
    hasMore: resp.total == null ? null : page * 20 < resp.total,
  );
});
await paged.refresh();
await paged.loadMore();
```

- `refresh()` 重新加载第一页；刷新在飞时再次调用会取消旧请求，旧结果不写回；
- `loadMore()` 只追加，失败只写 `snapshot.loadMoreError`，不清空列表；
- `hasMore` 为 null 时「本页非空即还有更多」；
- `replaceData(data, {bool? hasMore})` 会取消在飞 refresh / loadMore；
- 观察入口只有两个：`state`（四态，喂给 `WAsyncView`）与 `snapshot`（分页状态）。

#### 分页 footer 状态

`WAsyncPagedSnapshot` 是分页的唯一观察快照：

```dart
final footer = controller.snapshot.value;
footer.state;          // WAsyncState<List<T>>
footer.footerStatus;   // hidden / loading / failed / noMore / loadMore
footer.loadMoreError;  // 最近一次追加失败
footer.hasMore;
footer.isLoadingMore;  // footerStatus == loading
```

footer 用 `AnimatedBuilder(animation: controller.snapshot)` 重建。派生规则：

- 还没有数据（首屏 loading / empty / 整页 failed）→ `hidden`；
- `loadMoreError` 非空 → `failed`；
- 正在追加 → `loading`；
- 没有更多：成功翻过页 → `noMore`，第一页就到底 → `hidden`；
- 其余 → `loadMore`。

## 4. View

`WAsyncView` 渲染四态：

```dart
WAsyncView<List<Gift>>(
  state: controller.state,
  onRetry: controller.load,
  readyBuilder: (context, gifts) => GiftList(gifts),
);
```

- `onRetry` 为 `VoidCallback?`；为 null 时默认错误视图不渲染按钮；
- 每视图可覆盖 `loadingBuilder` / `emptyBuilder` / `errorBuilder` /
  `errorBannerBuilder` / `refreshingBuilder`，未传时回退到 `WAsyncTheme`；
- refreshing / errorBanner：宽高都有界时占固定槽，内容让位；任一维无界时是内容盒 overlay；
- ready / refreshing / failed + 旧数据共用同一层容器，状态切换不重建 `readyBuilder` 子树；
- 默认错误视图只显示标题，不渲染异常原文；需要详情用 `errorBuilder`。

`WAsyncStateSliver` 用于 `CustomScrollView`：

- ready → `readySliverBuilder`；
- loading / empty / failed（无数据）→ `SliverFillRemaining`；
- failed + 旧数据 → 错误条（列表上方）+ ready sliver；
- refreshing + 旧数据 → ready sliver，刷新进度由外层 `SmartRefresher` 负责；
- 始终返回同一个 `SliverMainAxisGroup`，ready 子树不会被重建。

`readySliverBuilder` 必须返回 sliver；loading / empty / error 的 theme builder 返回普通
Widget（不是 sliver），组件会自己包 `SliverFillRemaining`。

## 5. Theme

`WAsyncTheme` 放在 App 根部，统一默认视图与文案：

```dart
WAsyncTheme(
  strings: const WAsyncStrings(empty: '暂无数据', retry: '重试'),
  loadingBuilder: (_) => const AppLoadingView(),
  errorBuilder: (context, error, retry) => AppRetryView(retry),
  child: app,
);
```

| 字段 | 作用 |
| --- | --- |
| `loadingBuilder` / `emptyBuilder` | 普通视图与 sliver 共用的 loading / empty |
| `errorBuilder` / `errorBannerBuilder` | 整块错误 / 刷新失败错误条 |
| `refreshingBuilder` | 刷新进度 |
| `strings` | `WAsyncStrings` 文案 |

同一组 builder 同时作用于 `WAsyncView` 与 `WAsyncStateSliver`；builder 必须返回**非滚动**
Widget（不是 sliver，也不要返回 `ListView` / `CustomScrollView`）；需要滚动内容时用
`readyBuilder` / `readySliverBuilder`。
包内默认视图带 `liveRegion`；显式 / 主题 builder 不会自动加语义，自定义视图要自己保留。

## 6. 测试与版本

```bash
cd packages/async
flutter test
```

当前 7.0.0；迁移见 [async-7.0](../migrations/async-7.0.md)。
