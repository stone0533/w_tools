# scripts 运行手册

本文只回答三个问题：

```text
这个脚本做什么？
什么时候该跑？
被谁调用？
```

详细规则不在这里重复，见 [AI 使用契约](../docs/ai-contract.md)、
[接入约定](../docs/conventions.md)、[发布流程](../docs/releasing.md)。

---

## 只记一条命令

日常提交前 / 合并前：

```bash
bash scripts/preflight.sh --with-tests
```

只跑一个包（静态门禁 + 该包测试 + example）：

```bash
bash scripts/preflight.sh --package ui
```

这一条覆盖：

```text
format / analyze / docs（含符号 / 已删除 API / 安装版本）
公开类型 catalog / 弃用 / 命名 / 风格
API 快照逐包 diff / 测试 import 边界 / scripts 单测
catalog / templates 生成物新鲜度
release check
CI 包矩阵与门禁步骤 ↔ manifest / preflight 一致性
门禁覆盖（每个检查脚本都有入口，且在本手册登记）
全部包 + example + root 测试 + root example 测试 + 模板编译
```

**CI-only（本地 preflight 不跑）**：`check_version_bump.py` / `check_pr_scope.py`（`api-bump`
job，需要 PR body 与 base sha）、每包 `publish_package.sh --dry-run`（本地要
`--with-dry-run`）、`min_sdk` 的 analyze / test。所以「本地全绿」不等于「PR 一定绿」。
CI 的静态门禁直接调用 `preflight.sh`（不再手抄步骤），包矩阵由
`scripts/ci_matrix.py` 从 `packages.manifest` 生成。两边不再各维护一份清单。
重量级 job（umbrella / packages / min_sdk）由 `changes` job 按路径门控：纯文档改动时它们
全部 skip，仍会跑 `matrix` / `changes` / `docs`（`check_docs.sh` + `release_check` +
`ci_matrix --check` / `check_gate_coverage`）/ `api-bump` / `required` —— 这几个都不装
Flutter，合计约 10 秒；只改 `scripts/` 时跑 umbrella 的静态门禁 + docs，不跑 15 个包矩阵。
分支保护只要求最后的 `Required checks` 聚合 job，避免 required check 名字随包矩阵变化。

> 路径过滤在 `.github/workflows/ci.yml` 的 `changes` job，用 `dorny/paths-filter@v4` +
> `predicate-quantifier: 'some-with-excludes'`。**过滤器只写正向规则，不要再加 `!` 排除**：
> 默认的 `some` 会让 `!` 匹配「不在排除范围内」的所有文件（两个过滤器都恒为 true，纯文档 PR
> 跑满 17 个 job，PR #2 实测）；而 `some-with-excludes` 下 `!` 又没有「再包含」语义 ——
> 曾用 `!packages/**/*.md` 排除文档，结果把 `packages/cli/templates/**` 里的模板 md 一起挡掉，
> 改模板不跑生成物新鲜度。`python3 scripts/ci_matrix.py --check` 现在会拒绝带 `!` 的过滤器。

---

## 脚本分类

### 总门禁

| 脚本 | 作用 | 何时跑 |
|---|---|---|
| `preflight.sh` | 全仓门禁总入口（CI 直接调用它） | 提交前 / 合并前 |
| `install_git_hooks.sh` | 安装 `.githooks`（pre-push 阻止直接 push main） | 首次检出 / 流程要求 |
| `check_pr_checks.sh` | 用 `gh pr checks --required` 确认 PR Required checks | 发布前 |
| `check_docs.sh` | 文档与 AI 资产检查总入口（链接 / 链接锚点 / 旧命令 / 符号 / 已删除 API / 安装版本 / catalog 锚点 / 教学覆盖，每步会打名字；`--skip-feedback` 供不装 Flutter 的 CI docs job 用） | 只改文档时可单独跑 / CI docs job |
| `ci_matrix.py` | 从 `packages.manifest` 生成 CI 包矩阵；`--check` 查漂移（关键正向过滤器 / quantifier / required 接线 / docs job meta 检查 / `example` 列 ↔ `example/test`） | preflight / CI docs job / matrix job |
| `check_gate_coverage.py` | 每个 `scripts/*.sh` / `*.py` 都必须被 preflight / check_docs / release_check / workflow 之一调用（人工脚本在脚本内 `MANUAL` 写明理由），且在本手册登记 | preflight / CI docs job |
| `packages.manifest` | 包名 / 路径 / runner / root / example 的单一清单 | 新增包 / 改测试入口 |

