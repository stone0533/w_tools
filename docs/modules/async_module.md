# Async 模块

`w_tools_async` 负责异步执行、四态状态、Controller、分页与异步视图。

| 需求 | 入口 |
|------|------|
| 页面展示异步结果 | `WAsyncController` + `WAsyncView` |
| 观测 retry 失败 | `WAsyncView.onRetryError` / `WAsyncStateSliver.onRetryError` |
| 只执行、不要 UI | `WAsync` + `WAsyncResult` |
| 独立区块并行、保留每个结果 | `WAsync.settle` |
| 单区块本地替换 / 乐观更新 | `WAsyncController.replaceData` |
| 全 App 默认 loading / empty / error | `WAsyncTheme` |
| 滚动壳复用全局默认 | `WAsyncThemeViews.of(context)` |
| 刷新失败但保留旧数据 | `WAsyncErrorBanner` |
| 分页 | `WAsyncPagedController` |
| 分页 footer 状态 | `WAsyncPagedFooterStatus` / `WAsyncPagedController.footerStatus` |
| Sliver | `WAsyncStateSliver` |

不要手写 `ValueNotifier<WAsyncState>`，也不要在每个页面重复 `when + RetryView`。

## 快速判断

- 页面区块 → `WAsyncController` + `WAsyncView`
- 滚动页 / `SmartRefresher` → `WAsyncStateBuilder`
- Sliver → `WAsyncStateSliver`
- 纯执行 → `WAsync.tryRun`（结果对象）或 `WAsync.run`（失败抛异常）
- 分页 → `WAsyncPagedController`
- 可运行示例：[packages/async/example](../../packages/async/example/README.md)
- 强制规则：根 [`AGENTS.md`](../../AGENTS.md)

## 模块结构

```text
packages/async/lib/
  w_tools_async.dart
  src/
    task/
      async_task.dart       # WAsync / WAsyncOptions
      async_result.dart     # WAsyncResult / Success / Failure / Cancelled
      async_activity.dart   # WAsyncActivity（并发活动计数）
      cancel_token.dart     # WCancelToken / WCancellationException
    state/
      async_state.dart      # WAsyncState / WAsyncStatus
      async_controller.dart # WAsyncController
      async_paged_controller.dart # WAsyncPagedController
    view/
      async_view.dart       # WAsyncView
      async_error_view.dart # WAsyncErrorView
      async_error_banner.dart # WAsyncErrorBanner
      async_strings.dart    # WAsyncStrings（文案）
      async_state_builder.dart # WAsyncStateBuilder
      async_state_sliver.dart # WAsyncStateSliver
      async_theme.dart      # WAsyncTheme
      async_theme_views.dart # WAsyncThemeViews
```

## 1. WAsync

### WAsyncOptions

| 成员 | 类型 | 说明 |
|------|------|------|
| `activity` | `WAsyncActivity?` | 需要合并并发活动时传入 |
| `onError` | `void Function(Object)?` | 失败兜底回调 |

直接构造 options；5.0 删除 `copyWith`。`withoutActivity()` / `withoutOnError()` 分别只去掉 activity / onError。

### WAsyncActivity

| 成员 | 说明 |
|------|------|
| `onStart` / `onEnd` | 活动数 0→1 / 1→0 时各触发一次 |
| `isLoading` | 当前是否有操作 |
| `begin()` / `end()` | 框架内部使用 |

它不是加载视图，只是并发计数。

### WAsync 执行入口

不抛异常：

```dart
final result = await WAsync.tryRun(() => api.gift(id));
switch (result) {
  case WAsyncSuccess(:final value): ...
  case WAsyncFailure(:final error, :final stackTrace): ...
  case WAsyncCancelled(:final reason): ...
}
```

抛异常：

| 方法 | 说明 |
|------|------|
| `run<T>` | 返回成功值；失败抛原始异常，取消抛 `WCancellationException` |
| `map<T,R>` | 执行并映射成功值 |
| `retry<T>` | 重试后返回成功值 |
| `timeout<T>` | 超时抛 `TimeoutException` |
| `parallel<T>` | 等待多个已启动 Future（all-or-nothing） |
| `settle<T>` | 并发执行任务工厂，等待全部结束并保留每个 `WAsyncResult` |
| `pool<T>` | 按并发上限执行任务工厂 |
| `first<T>` | 返回最先完成结果；空集合抛 `StateError` |
| `serial<T>` | 顺序执行 |

