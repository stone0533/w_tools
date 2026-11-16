- **异步区块**（`explain WAsyncView` / `explain WAsyncPagedController`）：`WAsyncController` + `WAsyncView`，
  滚动组件放进 `readyBuilder`；sliver 用 `WAsyncStateSliver`；失败态必须传 `onRetry`（或自定义
  errorBuilder 带重试），默认错误视图不显示按钮；分页 footer 只读 `snapshot.footerStatus`
  （hidden / loading / failed / noMore / loadMore），`loadMore` 失败只写
  `snapshot.loadMoreError`，不要维护 `hasLoadedMorePage`；多个独立区块
  每块一个 controller + WAsyncView，不要用 `data != null` 代替四态；`WAsyncStatus` /
  `WAsyncStrings` 走 `WAsyncTheme`；结果分支 `WAsyncSuccess` / `WAsyncFailure` /
  `WAsyncCancelled`，取消异常 `WCancellationException`；纯执行用 `WAsync.tryRun` / `run`，
  独立区块用 `WAsync.settle`；`WAsyncView.state` 是 `ValueListenable` 不是 `Rx`，外层 `Obx` 要保留。
