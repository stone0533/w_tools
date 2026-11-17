> 决策记录：记录当时的决策背景；当前实现以模块文档和代码为准。

# ADR 0014：WAsync 默认生命周期钩子

- 状态：已采纳（2026-11-17）
- 相关：[`packages/async/lib/src/task/async_task.dart`](../../packages/async/lib/src/task/async_task.dart)、
  [`docs/adr/0011-api-surface-budget.md`](0011-api-surface-budget.md)、
  [`docs/modules/async_module.md`](../modules/async_module.md)

## 背景

`WAsync.run` / `tryRun` / `retry` / `timeout` / `settle` 已支持 `onStart` / `onError` /
`onFinally`，但项目里每个调用点都要重复传：

```dart
await WAsync.run(
  () => api.save(),
  onStart: AppLoading.show,
  onError: AppToast.error,
  onFinally: AppLoading.hide,
);
```

项目只能再包 `AppAsync.run` / `AppAsync.tryRun`，或者把 UI 配置散落在页面里。
需要一种“默认配置一次，单次调用可覆盖”的入口，同时不让 `WAsync` 依赖任何 UI。

## 决策

1. **`WAsyncHooks` 是不可变值对象**，只存 `onStart` / `onError` / `onFinally` 三个回调；
   `WAsyncHooks.none` 表示关闭默认。
2. **`WAsync.defaultHooks` 是全局默认**；项目在 composition root 设置一次
   （`main` / bootstrap / `WAppPlugin.onInit`）。
3. 每个执行入口增加 optional `hooks`；解析优先级固定为：
   显式回调 → 本次 `hooks` → `WAsync.defaultHooks`。
4. **不把 loading 框 / toast 内置到 `WAsync`**；核心包只认识回调，不依赖 Flutter / GetX /
   `WToast`。
5. `settle` 的 hooks 仍是 **batch-level**：整批一次；`retry` / `timeout` 是整次操作一次。
6. 测试必须重置全局默认（推荐 `setUp` / `tearDown` 设 `WAsyncHooks.none`）。
7. 新公开类型 `WAsyncHooks` 走 API budget exception；类型进入已发布快照后删除例外。

## 后果

正向：

- 默认 loading / error / finally 只配置一次；
- `run` / `tryRun` / `retry` / `timeout` / `settle` 自动复用；
- 单次调用可覆盖或关闭默认；
- 核心包保持零 UI 依赖；
- 项目不再需要 `AppAsync.run` / `tryRun` 两套包装。

代价 / 已知局限：

- `WAsync.defaultHooks` 是进程 / isolate 级全局状态；
- 测试、多个 app 实例、多 flavor 需要显式重置或覆盖；
- `WAsyncHooks` 是新公开类型，需要 ADR + API budget exception；
- `settle` 的 batch 语义需要文档写清，不能按 per-task 理解。

## 落地结果

- 状态：未执行
- 证据：待 7.3.0 发布后回填
- 与决策的偏差：无

## 备选方案

1. **项目层 `AppAsync.run` / `AppAsync.tryRun` 包装**：能解决默认配置，但多两层入口，
   且容易与 `WAsync` 的 hooks 形成两套路径。否决。
2. **`abstract class WAsyncOptions`**：强制项目实现子类，组合 / 测试 / 覆盖都更差；
   抽象类不会减少全局状态。否决。
3. **每个调用继续传三个回调**：最灵活但重复，正是本 ADR 要解决的问题。否决。
4. **只在 `WAsync` 内部放 UI 开关**：破坏核心包零 UI 依赖，否决。
5. **Zone 级默认**：隔离性更好，但理解成本高；保留为未来多 app / 强隔离场景的升级选项。

## 重新评估的条件

- 多 app / 多 isolate 场景导致全局默认不可接受；
- `WAsyncHooks` 的成员或默认解析规则继续膨胀；
- 项目需要 per-task 的 `settle` 钩子，而不是 batch-level；
- `WAsync` 开始需要更复杂的执行策略对象，而不是三个生命周期回调。
