> 分析记录：带日期的历史评审，不代表当前状态。

# 全流程审计：改动 → 门禁 → PR → 发布（2026-11-07）

> 基线 `main @ c8cf5c9`（PR #10 合并后），工作区干净，15 个包 + 根包与 pub.dev 版本、
> API 快照全部对齐（`release_status.py --online` 全「已发布」）。
> 范围：`AGENTS.md` / `CONTRIBUTING.md` / `README.md` / `docs/` / `scripts/` / `.github/workflows/`。
> 方法：文档与脚本对读 + 实跑门禁 + 反向验证（构造失败场景）+ 两个只读子审计。
> 环境限制：本机沙箱无法写 Flutter engine cache，`flutter analyze` 报
> `Operation not permitted`（环境问题，不计入仓库缺陷）；其余静态门禁全绿。

## 0. 结论

| 维度 | 评价 | 说明 |
| --- | --- | --- |
| 结构 | 好 | `packages.manifest` 单一来源、`preflight` 单入口、CI 派生、生成物、API 快照 |
| 自动门禁（形状） | 好 | 链接 / 锚点 / 符号 / 生成物 / 版本 / PR 分类都有人守，覆盖强于多数库 |
| 自动门禁（语义） | 中 | 教学、semver、行为变化仍靠人；多数检查只验「出现过」 |
| 发布流程 | 中 | fail-closed 方向对；状态机有断点，照文档批量发会卡 |
| 文档一致性 | 中 | 108 个 md / 1.2 万行；发布线 3 处说法冲突；规则有 3 份副本 |
| 可维护性 | 中偏低 | 35 个脚本、单人维护；meta 门禁自身缺少独立兜底 |

**一句话：骨架成立，不建议推翻；优先修发布状态机，其次收敛文档副本、把人工仪式变成可验证产物。**

P0：无——当前 `main` 没有发现必现的错误发布路径。下面 P1 都是「条件满足时才会踩到」的
fail-open / 断点，但其中几条已经在真实发布里踩过（PR #7）。

---

## 1. 流程全貌与断点

### 1.1 改动 → 合并（成熟）

```text
AGENTS.md 分类
  → 代码 + 测试（packages/<pkg>/test）
  → catalog/components.yaml → gen_catalog → components.md + catalog.g.dart
  → templates/agents/{zh,en} → gen_templates → templates.g.dart
  → README / example / docs/agents
  → bash scripts/preflight.sh --with-tests
  → PR（模板四类 + 命名 + J-4 + 版本物料）
  → CI: matrix / changes / docs / umbrella / packages / min_sdk / api-bump
  → Required checks → Merge commit → 删远端分支
```

薄弱点：J-4 无产物（P1-6）；规则三副本（P1-7）；`preflight` 不跑 `api-bump` 的两条
（P2-7，本地绿 ≠ CI 绿）。

### 1.2 发布（本轮主要问题）

```text
release_check --package <pkg> → PR 合并
  → release_check --strict + publish --dry-run
  → publish_package.sh packages/<pkg>
       ├ 保护：干净树 / main / HEAD == origin/main / release_check --strict
       ├ 复制到仓库外 staging（去 workspace）
       ├ pub publish
       └ 写 scripts/api_snapshots/<pkg>-<ver>.txt
  → 快照分支 + PR → 合并
  → release_check --strict（根）→ publish_package.sh .
  → release_check --package <pkg> --online / release_status.py --online
```

标记的断点：

- **A** 批量发布：上一包的未跟踪快照会挡住下一包（P1-1）。
- **B** `HEAD == origin/main` 比较的是未 fetch 的本地 ref（P1-2）。
- **C** 发布保护不检查快照是否齐全（P1-3）。
- **D** 快照写入失败会删掉 staging，恢复命令不可执行（P1-4）。
- **E** `--online` 的语义在文档间相反，且断网会「检查通过」（P1-5）。

### 1.3 消费方接入

```text
flutter pub add <子包> → dart pub add dev:w_tools_cli → w_tools init
  → dart pub get → w_tools doctor → context / list / explain
```

这条线文档本身是自洽的；唯一的大落差是 issue / triage 流程零使用（P2-10）。

---

## 2. 问题清单

### P1-1 批量发布时，第二包会被上一包的快照挡住

- **证据**：
  - `scripts/publish_package.sh:191-198`：存在任何未跟踪文件就失败；
  - `scripts/publish_package.sh:224-233`：发布成功后把快照写进工作区（未跟踪）；
  - `docs/releasing.md:110-133`：只写了单包流程，且第 121 行固定 `git switch -c
    chore/release-snapshots`（第二次会因分支已存在失败）；
  - `docs/ai-maintainer-prompts.md:949-952`：批量发布要求「每包 K-5 后发下一个」，
    但 K-5/发布段没有快照提交步骤。
  - PR #7 是实测记录（同一问题，后按维护者要求回退）。
- **影响**：一波发 N 个包，要么每包走一次「切分支 commit → 切回 main」再发下一个，
  要么用 `--force` 一次跳过干净树 / main / `HEAD == origin/main` / `release_check` 全部保护
  （`publish_package.sh:64` 的 `--force` 不分组）。文档允许「快照 PR 攒到下次发版前」，
  这又和周检冲突：`release_status.py:154-159` 在快照落后线上时判 error，周一 CI 必红。
