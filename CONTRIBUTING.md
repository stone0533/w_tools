# 贡献指南（新增/修改组件）

> 判据先看 [`docs/conventions.md`](docs/conventions.md)：这个组件**该不该**进包。
> 这里只写「决定进包之后，必须带齐什么」。

## 1. 新增组件的四条硬性要求

缺任何一条都不要提交：

- [ ] **设计稿实测尺寸写进注释**：宽/高/圆角/颜色/行距/间距，以及「为什么是这个值」
- [ ] **默认值可用**：不传任何参数也能渲染出一个合理的组件
- [ ] **至少一个测试**：`packages/<pkg>/test/` 下的 widget 测试；像素敏感的加上 golden
- [ ] **`CHANGELOG.md` 条目 + 版本号**：子包版本必须抬；如果该子包被根包聚合，
      根包的 `^x.y.z` 约束要一起改（改完跑 `bash scripts/release_check.sh`；
      它只**提醒**下界落后，发布根包前必须跑 `--strict`）。
      CI 的 `api-bump` job 会比对 base 与 HEAD 的公开 API 表面：API 变了但版本既没抬、
      也不高于**已发布**基线（CI 用 pub.dev 版本，取不到才退回快照）时直接失败；
      已经在未发布版本里的改动可以沿用。

## 2. 接口设计

通用原则见 [`docs/conventions.md`](docs/conventions.md) §6；这里只写最容易违反的两条：

- **命名**先看 [`docs/naming.md`](docs/naming.md) 的 30 秒流程与角色表（§3.3）：
  `W` 前缀、角色后缀、同义择一、review 清单都在那里。新增 `Config` 必须登记
  [`scripts/naming_baseline.yaml`](scripts/naming_baseline.yaml)，并按 §7 清单在 PR 里写结论。
- **参数 ≤ 3 个**：合成一个组件；**> 3 个**：说明它们是两个组件，不要硬合并
  （教训：一个 311 宽的弹窗壳，因为要塞内容/按钮/内边距/标题色，最后变成 4 个参数——
  正确的做法是「只共用壳，内容和按钮各自组装」）
- **布尔参数**要么全部默认 `false`，要么用一个 enum（避免 `type: true, compact: false` 这种调用点）
- **第三方类型**只要出现在公开签名里，就由本包 `w_tools_*.dart` barrel `export ... show` 转出
  （正例：toast 已转出 `BotToastInit` / `BotToastNavigatorObserver` / `CancelFunc`；
  反例：map 暴露 `CameraPosition` 却不转出 `google_maps_flutter`）。
  例外必须在 README 安装段写清“需自行添加的包 + 约束”。

## 3. 文档

- 表单相关改动先看 [`docs/agents/form.md`](docs/agents/form.md)
- 组件先登记到 [`packages/cli/catalog/components.yaml`](packages/cli/catalog/components.yaml)（`useFor` / `dontUseFor`），
  再跑 `cd packages/cli && dart run tool/gen_catalog.dart` 生成 [`docs/modules/components.md`](docs/modules/components.md)；
  **不要手改生成物**
- 「不要用在哪」比「怎么用」更有价值——误用是主要故障源
- 该子包的 `docs/modules/<module>_module.md` 补一段说明（如果有行为细节）
- 改完 `docs/` 后跑 `bash scripts/check_docs.sh`（链接、旧命令、安装版本、文档符号 / import 边界、
  已删除 API、索引、事实一致性）

## 4. 测试要求

- 行为测试放 `packages/<pkg>/test/`，并在该子包 `dev_dependencies` 声明依赖
  （子包要能脱离仓库根独立 `flutter test` / 发布）
- 像素敏感组件（卡片、弹窗、图标对齐）加 **golden**：
  ```bash
  flutter test --update-goldens packages/ui/test/image_golden_test.dart
  ```
