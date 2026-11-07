> 分析记录：带日期的历史评审，不代表当前状态。

# 全流程四轮审计：建议落地顺序的执行记录（2026-11-08）

> 基线 `main @ 84a188a4` + 工作区未提交改动（`check_published_links.py`、`check_pr_scope` 策略、
> `mutate_guard.sh` 基线、README 绝对链接）。本轮**只处理**三轮审计 §16.1 的「建议落地顺序」，
> 不扩展范围；每条先复现、再补失败测试 / 修复。
> 环境：本轮最终 `bash scripts/preflight.sh --with-tests` 全绿（format / analyze / docs / 包测试 /
> example / 模板编译均通过）。

## 0. 结论

| 优先级 | 项 | 结果 |
| --- | --- | --- |
| P0 | `check_published_links` 的 pub.dev / tarball 目标与覆盖范围 | 已改为 tarball 目标，文案与扫描范围同步；当前发布物无断链 |
| P0 | `check_pr_scope` 新用例依赖 toast 真实版本 | 已改为临时包 fixture + mock，不再随 toast 抬版本变红 |
| P0 | `unittest.main()` 位置导致直接跑文件漏 6 个用例 | 已移到文件末尾，直接跑 = discovery = 48 tests |
| P1 | 新 CHANGELOG / 根包 / 发布物策略的文档同步 | PR 模板、AGENTS、CONTRIBUTING、scripts README、ai-contract 已同步 |
| P1 | 根包 `w_tools` 版本门禁 | `check_version_bump` 增加根包 export 检查；无版本抬升 → exit 1 |
| P2 | 分支保护 `strict=false` | 已设为 `strict=true`（GitHub 远端设置） |
| P2 | `check_pr_scope` 对齐 pub.dev 基线（可选） | 已落地：`--online` + CI flag + 测试 |
| P3 | `touches_changelog` 跨包语义 | 已改为「每个被改包都要有自己的 CHANGELOG」 |
| P3 | 只改文档 + 勾「公开变化」的误报 | 已跳过 CHANGELOG 检查 |
| P3 | `check_docs` 不扫 CHANGELOG | 已把根 / 包 CHANGELOG 加入相对链接与锚点检查 |
| P3 | 绝对链接没有门禁 | `check_published_links` 增加本仓库 GitHub 绝对 URL 路径校验 |
| P3 | `check_published_links` 常量硬编码 | 未做，保留 |
| P3 | `mutate_guard` 基线双倍耗时 | 未做，保留（行为正确，只是慢） |

## 1. P0：`check_published_links` 目标与范围

**复现**：扩展扫描到 CHANGELOG / CONTRIBUTING 后，当前仓库有 18 处断链：

```text
CONTRIBUTING.md（15 处 docs/ scripts/ packages/ .github/）
packages/cli/templates/README.md:43（../../docs/...）
packages/ui/CHANGELOG.md:68（../../docs/...）
```

同时确认 pub.dev 会把相对链接改写成 repository 下的 GitHub URL（root `docs/conventions.md`、
ui `../../docs/modules/ui_module.md`、ui changelog、map `../map_google/README.md` 都能解析）；
真正断的是 tarball / pub cache，因为发布物不含 `docs/`、`scripts/`、`packages/`。

**修复**：
- `scripts/check_published_links.py`：docstring / 错误文案改成「tarball / pub cache」；
  扫描范围扩到根 `README.md` / `CHANGELOG.md` / `CONTRIBUTING.md` / `example/**/*.md`
  和每个包会发布的 Markdown（排除 `test/`、`build/`、`docs/` 等发布脚本排除项）；
  包内链接现在还禁止指向包内被排除的子目录。
- 修 18 处断链：`CONTRIBUTING.md`、`packages/ui/CHANGELOG.md`、
  `packages/cli/templates/README.md` 改成 GitHub 绝对 URL。
- 增加本仓库 GitHub 绝对 URL 的路径存在性校验（路径不存在 → 失败），避免转成绝对链接后
  失去 `check_docs` 的相对链接校验。

**验收**：

```text
python3 scripts/check_published_links.py                 # 通过
python3 -m unittest discover -p 'test_*.py'              # 249 tests OK
```

## 2. P0：`check_pr_scope` 测试的版本耦合

**复现**：新增用例把 `snapshot='2.0.0'`、`version='2.0.1'` 传给 `_main`，但旧 helper 只 mock
`latest_snapshot_version`，仍读真实 `package_version('toast')`；在 toast 还是 `2.0.0` 时
`_main` 返回 1，用例期望 0 → 失败。

```text
python3 -m unittest test_check_pr_scope.MainTest.test_bumped_version_with_old_changelog_section_passes
# AssertionError: 1 != 0
```

**修复**：`_main` 增加 `version` / `changelog` fixture（临时 `ROOT` + 假 `packages/toast/CHANGELOG.md`），
同时 mock `package_version` 与 `latest_snapshot_version`；三个 CHANGELOG 策略用例不再依赖真实 toast。

**验收**：docstring 中的命令通过；全量 `scripts/tests` 249 tests OK。

## 3. P0：`unittest.main()` 位置