- **建议**：见 §3.1 的两个方案；同时把「同一批快照」写进 `docs/releasing.md` 与 K-4。

### P1-2 发布保护比较的是本地缓存的 `origin/main`，不 fetch

- **证据**：`scripts/publish_package.sh:204-210` 直接 `git rev-parse origin/main`；
  `scripts/check_git_sync.sh:13-15` 也只比较 `@{u}`；全仓没有发布前的 `git fetch`。
- **影响**：clone 落后但 remote-tracking ref 未更新时，`HEAD == origin/main` 与
  ahead/behind=0 都成立，会把基于旧 main 的工作区发出去。`docs/releasing.md:195-198`
  把这条当作「暂存副本在 git 之外」的最终保护，实际是 fail-open。
- **建议**：保护前 `git -C "$repo_root" fetch --quiet origin main`（或用
  `git ls-remote origin refs/heads/main` 与 HEAD 比较）；`check_git_sync.sh` 同样处理。

### P1-3 发布保护不检查 API 快照是否齐全

- **证据**：`scripts/release_check.sh` 全文没有 `api_snapshots`；只有
  `scripts/release_status.py:154-159` 检查「缺快照 / 快照 ≠ 线上」；而
  `scripts/publish_package.sh:212-216` 的根包保护只跑 `release_check --strict`。
- **影响**：快照 PR 没合入时，`publish_package.sh .` 仍可能成功（工作区干净、版本/CHANGELOG
  都对），`main` 上缺基线；要等下一次 `preflight` 或周一 `release-status` 才暴露。
  `docs/releasing.md:129-133` 说「必须先合入快照 PR，否则会失败」——只对「未跟踪文件」
  成立；已 commit 到未合并分支时 main 是干净的，这条保护不生效。
- **建议**：`release_check --strict` 增加「每个包最新快照版本 == 本地 pubspec 版本」；
  或在根包发布前调用 `release_status.py --check`（离线即可，缺快照会报 error）。

### P1-4 发布成功但快照写入失败：staging 被删，恢复命令不可执行

- **证据**：`scripts/publish_package.sh:92-98` 的 `trap cleanup EXIT` 会在正式发布时
  删除 staging；`:223-228` 在快照写入失败后 `exit 1`，提示「请手动重跑
  `check_public_api_diff.py --snapshot-from`」，但没给路径，且 staging 已删。
- **影响**：包已上线、命令返回失败；操作者无法从本地重新生成快照，只能重新下载
  pub.dev 归档。同一段注释（`:223`）写「失败只提示，不让已完成的发布看起来失败」，
  与 `exit 1` 的行为相反。
- **建议**：发布成功后先写快照（源是 staging），失败时保留 staging 并打印完整、
  可复制的命令（含 `--snapshot-from <路径> --version <ver>`）；或改成 exit 0 + 醒目
  warning，由 `release_status --check` 兜底。

### P1-5 `--online` 语义冲突，且断网/404 会「检查通过」

- **证据**：
  - `scripts/release_check.sh:289-292` 取不到线上版本只 `warn`，`:315-320` 仍返回 0；
    实测把 `https_proxy` 指向死端口后输出「检查通过（1 条提醒）」EXIT=0。
  - `docs/releasing.md:152-153` 与 `scripts/README.md:220` 说「发布前跑必然待发布，
    不要放进发布前清单」；但 `docs/ai-maintainer-prompts.md:817-820`（K-1 发布前审计）
    要求跑 `release_check --package <pkg> --online`。
  - `release_check.sh:306-307` 把「仓库 > 线上（待发布）」判失败；`release_status.py:152-153`
    视为正常；而 `docs/releasing.md:141-146` 第 9 步同时推荐两者。
- **影响**：照 K-1 做会在发布前拿到非 0；照 `releasing` 做又会把断网当通过。发布后的
  「最新版本已上线」结论可能没有真的核对过。
- **建议**：只保留一个线上比较实现（推荐 `release_status.py`）。`release_check --online`
  要么改成「取不到即返回 2」，要么删掉；K-1 改用 `release_status.py --online`
  （待发布是正常状态）。404（包不存在）与网络错误要分开报。

### P1-6 J-4 仍是不可验证的人工勾选

- **证据**：`CONTRIBUTING.md:74-80`、`.github/PULL_REQUEST_TEMPLATE.md:21` 要求「跑 J-4
  并贴矩阵」，但 `scripts/check_pr_scope.py:29-43` 只查「公开变化」勾选 + 任意
  `packages/*/CHANGELOG.md` 被改；`scripts/check_teaching_coverage.py:46-58` 只做子串匹配。
- **影响**：公开 API / 行为变化可以在没有任何教学同步的情况下合并；J-4 的 8 列矩阵没有
  任何机器可读落点，勾选可以永远空着。
- **建议**：PR 模板加固定 J-4 小节（8 列表格）；`check_pr_scope` 在勾了「公开变化」时
  要求正文出现该表头 + 至少一行数据（内容仍人工判断）；或把矩阵存到
  `docs/analysis/j4/<pkg>-<ver>.md` 并要求 PR 链接。

### P1-7 规则存在三份副本，门禁只校验 6 个短语

- **证据**：`AGENTS.md`、`docs/agents/*.md`、`packages/cli/templates/agents/{zh,en}/*.md`
  （28 个模板 md）写同一批规则；`scripts/check_agents_consistency.py:91-127` 的
  `KEY_PHRASES` 只有 6 组，且只做 `phrase in text`。
