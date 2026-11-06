> 决策记录：记录当时的决策背景；当前实现以模块文档和代码为准。

# ADR 0007：组件命名收敛为角色判断（修订 ADR-0004 决策 2）

- 状态：已采纳（2026-11-06）
- 相关：[ADR-0004](0004-component-config-model.md)、[ADR-0005](0005-app-options-and-plugin-ownership.md)、
  [命名规范](../naming.md)、[`scripts/check_naming.py`](../../scripts/check_naming.py)、
  [`scripts/naming_baseline.yaml`](../../scripts/naming_baseline.yaml)

## 背景

ADR-0004 用「四类后缀 + 不再新增 `XxxConfig`」约束命名。它解决了当时的真实问题，但执行后出现了偏差
（类名截至 2026-11-06；类可能被删，角色不会）：

- `WLocaleConfig` 由 ADR-0005 引入，却不在 ADR-0004 的 Config 白名单；
- `WImageSlots` 是 UI builder 集合，四类后缀装不下；
- 后缀禁令没有脚本检查，`build()` 也已有公开反例。

问题不在于某个词，而在于两件事：**把命名写成了一张过大的角色表**，以及**规则没有唯一的堆放处**
——ADR 里一份、脚本里一份、CONTRIBUTING 里没有。

## 决策

1. **规则正文只有一份**：[docs/naming.md](../naming.md) 是命名规则的唯一事实源，
   覆盖包 / 目录 / 文件 / 类型 / 成员 / 测试 / 文档；ADR 只记录为什么这样定。
2. **先判断角色，再决定后缀**：视觉 → `Style`，行为 → `Options`，App 级默认 → `Theme`，
   UI 插槽 → `Slots`，运行期控制 → `Controller`，输入 → `Source`，
   输出 → `State` / `Result` / `Error`。
3. **Config 是可选的兜底角色，不是默认角色**：新增 Config 必须是不可变数据载体；
   能归入 `Style` / `Options` / `Theme` / `Slots` 时不要用 Config。
4. **例外集中登记、只减不增**：允许存在的旧名字登记在 `scripts/naming_baseline.yaml`；
   `check_naming.py` 同时检查「漏登记」与「已删除未删行」，不再维护第二份名单。
5. **机器校验只守可判定的部分**：公开 `W*Config` 白名单、库包公开类型 `W` 前缀、Dart 文件名；
   角色语义、成员命名、`build()` 是否唯一仍靠 review。

## 后果

- 命名从「记后缀表」变成「先判断角色」，维护成本更低；
- 规则只有一份，`WLocaleConfig` / `WImageSlots` 不再靠口头例外；
- `Config` 仍有门槛，但不会误伤不可变数据载体；
- 代价：脚本只守名字，语义误用仍要靠 review；ADR 不再重复规则正文。

## 不做什么

- 不把 `Slots` / `Settings` / `Params` 立刻扩成全局强制角色；
- 不为统一把 `WApiConfig` / `WAppConfig` / `WFormValidatorSettings` 现在改名；
- 不用命名检查替代 catalog 检查和 `analyze`；
- 不把 `WForm*Config` 的隐藏迁移壳重新公开。

## 落地结果

- 状态：已完成（2026-11-06）
- 证据：[`docs/naming.md`](../naming.md)、`scripts/naming_baseline.yaml`、
  `scripts/check_naming.py`、`scripts/preflight.sh`、ADR-0004 / ADR-0005 的修订记录。
- 与决策的偏差：`WApiConfig` / `WAppConfig` / `WFormValidatorSettings` 保留为遗留可变配置，
  下个 major 再评估；`WMapConfig` 已在 map_google 改名 `WMapOptions`，
  `WImageLoadConfig` 已在 ui 改名 `WImageLoadOptions`。

## 备选方案

- **继续扩 ADR-0004 的白名单**：规则仍散落在 ADR 与脚本两处，且 ADR 会被迫反复改；
- **只靠 code review**：后缀禁令已经证明会漂移（`build()` 公开反例）；
- **全量 AST 命名检查**：误报高，角色语义无法机器判定。

## 重新评估的条件

- 出现第二个真实使用 `XxxSlots` 的组件；
- 同一语义同时出现 `Options` / `Settings` / `Params`，且无法用现有角色解释；
- `check_naming.py` 误报率过高，导致维护者绕过登记；
- Dart 提供更强的命名或类型约束能力。