所有入口支持 `options` / `cancelToken`。

### 行为约定

- 业务异常与 `Error` 都由 `tryRun` 转为 `WAsyncFailure`；抛异常入口会重新抛出；
- 取消返回 `WAsyncCancelled`（或 `run` 抛 `WCancellationException`），不回调 `onError`；
- 取消与失败同轮竞态时，非 `Error` 的失败按取消处理；`Error` 仍作为 `WAsyncFailure`，
  避免吞掉编程错误；
- 取消是协作式的，不中止底层 Future；
- `parallel([])` / `serial([])` / `pool([])` 返回空列表并触发 activity；
- `first([])` 抛 `StateError`；
- `retryCount` 是重试次数（总尝试 = `retryCount + 1`）；`retryDelayBuilder` 可按失败次数
  生成退避，`onRetry` 观测每次重试且自身异常被忽略。

### 示例

```dart
final activity = WAsyncActivity(
  onStart: () => setState(() => _loading = true),
  onEnd: () => setState(() => _loading = false),
);
final options = WAsyncOptions(activity: activity);

final user = await WAsync.run(() => fetchUser(), options: options);
final name = await WAsync.map(() => fetchUser(), onSuccess: (u) => u.name);

final result = await WAsync.tryRun(() => unstableApi());
if (result is WAsyncFailure) log(result.error, result.stackTrace);

await WAsync.retry(
  () => submitOrder(),
  retryCount: 3,
  retryDelayBuilder: (attempt) =>
      Duration(milliseconds: 200 * (1 << (attempt - 1))),
  onRetry: (attempt, error, delay) => log('retry #$attempt: $error'),
);
```

## 2. WAsyncState

| 状态 | 构造 | 说明 |
|------|------|------|
| loading | `WAsyncState.loading()` | 首次加载 |
| ready | `WAsyncState.ready(data)` | 有数据 |
| empty | `WAsyncState.empty()` | 成功但为空 |
| failed | `WAsyncState.failed(error)` | 失败 |

刷新保留旧数据：

```dart
WAsyncState.loading(previousData: oldData)
WAsyncState.failed(error, previousData: oldData)
```

`data` 可读取旧数据；`when(...)` 四态全覆盖；`isRefreshing` 表示 loading + 旧数据
（首屏 loading 为 false；判断是否在加载用 `isLoading`）。
`WAsyncState.list(...)`（旧名 `ofList`，已 deprecated）把 null / 空列表转为 empty，与
`WAsyncController.list` 对称；但它**不复制、不包装**输入列表，需要不可变 data 时用
`WAsyncController.list` 或自己传 `List.unmodifiable(...)`。

`WAsyncState` 的相等性按字段 `==` 比较；`data` 是列表时按引用比较，不是深比较。

## 3. Controller

### WAsyncController

```dart
final controller = WAsyncController.list(
  () => api.gifts(),
  onError: (error) => log(error),
);
await controller.load();
```

- 每次 `load` 取消上一次 token；
- 旧请求不会覆盖新请求；
- 失败保留旧数据；
- `withToken` 让 loader 拿到 `WCancelToken`；`listWithToken` 同时保留空列表 → empty、
  `state.data` unmodifiable；
- `replaceData` 做单区块本地替换：取消在飞 `load`，旧结果不写回；空数据进 empty；
- Controller 只接 `onError`；activity 只在 `WAsync` 上用；
- `WAsyncController.list` / `WAsyncPagedController` 的 `state.data` 是 unmodifiable；泛型 `WAsyncController` 原样保存。

```dart
final controller = WAsyncController.listWithToken(
  (token) => api.gifts(cancelToken: token),
);

controller.replaceData(localItems); // 本地替换；需要服务端校准再 load()
```

### WAsyncPagedController

```dart
final paged = WAsyncPagedController<Gift>((page) => api.gifts(page: page));
await paged.refresh();
await paged.loadMore();
```

第一页不足一页 / 服务端有 `total` 时用 `withPage` 显式返回 `hasMore`，避免多发一次空页请求：

