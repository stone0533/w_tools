# Async 模块

`w_tools_async` 负责异步执行、状态、Controller 与异步视图。`WAsync` 只管「怎么请求」，
`WAsyncState` 只管「界面该显示什么」。

| 需求 | 入口 |
|------|------|
| 页面展示异步结果 | `WAsyncController` + `WAsyncView` |
| 只执行、不要 UI | `WAsync` |
| 全 App 默认 loading / empty / error | `WAsyncTheme`（普通 + sliver 一套） |
| 刷新失败但保留旧数据 | `WAsyncErrorBanner` |

不要手写 `ValueNotifier<WAsyncState>`，也不要在每个页面重复 `when + RetryView`。

## 快速判断
- 页面区块 → `WAsyncController` + `WAsyncView`
- 滚动页 / SmartRefresher → `WAsyncStateBuilder`
- Sliver → `WAsyncStateSliver`
- 纯执行 → `WAsync`
- 不要手写 `ValueNotifier<WAsyncState>`
- 可运行示例：[packages/async/example](../../packages/async/example/README.md)

- 强制规则：根 [`AGENTS.md`](../../AGENTS.md)

## 模块结构

```text
packages/async/lib/
  w_tools_async.dart
  src/
    task/
      async_task.dart       # WAsync / WAsyncOptions
      async_loading.dart    # WAsyncLoading（并发 loading 合并）
      cancel_token.dart     # WCancelToken / WCancellationException
    state/
      async_state.dart      # WAsyncState / WAsyncStatus
      async_controller.dart # WAsyncController
      async_paged_controller.dart # WAsyncPagedController
    view/
      async_view.dart       # WAsyncView
      async_error_view.dart # WAsyncErrorView
      async_error_banner.dart # WAsyncErrorBanner
      async_view_defaults.dart
      async_state_builder.dart # WAsyncStateBuilder
      async_state_sliver.dart # WAsyncStateSliver
      async_sliver_defaults.dart # 旧入口（3.0 移除）
      async_theme.dart      # WAsyncTheme
```

## 1. WAsync - 异步编排

### 功能说明

统一封装异步任务的执行、重试、超时、并发控制，内置 Loading 状态合并与错误处理。

### 类与成员概览

#### WAsyncOptions（执行选项，纯数据）

| 成员 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `loading` | `WAsyncLoading?` | null | 需要合并并发 Loading 时传入；不传就不跟踪 |
| `onError` | `void Function(Object?)?` | null | 未传 `onError` 时的兜底错误回调 |

`copyWith` 用哨兵实现：传 `null` 可以清空字段。`WAsyncOptions` 没有转发方法，
执行入口只有 `WAsync`。

#### WAsyncLoading（并发 Loading 合并）

| 成员 | 说明 |
|------|------|
| `onStart` / `onEnd` | 活动数 0→1 / 1→0 时各触发一次 |
| `isLoading` | 当前是否有操作在执行 |
| `begin()` / `end()` | 框架内部使用，业务不要直接调用 |

把同一个实例放进 `WAsyncOptions.loading` 并传给多个调用，即可合并成一次 start/end；
**合并是显式的**，不再因为“共享配置”而隐式发生。

#### WAsyncState（四态快照）

| 状态 | 构造 | 说明 |
|------|------|------|
| `loading` | `WAsyncState.loading()` | 首次加载 |
| `ready` | `WAsyncState.ready(data)` | 有数据 |
| `empty` | `WAsyncState.empty()` | 加载成功但为空 |
| `failed` | `WAsyncState.failed(error)` | 加载失败 |

刷新场景用：

```dart
WAsyncState.loading(previousData: oldData)
WAsyncState.failed(error, previousData: oldData)
```

`isRefreshing` / `dataOrNull` 可读取旧数据；`when(...)` 四态全覆盖。

#### WAsync（静态类）

| 方法 | 签名 | 说明 |
|------|------|------|
| `run<T,R>` | `(task, {options, onSuccess, onError, cancelToken})` | 执行单个任务 |
| `retry<T,R>` | `(task, {options, onSuccess, onError, retryCount=3, retryDelay=1s, retryIf, cancelToken})` | 带重试执行 |
| `timeout<T,R>` | `(task, timeout, {options, ...})` | 带超时执行 |
| `parallel<T,R>` | `(futures, {options, onSuccess, onError, eagerError=true, cancelToken})` | 等待多个已启动的 Future |
| `pool<T,R>` | `(tasks, {options, onSuccess, onError, concurrency=4, cancelToken})` | 按并发上限执行任务工厂 |
| `first<T,R>` | `(futures, {options, ...})` | 返回第一个完成的结果，空集合返回 null |
| `serial<T,R>` | `(tasks, {options, ...})` | 顺序串行执行 |

