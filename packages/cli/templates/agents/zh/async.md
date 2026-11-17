- **异步区块**（`explain WAsyncSection` / `explain WAsyncPagedList`；分页 controller：
  `explain WAsyncPagedController`）：业务页面单区块用 `WAsyncController` + `WAsyncSection`（默认 onRetry =
  controller.load），分页用 `WAsyncPagedList`（内部 SmartRefresher；header/footer 可覆盖），
  自定义滚动用 `WAsyncPagedSliver`；`WAsyncView` / `WAsyncStateSliver` 只用于库 / 设计系统 /
  自定义扩展。分页 footer 只读 `snapshot.footerStatus`（hidden / loading / failed / noMore /
  loadMore），`loadMore` 失败只写 `snapshot.loadMoreError`，不要维护 `hasLoadedMorePage`；
  多个独立区块每块一个 controller，不要用 `data != null` 代替四态；`WAsyncStatus` /
  `WAsyncStrings` 走 `WAsyncTheme`；结果分支 `WAsyncSuccess` / `WAsyncFailure` /
  `WAsyncCancelled`，取消异常 `WCancellationException`；纯执行用 `WAsync.tryRun` / `run`，
  独立区块用 `WAsync.settle`；`WAsyncView.state` 是 `ValueListenable` 不是 `Rx`，外层 `Obx` 要保留。