- **影响**：同一规则改一处漏两处，门禁仍然绿；消费方 AI 与仓库 AI 可能读到不同规则。
- **建议**：确定一份源（建议 `templates/agents/`），`docs/agents` 只保留维护者增量并链接；
  或反过来生成模板。短期把 `KEY_PHRASES` 扩到规则表所有行的机械比对，至少保证
  「规则名 + 禁止项」两边同现。

### P1-8 门禁自身的 fail-open：空基线 / 快照滞后 / PR 范围

三处独立的「门禁看起来在跑，实际没拦住」：

1. **空 API 基线仍显示 ✓**：`check_public_api_diff.py:269-276` 读空文件得到 `{}`，
   `:178` 只遍历 baseline key，`diff_api({}, current)` 返回 `[]`（已实测），最后打印
   「✓ 一致」。`--snapshot-from` 指错目录会写出只含 header 的文件并 exit 0
   （`:302-308`）。非 `NO_PUBLIC_API` 包的空基线应按「缺基线」失败；`--snapshot-from`
   应校验 `--version` 与目录 pubspec 一致、`lib/` 至少解析出一个类型。
2. **`check_version_bump` 用仓库快照当「已发布版本」**（`check_version_bump.py:171-175`）。
   实测 `requires_bump('6.1.0', '6.1.0', '6.0.0') == False`：若 6.1.0 已发布但快照 PR
   还在攒（文档允许），同版本再加 API 变化会被判「落在未发布版本里」放行。应查 pub.dev
   或维护显式 `published_versions`，取不到时 fail-closed。
3. **`check_pr_scope` 不查版本号是否抬、也不查版本段是否新增**
   （`check_pr_scope.py:31/42-43`）。行为变化可以只改已发布版本的旧 CHANGELOG 段、
   pubspec 不动，两个检查都绿。应对比 base 要求「pubspec 版本增加或出现新 `## <version>` 段」。

### P2-1 `check_pr_scope` 的包范围与根包

- **证据**：`check_pr_scope.py:31` 只接受 `packages/*/CHANGELOG.md`；实测
  `touches_package_changelog(['CHANGELOG.md']) == False`。
- **影响**：根包 re-export / 行为变化只写根 `CHANGELOG.md` 会被误判；同时改 A 包却写
  B 包 CHANGELOG 也能过。
- **建议 / 处理**：已按条件接受根 `CHANGELOG.md`（只有同时改根 `lib/` / `pubspec.yaml` 时），
  见 §8；跨包集合的严格推导经评估不做。

### P2-2 根包公开面没有 API 快照 / 版本门禁

- **证据**：`lib/w_tools.dart:3-8` 是 6 条 re-export；`scripts/api_snapshots/README.md`
  末尾说明根包没有快照；`check_version_bump.py:143` 只遍历 manifest（不含根包）。
- **影响**：删除一条 re-export 靠 `test/umbrella_test.dart:13-19` 编译失败兜底；新增
  re-export 完全无声，也不需要抬根包版本。
- **建议**：为根 barrel 的 export 行建基线，纳入 `check_version_bump` 或 api diff；
  至少加一条「恰好 6 条 export」的测试。

### P2-3 `MIN_FLUTTER_VERSION` 与 pubspec 声明没有一致性检查

- **证据**：`.github/workflows/ci.yml:19-25` 注释要求「pubspec 与这里一起改」；
  `ci_matrix.py:191-218` 只校验 `.fvmrc` ↔ `FLUTTER_VERSION`；全仓没有第二处读
  `MIN_FLUTTER_VERSION`，也没人读 pubspec 的 `flutter: ">=3.38.0"`。
- **影响**：pubspec 抬到 3.40 而 MIN 仍是 3.38.4 时，`min_sdk` job 名不副实；反过来
  声明下限高于 MIN 时 CI 根本测不到声明值。
- **建议**：`ci_matrix --check` 解析各包 `environment.flutter` 下限，断言
  `MIN_FLUTTER_VERSION >= 声明下限`，并把差异写进白名单/注释。

### P2-4 只改 `scripts/README.md` 不会跑门禁覆盖检查

- **证据**：`.github/workflows/ci.yml:94-110` 的 static 过滤器只有
  `scripts/**/*.sh|py|yaml|txt` + `packages.manifest` + `scripts/tests/**`，没有
  `scripts/**/*.md`；`check_gate_coverage` 只在 `preflight` 里跑。
- **影响**：删掉某脚本的 README 登记、改坏手册，CI 仍绿；下一轮代码 PR 才红。
- **建议**：static 加 `scripts/**/*.md`；并把 `ci_matrix --check` /
  `check_gate_coverage` / `scripts/tests` 加进 docs job（都只需要 python3）。

### P2-5 CI 的 meta 门禁只覆盖一半

- **证据**：`ci_matrix.py:26-57` 只拒绝 `!` 过滤器，不断言 manifest 路径仍被正向匹配；
  `:160-206` 不校验 `required` 的 `needs` 名单、`umbrella/packages/min_sdk` 的 `if`
  是否仍引用 `changes` 输出、docs job 是否仍调用 `check_docs/release_check`。
  `required` 允许这几个 job skipped（`ci.yml:355-365`）。
