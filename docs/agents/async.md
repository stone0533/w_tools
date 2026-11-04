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

`onRetry == null` 时不调用自定义 error / banner builder（它们要求可用的 retry）。

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

完整说明：[async_module.md](../modules/async_module.md) · 示例：[packages/async/example](../../packages/async/example/README.md)
