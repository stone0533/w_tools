# async_ui（规范应用层）

业务页面优先依赖 `w_tools_async_ui`：

- 单区块：`WAsyncSection`；
- 标准分页：`WAsyncPagedList`；
- 自定义滚动：`WAsyncPagedSliver`。

## 硬规则

- `WAsyncSection` 默认 `onRetry: controller.load`；不要再手动拼 `WAsyncView` 的 `state` + `onRetry`。
- `WAsyncPagedList` 用 `RefreshIndicator` 下拉刷新，滚动阈值自动 loadMore；
- `WAsyncPagedList` 的 controller 生命周期内保持稳定；per-list loading / error / errorBanner 走 `WAsyncTheme`，需要定制用 `WAsyncPagedSliver`；`refreshIndicatorStyle` 只配标准头。
  默认 footer 读 `snapshot.footerStatus`，文案（含 noMore）走 `WAsyncTheme.strings`，
  `footerBuilder` 可替换；`refreshIndicatorStyle` 只配标准刷新头样式。
- 程序化刷新用 `reloadRequests.value++`；不需要外部刷新 controller；刷新期间自动加载挂起，完成后恢复。
- `WAsyncPagedSliver` 只负责四态和 ready 分支；不包含刷新壳 / footer / 文案，
  header / footer 由调用方自己的滚动壳负责；自建刷新壳时传 `onRetry: gifts.refresh`。
- 不自动 load / refresh；页面 controller 的 `initState` / `onInit` 负责首屏请求。
- 业务页面不要直接使用 `WAsyncView` / `WAsyncStateSliver`；它们保留给库、设计系统、
  明确的自定义扩展。
- 不要维护 `hasLoadedMorePage`；分页 footer 只读 `snapshot.footerStatus`。
- 不要把 `parallel` / `pool` / `serial` / `first` / `map` 加回来；执行仍用
  `Future.wait` / `WAsync.tryAll` / `Future.any` / for。
- 不把全局 loading / toast / 登录失效塞进 async_ui；这些是 app 层策略。

完整说明：[docs/extensions/async_ui.md](../extensions/async_ui.md)、[README](../../packages/async_ui/README.md)。