- **影响**：改坏 `ci.yml` 自身（例如 `umbrella.if` 恒 false、删掉一个过滤器）时，
  该 PR 仍可能绿——过滤器只决定 `if`，不决定必须跑；下次纯代码 PR 的静态门禁就整体跳过。
- **建议**：`ci_matrix --check` 增加「每个 manifest 路径必须被 code 或 static 命中」
  「required.needs 必须包含 matrix/changes/docs，且覆盖 4 个门控 job」
  「quantifier 必须等于 some-with-excludes」；docs job 里跑一次 meta 检查。

### P2-6 `--package` 模式的契约与文档不符

- **证据**：`docs/releasing.md:232` 说「根包与其他子包不参与」；实际
  `release_check.sh:238-246` 仍检查根 README，`:248-253` 的 `check_deprecations.py`
  遍历所有包。
- **影响**：只想发 ui 时，会被 form 的弃用到期或根 README 的版本字样挡住，推动操作者
  用 `--force`。
- **建议**：README 检查只在 full 模式跑；`check_deprecations.py` 支持 `--package`；
  或改文档说清「只收窄版本/物料，不收窄弃用检查」。

### P2-7 本地 `preflight` 与 CI 不等价

- **证据**：`preflight.sh:76-105` 不含 `check_version_bump` / `check_pr_scope`
  （CI 的 `api-bump` 跑，`ci.yml:191-210`），也不含 per-package dry-run / example
  analyze（CI 的 packages job 跑，`ci.yml:286-303`）；但 `scripts/README.md:64` 称
  preflight 是「全仓门禁总入口」。
- **影响**：`preflight --with-tests` 全绿仍可能 PR 红（版本没抬、勾了公开变化没改
  CHANGELOG、example 缺 README），产生一轮返工。
- **建议**：preflight 增加可选 `--base`（跑这两条）；或在 README / PR 模板明示
  「CI-only」清单。

### P2-8 快照目录的文档与事实不一致

- **证据**：`scripts/api_snapshots/README.md` 说「每个包只保留一条：最新发布版本」；
  实际有 `w_tools_map_google-1.0.0.txt` + `2.0.0.txt`、`w_tools_cli-1.12.0.txt` +
  `1.13.0.txt`；`cli` 在 `check_public_api_diff.py:28` 是 `NO_PUBLIC_API`，却仍有快照
  （且 `:310-320` 先要求快照存在，再走「不适用」短路）。
- **影响**：读者以为旧文件可删；脚本实际取「最大版本」。cli 的空快照是「载重但无用」。
- **建议**：文档改成「保留历史，取最新」或清理旧文件；cli 明确不写快照、不要求基线。

### P2-9 发布状态机的几个小洞

- `release_status.py` 只看文件系统（`:71-78`），**不检查快照是否已提交**。本地
  `--online --check` 可以在「快照未跟踪」时全绿，周一 CI 才红。
- `release_status.py:195-206` 先 `return 1` 再判 `online_ok == 0`：断网 + 缺快照
  返回 1（误报事故），不是 2（跳过）。
- 不带 `--online` 跑 `release_status.py --check` 会打印「状态正常」（已实测），
  但所有包都是「未核对」。
- 发布脚本不预检「版本是否已存在」；republish 要等 pub 端报错。
- 根包发布只跑 `release_check --strict`，不校验子包版本真的在 pub.dev 上（根包先发
  会让消费方解析失败）；顺序要求写在 `docs/releasing.md:62`，脚本未强制。

### P2-10 issue / triage 流程零使用

- **证据**：`gh issue list --state all` 为空（`has_issues=true`，`open_issues_count=0`）；
  `docs/agents/issue-tracker.md` / `triage-labels.md` / wayfinder 一套文档与 label 齐全；
  `CONTRIBUTING.md:85-88` 要求 bug / 需求先开 issue。
- **影响**：流程文档与真实习惯脱节；新 agent 照文档先开 issue，会制造没人维护的 backlog。
- **建议**：要么真的用起来（补 bug / feature 模板，PR 链 `Closes #n`），要么把「先开
  issue」降级为建议，并删掉不用的 wayfinder 段。

### P2-11 semver 策略在 `AGENTS.md` 与 `releasing.md` 之间冲突

- **证据**：`AGENTS.md:70-78`「本地未发布版本就是 breaking 窗口」，例 7.1.0 vs 7.0.0；
  `docs/releasing.md:35` / `:59-61`「破坏性改动 → major」；`check_deprecations.py`
  要求 `remove-in` 是 `x.y.z` 且到期必须删；`publish_package.sh:168-176` 只警告不失败。
- **影响**：同一个删除，按 AGENTS 可进 7.1.0（minor），按 releasing 应进 8.0.0；
  AI 会给出不同答案，门禁也拦不住。
- **建议**：写一条 ADR 明确「未发布版本是否允许 breaking」，并把判断写进脚本
  （breaking 必须 `X.0.0`，或显式 allowlist）；AGENTS 只引用 ADR。

### P3（小项，不影响结论）

- `README.md:39` 说「不在文档里写死版本号」，`README.md:174` 又写
  `w_tools_app_getx: ^1.0.1`；`check_package_docs.py` 允许后者，但说法应改成
  「安装命令不写死，示例 caret 必须等于当前版本」。
- `scripts/README.md:44-47` 说「纯文档改动只跑轻量 docs job」，实际还跑
  `matrix` / `changes` / `api-bump`（full-history checkout）/ `required`。
