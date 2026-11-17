> 决策记录：记录当时的决策背景；当前实现以模块文档和代码为准。

# ADR 0013：async 的规范应用层独立成可选包

- 状态：已采纳（2026-11-17）
- 相关：[ADR-0006](0006-package-topology.md)、[ADR-0011](0011-api-surface-budget.md)、
  [`docs/extensions/async_ui.md`](../extensions/async_ui.md)、
  [`packages/async_ui/README.md`](../../packages/async_ui/README.md)

## 背景

`w_tools_async` 7.0 只保留核心原语后，同一功能仍有很多正确写法：

- `WAsyncView` + controller、`ValueListenableBuilder` + `WAsyncState.when`、
  `WAsyncStateSliver` + 自建 footer；
- 每个项目自己写 `AppPagedSliverList` / `ListFooter` / `AppAsyncOptions`；
- AI 在每个页面重新选一种写法，代码形状不一致，人阅读和 review 成本高。

核心 API 不适合继续吸收这些页面级便利：会重新长回 7.0 删除的第二入口，
并把 `pull_to_refresh`、设计系统、全局 loading 等依赖带进核心。

## 决策

1. **核心 `w_tools_async` 不变**：只保留 Controller / State / Snapshot / 原语 View。
2. **新增可选包 `w_tools_async_ui`**，只放业务页面规范入口：
   `WAsyncSection` / `WAsyncPagedList` / `WAsyncPagedSliver`。
3. **依赖方向**：`w_tools_async_ui → w_tools_async`；核心绝不反向依赖。
4. **不聚合进根包**：消费方按需直接依赖；新项目由 `init` 的 async feature 带入。
5. **不吸收 app 策略**：全局 loading / toast / 登录失效 / 设计系统留在 app；
   扩展包只接受 builder / theme。
6. **不恢复执行组合子**：`parallel` / `pool` / `serial` / `first` / `map` 仍用
   `Future.wait` / `WAsync.settle` / `Future.any` / for 替代。
7. **规范优先**：业务页面默认用 `WAsyncSection` / `WAsyncPagedList`；
   `WAsyncPagedSliver` 是自定义滚动例外，`WAsyncView` / `WAsyncStateSliver` 是库 /
   设计系统 / 自定义扩展入口。

## 后果

**正向**

- 核心保持小接口、零可选 UI 依赖；扩展包单独版本 / API 预算 / 测试 / 发布；
- 业务页面收敛为少数固定形状，AI 生成和 review 更一致；
- `pull_to_refresh` 只在可选包里，不需要分页的项目不被迫引入。

**代价 / 已知局限**

- 多一个包：workspace / manifest / catalog / docs / 发布都要同步；
- `WAsyncPagedList` 对刷新壳有默认选择（SmartRefresher），但 `header` / `footer`
  可覆盖；完全自定义滚动壳走 `WAsyncPagedSliver`；
- 扩展包仍需要 app 注入设计系统 / 文案 / 全局错误策略；
- 不能保证业务代码一定使用规范入口，仍需 catalog / AGENTS / doctor 配合。

## 落地结果

- 状态：部分完成（包 / catalog / init / 文档已落地；doctor 自动门禁仍为项目 opt-in）
- 证据：`packages/async_ui/`、`scripts/packages.manifest`、`scripts/api_budget.yaml`、`packages/cli/templates/agents/*/async_ui.md`
- 与决策的偏差：catalog 的 tier 分层 / doctor 默认 banned 规则未自动落地；当前由 AGENTS + catalog 反例 + 项目 opt-in 配置承担

## 备选方案

- **把便利组件加回核心**：公开面膨胀，`pull_to_refresh` 等依赖会外溢；否决。
- **每个项目自己写 app 层**：项目内一致、跨项目漂移，AI 仍会分叉；否决。
- **只写 recipe / 文档**：不形成可依赖的单一入口，AI 仍会选 raw API；否决。

## 重新评估的条件

- 3+ 个项目出现无法用 4 个入口表达的真实场景，再评估第五个入口；
- `WAsyncPagedList` 的刷新壳选择成为跨项目阻塞，再评估刷新适配器；
- 扩展包与核心版本强耦合，或扩展包开始吸收 app 策略，重新划分边界。
