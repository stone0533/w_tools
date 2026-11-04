# Async 模块

`w_tools_async` 负责异步执行、四态状态、Controller、分页与异步视图。

| 需求 | 入口 |
|------|------|
| 页面展示异步结果 | `WAsyncController` + `WAsyncView` |
| 观测 retry 失败 | `WAsyncView.onRetryError` / `WAsyncStateSliver.onRetryError` |
| 只执行、不要 UI | `WAsync` + `WAsyncResult` |
| 全 App 默认 loading / empty / error | `WAsyncTheme` |
| 滚动壳复用全局默认 | `WAsyncThemeViews.of(context)` |
| 刷新失败但保留旧数据 | `WAsyncErrorBanner` |
| 分页 | `WAsyncPagedController` |
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
| `onError` | `void Function(Object?)?` | 失败兜底回调 |

直接构造 options；5.0 删除 `copyWith`。`withoutActivity()` 仅去掉 activity。

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
| `parallel<T>` | 等待多个已启动 Future |
| `pool<T>` | 按并发上限执行任务工厂 |
| `first<T>` | 返回最先完成结果；空集合抛 `StateError` |
| `serial<T>` | 顺序执行 |

所有入口支持 `options` / `cancelToken`。

### 行为约定

- 业务异常与 `Error` 都由 `tryRun` 转为 `WAsyncFailure`；抛异常入口会重新抛出；
- 取消返回 `WAsyncCancelled`（或 `run` 抛 `WCancellationException`），不回调 `onError`；
- 取消是协作式的，不中止底层 Future；
- `parallel([])` / `serial([])` / `pool([])` 返回空列表并触发 activity；
- `first([])` 抛 `StateError`。

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

`data` 可读取旧数据；`when(...)` 四态全覆盖；`isRefreshing` 表示 loading + 旧数据。

## 3. Controller

### WAsyncController

```dart
final controller = WAsyncController.list(() => api.gifts());
await controller.load();
```

- 每次 `load` 取消上一次 token；
- 旧请求不会覆盖新请求；
- 失败保留旧数据；
- `withToken` 让 loader 拿到 `WCancelToken`。

### WAsyncPagedController

```dart
final paged = WAsyncPagedController<Gift>((page) => api.gifts(page: page));
await paged.refresh();
await paged.loadMore();
```

监听：

```text
state / isLoadingMore / loadMoreError / hasMoreListenable
```

`initialPage` 必须 >= 1；`initial: WAsyncState.ready([])` / `WAsyncState.empty()` 视为没有更多；`loadMore` 失败只写 `loadMoreError`，不清空列表。

## 4. View

| 视图 | 用途 |
|------|------|
| `WAsyncView` | 普通页面区块四态 |
| `WAsyncStateBuilder` | 自建滚动壳 |
| `WAsyncStateSliver` | `CustomScrollView` 四态 |
| `WAsyncErrorView` | 默认整块错误 |
| `WAsyncErrorBanner` | 保留旧数据时的错误条 |

- `WAsyncView.onRetry` 可选；无 retry 时不渲染按钮，也不调用自定义 error / banner builder；自定义 retry 失败用 `onRetryError` 观测；
- `WAsyncStateSliver.onRetry` 可选；无 retry 时不调用要求 retry 的自定义 builder；
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

当前 5.0.0；迁移见 [async-5.0](../migrations/async-5.0.md)。