- `ci.yml:134-135` 注释说「只改 CHANGELOG / 版本号 / 依赖约束时 code 不命中」，但
  `pubspec.yaml` / `pubspec.lock` 明确在 code 过滤器（`ci.yml:78-79,90-91`）。
- `publish_package.sh:28` 注释写排除 `doc`，实际排除 `docs`（`:109`）。
- `release_check.sh:260` 说「dry-run 也会因此返回 65」，但 `publish_package.sh:189`
  的 dry-run 根本不做干净树检查（65 来自 pub 自己的检查）。
- `docs/releasing.md:99-107` 第 6 步写在「合并到 main 之后」，却包含「在 PR 分支上确认
  Required checks」的命令；有 PR 号时可用，但句子容易误读。
- `docs/releasing.md:130` 说「否则会因未跟踪文件 / HEAD != origin/main 失败」：若快照已
  commit 到未合并分支，main 是干净的，root publish 不会失败（只会在之后 preflight 报
  缺快照）——与 P1-3 同源。

---

## 3. 建议（按 ROI 排序）

| # | 动作 | 关闭 | 成本 | 备注 |
| --- | --- | --- | --- | --- |
| 1 | 修发布回路（快照不再写工作区 / 一批一个 PR） | P1-1/3/4 | S/M | 方案见 §3.1 |
| 2 | 发布前 `git fetch origin main`，与真实远端比较 | P1-2 | S | 两处脚本 |
| 3 | 快照完整性进 `release_check --strict` | P1-3 | S | 复用 `release_status` 的检查 |
| 4 | 快照失败保留 staging + 完整命令 | P1-4 | S | |
| 5 | 统一线上比较（只留 `release_status.py`） | P1-5/P2-9 | S | 断网返回 2 |
| 6 | K 场景对齐 `releasing` | P1-1/5 | S | 文档 |
| 7 | J-4 落成 PR 正文表格并校验 | P1-6 | M | 模板 + `check_pr_scope` |
| 8 | 收敛三副本 | P1-7 | L | 生成或增量 |
| 9 | API 空基线 / 快照滞后 / PR 范围三条 fail-open | P1-8 | S/M | 见下 |
| 10 | ci_matrix 断言过滤器覆盖与 required 接线 | P2-5 | S | |
| 11 | scripts 路径过滤 + docs job 跑 meta 检查 | P2-4 | S | |
| 12 | root re-export 基线 / 测试 | P2-2 | S | |
| 13 | MIN Flutter 一致性 | P2-3 | S | |
| 14 | semver ADR | P2-11 | M | 决策 |
| 15 | issue 流程决策 | P2-10 | S/M | 决策 |

### 3.1 发布回路：两个可选方案

**方案 A（推荐，保持 fail-closed，不碰 PR #7 的红线）**

- `publish_package.sh` 不再把快照写进工作区，而是写到
  `${TMPDIR}/w-tools-snapshots/`（或 `--snapshots-dir`）；
- 新增 `scripts/apply_snapshots.sh`：把目录里的快照拷进 `scripts/api_snapshots/`，
  打印分支 + commit + PR 命令；
- 根包发布保护增加 `release_status.py --check`（离线即可，缺快照直接失败）；
- 文档 / K 提示词改成：「发完一批 → apply → 一个快照 PR → 合并 → 发根包」。
- 效果：一次 PR 收一批快照，不再每包切分支；严格性不降。

**方案 B（PR #7 的最小版，需要维护者接受「快照暂未提交」的窗口）**

- 发布保护只放行 `scripts/api_snapshots/**` 下的未跟踪文件，其它未跟踪文件仍然阻止；
- 根包发布前要求 `release_status --check`，保证不会带着缺失基线发根包；
- 风险：快照可能长期不提交；适合能接受这个窗口的人。

两条方案都要顺手修：分支名带包名/版本（或 `switch -c || switch`）、`--force` 至少打印
「已跳过哪些保护」、失败提示从 pub.dev 归档重新生成的具体命令。

### 3.2 把 J-4 变成产物（最小改动）

PR 模板加一段：

```markdown
### J-4 矩阵（勾了「公开变化」必填）

| 公开类型 | catalog | teach | AGENTS zh | AGENTS en | explain | README | example |
| --- | --- | --- | --- | --- | --- | --- | --- |
```

`check_pr_scope` 在勾了「公开变化」时要求正文出现该表头 + 至少一行数据；内容仍由人
判断（机器只能验「有没有做」）。这比新增一个门禁脚本便宜，且不改变 J-4 的语义。

### 3.3 三条 fail-open 的最小修法

1. `check_public_api_diff._load_snapshot` 为空且包不在 `NO_PUBLIC_API` → 报「基线为空」；
   `--snapshot-from` 校验 `--version` 与目录 pubspec 一致、`lib/` 至少解析出一个类型。
2. `check_version_bump`：`published` 不要只从快照推断；CI 有网时查 pub.dev，
   取不到时 fail-closed（或要求发布脚本维护 `scripts/published_versions.txt`）。
3. `check_pr_scope`：按改动路径派生包集合，要求同包 `CHANGELOG.md` 被改且 pubspec 版本
   增加（或出现新 `## <version>` 段），不再只认勾选。

---

## 4. 本轮验证记录