- 根 `test/` 只放聚合契约（`w_tools.dart` 重导出）与跨包回归，单包行为测试放回 `packages/<pkg>/test/`
- `packages/cli` 是纯 Dart 包：用 `dart test`，不要引入 `flutter_test`
- 行为测试只 import barrel；确实需要内部 helper 的测试放 `test/internal/`（不限于纯内部逻辑）。
  `check_test_imports.py` 会挡住全仓 `test/`、`integration_test/`、`example/test/` 里的 `src` import；
  存量白盒测试登记在 `scripts/test_imports_baseline.yaml`，只减不增（修好一个删一行）。

## 5. 发布

- 实际发布用 `bash scripts/publish_package.sh <包目录>`（根包用 `.`），
  **不要**在包目录直接 `flutter pub publish` —— `workspace:` 字段会被原样发布，
  消费方 `dart pub deps` 会失败。正式发布时脚本会自己先 `git fetch`，再要求：干净工作区、
  `main` 且 `HEAD == origin/main`、`release_check.sh --strict` 通过；子包还要过快照基线守卫
  （最新快照已提交，本地版本不得低于 / 等于快照，除非是新包首发）。`--force --reason "..."` 只用于明确的例外，reason 会打日志。
- 版本策略与流程见 [`docs/releasing.md`](docs/releasing.md)
- 公开 API 变化（删除 / 类型变化 / 可空性变化）先跑
  `python3 scripts/check_public_api_diff.py --package <pkg>`；它要求变化写进
  **当前 pubspec 版本**对应 CHANGELOG 段的 `### Breaking` / `### Removed`，或 migration。
  基线在 `scripts/api_snapshots/`：发布脚本先把快照写到 `.w_tools/release-snapshots/`
  （gitignored），一批发完运行 `bash scripts/apply_snapshots.sh` 应用过来，**记得提交**；
  缺基线时门禁直接失败（不再静默跳过）。
  快照提交**走分支 + PR**：`pre-push` 禁止直接 push main，而发布脚本要求
  `HEAD == origin/main`。同一波还要发根包时，先合入快照 PR 再发根包；
  细节见 [`docs/releasing.md`](docs/releasing.md) 第 7 步。
- 有公开 API / 行为变化时，合并前跑一次 **J-4（AI 教学覆盖审计）**，并在 PR 里贴矩阵结论；
  J-4 只读，不修改文件。定义与提示词见
  [`docs/ai-maintainer-prompts.md`](docs/ai-maintainer-prompts.md) 的 J-4 一节。
  至少确认：catalog、`docs/agents/<pkg>.md`、
  `templates/agents/{zh,en}/<feature>.md`（模板按 init feature 命名，不是包名；
  `app_getx` 用 `app.md`、`map_google` 用 `map.md`）、README、example 都已同步。
  矩阵列至少：公开类型 | catalog | teach | AGENTS zh | AGENTS en | explain | README | example。
  矩阵目前没有机器落点（PR 模板里只有一行结论位），所以 J-4 的结论要写进 PR 正文。
- 自动门禁覆盖符号 / 锚点 / 生成物 / 入口名（J-4A），但教学方法是否讲清楚仍需要 J-4 人工判断。

## 6. Git / PR 流程

- 首次检出先跑 `bash scripts/install_git_hooks.sh`；`.githooks/pre-push` 会阻止直接 push main。
- 需求 / 可复现的 bug 先开 issue：反馈类用 [`.github/ISSUE_TEMPLATE/feedback.md`](.github/ISSUE_TEMPLATE/feedback.md)
  （自动带 `needs-triage`），其余用空白 issue；小修 / 文档 / 内部重构可以直接开 PR。
  PR 链 issue 时写 `Closes #n`。issue 的读写与 label 约定见
  [`docs/agents/issue-tracker.md`](docs/agents/issue-tracker.md) 与 [`docs/agents/triage-labels.md`](docs/agents/triage-labels.md)。
