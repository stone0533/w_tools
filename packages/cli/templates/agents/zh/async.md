- **异步区块**：页面统一 `WAsyncController + WAsyncView`；不要手写
  `ValueNotifier<WAsyncState>`，也不要每页重复 `when + RetryView`。
  每个独立区块一个 Controller；全局默认 loading/empty/error 用 `WAsyncTheme`，
  放在 App 根节点（`WAppOptions.appWrapper`；或消费方自建插件的 `wrapApp`），不要只放页面 body。
  普通页面区块用 `WAsyncView`；滚动页面 / `SmartRefresher` 用 `WAsyncStateBuilder`，
  不要把 `SmartRefresher` 包在 `WAsyncView` 外面；分页用 `WAsyncPagedController`，
  `loadMore` 失败写 `loadMoreError` / footer，不要用 `WAsyncController.failed` 替换列表。
  `WAsyncStateBuilder.builder` 必须始终返回同一个 `SmartRefresher + CustomScrollView`；
  loading/empty/error 只能作为 slivers 分支。Sliver 页面默认视图用 `WAsyncTheme` 的 `sliver*Builder`，
  `CustomScrollView` 四态用 `WAsyncStateSliver`；`readySliverBuilder` 必须返回 sliver。
  纯执行、不要 UI 用 `WAsync.tryRun` + `WAsyncResult`，或 `WAsync.run`（失败抛异常）；
  不要用已删除的 `WAsync.run(onSuccess:)` / `runValue` / `WAsyncLoading`。

  最小页面：

  ```dart
  final c = WAsyncController.list(() => api.list());
  c.load();
  WAsyncView(state: c.state, onRetry: c.load, readyBuilder: (_, data) => ...);
  ```

  结果分支与取消：

  ```dart
  switch (result) {
    case WAsyncSuccess(:final value): use(value);
    case WAsyncFailure(:final error, :final stackTrace): log(error, stackTrace);
    case WAsyncCancelled(:final reason): log(reason);
  }
  ```

  `WAsyncStatus`（`state.status`）是四态枚举；`WAsyncStrings` 通过
  `WAsyncTheme(strings: ...)` 注入默认文案；取消异常用 `WCancellationException`。
  `WAsyncActivity` 只用于同一批并行任务，不要拿它合并多个独立区块。

  查用法：`dart run w_tools_cli:w_tools explain WAsync --format=prompt`。
