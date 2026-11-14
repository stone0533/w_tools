> 决策记录：记录当时的决策背景；当前实现以模块文档和代码为准。

# ADR 0010：补丁发布保持精确下界，不按 patch 放宽

- 状态：已采纳（2026-11-15）
- 相关：[`scripts/check_versions.py`](../../scripts/check_versions.py)、
  [`docs/releasing.md`](../releasing.md)、[ADR-0001](0001-package-versioning.md)

## 背景

一次单行修复的 patch 发布，按仓库现有规则需要同时抬子包、CLI `init` 约束与根包约束，
并走两次快照 PR（子包 + 快照 → CLI/根包）。原因是
[`scripts/check_versions.py`](../../scripts/check_versions.py) 只认一个真相：

- 根 `pubspec.yaml` 的 `w_tools_<pkg>: ^x.y.z` 下界 == 子包当前版本；
- `packages/cli/lib/src/init/versions.dart` 的 `subpackageConstraints` 同样 == 当前版本。

这保证 `w_tools init` 永远给最新版本，但也让 patch 变成“三包发布”。评审时提出过
“patch 是否允许沿用 `^x.y.0`”的选项，需要决定是否放宽。

## 决策

1. **保持精确下界**：patch 发布时，根 pubspec 与 `versions.dart` 的下界仍然抬到
   `^x.y.z`，不沿用 `^x.y.0`；`check_versions.py` 不改规则。
2. **patch 级联走自动化**：子包 → 快照 PR → CLI / 根包按 `release_wave.py` 的顺序执行；
   版本提案仍由 K-2 确认，不由工具自动决定。
3. **发布手册记录已知摩擦**：pub.dev 传播延迟、快照 PR 后 HEAD 变化导致 `--resume`
   失效、发布后消费方冒烟，都写进 [`docs/releasing.md`](../releasing.md)，不靠个人记忆。
4. **不为 patch 单独放宽 `init` 约束**：`init` 继续写当前版本；老项目已有的约束不被覆盖，
   新项目拿最新 patch。

## 后果

正向：

- `init` 与根约束始终指向最新版本，消费方不会因为“下界还是旧 patch”而漏掉修复；
- 版本只有一个真相，周检 / `check_versions` / `publish_package.sh` 的规则不用分叉；
- patch 级联虽然多两步，但 `release_wave` 已把 dry-run、快照、可见性等待与验证串起来。

代价 / 已知局限：

- 一行修复也会触发三包发布 + 两次快照 PR，发布窗口更长；
- 依赖 pub.dev 传播，根包 dry-run 可能先失败，需要等可见后重新 plan；
- 需要维护者理解“为什么不直接放宽”，否则容易在下次 patch 时绕过规则。

## 落地结果

- 状态：已完成
- 证据：一次 patch 修复按“子包 → 快照 PR → CLI → 根包”的顺序发布，`release_wave`
  完成 dry-run、快照合并、可见性等待与发布后验证；`release_check --strict` 与
  `release_status --online --check` 通过。
- 与决策的偏差：无；传播延迟与快照后重新 plan 的摩擦已补进发布手册。

## 备选方案

1. **patch 放宽到 `^x.y.0`**：拒绝。`init` 会把新项目 pin 到旧 patch，消费方可能漏修复；
   `check_versions` 需要区分 patch / minor，“下界 == 当前版本”的单一规则被稀释。
2. **CLI 约束独立于根包**：拒绝。会出现两个版本真相，`init` 与根包解析可能不一致。
3. **发布脚本自动抬三包版本**：拒绝。版本提案属于 K-2 的人工确认，工具不替维护者决定 semver。

## 重新评估的条件

- patch 发布频率高到每周多次，三包级联明显拖慢修复；
- `release_wave` 多次因 pub.dev 传播或快照 PR 卡住，且无法用等待 / 重新 plan 解决；
- `init` 的约束策略变化（例如改为“跟随 pub.dev latest”而不是写死下界）。
