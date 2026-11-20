- **Async 规范入口**（`explain WAsyncSection` / `explain WAsyncPagedList`）：业务页面单区块用
  `WAsyncSection`，标准分页用 `WAsyncPagedList`（内部 RefreshIndicator；自动 loadMore；自定义刷新壳用 WAsyncPagedSliver），
  自定义滚动用 `WAsyncPagedSliver`；业务入口查询用 `list --tier=app`。不要维护
  `hasLoadedMorePage`，分页只读 `snapshot.footerStatus`（footer 文案（含 noMore）走 `WAsyncTheme.strings`，可用 `footerBuilder` 覆盖）；`WAsyncView` / `WAsyncStateSliver`
  只用于库 / 设计系统 / 明确的自定义扩展。
