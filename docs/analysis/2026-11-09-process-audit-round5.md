> 分析记录：带日期的历史评审，不代表当前状态。

# 全流程五轮审计：发布物 / 约束 / 本机可执行性（2026-11-09）

> 基线 `main @ 24aa15f3`。本轮把四轮审计之后的剩余问题按「发布物 → 版本约束 → 发布命令 →
> 规则一致性 → 本机执行层 → 小项」的顺序落地；只改流程与检查，不改库的公开 API。

## 0. 结论

| 优先级 | 项 | 结果 |
| --- | --- | --- |
| P1 | root / app_getx / map_google 的已发布 example 无法独立 `pub get` | 已修：包外 path override 移到 `example/pubspec_overrides.yaml`；map_google 改 hosted `w_tools_map`；发布脚本排除 overrides；新增 `check_example_paths.py` |
| P1 | CLI `cliConstraint` 停在 `^1.16.0`，测试硬编码过期值 | 已修：测试读 `packages/cli/pubspec.yaml`，约束抬到 `^1.17.1`；新增 `check_versions.py` |
| P1 | 文档要求 `gh pr merge --auto --merge`，但仓库 `allow_auto_merge=false` | 已修：快照 PR 命令改为 `gh pr checks --required` + `gh pr merge --merge`，并注明开启 auto-merge 后才用 `--auto` |
| P1 | 「约束什么时候抬」在 AGENTS / CONTRIBUTING / PR 模板 / releasing 之间互相矛盾 | 已统一为：功能 PR 可抬约束 + 写 `## Unreleased`；K-2 折叠并抬 root / CLI 版本；`check_versions.py` 保证下界 == 当前版本 |
| P2 | 本机 / agent 沙箱跑不动 preflight（FVM cache / telemetry） | 已修：`CI=true`、`dart analyze`、`--changed`、`--sandbox`；format_staged / check_templates_compile 也不再依赖 Flutter engine |
| P3 | 根包 CHANGELOG 策略不覆盖 root pubspec-only 变化 | 已修：`check_pr_scope` 根包策略要求「版本没抬 → 非空 `## Unreleased`」 |
| P3 | `.pubignore` 与 `check_published_links` 常量各写一份 | 已加测试：`.pubignore` 顶层目录项必须在常量里 |
| P3 | pre-push 只挡 main，版本检查要等 CI | 已加：干净工作区 + 有 `origin/main` + 非浅克隆时跑 `check_version_bump` |

**刻意未做**：

- CI 按改动包过滤矩阵：当前 PR 端到端 2–4 分钟，改造 `changes` + matrix 的成本高于收益；
  证书 / 计费有压力时再做。
- `mutate_guard.sh` 基线双跑：基线正是「不把原来就红当成变异被杀死」的保证，去掉会削弱
  测试有效性；保持现状。

## 1. 发布物 example

`pub publish --dry-run` 只分析 `lib` 和主 pubspec（实测输出 `Analyzing lib, pubspec.yaml`），
不解析 `example/`；CI 的 example analyze/test 又都在仓库内跑，所以 `../packages/qr`、
`../../app`、`../../map` 这些路径在发布物里断掉也一直是绿的。

落点：

- root `example/pubspec.yaml`、`packages/app_getx/example/pubspec.yaml`、
  `packages/map_google/example/pubspec.yaml`：去掉会发布的 `dependency_overrides` /
  包外 path；本地覆盖放 `example/pubspec_overrides.yaml`。
- `publish_package.sh` rsync 排除 `pubspec_overrides.yaml`（pub 只自动排除包根的那份，
  嵌套在 `example/` 下的会进 tarball）；`check_publish_drift.py` 同步排除。
- `check_example_paths.py`：会发布的 `example/pubspec.yaml` 的 `path:` 必须在包目录内，
  且不得带 `dependency_overrides`；preflight 调用。