### 行为说明

- **业务异常 vs 编程错误**：`Exception` 被捕获并回调 `onError`；`Error`（`TypeError`、`StateError` 等）向上抛出不拦截。
- **取消语义**：`WCancelToken.cancel()` 后任务返回 `null`，**不回调 onError**；取消是协作式的，任务内部需主动检查。
  `parallel` / `first` / `timeout` 在等待期间取消会立即返回；`run` / `serial` 在当前任务结束后响应。
- **Loading 合并**：多个并发任务共享同一个 `WAsyncLoading` 时只会触发一次 start/end；不传
  `options.loading` 就完全不跟踪。控制器自己维护四态，不会再触发 options 的 loading。
- **空集合**：`first([])` 直接返回 null，不进入 Loading；`parallel([])` / `serial([])` /
  `pool([])` 视为成功空结果，会触发 Loading。
- **并发取消**：`pool` 取消后不再启动新任务，但会等待当前在途任务结束后返回。

### 使用示例

```dart
// 基础执行
final loading = WAsyncLoading(
  onStart: () => setState(() => _loading = true),
  onEnd: () => setState(() => _loading = false),
);
final options = WAsyncOptions(loading: loading);

final result = await WAsync.run(
  () => fetchUserData(),
  options: options,
  onSuccess: (data) => print('成功: $data'),
  onError: (e) => print('失败: $e'),
);

// 带重试（固定 retryDelay）
final apiResult = await WAsync.retry(
  () => unstableApiCall(),
  retryCount: 3,
  retryDelay: const Duration(seconds: 1),
  retryIf: (e) => e is TimeoutException,
);

// 并发限流（最多 4 个同时运行）
final results = await WAsync.pool(
  [task1, task2, task3, task4, task5, task6],
  concurrency: 4,
);

// 取消任务
final cancelToken = WCancelToken();
WAsync.run(
  () => longRunningTask(cancelToken),
  cancelToken: cancelToken,
);
// 在需要时取消
cancelToken.cancel('用户主动取消');
```


---

## 2. WCancelToken - 取消令牌

### 功能说明

协作式取消的令牌对象。任务内需要主动检查 `isCancelled` 或调用 `throwIfCancelled()` 来响应取消请求。

### 成员方法

| 成员 | 类型 | 说明 |
|------|------|------|
| `isCancelled` | bool (getter) | 是否已取消 |
| `cancelReason` | Object? (getter) | 取消原因 |
| `cancel([reason])` | void | 触发取消 |
| `addListener(callback)` | void | 添加取消监听 |
| `removeListener(callback)` | void | 移除取消监听 |
| `throwIfCancelled()` | void | 若已取消则抛出 `WCancellationException` |
| `clearListeners()` | void | 清空所有监听 |

### 注意事项

**不可复用**：取消后令牌进入终态，后续新任务直接返回 null。如需再次执行请创建新实例。

### 使用示例

```dart
final token = WCancelToken();

// 添加监听
token.addListener((reason) {
  print('已取消: $reason');
});

// 任务内部检查
Future<void> longTask(WCancelToken token) async {
  for (var i = 0; i < 100; i++) {
    await Future.delayed(const Duration(milliseconds: 50));
    token.throwIfCancelled(); // 主动抛出异常响应取消
    print('进度: $i');
  }
}

// 取消
token.cancel('页面已销毁');
```

---


## 3. WAsyncState - 四态状态

```dart
enum WAsyncStatus { loading, ready, empty, failed }
```

```dart
WAsyncState<List<Gift>>.loading()
WAsyncState.ready(gifts)
WAsyncState.empty()
WAsyncState.failed(error, previousData: oldGifts)
```

- `loading(previousData:)` 用于刷新时保留旧数据；
- `isRefreshing` / `dataOrNull` 可读取旧数据；
- `when(...)` 四态全覆盖。

## 4. WAsyncController - 状态流转

```dart
final controller = WAsyncController.list(() => api.gifts());

WAsyncView<List<Gift>>(
  state: controller.state,
  onRetry: controller.load,
  readyBuilder: (context, gifts) => GiftList(gifts),
)
```

每个异步区块使用独立 controller；旧请求返回后不会覆盖新请求状态。