**复现**：

```text
python3 scripts/tests/test_check_pr_scope.py          # 39 tests
python3 -m unittest test_check_pr_scope               # 45 tests
```

`ChangelogPolicyTest` 定义在 `unittest.main()` 之后，直接跑文件时不会被收集。

**修复**：把 `if __name__ == '__main__'` 移到文件末尾。

**验收**：直接跑文件与 discovery 都是 48 tests（本轮新增用例后）。

## 4. P1：文档同步

**改动**：
- `.github/PULL_REQUEST_TEMPLATE.md`：不再说「CI 只校验有没有改 CHANGELOG」；写清
  CHANGELOG + 版本高于快照 / 非空 `## Unreleased`，版本段内容由 review / api diff 核对。
- `AGENTS.md`：公开变化一节补根包 CHANGELOG / 根包版本 / Unreleased。
- `CONTRIBUTING.md`：§1 补根包 export 版本；§6 补 `check_pr_scope` 的完整条件。
- `scripts/README.md`：`check_docs` 行、`check_pr_scope` 行、`check_version_bump` 行、
  `check_published_links` 行与「检查边界」。
- `docs/ai-contract.md`：5.11 更新，新增 5.12「发布物链接」；边界说明同步。

**验收**：`bash scripts/check_docs.sh` 全绿（19 步）。

## 5. P1：根包版本门禁

**复现**：在 `lib/w_tools.dart` 末尾临时加一行 export，不改根包版本：

```text
python3 scripts/check_version_bump.py --base main
# ✗ w_tools: 根包 re-export 有变化，但版本 11.0.0 没有高于 base 11.0.0
# exit 1（修复前 exit 0）
```

**修复**：`scripts/check_version_bump.py` 增加 `root_export_surface` / `root_requires_bump`；
只比较 export 行（排序后），默认模式同时检查根包；`--package w_tools` 可只跑根包。

**测试**：`scripts/tests/test_check_version_bump.py` 新增 4 个 `RootPackageTest` 用例
（export 解析、无抬升失败、已抬升通过、仅顺序变化不算变化）。

**验收**：

```text
python3 scripts/check_version_bump.py --base main        # 通过（14 个包 + 根包）
python3 -m unittest test_check_version_bump              # OK
```

## 6. P2：分支保护

`gh api .../branches/main/protection/required_status_checks` 原为 `strict=false`；
已 PATCH 为 `strict=true`（contexts 仍为 `Required checks`）。这是远端设置，不在仓库 diff 中。

## 7. P3：顺手项

| 项 | 改动 | 测试 |
| --- | --- | --- |
| `touches_changelog` 跨包语义 | `scripts/check_pr_scope.py` 改为每个被改包都要求自己的 CHANGELOG | 新增「改 ui 只改 toast CHANGELOG」失败用例 |
| docs-only + 公开变化误报 | 没有公开代码 / 根包公开面变化时跳过 CHANGELOG 检查 | 新增 README-only 用例 |
| `check_docs` 不扫 CHANGELOG | 根 / 包 `CHANGELOG.md` 加入相对链接与锚点检查 | `bash scripts/check_docs.sh` |
| 绝对链接无门禁 | `check_published_links.py` 校验本仓库 GitHub 绝对 URL 的路径存在 | 新增缺失路径 / 存在路径用例 |

## 8. 验证记录

```text
python3 scripts/check_published_links.py        # 通过
bash scripts/check_docs.sh                      # 19 步全 ✓
cd scripts/tests && python3 -m unittest discover -p 'test_*.py'   # 249 tests OK
python3 scripts/ci_matrix.py --check            # 通过
python3 scripts/check_gate_coverage.py          # 通过
python3 scripts/check_version_bump.py --base main   # 通过（14 包 + 根包）
bash scripts/preflight.sh --with-tests          # 门禁通过（format / analyze / docs / 全部测试）
```

## 9. 未解决项

- **P3**：`check_published_links.py` 的排除常量仍与 `.pubignore` / 发布脚本各写一份，没有守卫；
  建议后续加「`.pubignore` 顶层排除项都在常量里」的测试。
- **P3**：`mutate_guard.sh` 的基线让每次变异跑两遍命令，耗时翻倍；行为正确，未改。

## 10. P2-7 落地（2026-11-08）

- **复现**：快照 `1.9.0`、本地 `2.0.0`、pub.dev `2.0.0`；旧实现用快照当已发布基线，
  `changelog_policy_error_for(...)` 返回 None（放行）——行为变化可以写进已发布版本的 CHANGELOG。
- **修复**：`check_pr_scope.py` 增加 `--online`，复用 `check_version_bump.published_version`
  （取不到 pub.dev 时回退快照并打印 warning）；CI 的 `api-bump` job 加 `--online`。
- **测试**：`test_online_baseline_does_not_trust_stale_snapshot`（stale 快照 → exit 1）、
  `test_online_baseline_falls_back_when_pubdev_missing`（无线上基线 → 跳过）。
- **验收**：`test_check_pr_scope` 50 tests；`check_docs` 19 步；`preflight --with-tests` 门禁通过。