```bash
bash scripts/check_docs.sh                    # 18 步全 ✓
python3 scripts/check_docs.sh --skip-feedback # 无 Dart 环境模拟 CI docs job，全 ✓
bash scripts/preflight.sh                     # 除 analyze（沙箱）外全 ✓
python3 scripts/release_status.py --online    # 15 包 + root 全部「已发布」，快照一致
python3 scripts/release_status.py --check     # 离线：全部「未核对」却打印「状态正常」
https_proxy=http://127.0.0.1:9 \
  bash scripts/release_check.sh --package ui --online
                                              # 断网：EXIT 0「检查通过（1 条提醒）」
bash -n scripts/*.sh                          # 全部通过
python3 scripts/ci_matrix.py --check          # 通过（15 个包）
python3 scripts/check_gate_coverage.py        # 通过
python3 -c "import check_pr_scope as c; print(c.touches_package_changelog(['CHANGELOG.md']))"
                                              # False（根 CHANGELOG 不被接受）
python3 -c "import check_version_bump as c; print(c.requires_bump('6.1.0','6.1.0','6.0.0'))"
                                              # False（快照滞后时放行同版本 API 变化）
gh api repos/stone0533/w_tools                # allow_merge_commit=true,
                                              # squash/rebase=false, delete_branch_on_merge=true
gh api repos/stone0533/w_tools/branches/main/protection
                                              # required_status_checks=["Required checks"],
                                              # enforce_admins=false, 无 review 要求
```

`flutter analyze` 失败是沙箱权限（无法写 fvm cache），不是仓库缺陷；CI 上同命令在
PR #10 的 run 里成功。

---

## 5. 不是问题、别误判的点

- **`preflight` / `check_docs` 全绿不代表内容正确**：它们只覆盖形状（链接、符号、生成物、
  版本），文档自己也这么写；不要把它当语义审计。
- **`check_teaching_coverage` 是 J-4A（子串）**：通过不等于讲清楚，这是设计边界，不是 bug。
- **`cli` 没有 barrel / 没有真实公开 API 快照**：`NO_PUBLIC_API` 是显式登记，不是漏检；
  只是 P2-8 说的「空快照载重」可以清理。
- **子包发布阶段跑 `--all` 会失败**：根包 dry-run 要求依赖已发布，这是预期
  （`docs/releasing.md:19-21`）。
- **`--force` 存在**：是明确的逃生门，本身不是 bug；问题是它粒度太粗。
- **branch protection 没有 `enforce_admins` / review 要求**：单人维护的取舍；required
  check 是真实生效的。真正的强制来自 GitHub，不是 `.githooks/pre-push`（可 `--no-verify`）。
- **快照 PR 流程不是死锁**：`git switch -c` 可以把未跟踪快照带到分支提交，再切回 main；
  问题是每包一轮的成本逼出 `--force`，以及文档只写了单包。

---

## 6. 值不值得改（ROI 复核）

> 这一节是对 §3 建议的二次判断：不是「技术上对不对」，而是「现在值不值得花时间」。
>
> 判断口径：**发生频率 × 损失（可逆性）× 影响面 ÷（实现成本 + 维护成本 + 新增摩擦）**。
> 仓库现状：单人维护；8 天 744 个 commit、11-06 一天 10 个 PR；15 个包 + 根包已全部发布
> 且快照对齐。也就是说，**当前不是救火状态，改的是「下一次发版会不会踩」**。

### 6.1 结论表

成本口径：S ≤ 30 分钟；M = 0.5–2 小时；L > 1 天。维护成本指「以后每次改相关文件都要记得同步」。

| 建议 | 频率 / 证据 | 不修的后果 | 成本 | 维护 | 判断 |
| --- | --- | --- | --- | --- | --- |
| 发布前 `git fetch origin main` | 每次发布；条件触发 | 发出旧树，不可回滚 | S | 无 | **立即做** |
| 根包发布前校验快照已跟踪 + 版本一致 | 每次发布；PR #8 已发生（快照被 reset 掉） | 缺基线、周检误报、修复 PR | S | 低 | **立即做** |
| 快照写入失败保留 staging + 正确命令 | 极低频 | 恢复 10–30 分钟 | S | 无 | 顺手做 |
| `--online` 断网返回 2 + K-1/releasing 口径统一 | 每次发布审计 | 假绿 / K-1 卡住 | S | 低 | **立即做** |
| K / releasing / README 文档对齐 | 每次发布 | AI 照做卡住或误判 | S | 无 | **立即做** |
| 批量快照（pending 目录 + `apply_snapshots.sh`） | 每次多包发版；PR #7/#8/#9 | 每包一轮分支操作，或 `--force` 跳过全部保护 | M 1–2h | 低 | **已做（方案 B，见 §7）** |
| CI meta：正向过滤器覆盖 + required 接线 | 每次改 `ci.yml`（很频繁） | 门禁整体静默失效 | S 1h | 低 | 已做（§8） |
| 根 barrel 加「恰好 6 条 export」测试 | 根变化少 | 删 export 只能靠 umbrella 编译兜底 | S 15min | 无 | 值得 |
| `check_pr_scope` 接受根 CHANGELOG（条件） | 每次公开 PR | 根包公开变化被误杀 | S 20min | 低 | 已做（§8） |
| J-4 强制 8 列表 + 机器校验 | 每次公开 PR | 教学漂移 | M + 每 PR 填表 | 中 | **降级：不强制**（见 6.3） |
| 收敛 `AGENTS` / `docs/agents` / 模板三副本 | 持续 | 语义漂移 | L 1–2 天 | 中 | **暂不做**（见 6.3） |
| semver 策略澄清（ADR-0001 补充） | 每次删除/弃用 | 决策不一致 | S 30min | 无 | 已做（§8） |
| issue / triage 流程 | 0 次（`gh issue list --state all` 为空） | 文档与习惯脱节 | S 改文档 | 无 | **不采用**，把「先开 issue」降级 |
| `MIN_FLUTTER_VERSION` ↔ pubspec 一致性 | Flutter 升级时 | min_sdk 名不副实 | S 30min | 低 | 下次升级时做 |
| preflight 增加 `--base` 跑 PR 门禁 | 每次 PR | 一轮返工（约 3 分钟） | M | 中 | **不做**，文档写明 CI-only |
| 快照 README / cli 空快照 / `--package` 全量弃用 | 一次性 | 读者误解 / 被别的包挡住 | S 20min | 无 | 顺手做 |