## 5. WAsyncView - 异步视图

```dart
WAsyncView<List<Gift>>(
  state: controller.state,
  onRetry: controller.load,
  readyBuilder: (context, data) => GiftList(data),
  emptyBuilder: (context) => const EmptyView(),
  errorBuilder: (context, error, retry) => RetryView(
    error: error,
    onRetry: retry,
  ),
)
```

默认行为：

- loading → `CircularProgressIndicator`；
- empty → 「暂无数据」；
- failed → `WAsyncErrorView` + 重试按钮；
- failed + 旧数据 → 保留内容 + `WAsyncErrorBanner`；
- refreshing → 保留内容 + 线性进度条。

`WAsyncView` 为错误条/刷新条约束有界宽度，不强制高度；滚动组件的高度由页面父级提供。

刷新进度条可通过 `WAsyncView.refreshingBuilder` / `WAsyncTheme.refreshingBuilder` 覆盖；
默认仍为 `LinearProgressIndicator`。

默认视图可通过 `WAsyncTheme` 在 App 根部统一配置（普通 + sliver）。
优先放在 `WAppOptions.appWrapper`（或消费方自建插件的 `wrapApp`），不要只放在 `AppScaffold.body`；
否则 AppBar actions、对话框、bottom sheet、Tab 页面不会继承默认值。

```dart
class AsyncDefaultsPlugin with WAppPlugin {
  @override
  String get name => 'async-defaults';

  @override
  Widget wrapApp(Widget child) {
    return WAsyncTheme(
      errorBuilder: ...,
      errorBannerBuilder: ...,
      sliverErrorBuilder: ...,
      child: child,
    );
  }
}
```



```dart
WAsyncTheme(
  loadingBuilder: (_) => const AppLoadingView(),
  emptyBuilder: (_) => const AppEmptyView(),
  errorBuilder: (context, error, retry) =>
      AppRetryView(error, retry),
  errorBannerBuilder: (context, error, retry) =>
      AppErrorBanner(error, retry),
  // sliver 视图用 sliver* 前缀，builder 必须返回非滚动内容
  sliverLoadingBuilder: (_) => const AppLoadingView(),
  child: MaterialApp(...),
)
```

`WAsyncTheme` 的普通 builder 只作用于 `WAsyncView`；`WAsyncStateBuilder` 不会读取它。

优先级：

```text
WAsyncView 显式 builder
  ↓
WAsyncTheme
  ↓
包内默认视图
```

默认视图通过 `WAsyncTheme` 在 App 根部统一配置；`errorBannerBuilder` 可单独覆盖刷新失败条。

`WAsyncController.state` 是只读的 `ValueListenable`，状态变更必须经过 `load()` / `retry()`；
可通过 `initial:` 指定初始状态。

Controller 会把所有异常（包括 `Error`）转为 failed，便于 UI 展示；它只丢弃旧请求结果，
不会中止已启动的底层 Future。需要区分业务异常与编程错误时使用 `WAsync`。

## WAsyncStateSliver

`WAsyncStateSliver` 负责 `CustomScrollView` 里的状态 sliver：

```dart
WAsyncStateSliver<List<Gift>>(
  state: controller.state,
  onRetry: controller.load,
  readySliverBuilder: (context, gifts) => WListViewSliver.list(...),
  emptyBuilder: (context) => ...,
  errorBuilder: (context, error, onRetry) => ...,
)
```

它会把四态统一成：

```text
ready                   → readySliverBuilder
loading / empty / failed → SliverFillRemaining
failed + 旧数据         → ready sliver + WAsyncErrorBanner
refreshing + 旧数据     → ready sliver；默认不添加进度，避免和 SmartRefresher 重复
```

`readySliverBuilder` 必须返回 sliver，不能返回 `ListView` / `Column`。
它始终用 `SliverMainAxisGroup`，所以状态切换不会重建 ready 子树。

## Sliver 默认视图

`WAsyncStateSliver` 的默认视图用 `WAsyncTheme` 的 `sliver*Builder`：

```dart
WAsyncTheme(
  sliverLoadingBuilder: (_) => const AppAsyncStatusLoading(),
  sliverEmptyBuilder: (_) => const AppAsyncStatusEmpty(),
  sliverErrorBuilder: (context, error, retry) => AppAsyncStatusError(error, retry),
  sliverErrorBannerBuilder: (context, error, retry) => AppErrorBanner(error, retry),
  child: MaterialApp(...),
)
```

