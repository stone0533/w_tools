# w_tools_cli 2.9.15：catalog 入口可解释性修复与发布记录

> 记录日期：2026-11-27。结论：`AUDIT-001~005` 已修复并发布为 `w_tools_cli 2.9.15`
> （PR #435，快照 PR #436）；`release_status --online --check` 状态正常，
> 消费方临时工程可解析并运行 2.9.15。`AUDIT-006~008` 核实为非缺口。

## 背景

全仓审计（I 第 1 轮，只读）按 J-0 逐包检查后发现：`entrypoints.yaml` 里的 3 个核心入口
无法被 `explain` 精确命中，另有 1 个入口没有用法。

| ID | 入口 | 现象 |
|---|---|---|
| AUDIT-001 | `WMapOptions` | `explain` 返回「没有找到」，exit 1 |
| AUDIT-002 | `WToastTheme` | 回退到近似匹配 `WToastStyle` |
| AUDIT-003 | `WMapItem` | 回退到 `WMapItemMapper` |
| AUDIT-004 | `WDebounce` | 有条目，但无 usage / pitfalls |
| AUDIT-005 | map_google README | 只有 19 行，缺少 `WMap` 最小用法 |

前三个入口同时出现在 `packages/cli/catalog/entrypoints.yaml`（必须教）与
`packages/cli/catalog/uncataloged.yaml`（有意不登记）里，形成「必须教 / 但不进 catalog」
的矛盾；`explain` 只能近似匹配或直接找不到。

## 修复

- catalog 补登 `WToastTheme` / `WMapItem` / `WMapOptions`，补 usage / pitfalls / related，
  `teach: true`；`WDebounce` 补 usage / pitfalls / related；`uncataloged.yaml` 19 → 16。
- `packages/map_google/README.md` 补 `## 最小用法`。
- `w_tools_cli` 2.9.15：`pubspec` / `cliVersion` / `init` 的 `cliConstraint` 同步；
  `docs/metrics/agents_budget.jsonl` 记录 2.9.15。
- 新增 `packages/cli/test/internal/catalog_test.dart` 回归：AUDIT-001~003 / 004
  两条测试先红后绿。

## 验证

| 命令 | 结果 |
|---|---|
| `dart test`（packages/cli） | 554 通过 |
| `check_public_catalog.py` | 通过（16 个已登记子 API） |
| `check_teaching_coverage.py` | 通过（12 包） |
| `check_catalog_symbols.py` / `check_catalog_anchors.py` | 通过（149 条） |
| `preflight.sh --with-tests --with-flutter-analyze` | 门禁通过（16 包 + 根包 + 9 个 example） |
| `explain` 抽查 | 4 个入口均精确命中并带用法 |

## 发布

| 步骤 | 结果 |
|---|---|
| 功能 PR | #435，Merge commit `5a886891` |
| pub.dev | `w_tools_cli 2.9.15`（182 KB，0 warnings） |
| 快照 PR | #436（`w_tools_cli-2.9.15.txt`），Merge commit `b93ffd29` |
| K-5 阶段 1 | `release_status --online` 无异常段 |
| K-5 阶段 2 | `release_status --online --check` 状态正常；`check_publish_drift --package cli` 无漂移 |
| 消费方冒烟 | 临时工程 `dart pub get` 拉到 2.9.15，`dart run w_tools_cli:w_tools --version` 输出 2.9.15 |

发布流程见 [`docs/releasing.md`](../releasing.md)；catalog 的更新约束见
[`docs/ai-contract.md`](../ai-contract.md)。

## 后续

- `AUDIT-006~008` 核实为非缺口：app 示例在 `app_getx/example`，map 示例在
  `map_google/example`，e2e 由 [`docs/agents/device-testing.md`](../agents/device-testing.md)
  覆盖，工具包示例即 README 命令。
- `packages/map_google/README.md` 的改动属于 docs drift（2.0.1 已发布），要等
  map_google 下次发版才更新到 pub.dev，按手册可延后。
