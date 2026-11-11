> 分析记录：提案，部分已落地；状态以「进度」表为准。关联 issue [#116](https://github.com/stone0533/w_tools/issues/116)。

# 工具链优化计划（2026-11-11）

> 背景：实现 `w_tools_cli` 1.19.0 的 `upgrade` 命令并走完发布全程后，暴露的**仓库流程摩擦**
> （不是 w_tools 使用问题）。范围：CLI 命令的文档 / 门禁一致性、发布脚本、本机与沙箱环境前提。
> 基线 `main @ 00904bf1`，工作区干净，15 个包全部已发布。
>
> 后续基线 / 子票状态见 issue #116 的「当前状态」；本文件保留分析时点，不随版本重写历史。

## 结论

**把「命令」当成和「组件」同级的一等公民**（单一事实源 + 契约检查），**把发布脚本的环境前提写下来**。
优先做「校验」和「脚本去硬编码」，暂不做「文档生成」：仓库已有 `readme_contract_test.dart` /
`docs_contract_test.dart` 这种跨文件契约测试的先例，也有 `check_docs_facts.py` 解析 markdown 表格
对比两份来源的做法；沿这两条路走，比新建清单 + 生成器便宜一个量级，也不会和 README 里手写的散文打架。

## 进度

| 阶段 | 项 | 状态 | 落点 / 验收 |
| --- | --- | --- | --- |
| 1 | 1.1 命令契约测试 | 完成（PR #134） | `packages/cli/test/internal/command_contract_test.dart`；删一行表格应红 |
| 1 | 1.2 脚本去硬编码命令名 | 完成（PR #134） | `check_docs_facts.py` / `check_prompt_docs.py` 从 `bin/` 派生 |
| 1 | 1.3（可选）`command_registry.dart` | 未做 | `lib/` 改动，随下个 CLI 版本发 |
| 2 | 2.1 `ship.sh` 等 checks 竞态 | 完成（PR #136） | 两处 `gh pr checks --watch` 前先等 checks 注册 |
| 2 | 2.2 自动建分支 | 完成（PR #137） | main 上给 `-m` 就建 `feat|fix|chore|docs|refactor|test/<slug>`；`--branch` 覆盖 |
| 2 | 2.3 快照 PR 一条命令 | 完成（PR #137） | `apply_snapshots.sh --ship` |
| 2 | 2.4 `preflight` 失败摘要 | 完成（PR #136） | 结尾打印「失败步骤：…」 |
| 3 | 3.1 环境前提文档 | 完成（PR #135） | `scripts/README.md` 新增「环境前提」节（含 FVM / Flutter cache） |
| 3 | 3.2 `scripts/_python.sh` | 完成（PR #135） | `preflight` / `check_docs` 共用 PyYAML 守卫 |
| 3 | 3.3 发布可写性预检 | 完成（PR #135） | `publish_package.sh` 提前探测 `~/.pub-cache` / `~/.dart-tool` |
| 4 | 4.1 PR 模板 J-4 工具包写法 | 未做 | `.github/pull_request_template.md` |
| 4 | 4.2 `documentation-map` 索引说明 | 未做 | `docs/documentation-map.md` 的 analysis 行 |
| 4 | 4.3 `context` 命令分行 | 未做 | `context_project.dart` 的 `toPrompt` |
| 4 | 4.4 `--format` 约定 | 未做 | `docs/agents/cli.md` 工具包约定 |
| 5 | 5.1 `release_wave plan` 语义 | 完成（基线 00904bf1 已有 plan 0 / `--check` 1、blockers / warnings；不建票） | 区分「计划可用 / 发布阻断」 |

子票（#116 为父票）：A=#127 1.1+1.2；B=#128 3.1+3.2+3.3；C=#129 2.1+2.4；
D=#131 2.2+2.3（依赖 C）；E=#132 1.3+4.3（依赖 A）；F=#130 4.1+4.2+4.4；
5.1 已完成，不建票。

## 1. 命令契约（约半天，零行为变化）

### 1.1 命令契约测试

**证据**：注册 `upgrade` 改了 13 个文件，其中 6 个是文档表；漏改任何一处都不会红。

**做法**：新增 `packages/cli/test/internal/command_contract_test.dart`（纯测试，不改 `lib/`）：

- 从 `bin/w_tools.dart` 用正则取 `case '<cmd>':` → 命令清单（事实源）；
- 每个命令断言：`packages/cli/README.md` 的「命令怎么选」表有行、退出码表有行、
  `docs/agents/cli.md` 的「命令选择」表有行、`ProjectSnapshot.commands()` 有 value 含
  `w_tools <cmd>`、`bin/<cmd>.dart` 存在；
- 反向：表格里出现但 dispatcher 没有的命令名 → 红（防止删命令忘删文档）。

实现要点：表格解析只做「行内包含命令名」，不做单元格对齐；错误信息点名文件 + 缺哪张表。
放 `packages/cli/test/` 后由 preflight 的 CLI 测试 job 与 CI 自动跑到，**不需要新脚本、不走
`check_gate_coverage`**。

**验收**：手工删掉 README 里 `upgrade` 一行 → 测试红；恢复 → 绿（满足「删掉被守逻辑它就红」）。

**风险**：正则依赖 dispatcher 的 `case` 形状；将来改成注册表时测试跟着改一处。

### 1.2 脚本去硬编码命令名

**证据**：`check_docs_facts.py` 的旧入口正则、`check_prompt_docs.py` 的 `_cli_flags`（先为
`feedback` 加特例，这次又加 `upgrade`）都是手写列表。

**做法**：

- `check_docs_facts.py`：命令名从 `bin/w_tools.dart` 的 `case '([a-z0-9-]+)':` 取，正则动态拼；
- `check_prompt_docs._cli_flags`：`paths = [bin/<sub>.dart, *glob('lib/src/<sub>/*.dart')]`，
  删掉特例分支。

**验收**：两个脚本全绿；在某个 md 里故意写旧入口 `w_tools_cli:upgrade`，应报错。

### 1.3（可选）`command_registry.dart`

只收拢**机器面**：`_usage` 的命令段与 `context.commands` 由注册表派生；人写的表格仍由 1.1 校验。
不做全量生成：README 的命令表是「散文 + 短表」混排，生成会把排版锁死。

注意：改 `lib/` 属于公开行为变化，要抬 `w_tools_cli` minor + CHANGELOG + `agent_budget --record`，
**并进下一个功能 PR**，不要单独发版。

## 2. 发布链路（约半天到一天）

### 2.1 `ship.sh` 等 checks 的竞态

**证据**：PR #114 里 checks 尚未注册时 `gh pr checks --watch` 立即返回 `no checks reported`，
脚本正常退出，PR 停在 `BLOCKED`；两处调用点都要修（merge-only 路径与主路径）。

**做法**：抽 `scripts/_gh.sh`（`_` 前缀不进 `check_gate_coverage`），导出 `gh_wait_checks()`：
先轮询 `gh pr view --json statusCheckRollup --jq '(.statusCheckRollup // []) | length'`，
非空再 `gh pr checks --watch`；超时仍为空 → 明确报「没有注册任何 checks，拒绝自动合并」并 exit 1。

**验收**：`PATH` 里放假 `gh`（先返回 `[]` 再返回 1 条），`bash -c 'source scripts/_gh.sh; gh_wait_checks'`
应等待后继续；配方写进 `scripts/README.md` 的人工测试小节。

### 2.2 `ship.sh` 自动建分支

**证据**：在 main 上直接 `die`，但标题已含类型；这次手动 `git switch -c feat/cli-upgrade`。

**做法**：`-m` 给出且当前是 main 时，从标题取 `feat|fix|chore|docs|refactor` + 冒号后的 slug
（kebab、截断 50 字符）建分支；同名分支已存在则报错给建议；新增 `--branch` 覆盖；`--dry-run` 打印分支名。

### 2.3 快照 PR 一条命令

**做法**：`apply_snapshots.sh --ship`：应用快照后自动建 `chore/release-snapshots-<时间戳>`，
再调 `ship.sh -m "chore(release): <包 版本> API 基线" --type internal --merge -y`；
不带 `--ship` 时行为不变（`release_wave.py` 仍用旧方式）。

**依赖**：排在 2.1 之后（否则 `--merge` 仍会竞争失败）。

### 2.4 `preflight` 失败摘要

**证据**：format 失败时 `✗ format` 被几百行测试进度冲掉，只剩 `门禁失败`。

**做法**：`preflight.sh` 的 `run()` 里收集失败步骤名，退出前打印 `✗ 失败步骤：format, docs`。

## 3. 环境前提（约 2 小时，本次浪费时间最多处）

### 3.1 文档：`scripts/README.md` 新增「环境前提（本机 / AI 沙箱）」

| 前提 | 现象 | 一行修法 |
| --- | --- | --- |
| `CI=true` | `dart test` 在 `~/.dart-tool` 不可写时**无测试输出、exit 1** | `export CI=true`（preflight 已内置） |
| PyYAML | `preflight` / `check_docs` 直接退出 2 | `python3 -m pip install --target /tmp/pylibs pyyaml && export PYTHONPATH=/tmp/pylibs` |
| `~/.pub-cache` 可写 | `publish_package.sh` exit 66 + 一行 `FileSystemException` | 在允许写该目录的环境发布；`CI=true` 避免 telemetry 写入 |
| FVM / Flutter SDK cache 可写 | `flutter test` 直接 exit 1 / 无测试输出（`.../bin/cache/engine.stamp.tmp: Operation not permitted`） | 用可写环境；或 `preflight --sandbox` 跳过，由 CI 覆盖 |

不删 PyYAML：11 个检查脚本 import yaml，是另一个工程。

### 3.2 `scripts/_python.sh`

`preflight.sh` 与 `check_docs.sh` 各写了一遍同样的报错文案，且文案不够用。抽
`require_python_yaml()` 给两处 `source`，报错时打印上表里的两条可用命令。

### 3.3 `publish_package.sh` 可写性预检

参数解析后、暂存前探测 `$HOME/.pub-cache` 与 `$HOME/.dart-tool`（`mkdir -p` + `touch`），
失败文案点明「这是沙箱 / 只读 HOME 的限制，不是发布内容的问题」，并给替代：
`PUB_CACHE=$PWD/.w_tools/pub-cache`（会重新下载）或换环境。

**验收**：临时 `HOME`（不可写）跑 `--dry-run`，应立刻给人话而不是 exit 66。

## 4. 契约细节（约 1 小时）

1. **PR 模板 J-4 加工具包写法**：工具包 / CLI 命令的 catalog / teach / explain 天然不适用，只填
   AGENTS zh-en、README、example，并写一句命令清单同步位置。这次 J-4 是现编的。
2. **`documentation-map.md` 的 analysis 行**补「新增要在 `docs/README.md` 留一行」。
3. **`context --format=prompt` 的命令分行**：现在所有命令挤一行（约 700 字符），改成 `命令:` 后
   每行一个 `key=value`；`ai_contract_test` 只守 <5000 字符，`snapshot_test` 走截断分支，安全。
4. **`docs/agents/cli.md` 工具包约定**：「新命令统一 `--format`，`--json` 只作兼容别名」。

## 5. （可选）`release_wave.py plan` 语义

`plan --all` 在 feature 分支上把「工作区有未提交改动」列为**阻断**，但仍输出完整计划；对 AI 来说
exit code 容易被误读。输出里区分「计划可用 / 发布阻断」，exit code 只对「计划本身不可用」非 0。

## 建议顺序与收益

| 顺序 | 内容 | 验收 | 工作量 |
| --- | --- | --- | --- |
| 1 | 1.1 + 1.2 | 删一行表格 → 测试红；两个 python 检查全绿 | S |
| 2 | 2.1 + 2.4 | 假 `gh` 等待用例；注入失败步骤看摘要 | S/M |
| 3 | 3.1 + 3.2 + 3.3 | 缺 yaml / 只读 HOME 各跑一次 | S |
| 4 | 2.2 + 2.3 | 一次真实（或临时假）快照 PR 走通 | S |
| 5 | 1.3 + 4.3（同一个 CLI 版本） | `dart test` + `check_docs` + 发 minor | M |
| 6 | 4.1 / 4.2 / 4.4 / 5.1 | `bash scripts/check_docs.sh` | S |

完成后新增一个 CLI 命令的必改文件从 13 降到约 5，漏改由测试点名；发布链路从「手动 8 条 +
一次竞态重试」降到 2 条命令。

## 不做的

- **YAML manifest + 文档生成器**：README 命令表是「散文 + 短表」，生成会把排版锁死；
  `catalog/entrypoints.yaml` 的经验也说明工具包刻意不进 catalog。
- **删 PyYAML / 把检查脚本改写成纯 shell**：11 个脚本依赖，收益低风险高。
- **为 shell 脚本新建测试框架**：用假 `gh` / 假 `HOME` 的人工配方即可。

## 如何开始

```bash
bash scripts/preflight.sh --package=cli   # 确认基线绿
```

子票 A（#127）、B（#128）、C（#129）、D（#131）已分别由 PR #134 / #135 / #136 / #137 完成；下一张从子票 E（#132，CLI registry + context 命令分行）开始。

## 维护规则

- 状态只改本文件「进度」表；issue #116 只维护子票链接和完成条件，不复制讨论；
- 每完成一项补 PR 链接，**不要让文档和 issue 各说各话**；
- 全部完成时：本文件顶部补「已全部落地（日期）」并关 issue；文件保留（`analysis/` 是历史记录，不删）；
- 新想法先进 issue 评论，攒够一批再改本文件。