### 6.2 三阶段落地

**Phase 0（约 1.5 小时，一个 PR）——只做「低成本 + 已发生过」的：**

1. `publish_package.sh` + `check_git_sync.sh` 在比较前 `git fetch origin main`；
2. 根包发布前校验「每个包最新快照已 tracked（`git ls-files --error-unmatch`）且版本 == 本地」；
3. 快照写入失败时保留 staging（或打印 pub.dev 归档恢复命令）；
4. `release_check --online` 网络失败返回 2；`release_status --check` 无 `--online` 返回 2；
5. 修文档矛盾：`releasing.md` 的 `--online`、K-1/K-2/K-4、`scripts/README.md`、快照 README；
6. 根 barrel 测试。

验收：构造「未提交快照 + 根包发布」必须失败；断网 `--online` 返回 2；`check_docs` 全绿。

**Phase 1（约半天，一个 PR）——只做「省掉每次发版摩擦」的：**

1. 批量快照：`publish_package.sh` 把快照写到 `.w_tools/release-snapshots/`，一批结束后
   `apply_snapshots.sh` 一次应用 + 一个 PR（最终采用，见 §7；窄开关方案未采用）。
2. 文档写清「一批 = 连续发 N 个包 → 一个快照 PR → 合并 → 发根包」；
3. `ci_matrix --check` 增加「每个 manifest 路径必须被 code/static 命中」「required.needs 必须
   覆盖 matrix/changes/docs + 4 个门控 job」「quantifier 必须 some-with-excludes」；
4. `check_pr_scope` 按改动路径派生包、要求同包 CHANGELOG 的**当前版本段**被改；
5. semver ADR（半页）。

**Phase 2（观察，不排期）：** 三副本收敛、J-4 强制、MIN 检查、issue 流程。

### 6.3 我改变主意的两条

**J-4：不强制。** 上一轮建议「PR 正文加 8 列表并由 `check_pr_scope` 校验」，按 ROI 重新算
不划算：单人维护时，表格只能证明「填过」，不能证明「讲清楚」；每来一个公开 PR 都要多填
8 列，摩擦是持续的，收益是一次性的。更划算的做法是：

- J-4 留在**发布审计**（K-1/K-1M 本来就要求全量看），一次覆盖所有包；
- PR 模板只要求一行「J-4 结论 / 链接」，不要求矩阵；
- 真正的漏洞（行为变化不抬版本、写进旧 CHANGELOG 段）用 `check_pr_scope` 的版本段校验
  堵住，这比表格更机械、更便宜。

如果以后有外部贡献者、或教学漂移再次发生，再升级成强制矩阵。

**三副本：不生成。** `docs/agents` 是维护者视角，`templates/agents/{zh,en}` 是消费方视角，
内容本来就不该逐字相同；强行生成会引入一个新的生成器 + 漂移检查 + 28 个文件的迁移，
成本 1–2 天，收益是「少改两处」。当前 `check_agents_consistency` 已经覆盖入口名 + 6 个
高频短语，够用。等真的出现「同一规则三处不一致」的事故，再加 2–3 条短语检查，成本 10 分钟。

### 6.4 明确不要做

- **不要**重新提 PR #7 的「默认放行未跟踪快照」：维护者已经否过一次；窄开关是显式 opt-in，
  根包仍然 fail-closed，和那次改动的性质不同。
- **不要**写一个通用发布编排器 / 自动 `gh pr create`：单人仓库，脚本越自动越难 debug；
  先让状态机可检查，再谈自动化。
- **不要**为了「更全」继续加门禁。现有 35 个脚本已经把形状类检查做得很满；边际收益在
  递减，下一步应该让已有门禁**不可绕过**（fetch、tracked、版本段、required 接线），
  而不是再加新脚本。
- **不要**把需要 Flutter 的检查塞进 docs job（会毁掉 docs-only 的 10 秒反馈）。
- **不要**为了 J-4 / 三副本做大迁移：那是把流程债换成维护债。

### 6.5 一句话

**值得改的只有两件：让发布状态机不可绕过（Phase 0），让批量发布不再逼出 `--force`
（Phase 1）。** 其余建议里，文档修正顺手做；J-4 强制、三副本生成、issue 流程都可以不做。
总投入约 1 天，换来的是「发布这件事不依赖操作者记得住 6 个步骤」。

---

## 7. 落地记录（2026-11-07）

