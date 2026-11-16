# async_ui（规范应用层）

业务页面优先依赖 `w_tools_async_ui`：

- 单区块：`WAsyncSection`；
- 标准分页：`WAsyncPagedList`；
- 自定义滚动：`WAsyncPagedSliver`；
- footer 文案：`WAsyncPagedStrings`。

## 硬规则

- `WAsyncSection` 默认 `onRetry: controller.load`；不要再手动拼 `WAsyncView` 的 `state` + `onRetry`。
- `WAsyncPagedList` 内部处理 SmartRefresher、footer、重试和 generation；不要再传
  `footerStatus` + `footerChanges` 两套参数。
- 不自动 load / refresh；页面 controller 的 `initState` / `onInit` 负责首屏请求。
- 业务页面不要直接使用 `WAsyncView` / `WAsyncStateSliver`；它们保留给库、设计系统、
  明确的自定义扩展。
- 不要维护 `hasLoadedMorePage`；分页 footer 只读 `snapshot.footerStatus`。
- 不要把 `parallel` / `pool` / `serial` / `first` / `map` 加回来；执行仍用
  `Future.wait` / `WAsync.settle` / `Future.any` / for。
- 不把全局 loading / toast / 登录失效塞进 async_ui；这些是 app 层策略。

完整说明：[docs/extensions/async_ui.md](../extensions/async_ui.md)、[README](../../packages/async_ui/README.md)。