- `sliverLoading/sliverEmpty/sliverError` builder 必须返回非滚动 Widget（会放进 `SliverFillRemaining(hasScrollBody: false)`）；
- `refreshingSliverBuilder` 必须返回 sliver；
- 普通视图与 sliver 共用同一个 `WAsyncTheme`，不要嵌套两个实例；
- 不要把 `AppRefreshable` / `SingleChildScrollView` 放进 sliver 状态。

## App 层固定滚动壳

`WAsyncStateBuilder → SmartRefresher → CustomScrollView` 建议在 App 层封装：

```dart
class AsyncRefreshShell<T> extends StatelessWidget {
  const AsyncRefreshShell({
    super.key,
    required this.state,
    required this.controller,
    required this.onRefresh,
    required this.onLoading,
    required this.slivers,
  });

  final ValueListenable<WAsyncState<T>> state;
  final RefreshController controller;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoading;
  final List<Widget> Function(BuildContext, WAsyncState<T>) slivers;

  @override
  Widget build(BuildContext context) {
    return WAsyncStateBuilder<T>(
      state: controller.state,
      builder: (context, value) {
        return SmartRefresher(
          controller: controller,
          onRefresh: onRefresh,
          onLoading: onLoading,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: slivers(context, value),
          ),
        );
      },
    );
  }
}
```

`w_tools_async` 不依赖 `pull_to_refresh`，所以这个 helper 放在 App 层。

## 分页控制器

`WAsyncPagedController` 负责首屏、刷新、追加和 `hasMore`：

```dart
final gifts = WAsyncPagedController<Gift>(
  (page) => api.gifts(page: page),
);

await gifts.refresh();
await gifts.loadMore();
```

- `state`：`WAsyncState<List<T>>`
- `isLoadingMore`：追加中
- `loadMoreError`：追加失败，不进入 `state.failed`
- `hasMore`：是否还有下一页；它是普通 getter，不是 `ValueListenable`
  footer 应同时监听 `isLoadingMore` / `loadMoreError` / `state`，不要只监听 `state`

`initial` 传 `WAsyncState.ready(data)` 表示第一页已经加载，下一次 `loadMore()`
会从 `initialPage + 1` 开始；`hasMore` 默认仍为 true，若 initial 已是最后一页，
调用方需要自行处理或 refresh。传 loading / empty 时仍从 `initialPage` 开始。

分页失败应该交给 `SmartRefresher` footer（`loadFailed`），不要用 `state.failed` 替换整个列表。

## 异步列表：WAsyncStateBuilder + SmartRefresher

滚动页面使用 `WAsyncStateBuilder`，让 `SmartRefresher` 的直接子节点始终是 `CustomScrollView`：

```dart
WAsyncStateBuilder<List<Gift>>(
  state: controller.state,
  builder: (context, state) {
    final gifts = state.dataOrNull ?? const <Gift>[];

    return SmartRefresher(
      controller: refreshController,
      onRefresh: controller.load,
      onLoading: loadMore,
      child: CustomScrollView(
        slivers: [
          if (state.isLoading && gifts.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('暂无数据')),
            )
          else if (state.isFailed && gifts.isEmpty)
            SliverFillRemaining(
              child: WAsyncErrorView(
                error: state.error!,
                onRetry: controller.load,
              ),
            )
          else
            SliverList.builder(
              itemCount: gifts.length,
              itemBuilder: (context, index) => GiftTile(gift: gifts[index]),
            ),
          if (state.isFailed && gifts.isNotEmpty)
            SliverToBoxAdapter(
              child: WAsyncErrorBanner(
                error: state.error!,
                onRetry: controller.load,
              ),
            ),
        ],
      ),
    );
  },
)
```

`WAsyncController` 负责首屏和整页刷新；`loadMore` 的追加与 footer 状态由业务侧维护，不要用 `WAsyncController.failed` 表示分页失败。

`WAsyncStateBuilder.builder` 必须始终返回同一个滚动壳：

```text
WAsyncStateBuilder
  → SmartRefresher
      → CustomScrollView
```

loading / empty / error 只能作为 `slivers` 内部的分支，不要在外层直接 return `Center` / `WAsyncErrorView`，否则 `SmartRefresher` 会被重新挂载。

`WAsyncView` 适合普通页面区块；滚动页面用 `WAsyncStateBuilder`，不要把 `SmartRefresher` 包在 `WAsyncView` 外面。

`WAsyncBuilder` 已删除（2.0）；用 `WAsyncStateBuilder`。
