> 决策记录：记录当时的决策背景；当前实现以模块文档和代码为准。

# ADR 0015：用 WAsyncExecutor 替代全局 defaultHooks

- 状态：已采纳（2026-11-17）
- 相关：[`packages/async/lib/src/task/async_executor.dart`](../../packages/async/lib/src/task/async_executor.dart)、
  [`docs/adr/0014-async-default-hooks.md`](0014-async-default-hooks.md)、
  [`docs/adr/0011-api-surface-budget.md`](0011-api-surface-budget.md)

## 背景

7.3 引入 `WAsync.defaultHooks`，希望“配置一次，所有执行入口复用”。实际使用中：

- 全局默认会被 `WAsyncController.load` / `WAsyncPagedController.refresh` /
  `loadMore` 内部继承，造成页面骨架 + 全屏遮罩双重 loading；
- 库内部必须逐个 `hooks: WAsyncHooks.none` opt-out；
- 第三方基于 `WAsync` 的封装也会误继承；
- 测试 / 多 app / 多 flavor 需要重置或覆盖全局状态。

`defaultHooks` 让 `WAsync` 无法区分“业务显式动作”和“页面状态加载”。

## 决策

1. **新增 `WAsyncExecutor`**：携带默认 `WAsyncHooks` 的实例执行器，提供
   `run` / `tryRun` / `retry` / `timeout` / `settle`。
2. **项目在 composition root 创建一次并注入**；不再依赖全局静态默认。
3. **`WAsync.defaultHooks` 标记 deprecated**，保留到 8.0.0 再删除。
4. `WAsyncHooks` / `hooks` 参数继续作为底层显式原语。
5. `WAsyncController` / `WAsyncPagedController` 继续不继承任何默认 hooks；
   页面四态由 view 管理。
6. `WAsyncExecutor` 是新公开类型，走 API budget exception / ADR。

## 后果

正向：

- 默认配置只创建一次，但作用域明确；
- 多 app / 测试可以独立创建 executor；
- controller 不会被全局 loading 污染；
- 第三方封装不会误继承；
- `WAsync` 不再持有 app UI 策略的全局状态。

代价 / 已知局限：

- 业务调用从 `WAsync.run` 变成 `executor.run`；
- 需要把 executor 注入到 service / page；
- `defaultHooks` 仍会存在到 8.0.0，需要迁移窗口；
- `WAsyncExecutor` 增加公开 API 面，需要 ADR + exception。

## 落地结果

- 状态：未执行
- 证据：待 7.4.0 发布后回填
- 与决策的偏差：无

## 备选方案

1. **保留 `defaultHooks`**：便利但全局隐式，controller / 第三方封装会继续误继承。
   否决。
2. **项目层 `AppAsync` 包装**：可以去掉全局状态，但没有解决库内统一的执行器接口；
   `WAsyncExecutor` 放在库里更可复用。否决。
3. **Zone 级默认**：隔离性更好，但隐式、调试成本高；保留为未来强隔离场景的选项。
4. **`WAsyncHooks` 扩展方法**：`hooks.run()` 语义不清，不能作为稳定注入接口。否决。

## 重新评估的条件

- 多 app / 多 isolate 场景需要更强隔离；
- `WAsyncExecutor` 需要按模块拆分不同 hooks；
- `defaultHooks` 迁移完成，8.0.0 删除后可简化文档；
- 业务需要 per-call 执行策略对象，而不是三个生命周期回调。
