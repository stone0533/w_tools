# 异步区块（给人和 AI）

- 页面展示异步结果：`WAsyncController` + `WAsyncView`。
- 不要手写 `ValueNotifier<WAsyncState>`，也不要每页重复 `when + RetryView`。
- 每个独立区块一个 Controller；不要用一个 `WAsyncActivity` 合并多个独立区块。
- 全局默认 loading / empty / error 用 `WAsyncTheme`；放在 App 根节点。
- 普通页面区块用 `WAsyncView`；滚动页面 / `SmartRefresher` 用 `WAsyncStateBuilder`。
- Sliver 页面用 `WAsyncStateSliver`；失败无 retry 时不显示按钮。
- 分页用 `WAsyncPagedController`；`loadMore` 失败只写 `loadMoreError`。
- 纯执行、不要 UI：`WAsync.tryRun` 拿 `WAsyncResult`，或 `WAsync.run` 失败抛异常。
- `WAsync.run` 不再接受 `onSuccess`；需要映射用 `WAsync.map`。`runValue` / `WAsyncLoading` 已删除。
- 取消用 `WCancelToken`；`withToken` 让 loader 感知取消；取消不中止底层 Future。

选择入口：

| 需求 | 用 |
| --- | --- |
| 页面区块 | `WAsyncController` + `WAsyncView` |
| 滚动页 | `WAsyncStateBuilder` |
| Sliver | `WAsyncStateSliver` |
| 纯执行，不抛异常 | `WAsync.tryRun` |
| 纯执行，失败抛异常 | `WAsync.run` |
| 映射成功值 | `WAsync.map` |
| 重试 / 超时 / 并发 | `WAsync.retry` / `timeout` / `parallel` / `pool` / `serial` / `first` |
| 分页 | `WAsyncPagedController` |
| 观测自定义 retry 失败 | `WAsyncView.onRetryError` / `WAsyncStateSliver.onRetryError` |

`WAsync.map` 做结果映射，`serial` 做同类型顺序任务，`first` 做多源竞速。

`onRetry == null` 时不显示重试按钮；自定义 error / banner builder 仍会收到 `null`，由 builder 决定是否渲染按钮。

`tryRun` 结果：

```dart
switch (result) {
  case WAsyncSuccess(:final value): use(value);
  case WAsyncFailure(:final error, :final stackTrace): log(error, stackTrace);
  case WAsyncCancelled(:final reason): log('cancelled: $reason');
}
```

最小用法：

```dart
final gifts = WAsyncController.list(() => api.gifts());
gifts.load();

WAsyncView<List<Gift>>(
  state: gifts.state,
  onRetry: gifts.load,
  readyBuilder: (context, data) => GiftList(data),
);
```

执行结果：

```dart
final result = await WAsync.tryRun(() => api.gift(id));
if (result is WAsyncSuccess<Gift>) {
  use(result.value);
} else if (result is WAsyncFailure<Gift>) {
  log(result.error, result.stackTrace);
}
```

`WAsyncView` 还支持按页面覆盖 `loadingBuilder` / `emptyBuilder` / `errorBuilder` /
`errorBannerBuilder` / `refreshingBuilder`，以及 `onRetryError`；未传时回退到
`WAsyncTheme`。`WAsyncStrings` 注入默认文案，`WAsyncStatus` 是 `state.status` 的枚举，
取消抛 `WCancellationException`，`tryRun` 的结果分支是 `WAsyncSuccess` /
`WAsyncFailure` / `WAsyncCancelled`。

`WAsyncActivity` 只用于同一批并行任务（如 `WAsync.parallel`），不要合并多个独立区块。

状态 / 结果 / 活动分不清时：

| 类型 | 是什么 | 不是什么 |
|---|---|---|
| `WAsyncState` | 一次请求的四态快照（status / data / error） | 不是执行结果 |
| `WAsyncStatus` | 四态枚举 | 不是状态载体 |
| `WAsyncResult` | `tryRun` 的成功 / 失败 / 取消结果 | 不是 UI 状态 |
| `WAsyncActivity` | 并发活动计数器 | 不是加载视图 |

完整说明：[async_module.md](../modules/async_module.md) · 示例：[packages/async/example](../../packages/async/example/README.md)
