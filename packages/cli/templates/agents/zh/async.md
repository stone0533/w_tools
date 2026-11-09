- **异步区块**（`explain WAsyncPagedController`）：`WAsyncController` + `WAsyncView`，滚动页 `WAsyncStateBuilder`，
  sliver 用 `WAsyncStateSliver`；`WAsyncStatus` / `WAsyncStrings` 走 `WAsyncTheme`（放 App 根节点）；
  结果分支 `WAsyncSuccess` / `WAsyncFailure` / `WAsyncCancelled`，取消异常 `WCancellationException`；
  纯执行（不要 UI）用 `WAsync.tryRun` / `WAsync.run`；分页 `WAsyncPagedController`，`loadMore` 失败只写 `loadMoreError`。
  `WAsync` 的 `state` 是 `ValueListenable` 不是 `Rx`：换成 `WAsyncStateBuilder` 后外层 `Obx` 还得包着，
  删掉不报错，但页面里其它 Rx 状态不再触发重建。