`check_docs.sh` 是 `preflight` 的子集，**不要只跑它就说全仓通过**。

`packages.manifest` 是 CI 矩阵、preflight、release_check 的共同来源；新增包时先改它。

### 文档 / AI 契约

| 脚本 | 作用 | 调用方 |
|---|---|---|
| `check_doc_symbols.py` | 文档 `W*` 符号 / 成员是否存在，且 import 的包（根 barrel / 子包 / package 级 re-export）按 barrel 真正导出能提供该符号；用到未导出的内部类型会报错（含 root `README.md` / `AGENTS.md` / `packages/*/AGENTS.md`、`docs/naming.md` 行内示例） | check_docs / preflight |
| `check_docs_snippets.py` | 已证伪 API / components 表格列数 | check_docs |
| `check_docs_duplicates.py` | `docs/modules` 与包 README 不再复制同一段 dart 示例 | check_docs |
| `check_docs_versions.py` | 文档不得声明已发布/待发布版本 | check_docs |
| `check_async_docs.py` | async 公开文档旧 API | check_docs |
| `check_package_docs.py` | 当前文档安装约束（仍写成 caret 的示例必须下界 == 当前版本，非 caret 直接失败；`pub add` 命令不参与）/ 跨包示例 / example 链接 | check_docs |
| `check_docs_facts.py` | 规模数字（从 pubspec 推导）/ 文档索引完整性（含每个 ADR 在 `docs/README.md` 留行）/ ADR 编号、状态、索引一致、补充日期 / doctor 规则表一致性 / 旧命令 | check_docs |
| `check_agents_consistency.py` | `docs/agents` 索引与规则页的入口名 + 高频规则短语一致 | check_docs |
| `check_prompt_docs.py` | 文档命令可执行（提示词手册 **+ `packages/cli/templates/ai/*.md`**：脚本 / flag / cwd / 占位符（带空格的写法逃过校验，模板里不许写空格）/ 场景编号（§1 ↔ 标题双向、重复标题）/ `w_tools` 子命令 flag（含 `\` 续行）/ 手册内 docs 路径 / 生成器与测试文件存在；其余当前文档：脚本存在 + flag 存在 + CLI flag 存在；历史目录不参与） | check_docs |
| `check_public_catalog.py` | 公开类型 → catalog 反向检查（双向：新类型要登记，基线里的旧名字也要删） | preflight |
| `check_catalog_anchors.py` | catalog 的 `docsAnchor` 必须能在 `docs/modules/*_module.md` 的标题里找到 | check_docs / preflight |
| `check_catalog_symbols.py` | catalog `usage` / `useFor` / `related` 里的 `W*` / `W*.member` 必须真实存在于公开 API | preflight |
| `check_public_api_diff.py` | 公开 API 快照 diff：删除 / 类型/可空性 / 方法 / 构造器变化必须出现在**当前 pubspec 版本**的 CHANGELOG Breaking/Removed 或 migration（构造器可选参数可记 Added）；缺基线直接失败 | preflight |
| `check_test_imports.py` | `package:w_tools_<pkg>/src/...` 只允许出现在 `test/internal/`；全包检查，存量登记在 `test_imports_baseline.yaml`（只减不增） | preflight |
| `check_teaching_coverage.py` | 11 个库包的 `entrypoints.yaml` 入口必须出现在 docs/agents / 模板 zh+en / README（有 example 还要在 example/lib）；app_getx / map_google 共用 app / map 规则页（J-4A） | check_docs / preflight |
| `check_git_sync.sh` | 先 fetch 远端，再要求当前分支有 upstream 且 ahead/behind 都为 0；`release_check --strict` 调用 | release_check / 发布前 |
| `check_removed_api.py` | 已删除 API 是否还在推荐文档 / catalog（含 root + `packages/*/AGENTS.md` + `catalog/components.yaml`） | check_docs / preflight |
| `check_naming.py` | 规则在 `docs/naming.md`：公开 `W*Config` / 前缀例外读 `naming_baseline.yaml`；Dart 文件名 snake_case | preflight |

### API / 风格

| 脚本 | 作用 | 何时跑 |
|---|---|---|
| `check_deprecations.py` | `@Deprecated` 的 `remove-in` 是否到期；只认紧贴声明上方的注释块（相邻弃用不会互借） | preflight |
| `list_removals.py` | 列出所有待删除弃用项 | 准备大版本 |
| `check_style_literals.py` | form/toast/async 默认样式禁止硬编码颜色 | preflight |
| `check_version_bump.py` | 对比 PR 的 **merge-base** 与 HEAD 的公开 API 表面：版本降级、版本不高于已发布基线、或版本没抬 → 失败（已抬过且高于已发布基线的未发布版本可以继续沿用；内部重构不会误报；无 barrel 的 cli 显式跳过）。`--online` 时用 pub.dev 当已发布基线（取不到回退仓库快照并提醒），修 `git archive` 失败被当成新包 | CI `api-bump` job（带 `--online`）/ 本地 `--base main` |
| `check_pr_scope.py` | 读 PR 模板：改了公开代码（`lib/` / `bin/` / CLI `templates/` / `catalog/` / `schema/`）的 PR 必须有「## 改动类型」段且至少勾选一项；空 body 也失败。勾了公开类别（公开变化 / 删除废弃 / 新增包）时，**每个改了公开代码的包**都要改自己的 CHANGELOG | CI `api-bump` job |
| `check_feedback.sh` | `docs/feedback/` 台账检查 | check_docs |

### 发布

| 脚本 | 作用 | 注意 |
|---|---|---|
| `release_check.sh` | 版本 / CHANGELOG / 根约束 / README / pub.dev 漂移；`--package` 会报「快照高于本地 / 缺失 / 等于本地」的基线提示；完整 `--strict` 还要求每个包最新快照已 tracked，且**根聚合包**的版本 == 本地（工具包 / 不聚合的包允许待发布）；`--online` 全部取不到时返回 2 | 发布前先跑 `--strict` |
| `release_status.py` | 发布状态总表：本地 / 线上 / API 快照 / 结论；`--check` 把「落后 / 快照漂移 / 缺快照 / pub.dev 404」判失败，「待发布」正常；网络不可达重试后返回 2（周检按跳过处理）；`--check` 没带 `--online` / `--require-*` 返回 3（用法错误）；`--require-tracked --require-local` 做离线快照结构检查（`--require-local` 只要求**根聚合包**快照 == 本地），`--quiet` 只输出异常；`pending_first_release.txt` 里的新包 404 只警告（结论「待首发」） | 发布后核对 / 每周一 CI / 根包发布前 |
| `publish_package.sh` | 在去掉 workspace 的暂存副本里发布；**正式发布前自己 fail-closed**：先 `git fetch`，再查干净工作区 + `main` 且 HEAD == `origin/main` + `release_check --strict` + 子包快照基线守卫（快照必须已提交，本地版本不得低于 / 等于快照，除非新包在 `pending_first_release.txt`）（`--force --reason "..."` 才跳过，reason 会打日志）；快照写入失败保留 staging；发布成功后快照先写到 `.w_tools/release-snapshots/` | **真正发布会执行，不是 dry-run** |
| `apply_snapshots.sh` | 把 `.w_tools/release-snapshots/` 里暂存的 API 快照应用回 `scripts/api_snapshots/`，并打印快照 PR 的命令；不 commit / 不 push | 一批发布结束后、发根包前 |
| `pending_first_release.txt` | 已合并、尚未首次发布到 pub.dev 的包（裸名）；`release_status` 对 404 只警告，避免新包首发窗口让周检变红 | 新包合并 → 首发成功后删行 |
| `install-gh.sh` | GitHub CLI 安装 / 登录向导 | 一次性 |

### 包内检查

| 工具 | 作用 | 何时跑 |
|---|---|---|
| `packages/cli/tool/gen_catalog.dart --check` | `catalog.g.dart` / `components.md` 与 `components.yaml` 一致 | preflight / 改 catalog |
| `packages/cli/tool/gen_templates.dart --check` | `templates.g.dart` 与 `templates/` 一致 | preflight / 改 templates |
| `packages/cli/tool/check_templates_compile.dart` | init 模板生成后能否通过 Flutter analyze | `preflight --with-tests` |
| `packages/cli/test/internal/ai_contract_test.dart` | teach / prompt / AGENTS feature 契约 | `preflight --with-tests` |

### 测试有效性（人工）

| 脚本 | 作用 | 何时跑 |
|---|---|---|
| `mutate_guard.sh` | 定向变异：临时破坏一段「被守逻辑」，确认目标用例**变红**后无条件还原；变异后仍绿说明用例空转或守卫无价值 | 写 / 审守卫、错误分支、边界 clamp 的用例时 |

```bash
bash scripts/mutate_guard.sh \
  --file packages/form/lib/src/components/fields/multi_dropdown_field.dart \
  --from 'if (!state.mounted) return;' --to '// mutated' \
  --expect 'after dispose' \
  -- bash -c 'cd packages/form && flutter test test/form_gaps_test.dart --plain-name "multi 弹层打开后字段卸载"'