§6 的 Phase 0 与 Phase 1（方案 B：快照写仓库外，不碰「干净树」红线）均已实现。

| 项 | 落点 | 验收 |
| --- | --- | --- |
| 发布前 fetch | `scripts/publish_package.sh`（分支检查后）、`scripts/check_git_sync.sh`（比较前） | `test_check_git_sync.py` 新增「远端前进但本地未 fetch → 判落后」用例 |
| 根包前快照 tracked + 版本一致 | `scripts/release_status.py` 新增 `--require-tracked` / `--require-local` / `--quiet`；`release_check.sh --strict`（完整模式）调用它 | 临时放一个 `w_tools_ui-99.0.0.txt`：同时报「未提交」「≠ 本地版本」，exit 1 |
| 快照失败保留 staging | `publish_package.sh` 失败分支设置 `stage_only=1` 并打印完整重跑命令 | `test_publish_snapshot.py` 断言 `stage_only=1` |
| `--online` 断网语义 | `release_check.sh` 全部取不到时 exit 2；`release_status.py --check` 无 `--online` 且无 `--require-*` 时 exit 2 | 断网代理下 `release_check --package ui --online` → EXIT 2 |
| 文档口径 | `docs/releasing.md`（批量步骤 / 快照 / 表格）、`docs/ai-maintainer-prompts.md`（K-1/K-2/K-4）、`scripts/README.md`、`scripts/api_snapshots/README.md`、根 `README.md`、`AGENTS.md`、`CONTRIBUTING.md` | `bash scripts/check_docs.sh` 全绿 |
| 根 barrel 契约 | `test/umbrella_test.dart` 新增「恰好 6 条 export」断言 | `dart analyze test/umbrella_test.dart` 无问题；`flutter test` 在本机沙箱被 engine cache 挡住，CI 上会跑 |
| 批量快照（方案 B） | `publish_package.sh` 把快照写到 `.w_tools/release-snapshots/`（gitignored）；新增 `scripts/apply_snapshots.sh`；根包发布前拒绝「pending 里还有未应用快照」 | `test_apply_snapshots.py`（缺失/空/多个/忽略非快照文件）；`test_publish_snapshot.py` 断言输出目录与 apply 命令 |
| 发布物隔离 | `.gitignore` 加 `/.w_tools/`；`.pubignore` 加 `.w_tools/`；`rsync` 排除 `.w_tools` | 待发快照不会进根包发布物 |

验证结果（本机）：

```text
bash scripts/check_docs.sh                 # 全绿
scripts/tests unittest                      # 84 tests OK
bash scripts/release_check.sh              # 0 提醒
python3 scripts/release_status.py --online --check   # 15 包 + root 已发布，状态正常
python3 scripts/ci_matrix.py --check       # 15 个包
python3 scripts/check_gate_coverage.py     # 通过
bash scripts/preflight.sh                  # 除 analyze（沙箱写不了 fvm cache）外全绿
```

方案 B 的效果：一串 `publish_package.sh` 之间不再需要切分支/commit，快照在
`.w_tools/release-snapshots/` 累积；一批结束后 `apply_snapshots.sh` 一次应用、一个 PR。
默认保护没有放宽：根包仍要求快照已 tracked、版本一致，且 pending 为空。
Phase 1 的另外三项（`ci_matrix --check` 正向断言、`check_pr_scope` 根 CHANGELOG、semver 澄清）
见 §8；`check_pr_scope` 的「当前版本段」严格校验经评估不做。


---

## 8. 后续三项落地（2026-11-07）

按 §6 的 ROI 复核，只做了 1–3；第 4 项（semver API 门禁）等 0.x 策略确认后再做。

| 项 | 落点 | 验收 |
| --- | --- | --- |
| semver 澄清 | `docs/adr/0001-package-versioning.md` 新增「补充（2026-11-07）：未发布窗口的边界」；`AGENTS.md` / `docs/releasing.md` 的 7.1 示例改成「已发布 API 删除 → 8.0.0；上次发布后新增的 API 才能在当前未发布版本直接改」 | `check_docs.sh` 全绿；ADR 补充段带日期 |
| ci_matrix 正向断言 | `scripts/ci_matrix.py` 新增 `required_filter_errors`（关键正向规则 + quantifier）、`required_job_errors`（required.needs / 门控 job 的 if / docs job meta 命令）；`ci.yml` 的 docs job 增加 `ci_matrix --check` + `check_gate_coverage` | `test_ci_matrix_path_filters.py` 覆盖「删关键规则 / 错 quantifier / required 缺 docs / docs job 少 meta」；`ci_matrix --check` 通过 |
| check_pr_scope 根 CHANGELOG | 根 CHANGELOG 只有在同时改根 `lib/` 或 `pubspec.yaml` 时才算；改子包代码 + 根 CHANGELOG 仍不算 | `test_check_pr_scope.py` 覆盖根 lib / 根 pubspec / 根 CHANGELOG 单改 / 子包代码四种组合 |

验证：`bash scripts/check_docs.sh` 全绿；`scripts/tests` 92 tests OK；`ci_matrix --check` / `check_gate_coverage` 通过。

未做：

- `check_pr_scope` 的「当前版本段是否被改」严格解析——依赖作者勾选，边际收益低，等出现旧段记录再说；
- semver API 门禁——需要先定 0.x（figma / device / e2e）策略，再决定是否强制 major。
