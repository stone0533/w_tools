## 改动类型

> 改了公开代码（`lib/` / `bin/` / CLI `templates/` / `catalog/` / `schema/`）的 PR 必须
> 保留这一段，并**至少勾选一项**（`check_pr_scope` 会拦截空 body / 全未勾选）。勾了公开类别（公开变化 / 删除废弃 / 新增包）时，CI 要求**每个改了公开代码的包**
> 都改自己的 `packages/<pkg>/CHANGELOG.md`（根包改 `lib/` / `pubspec.yaml` 时用根
> `CHANGELOG.md`），且本地版本要高于已发布基线（CI 带 `--online` 时用 pub.dev，取不到回退快照；或 `CHANGELOG` 有非空 `## Unreleased`）。
> CI 校验「CHANGELOG 是否被改 + 版本是否高于已发布基线」；版本段内容与破坏性说明
> 仍由 review 和 `check_public_api_diff` 核对。

- [ ] 内部重构（公开 API / 默认行为不变）
- [ ] 公开变化（API / 行为 / 新组件）
- [ ] 删除 / 废弃
- [ ] 新增包

## J-4 结论（有公开 API / 行为变化时必填）

> 矩阵列：公开类型 | catalog | teach | AGENTS zh | AGENTS en | explain | README | example。
> 至少写一行结论；完整矩阵可贴在这里或链接到 issue / analysis。
>
> 工具包（`w_tools_cli` / `w_tools_figma` / `w_tools_device` / `w_tools_e2e`）无 barrel / catalog：
> `catalog` / `teach` / `explain` 写 `N/A`，填 `AGENTS zh` / `AGENTS en` / `README` / `example`，
> 并写命令清单同步位置（顶层 usage / `help` / README / `docs/agents/cli.md`）。

- J-4 结论：

## 命名（`docs/naming.md` §7）

- [ ] 新公开类型有且只有一个角色后缀（§3.3）
- [ ] 没有双角色名、`Config` 装行为、`Options` 装 UI
- [ ] 新增 `Config` 已登记 `scripts/naming_baseline.yaml`
- [ ] 公开 `build()` 只在 `*Builder` 上
- [ ] 改名 / 删除已同步 catalog、README、example、migration、baseline

## 公开变化的教学同步（有公开 API / 行为变化时）

- [ ] 已跑 J-4（AI 教学覆盖审计，定义见 [`docs/ai-maintainer-prompts.md`](../docs/ai-maintainer-prompts.md) 的 J-4 一节），结论贴在本 PR
- [ ] catalog 的 `usage` / `pitfalls` / `related` / `dontUseFor` 已同步
- [ ] `docs/agents/<pkg>.md` 与 `templates/agents/{zh,en}/<feature>.md` 已同步（模板按 init feature 命名；`app_getx`→`app.md`、`map_google`→`map.md`）
- [ ] README / example / migration 已同步
- [ ] `bash scripts/preflight.sh --with-tests` 通过（本机 / 沙箱可跑 `--sandbox`，Flutter 测试由 CI 覆盖）

## 版本 / 发布物料（有公开 API / 行为变化时）

- [ ] 子包 `version` 已抬，`CHANGELOG.md` 有对应 `## x.y.z` 段（新段落排在最上面）
- [ ] 聚合子包已同步根 `pubspec.yaml` / `init/versions.dart` 下界（或写进 `## Unreleased`，由 K-2 折叠）
- [ ] `python3 scripts/check_versions.py` 通过（所有约束下界 == 当前版本）
- [ ] 破坏性变更已写 migration（或 CHANGELOG `### Breaking` / `### Removed` 里写明 `Type.member`）

## 自检

- [ ] `bash scripts/preflight.sh --with-tests`（或 `--changed` / `--sandbox`，说明未跑原因）
- [ ] 守卫 / 边界类用例已做**变异验证**（不适用写「不适用」）
  - 变异点：`路径:行`（`--from` → `--to`）
  - 命令：`bash scripts/mutate_guard.sh ... --expect '...' -- bash -c '...'`
  - 结果：`✓ 变异被杀死` / `✗ 变异存活（已补断言 / 已删守卫）`
- [ ] PR 内 commit 已整理（无 `wip` / `fixup`；一个 PR 只做一件事）
- [ ] 合并方式使用 **Merge commit**（见 `CONTRIBUTING.md` §6）