```

- 测试命令必须用 **`bash -c '...'` 包成一个参数**。直接写 `-- cd packages/form && flutter test ...` 会被调用方 shell 按 `&&` 拆开，脚本只收到 `cd packages/form`：在仓库根跑报「变异存活」、在 `packages/form` 里跑报「变异被杀死」，两次测试其实都没跑（脚本会拦下这种写法）。
- `--expect <特征串>` 要求红输出里出现该串，避免把「编译失败」当成「用例变红」；不写时也会显式拒绝 `Compilation failed` / `Failed to load` / 没匹配到用例。
- 退出码：`0` 杀死 / `1` 存活 / `2` 无效（含超时）/ `3` 还原失败。`--timeout <秒>` 默认 600，`0` 关闭。
- 变异点必须**恰好命中 1 处**；脚本用 `trap` 保证任何退出路径都会还原文件，并用 `cmp` 校验还原结果，跑完 `git status` 应只剩你自己的改动。

### 检查边界

这些是启发式检查，不是完整编译器/analyzer：

- `check_doc_symbols.py`：正则匹配符号和成员（扫 ```dart 代码块；所有推荐文档额外扫行内
  `` `WXxx` `` 的类型名，但同一行写了「已删除 / 不要 / 没有 / 反例」等上下文时放行；
  成员检查仍只覆盖代码块与 `docs/naming.md`）；
