# 异步区块（给人和 AI）

- 页面展示异步结果：`WAsyncController` + `WAsyncView`。
- 不要手写 `ValueNotifier<WAsyncState>`，也不要每页重复 `when + RetryView`。
- 每个独立区块一个 Controller；不要用一个 `WAsyncActivity` 合并多个独立区块。
- 全局默认 loading / empty / error 用 `WAsyncTheme`；放在 App 根节点。
- 普通页面区块用 `WAsyncView`；滚动页面 / `SmartRefresher` 用 `WAsyncStateBuilder`。
- Sliver 页面用 `WAsyncStateSliver`；失败无 retry 时不显示按钮。
- 分页用 `WAsyncPagedController`；`loadMore` 失败只写 `loadMoreError`。
- 纯执行、不要 UI：`WAsync.tryRun` 拿 `WAsyncResult`，或 `WAsync.run` 失败抛异常。
- 不要用 `WAsync.run` 的旧写法（不再有 `onSuccess` / `runValue` / `WAsyncLoading`）。
- 取消用 `WCancelToken`；`withToken` 让 loader 感知取消；取消不中止底层 Future。

最小用法：

```dart
final gifts = WAsyncController.list(() => api.gifts());

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

完整说明：[async_module.md](../modules/async_module.md)
