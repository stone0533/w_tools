- **Async 规范入口**（`explain WAsyncSection` / `explain WAsyncPagedList`）：业务页面单区块用
  `WAsyncSection`，标准分页用 `WAsyncPagedList`（内部 SmartRefresher / footer / 重试），
  自定义滚动用 `WAsyncPagedSliver`；footer 文案用 `WAsyncPagedStrings`。不要维护
  `hasLoadedMorePage`，分页只读 `snapshot.footerStatus`；`WAsyncView` / `WAsyncStateSliver`
  只用于库 / 设计系统 / 明确的自定义扩展。