- `check_docs.sh` 的链接锚点：按 GitHub slug 近似（去反引号 / 标点、空格转 `-`），
  不处理重复标题的 `-1` 后缀；新增重名标题时写成唯一标题；
- `check_docs_snippets.py`：只拦截已知错误写法；
- `check_public_catalog.py`：基于 export/part 的静态扫描 + `uncataloged.yaml` 基线（双向）；
- `check_naming.py`：只认 barrel 导出的公开名字（`hide` / `lib/src` 内部实现不参与），
  例外读 `naming_baseline.yaml`；
- `check_docs_facts.py`：规模数字与索引完整性，不校验 API 细节；
- `check_agents_consistency.py`：比入口名 + 高频规则短语，不做全文语义比对；
- `check_package_docs.py`：安装示例的下界必须等于当前版本（含 patch；非 caret 直接失败）；
- `check_teaching_coverage.py`：只比对入口名是否出现在 docs/agents / 模板 / README（有 example 时再加 example/lib）
  这几个载体里（子串匹配，不代表讲清楚了）；`entrypoints.yaml` 覆盖 11 个库包；
- `check_test_imports.py`：只按文件判断，不区分“行为测试”与“白盒测试”；存量在
  `test_imports_baseline.yaml`，修好后要删行（否则脚本会报 stale）；
- `check_public_api_diff.py`：只比较快照里已有的 key（删除 / 改签名），新增成员不拦；缺基线直接失败；
  没有 `w_tools_*.dart` barrel 的包（目前只有 `cli`）显式登记为「不适用」，不会打印假 ✓；
- `check_version_bump.py`：只比较 barrel 公开面；「已抬过但还没发布」的版本按已发布基线判断（CI 带 `--online` 时以 pub.dev 为准），不重复要求抬版本；
- `ci_matrix.py --check`：查清单是否同源、路径过滤器是否只写正向，不查 workflow 语义；
- `check_gate_coverage.py`：只按文件名找入口，不判断入口里的参数 / 条件是否真会执行到。