- 公开变化走 feature 分支 + PR，等 Required checks 通过后合并；不要用管理员绕过。
- PR body 必须带仓库模板的「## 改动类型」段，并至少勾选一项（改了公开代码
  `lib/` / `bin/` / CLI `templates/` / `catalog/` / `schema/` 时 `check_pr_scope` 会强制；
  空 body 或四类全空都会失败）。
  用 `gh pr create --fill` 创建后要 `gh pr edit --body` 补上四类勾选；只改脚本 / 文档的
  PR（例如快照 PR）不受这条限制。
- 发布前用 `bash scripts/check_pr_checks.sh [PR号]` 确认 Required checks（需要 `gh`）。

### 合并方式：固定 Merge commit

仓库只允许 **Merge commit**（GitHub 已关闭 Squash / Rebase，合并后自动删远端分支）。这样每个逻辑 commit 的**原始 SHA 与作者时间**都会保留：

```bash
git log --first-parent main   # PR 级历史（发布说明用这个）
git log main                  # 完整细节（每个逻辑步骤）
```

- **合并前整理 commit**：用 `git rebase -i` 收掉 `wip` / `fixup` / `fix test`；每个 commit 用
  conventional 前缀（`feat` / `fix` / `docs` / `chore` …）+ 一句人话；
- **一个 PR 只做一件事**：顺手修（如 CI 红灯）单独开 PR，不要塞进主题 PR；
- **合并只在 GitHub 上做**：本地只 `git pull --ff-only`，不要先把分支合进本地 main 再开 PR；
- **回滚一个 PR** 用 `git revert -m 1 <merge-sha>`，并在 PR / CHANGELOG 里说明；
  同一分支再合回来需要先 revert 掉这次 revert。

> 不用 Rebase 合并：它会重写 committer 时间与 SHA（PR #1 踩过，5 个 commit 的时间全变成合并时刻）；
> 不用 Squash：会丢掉 agent 一次会话里「门禁 / 基线 / 测试迁移」这类分层步骤的叙事。

## 7. grep / 检查脚本经验

写 `grep` / `rg` 检查脚本时：

- 行首锚点用 `grep -rh`，不要用 `-rn`。`-n` 会在行首加 `file:line:`，导致 `^//` 这类正则永远不命中。
- 如果输出带 `file:line:` 前缀，过滤注释要用 `^[^:]*:[0-9]+:\s*//`，不要用 `^\s*//`。
- 先拿一个已知违规样本跑一次，确认脚本真的能报出来，再接入 CI。

这些是维护者检查脚本的经验，不进入消费方 AGENTS。

## 8. 组件从「消费方暂存层」上移时

1. 确认满足上面四条
2. 把消费方 `lib/app/design_system/` 里的文件删掉，引用改成 `package:w_tools_ui`
3. 该消费方的 `toolkit.dart`（聚合入口）里加一行 `export`
4. 在消费方的 issue/PR 里注明「已上移」，并清掉暂存层里对应的 `// STAGED:` 标记
   （本仓库没有 `docs/agents/w_tools.md` 这类待上移清单，别去找）

## 9. 使用反馈（`docs/feedback/`）

消费方撞到的问题按固定格式汇总在 [`docs/feedback/`](docs/feedback/README.md)。

**完整流程（消费方 / 维护者两套步骤、一条完整示例）只维护一份**，见
[`docs/feedback/README.md`](docs/feedback/README.md)。本节只留三条硬规则：

1. **有反馈才建文件**：`docs/feedback/<包>.md`，不要为每个包预建空文件；
2. `已修复` **必须带版本号**（+ commit），细节写进 CHANGELOG；
3. 已闭环压成表格一行；提交前跑 `bash scripts/check_feedback.sh`。

### 放哪里（容易搞错）

| 内容 | 位置 | 理由 |
| --- | --- | --- |
| 反馈、契约、ADR、agent 指南 | `docs/` | 人读、需评审、不可再生成 |
| manifest、缓存、索引 | 消费方 `.w_tools/` 或 `~/.cache/w_tools/` | 机器本地、删了能重建 |

> 一句话：**`.w_tools/` 只放「删了能重建」的东西。**