```dart
final paged = WAsyncPagedController<Gift>.withPage((page) async {
  final resp = await api.gifts(page: page, limit: 10);
  return WAsyncPage(
    items: resp.list,
    hasMore: resp.total == null ? resp.list.length >= 10 : page * 10 < resp.total!,
  );
});
```

监听：

```text
state / isLoadingMore / loadMoreError / hasMoreListenable
```

只挂一个监听时用 `changes`（合并以上四项）；需要细粒度重建时仍用上面的单项。
追加使用 chunked 不可变列表（结构共享），不会每页复制整表；`state.data` 仍是 `List<T>`。

页号：

- `page` 是**下一次 `loadMore` 将请求的页码**，首屏完成前等于 `initialPage`；刷新失败保留刷新前的页码。
- `hasLoadedMoreThanOnePage`（`page > initialPage + 1`）表示已成功追加过第二页，
  用它区分「首屏还没翻过页」和「已翻过页、现在没有更多了」；不要用 `state.data.length` 变大去猜。
#### 分页 footer 状态

- `footerStatus` 直接给出 footer 状态：`hidden` / `loading` / `failed` / `noMore` / `loadMore`；
  它是普通 getter，不通知，footer 用 `changes` 重建。

`initialPage` 必须 >= 1；`initial: WAsyncState.ready([])` / `WAsyncState.empty()` 视为没有更多；`loadMore` 失败只写 `loadMoreError`，不清空列表。

切换筛选 / 搜索直接再调 `refresh()`：在飞刷新会被取消，旧结果不写回；不需要禁用筛选。
本地替换 / 乐观更新用 `replaceData`：会取消在飞 `refresh` / `loadMore`，`page` / `hasMore`
默认沿用当前值，空列表默认没有更多；需要服务端校准再 `refresh()`。

SmartRefresher 组合（首屏、generation、footer 重试）见
[`docs/recipes/paged-list.md`](../recipes/paged-list.md)；首屏用 `refresh()`，所有 refresh
入口统一走同一个 generation helper，只让最新一次 `refreshCompleted()`。

## 4. View

| 视图 | 用途 |
|------|------|
| `WAsyncView` | 普通页面区块四态 |
| `WAsyncStateBuilder` | 自建滚动壳 |
| `WAsyncStateSliver` | `CustomScrollView` 四态 |
| `WAsyncErrorView` | 默认整块错误 |
| `WAsyncErrorBanner` | 保留旧数据时的错误条 |

- `WAsyncView.onRetry` 可选；无 retry 时不渲染按钮，但自定义 error / banner builder 仍会收到 `null`，由 builder 决定是否渲染按钮；自定义 retry 失败用 `onRetryError` 观测；
- `WAsyncStateSliver.onRetry` 可选；无 retry 时自定义 builder 仍会收到 `null`；
- `WAsyncStateSliver` 的 failed + 旧数据错误条在列表上方，ready 子树不重建；
- `WAsyncView` 的 refreshing / errorBanner 是**内容盒** overlay，不一定是视口：作为
  `Scaffold.body` / `Expanded` 等紧约束时填满视口，作为 `Column` 子项 / `ListView` item
  时只包住内容；需要固定到视口时外层给有界高度，或用 `WAsyncStateBuilder` 自建滚动壳；
- 长列表深滚动时顶部错误条可能在视口外：用 `onError` toast 或 `WAsyncStateBuilder` overlay；
- 默认文案由 `WAsyncStrings` 提供，通过 `WAsyncTheme.strings` 注入本地化。

## 5. Theme

```dart
WAsyncTheme(
  strings: const WAsyncStrings(empty: '暂无数据', errorTitle: '加载失败', retry: '重试'),
  loadingBuilder: (_) => const AppLoadingView(),
  emptyBuilder: (_) => const AppEmptyView(),
  errorBuilder: (context, error, retry) => AppRetryView(error, retry),
  errorBannerBuilder: (context, error, retry) => AppErrorBanner(error, retry),
  child: MaterialApp(...),
)
```

普通 builder 只作用于 `WAsyncView`；sliver builder 以 `sliver*` 前缀区分。

自建滚动壳复用默认视图：

```dart
final views = WAsyncThemeViews.of(context);
```

## 6. 测试与版本

```bash
cd packages/async
flutter test
```

当前 6.5.0；迁移见 [async-6.0](../migrations/async-6.0.md)。
