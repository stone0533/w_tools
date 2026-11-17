# async_ui（规范应用层）

业务页面优先依赖 `w_tools_async_ui`：

- 单区块：`WAsyncSection`；
- 标准分页：`WAsyncPagedList`；
- 自定义滚动：`WAsyncPagedSliver`。

## 硬规则

- `WAsyncSection` 默认 `onRetry: controller.load`；不要再手动拼 `WAsyncView` 的 `state` + `onRetry`。
- `WAsyncPagedList` 内部处理 SmartRefresher、generation 和 loadMore 收尾；
  `header` / `footer` 原样转给 SmartRefresher，样式由 app 决定。
- 需要带动画的程序化刷新时传 `refreshController`，再调 `requestRefresh()`；
  外部传入的 controller 由 app dispose。
- app 自定义 footer 时读 `controller.snapshot`；重试调用 `controller.loadMore()`，
  不要依赖内部 `RefreshController`。
- `WAsyncPagedSliver` 只负责四态和 ready 分支；不包含 footer / 文案，
  header / footer 由调用方自己的滚动壳负责；自建刷新壳时传
  `onRetry: refreshController.requestRefresh`。
- 不自动 load / refresh；页面 controller 的 `initState` / `onInit` 负责首屏请求。
- 业务页面不要直接使用 `WAsyncView` / `WAsyncStateSliver`；它们保留给库、设计系统、
  明确的自定义扩展。
- 不要维护 `hasLoadedMorePage`；分页 footer 只读 `snapshot.footerStatus`。
- 不要把 `parallel` / `pool` / `serial` / `first` / `map` 加回来；执行仍用
  `Future.wait` / `WAsync.settle` / `Future.any` / for。
- 不把全局 loading / toast / 登录失效塞进 async_ui；这些是 app 层策略。

完整说明：[docs/extensions/async_ui.md](../extensions/async_ui.md)、[README](../../packages/async_ui/README.md)。