发布前：

```bash
bash scripts/release_check.sh --strict
bash scripts/publish_package.sh packages/<pkg> --dry-run
```

真正发布：

```bash
bash scripts/publish_package.sh packages/<pkg>
bash scripts/publish_package.sh .
```

不要直接：

```bash
flutter pub publish
```

原因见 [`publish_package.sh`](publish_package.sh) 顶部说明。

---

## 推荐工作流

### 改代码

```bash
bash scripts/preflight.sh --with-tests
```

### 只改文档

```bash
bash scripts/check_docs.sh
```

### 改公开 API

```bash
cd packages/cli
dart run tool/gen_catalog.dart
cd ../..
python3 scripts/check_public_catalog.py
bash scripts/preflight.sh --with-tests
```

### 改弃用

```bash
python3 scripts/list_removals.py
python3 scripts/check_deprecations.py
```

### 发布前（步骤以 [releasing.md](../docs/releasing.md) 为准）

```bash
bash scripts/check_pr_checks.sh <PR号>             # 合并前，在 PR 分支上；需要 gh
bash scripts/release_check.sh --strict
bash scripts/publish_package.sh packages/<pkg> --dry-run
```

`preflight.sh --all` 会带根包 dry-run，**失败计入门禁**（要求根包依赖都已发布）；
发布子包阶段用 `--with-tests`，子包全部上线后再跑 `--all`。

完整 `--strict`（不带 `--package`）还会要求每个包的最新 API 快照**已 tracked**，且
**根聚合包**版本 == 本地 pubspec：发根包前必须先合入快照 PR（untracked 快照会被
`reset --hard` / `clean` 丢掉）；工具包 / 不聚合的包允许待发布。

`--online` 只在**发布后**核对线上版本；发布前跑 `release_check --online` 必然报「待发布」，
不要放进发布前清单。线上核对推荐：

```bash
python3 scripts/release_status.py --online --check
```

它把「待发布」视为正常；`release_check --online` 在全部取不到线上版本时返回 2
（环境不可用），不会打印「检查通过」。

### 真正发布

```bash
bash scripts/publish_package.sh packages/<pkg>
bash scripts/publish_package.sh .
```

---

## 不要做

- 不要直接 `flutter pub publish`；
- 不要只跑 `check_docs.sh` 就认为全仓通过；
- 不要手改 `catalog.g.dart` / `templates.g.dart` / `components.md`；
- 不要为了通过 `check_public_catalog.py` 直接 `--write` 基线，先 review 新类型；
- 不要把 `publish_package.sh` 当 dry-run 使用。

---

## 相关文档

- [AI 使用契约](../docs/ai-contract.md)
- [维护者 AI 提示词](../docs/ai-maintainer-prompts.md)
- [接入约定](../docs/conventions.md)
- [发布流程](../docs/releasing.md)
- [CLI 使用](../packages/cli/README.md)
- [组件目录源](../packages/cli/catalog/components.yaml)
- [模板生成器](../packages/cli/tool/gen_templates.dart)
- [目录生成器](../packages/cli/tool/gen_catalog.dart)


### 公开 API 快照

`scripts/api_snapshots/w_tools_<pkg>-<version>.txt` 是**已发布版本**的公开 API 基线，
由脚本生成，不要手改。`preflight` 按 manifest 逐包对比，**缺基线直接失败**（不再静默跳过）。

- 正常情况：`publish_package.sh` 发布成功后先写到 `.w_tools/release-snapshots/`
  （gitignored，不会挡住下一个包），一批发完用 `apply_snapshots.sh` 应用到这里；
  **提交必须走分支 + PR**
  （`pre-push` 禁止直接 push main；发布脚本要求 `HEAD == origin/main`）。
  同一波要发聚合包时，先合入快照 PR，再 `git pull --ff-only` 后发根包。
  细节见 [releasing.md](../docs/releasing.md) 第 7 步。
- 新包 / 补基线：从 pub.dev 归档（首次发布前可用当前版本）生成：

```bash
python3 scripts/check_public_api_diff.py \
  --snapshot-from /tmp/<pkg>-<version> --package <pkg> --version <version>
```

- 聚合包 `w_tools` 只 re-export，没有自己的 API 快照。