验证：三个包的暂存副本在 `example/` 里 `pub get` 均通过（修复前分别报
`w_tools_qr at "../packages/qr"`、`w_tools_app at "../../app"`、`w_tools_map at "../../map"`）。

## 2. CLI 自约束

`packages/cli/pubspec.yaml` 1.17.0、pub.dev 1.17.0，但 `versions.dart` 的 `cliConstraint`
是 `^1.16.0`；`init_test.dart` 又写死 `expect(cliConstraint, '^1.16.0')`，所以测试不会红。
1.17.0 的功能 PR 抬了 CLI 版本，后续没有 K-2 发布准备 PR 来同步自约束。

落点：

- `init_test.dart` 读 `packages/cli/pubspec.yaml` 校验 `cliConstraint`；
- `versions.dart` 抬到 `^1.17.1`，`cliVersion` / pubspec / CHANGELOG 同步；
- 新增 `check_versions.py`：root `pubspec.yaml` 的聚合包下界、`subpackageConstraints`、
  `cliConstraint`、`wToolsDeviceConstraint` 都必须等于当前版本；preflight 调用。

## 3. 快照 PR 命令

仓库 `allow_auto_merge=false`，原文档 / `apply_snapshots.sh` 输出 / 测试都要求
`gh pr merge --auto --merge`。已改为先 `gh pr checks --required` 再
`gh pr merge --merge`；开启 auto-merge 后才用 `--auto`。

## 4. 约束抬升规则

统一为「功能 PR 可抬 + `## Unreleased`，K-2 折叠」：

- AGENTS / CONTRIBUTING / PR 模板 / releasing / AI 提示词 K-2 同一口径；
- `check_pr_scope` 新增根包策略：root pubspec/lib 变了但版本没抬时，必须有非空
  `## Unreleased`，不能追写已发布段；
- `check_versions.py` 保证下界 == 当前版本。

注意发布顺序：`versions.dart` 里 app_getx / map_google 的约束已抬到 2.1.1 / 2.0.1，
必须先发这两个子包，再发 CLI 1.17.1；根包 12.0.2 不被它们阻塞。

## 5. 本机 / agent 可执行性

- `flutter analyze` / `flutter test` 在沙箱下写 FVM `engine.stamp` 失败；`dart test` 的
  子进程写 `~/.dart-tool` 失败。
- 处理：preflight 顶部 `export CI=true`；analyze 改 `dart --suppress-analytics analyze`
  （同一 analyzer，能扫到 packages 下的错误）；新增 `--changed`（按 merge-base 映射包）
  与 `--sandbox`（跳过 Flutter 测试 / dry-run，明确打印由 CI 覆盖）。
- `format_staged.sh` 用 `dart --suppress-analytics`，退出码 1 才是「未格式化」，
  其它退出按环境 / 工具问题处理。
- `check_templates_compile.dart` 改 `dart pub get` / `dart analyze`，不再要求 Flutter engine。

验证：`preflight --sandbox` 静态档约 30s 全绿；`preflight --package cli --sandbox`
约 1m36s（含 483 条 cli 测试 + 模板编译）；`scripts/tests` 310 条通过。

## 6. 其余小项

- `check_published_links` 常量补 `.flutter-plugins` / `.DS_Store`，加 `.pubignore`
  顶层项覆盖测试。
- `.githooks/pre-push` 在干净工作区、有 `origin/main`、非浅克隆时跑
  `check_version_bump --base origin/main`，把 api-bump 红灯前移。

## 7. 验证记录

```text
bash scripts/check_docs.sh                         # 19 步通过
bash scripts/preflight.sh --sandbox                # 静态档通过（约 30s）
bash scripts/preflight.sh --package cli --sandbox  # 含 cli 测试 + 模板编译通过
python3 scripts/release_check.sh                   # 0 提醒
python3 scripts/check_versions.py                  # 通过
python3 scripts/check_version_bump.py --base main  # 14 包 + 根包通过
bash scripts/check_pr_ready.sh /tmp/pr.md main     # PR 级门禁通过
```
