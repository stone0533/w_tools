# 异步区块（给人和 AI）

- 业务页面展示异步结果：单区块用 `WAsyncSection`，标准分页用 `WAsyncPagedList`（来自 `w_tools_async_ui`）。
- 库 / 设计系统 / 自定义扩展才直接用 `WAsyncView` / `WAsyncStateSliver` 原语。
- 不要手写 `ValueNotifier<WAsyncState>`，也不要每页重复 `when + RetryView`。
- 每个独立区块一个 Controller；不要在多个独立区块之间共享一个加载计数器。
- Controller 重新加载用 `load()`；自动重试用 `WAsync.retry`。
- 全局默认 loading / empty / error 用 `WAsyncTheme`；放在 App 根节点。builder 必须返回
  **非滚动** Widget（sliver 复用同一组 builder），不要把 `ListView` 塞进 loading / error。
- 单区块用 `WAsyncSection`；它默认把失败重试接到 `controller.load`。
- 标准分页用 `WAsyncPagedList`；需要自定义刷新头 / footer 时传它的 `header` / `footer`，
  不要再在外面包一层 `SmartRefresher`；程序化带动画刷新传 `refreshController`。
- 自定义滚动壳用 `WAsyncPagedSliver`；它的 header / footer 由调用方自己的滚动壳负责，
  错误重试传 `onRetry: refreshController.requestRefresh`。
- 核心 `WAsyncStateSliver` 只用于库 / 设计系统 / 自定义扩展；业务页面用 `WAsyncPagedList` / `WAsyncPagedSliver`。
- `WAsyncView` / `WAsyncStateSliver` 只监听 `ValueListenable`（`state` 不是 `Rx`）：
  页面里其它 Rx 状态（筛选条件、倒计时）该包 `Obx` 还得包；迁移时顺手删掉外层 `Obx`
  不会有编译错误，但那些状态就不再触发重建。
- `WAsyncView` 的 refreshing / errorBanner：宽高都有界（`Scaffold.body` / `Expanded`）时占固定槽，
  内容让位；普通内容保持自身高度，滚动内容拿满可用高度；任一维无界（`Column` 子项 /
  `ListView` item / `Row`）时是内容盒 overlay。
- 分页用 `WAsyncPagedController`；`loadMore` 失败只写 `snapshot.loadMoreError`。
- 第一页不足一页 / 服务端有 `total`：loader 返回 `WAsyncPage(items:, hasMore: page * pageSize < total)`，
  不要用 `data.length` 猜。
- 分页 footer 只读 `controller.snapshot.value.footerStatus`（hidden / loading / failed / noMore / loadMore），
  重建用 `AnimatedBuilder(animation: controller.snapshot)`；不要在外部拼 data / error / hasMore。
- 切换筛选 / 搜索直接再调 `refresh()`：在飞刷新会被取消，旧结果不写回；不要禁用筛选。
- 本地替换 / 乐观更新用 `replaceData`：会取消在飞 refresh / loadMore，`hasMore` 默认继承。
- 单区块本地替换用 `WAsyncController.replaceData`：取消在飞 `load`，旧结果不写回。
- 列表语义用 `WAsyncController.list`：保留空列表 → empty、`state.data` unmodifiable。
- `state.isRefreshing` 只在有旧数据时为 true；首屏 / 重试用 `isLoading`；切换筛选直接 `refresh()`。
- 分页 + SmartRefresher：标准壳用 `WAsyncPagedList`；自定义壳用 `WAsyncPagedSliver` + 自己的
  `SmartRefresher`，见 `docs/recipes/paged-list.md`。
- 纯执行、不要 UI：`WAsync.tryRun` 拿 `WAsyncResult`，或 `WAsync.run` 失败抛异常；
  独立区块并行用 `WAsync.settle`；普通并发直接用 `Future.wait` / `Future.any`。
- `WAsyncState.list` 不复制 / 不包装输入列表；需要不可变 data 用
  `WAsyncController.list` 或 `List.unmodifiable`。状态相等性是浅比较，列表按引用比较。
- `onError` 只是通知，不会吞异常；`run(...).then(onSuccess)` 必须同时给
  `onError` / `catchError`，否则会有 unhandled Future。不要用空 `onError` 当 catch。
- `WAsyncHooks` / `WAsync.defaultHooks` 管显式执行入口的默认；单次 `hooks` 可覆盖，
  `WAsyncHooks.none` 关闭默认；测试必须重置。
- `WAsyncController.load` / `WAsyncPagedController.refresh` / `loadMore` 不继承
  `defaultHooks`；页面 loading 走 `WAsyncSection` / `WAsyncPagedList` 四态。
- `WAsync.run` / `tryRun` / `retry` / `timeout` 的 `onStart` / `onFinally` 管 loading 生命周期；
  `onFinally` 在成功 / 失败 / 取消都执行，成功用返回值，不提供 `onSuccess`。
- `retry` / `timeout` 的钩子整次一次；`settle` 的钩子是 batch-level，整批一次。
- `WAsync.run` 不接受 `onSuccess`；7.0 已删除 `WAsync.map` / `parallel` / `pool` / `serial` / `first`；
  `runValue` / `WAsyncLoading` 也已删除。- 取消用 `WCancelToken`；Controller 的 loader 统一接收 token；取消不中止底层 Future；
  被新 refresh 取代的旧 refresh 也会 cancel token。
- 取消与失败同轮竞态：非 `Error` 按取消处理；`Error` 仍返回 failure，避免吞编程错误。
- 默认 loading / empty / error 视图带 `liveRegion`；显式 / theme builder 不会自动加语义。
- 默认错误视图只显示标题，不渲染异常原文；需要展示详情时用 `errorBuilder` 并自己确认脱敏。

选择入口：

| 需求 | 用 |
| --- | --- |
| 单区块页面 | `WAsyncSection` |
| 标准分页 | `WAsyncPagedList` |
| 自定义滚动 / Sliver | `WAsyncPagedSliver` |
| 纯执行，不抛异常 | `WAsync.tryRun` |
| 纯执行，失败抛异常 | `WAsync.run` |
| 重试 / 超时 | `WAsync.retry` / `WAsync.timeout` |
| 独立区块并行，保留每个结果 | `WAsync.settle` |
| 单区块本地替换 | `WAsyncController.replaceData` |
| 分页 controller | `WAsyncPagedController` |
| 分页 footer 状态 | `WAsyncPagedSnapshot.footerStatus` |

## 规范应用层（async_ui）

业务页面优先依赖 `w_tools_async_ui`：

```dart
WAsyncSection<List<Gift>>(
  controller: gifts,
  builder: (context, data) => GiftList(data),
)
```

```dart
WAsyncPagedList<Gift>(
  controller: gifts,
  itemBuilder: (context, gift) => GiftTile(gift),
)
```

- `WAsyncSection`：单区块；默认 `onRetry: controller.load`；
- `WAsyncPagedList`：标准分页；内部持有 `RefreshController` / SmartRefresher，处理 generation
  和 loadMore 收尾；`header` / `footer` 可覆盖；
- `WAsyncPagedSliver`：自定义 `CustomScrollView` 用；只负责四态和 ready 分支，不包含刷新壳 / footer；
- 不自动 load / refresh；页面 controller 负责首屏请求；
- 核心 `WAsyncView` / `WAsyncStateSliver` 保留给库、设计系统、明确的自定义扩展。

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
final gifts = WAsyncController.list((_) => api.gifts());
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
`errorBannerBuilder` / `refreshingBuilder`；未传时回退到 `WAsyncTheme`。
`WAsyncStrings` 注入默认文案，`WAsyncStatus` 是 `state.status` 的枚举，
取消抛 `WCancellationException`，`tryRun` 的结果分支是 `WAsyncSuccess` /
`WAsyncFailure` / `WAsyncCancelled`。

`WAsync.retry` 的 `retryCount` 是重试次数（总尝试 = `retryCount + 1`）；`retryDelayBuilder`
按失败次数生成退避，`onRetry` 观测每次重试，回调自身异常会被忽略。

状态 / 结果分不清时：

| 类型 | 是什么 | 不是什么 |
|---|---|---|
| `WAsyncState` | 一次请求的四态快照（status / data / error） | 不是执行结果 |
| `WAsyncStatus` | 四态枚举 | 不是状态载体 |
| `WAsyncResult` | `tryRun` 的成功 / 失败 / 取消结果 | 不是 UI 状态 |
| `WAsyncPagedSnapshot` | 分页列表的只读快照 | 不是单区块四态 |

完整说明：[async_module.md](../modules/async_module.md) · 示例：[packages/async/example](../../packages/async/example/README.md)
