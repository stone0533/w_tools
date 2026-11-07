> 分析记录：带日期的历史评审，不代表当前状态。

# 全流程三轮审计：改动 → 门禁 → PR → 发布（2026-11-07）

> 基线 `main @ 9350071`（PR #19 合并后，工作区干净，`HEAD == origin/main`）。
> 范围：`AGENTS.md` / `CONTRIBUTING.md` / `README.md` / `docs/` / `scripts/` / `.github/workflows/`。
> 方法：文档与脚本对读 + 实跑门禁 + 在 `/tmp` 副本上做对抗性验证（工作区未改）。
> 环境限制：本机沙箱不能写 Flutter engine cache，`flutter analyze` / `flutter test` 报
> `Operation not permitted`；`dart test` 在 `packages/cli` 里默认也会因嵌套 `dart run`
> 写 `~/.dart-tool` 遥测失败，设置可写 `HOME` 后 418 个 CLI 测试全过。
> 这两条是环境问题，不计入仓库缺陷；同一命令在 PR #19 的 CI 上成功。

## 0. 结论

| 维度 | 评价 | 说明 |
| --- | --- | --- |
| 结构与单一来源 | 好 | manifest / preflight / CI 派生 / 生成物 / API 快照 / 周检的骨架成立 |
| 当前 main 门禁 | 好 | `check_docs` 18 步、`release_check --strict`、`ci_matrix --check`、`gate coverage`、167 个脚本单测全绿 |
| PR 分类门禁 | 中 | 空 PR body、模板段但一个勾选都没有，都会让行为变化通道静默跳过 |
| 版本门禁 | 中 | 用 base tip 而不是 merge-base；版本降级可过；根包不在门禁内 |
| 发布状态机 | 中 | `--strict --package` 跳过快照不变量，单包发布可以带着「快照比本地新」上线 |
| 周检 | 中 | 删 `schedule` / 加 `if: false` / `continue-on-error` 后，meta 门禁仍然绿 |
| 工具包（尤其 cli） | 中 | `check_pr_scope` 只看 `lib/`；CLI 的 `bin/`、templates、catalog 变化没有分类/版本兜底 |
| 文档一致性 | 中 | 大部分已收敛，仍有 3 处会误导操作者的表述 |
| 可维护性 | 中 | 单人维护、36 个脚本、200+ md；meta 门禁能挡大部分接线回归，但挡不住「改配置关掉门禁」 |

**一句话：二轮修掉的假绿没有再复发，骨架不需要改；本轮真正值得修的是 3 条假绿
（空 body / 全未勾选、base tip、单包 `--strict` 跳过快照）和 2 条发布/周检断点，
合计约 2–3 小时；其余是文档漂移与已知的仪式类取舍。**

## 1. 流程全貌与本次实测

```text
改代码 / 文档
  → preflight.sh（本地；静态 + 可选测试 + 可选 dry-run）
  → PR（模板四类 + J-4 + 版本物料）
  → CI: matrix / changes / docs / umbrella / api-bump / min_sdk / packages
  → Required checks → Merge commit
  → release_check --package → publish 子包（快照进 .w_tools/）
  → apply_snapshots + 快照 PR → release_check --strict（根）→ publish 根包
  → release_status --online / 每周一 CI
```

实测结果：

```bash
bash scripts/check_docs.sh                                  # 18 步全 ✓
bash scripts/preflight.sh                                   # 除 analyze（沙箱）外全 ✓
bash scripts/release_check.sh --strict                      # 通过（0 提醒）
python3 scripts/release_status.py --online                  # cli 1.15.0 待发布，其余已发布
python3 scripts/ci_matrix.py --check                        # 通过（15 个包）
python3 scripts/check_gate_coverage.py                      # 通过
cd scripts/tests && python3 -m unittest discover -p 'test_*.py'   # 167 tests OK
cd packages/cli && HOME=/tmp/wt-home dart test              # 418 tests OK
gh run list --branch main --limit 1                         # PR #19 的 CI success
```

对抗性验证（均在工作区外的 `/tmp` 副本上）：

```text
PR_BODY='' + 改 lib/                         → check_pr_scope exit 0（P1-1）
模板段 + 四个勾选全空 + 改 lib/               → check_pr_scope exit 0（P1-1）
version 2.0.0 → 1.9.0 + 新增公开类型          → check_version_bump exit 0（P1-2）
main 前进后，feature 未同步且自身无改动       → check_version_bump 误报「没抬版本」（P1-2）
快照 9.9.9、本地 2.0.0                         → release_check --strict --package exit 0；完整 --strict exit 1（P2-1）
release-status.yml 加 if: false / continue-on-error / 删 schedule → ci_matrix --check exit 0（P2-2）
删掉 cli 的全部快照                            → check_public_api_diff --package cli exit 1（P3-1）
```

## 2. P1-1 空 PR body / 全未勾选，仍然放行行为变化

**证据**

```text
# 改了 packages/toast/lib/w_tools_toast.dart，PR body 为空
$ PR_BODY='' python3 scripts/check_pr_scope.py --base HEAD~1
没有 PR body 上下文（本地 / 非 PR 事件），跳过改动类型检查
exit=0

# PR body 有「## 改动类型」，但四个勾选全是 [ ]（模板默认状态）
$ PR_BODY=$'## 改动类型\n\n- [ ] 内部重构\n- [ ] 公开变化（API / 行为 / 新组件）' \
    python3 scripts/check_pr_scope.py --base HEAD~1
PR 未勾选「公开变化」，跳过 CHANGELOG 检查
exit=0
```

`check_pr_scope.py:118-121` 把「body 为空」当成「没有 PR 上下文」；而 CI 里
`github.event.pull_request.body` 为空时，脚本收到的同样是一个空字符串，无法区分。
`has_template_section` 只检查 `## 改动类型` 出现过，不要求至少勾选一项。

**影响**：行为变化没有 API diff，`check_version_bump` / `check_public_api_diff` 都看不到；
这条 PR 模板通道是它们唯一的兜底。用 `gh pr create --fill`、或干脆不勾选，就能
把「公开变化」声明成「内部重构」，不写 CHANGELOG、不抬版本合并。

**最小修法**

1. CI 显式传上下文（例如 `PR_CONTEXT=1`），或脚本读 `GITHUB_EVENT_NAME=pull_request`；
   在「PR 上下文且 body 为空、又改了 `lib/`」时直接失败，不再打印「跳过」。
2. `touches_public_code(changed)` 为真时，要求四类勾选**至少中一个**；一个都没勾
   视为「没声明」，失败并提示用模板。
3. 补 `test_check_pr_scope.py`：空 body、全未勾选、section 被删三种输入都应 exit 1。
4. 同步 `AGENTS.md:21`、PR 模板的说明：空 body 不是「内部重构」。

**验收**：上面两条命令都 exit 1；只改 scripts/docs 的 PR 仍然 exit 0。

## 3. P1-2 `check_version_bump` 用 base tip 而不是 merge-base；版本可降级

**证据**

```text
# main 上另一个 PR 新增了公开类型（未抬版本），feature 分支未同步、自身无改动
$ git checkout feature && python3 scripts/check_version_bump.py --base main
✗ toast: 公开 API 有 2 处变化（WOtherProbe、WOtherProbe.new…），但版本仍是 2.0.0
exit=1        # 这个 PR 什么都没改，却被判「没抬版本」

# 同一 PR：新增公开类型 + 把 2.0.0 改成 1.9.0
$ python3 scripts/check_version_bump.py --base HEAD~1
✓ 公开 API 变化的包都已抬版本（对比 14 个包）
exit=0        # 版本降级 + API 变化，直接放行
```

`check_version_bump.py:206` 直接用 `args.base` 取 base 表面；`check_pr_scope.py:93-110`
却正确地用了 `git merge-base`。`requires_bump()` 的第一条是
`new_version != base_version` 就放行，没有校验 `new > base` / `new > published`。

**影响**

- 依赖「先 merge main 再 push」；一旦 main 前进后只 push 了业务提交，Required check
  会误报，逼人合并无关改动或改版本号。
- 版本降级（2.0.0 → 1.9.0）在 PR 上绿灯；`pub publish` 只会在「目标版本已存在」时
  报 409，若降到某个从未发布的旧版本，仍可能发出去。
- 根包 `w_tools` 不在 `manifest_packages()` 里，删除一条 re-export 没有版本门禁
  （见 P3 清单的「根包 re-export」项）。

**最小修法**

1. 用 `git merge-base <base> HEAD` 作为 surface / version 的对比点；base ref 只用于
   找 merge-base，archive 也从 merge-base 取。
2. `requires_bump()` 增加 `new_version > published_version`（`--online` 时以 pub.dev
   为准），以及 `new_version >= base_version`；降级直接报错。
3. 补单测：main 前进、降级、同版本未发布、根包 re-export 四类。

**验收**：feature 无改动 + main 前进 → exit 0；降级 + API 变化 → exit 1。

## 4. P2-1 `release_check --strict --package` 跳过快照不变量

**证据**

```text
# /tmp 副本：给 toast 多放一个 w_tools_toast-9.9.9.txt，本地仍是 2.0.0
$ bash scripts/release_check.sh --strict --package toast
检查通过（0 条提醒）        exit=0

$ bash scripts/release_check.sh --strict
✗ toast: API 快照 9.9.9 ≠ 本地版本 2.0.0——先发布子包并提交快照，再发根包
exit=1
```

`release_check.sh:273` 的整个「API 快照」段被包在 `if [ -z "$SELECTED" ]` 里；
`publish_package.sh:251` 对子包正好调用 `release_check.sh --strict --package`。
所以单包发布路径**从不检查最新快照是否比本地版本新、是否已 tracked**。

**影响**：快照比本地新说明包回退过（或快照挂错版本），但单包发布不会拦；而发布是
不可回滚的。完整 `--strict` 会在下一次根包发布时才发现，届时已经晚了。

**最小修法**

1. 把快照检查移出 `if [ -z "$SELECTED" ]`，按 `$SELECTED` 只查该包；判据：
   - 最新快照必须存在且已 tracked（新包首发窗口可显式放行）；
   - `version_tuple(snapshot) <= version_tuple(local)`，即不允许「快照比本地新」。
2. 或在 `publish_package.sh` 发布前直接比较 staging 的 version 与
   `latest_snapshot_version(pkg)`：本地 < 快照 → 拒绝；无快照 → 仅新包允许。
3. 补一条 `--strict --package` 的回归测试（更快、比全仓 strict 更贴近真实发布路径）。

**验收**：快照 9.9.9 / 本地 2.0.0 时，`--strict --package` 与 `publish_package.sh --dry-run`
都失败；正常「本地领先快照」仍放行。

## 5. P2-2 周检可以被静默关掉，meta 门禁仍然绿

**证据**

```text
# 给 .github/workflows/release-status.yml 的步骤加 if: false
$ python3 scripts/ci_matrix.py --check
CI / 包清单一致性检查通过（15 个包）     exit=0

# 加 continue-on-error: true
$ python3 scripts/ci_matrix.py --check
CI / 包清单一致性检查通过（15 个包）     exit=0

# 删掉 on.schedule，只留 workflow_dispatch
$ python3 scripts/ci_matrix.py --check
CI / 包清单一致性检查通过（15 个包）     exit=0
```

`ci_matrix.release_status_workflow_errors()` 只把 workflow 的 `run` 文本拼起来找
`scripts/release_status.py --online --check`；不解析 `on.schedule`，也不检查该 step
的 `if` / `continue-on-error`。`gate_step_errors()` 覆盖的是 `ci.yml` 的
required / min_sdk / umbrella / api-bump / docs / matrix / packages，不覆盖周检。

**影响**：周检是唯一能发现「仓库落后线上 / 快照漂移 / 缺快照」的门禁。删 schedule 或
加一行 `if: false`，本地 / CI 都不会红，故障只能等下一次发布时手发现。

**最小修法**

1. 解析 `on.schedule`，断言存在 `cron`（`0 1 * * 1`），否则报错。
2. 对 `status` job 的步骤复用 `_gate_step_errors()`：带 `if` / `continue-on-error` 即失败。
3. 把 `release-status.yml` 加进 `ci_matrix` 的回归测试（目前只在 `scripts/tests` 里可能
   有零散覆盖；至少补一条「删 schedule / 加 if」用例）。

**验收**：上述三种改法都让 `ci_matrix --check` exit 1。

## 6. P2-3 `release_check --online` 的 404 仍然只警告（一轮 P1-5 残留）

**证据**：`release_check.sh:301-303`：

```bash
json="$(curl -fsSL --max-time 10 "https://pub.dev/api/packages/$name" 2>/dev/null)" || json=""
if [ -z "$json" ]; then
  warn "$name: 取不到线上版本（网络不可达或包不存在），跳过比对"
  continue
fi
```

404 与断网都落到空 `json`，只 warn；只要还有一个包取到，最后 exit 0。
而 `docs/releasing.md:247` 写的是「pub.dev 404 判失败（包名拼错 / 改名）」。

**影响**：发布后核对时，包名拼错 / 改名 / 被删只会得到一条提醒；`release_check --online`
仍打印「检查通过」。`release_status.py` 已经区分 404 与网络错误，这里没有跟上。

**最小修法**：用 `curl -w '%{http_code}'` 或 Python `urllib` 取状态码，404 直接 fail；
网络错误才 warn / 返回 2。更省事的做法是 `release_check --online` 直接委托
`release_status.py --online --check`（但注意「待发布」语义不同，不能直接互替）。

**验收**：单包 404 → exit 1；断网 → exit 2；正常 → exit 0。同步修
`docs/releasing.md:163-164`（现在写「只有落后 / 快照不一致才会红」，漏了 404 / 缺快照）。

## 7. P2-4 PR 门禁依赖分支保护设置，当前可被直推绕过

**证据**

```text
$ gh api repos/stone0533/w_tools/branches/main/protection
required_status_checks.strict = false
enforce_admins.enabled = false
```

- `ci.yml:206-208` 的 `api-bump` 只在 `pull_request` 事件跑；`push` 到 main 时
  `check_version_bump` / `check_pr_scope` 不会执行（main 的 CI 只跑 umbrella / docs /
  packages）。
- `.githooks/pre-push` 能挡直推，但要先 `install_git_hooks.sh`；`--no-verify` 可绕过。
- `strict=false` 允许 PR 在落后 main 时合并；合并提交没有重新跑 PR 门禁。

**影响**：管理员（仓库所有者）直推 main 时，版本门禁 / PR 分类门禁完全跳过；
落后分支合并后，merge commit 的组合状态也从未被 PR 门禁验证过。

**最小修法**（二选一）

1. 打开 `enforce_admins`（至少让 required checks 对管理员生效），并把
   `required_status_checks.strict` 设为 true；代价是每次合并前要同步 main。
2. 给 `api-bump` 增加 `push` 分支：用 `github.event.before` 当 base 跑
   `check_version_bump` / `check_pr_scope`（PR body 从 `github.event.head_commit.message`
   取不到，PR 分类只能跳过；至少版本门禁能跑）。

单人或小团队可以保留现状，但应在 `CONTRIBUTING` 写明「直推 main 会跳过版本门禁，
属于已知例外」，不要让读者以为 pre-push 是强制的。

## 8. P2-5 CLI 的 `bin/` / templates / catalog 不在 PR 分类门禁内

**证据**

```text
# 只改 packages/cli/templates/agents/zh/core.md，带模板段但只勾「内部重构」
$ PR_BODY=$'## 改动类型\n\n- [ ] 内部重构（公开 API / 默认行为不变）' \
    python3 scripts/check_pr_scope.py --base HEAD~1
PR 未勾选「公开变化」，跳过 CHANGELOG 检查
exit=0
```

`check_pr_scope.PUBLIC_PATH` 只有 `^(?:packages/[^/]+/lib/|lib/)`；`bin/`、`templates/`、
`catalog/` 都不算「公开代码」。`check_version_bump` 对 `cli` 在
`NO_PUBLIC_API` 里直接跳过（`check_version_bump.py:198-200`），
`check_public_api_diff` 对 cli 只做「快照版本对齐」，不比较内容。

**影响**：CLI 的公开行为主要是生成的 AGENTS / AI_PROMPTS / catalog 和命令参数；改模板
（例如 Form / Button 规则）对消费方是行为变化，但可以按「内部重构」合并，不抬
`w_tools_cli` 版本、不写 CHANGELOG。AI 资产是这一层的主要交付物，正好落在门禁之外。

**最小修法**

1. 把 `packages/*/bin/`、`packages/cli/templates/**`、`packages/cli/catalog/**`、
   `packages/cli/schema/**` 加进 `PUBLIC_PATH`（至少让改 `lib/` 的「必须带段」规则
   扩展到这些路径）。
2. 勾了「公开变化」时，`packages/cli/CHANGELOG.md` 必须被改（现有 `touches_changelog`
   接受任意包 CHANGELOG，需补「改的是哪个包」的归属）。
3. 若不想把模板算公开 API，至少在 `CONTRIBUTING` / `AGENTS` 写明「模板 / catalog 改动
   按公开变化处理」，否则规则和门禁对不上。

## 9. P3 清单（不影响当前门禁，按需处理）

| 项 | 证据 / 现状 | 建议 |
| --- | --- | --- |
| 新增工具包缺 header-only 快照 | `check_public_api_diff.py:373-383` 在 `NO_PUBLIC_API` 判断之前就要求快照；删掉 cli 快照后 `--package cli` exit 1 | `AGENTS.md:23` 的新增包清单补「工具包也要生成 header-only 快照」；或对 `NO_PUBLIC_API` 的缺快照给专门提示 |
| 根包 re-export 无 API 门禁 | `check_version_bump.manifest_packages()` 不含 `w_tools`；根 barrel 删除一条 export 只靠测试兜底 | 为 `lib/w_tools.dart` 的 export 行建小基线，纳入 `check_version_bump`；至少测试断言「恰好 6 条 export」 |
| `ci_matrix.REQUIRED_FILTERS` 只是子集 | `code` 未钉 `packages/**/assets/**`、`packages/**/pubspec.lock`、`example/**`、`pubspec.lock`、`analysis_options.yaml`；`static` 未钉 `scripts/**/*.yaml`、`scripts/**/*.txt`、`.githooks/**` | 全量钉住正向规则，或像二轮那样用 `git ls-files` 反算「非文档文件必须至少命中 code/static」，删规则时直接失败 |
| 文档漂移 | `scripts/README.md:227` 说「每个包最新快照版本 == 本地」，实际只有根聚合包；`docs/releasing.md:247` 的 404 说明与 `release_check.sh` 不符；`:163` 漏了 404 / 缺快照 | 改成「每个包快照已 tracked，根聚合包版本 == 本地」；404 说明改到 `release_status` 或修脚本；补 404 / 缺快照两种红 |
| `MIN_FLUTTER_VERSION` 无一致性检查 | `ci.yml:19-25` 注释要求与 pubspec 一起改，`ci_matrix --check` 只校验 `.fvmrc` ↔ `FLUTTER_VERSION` | 解析各包 `environment.flutter` 下限，断言 `MIN_FLUTTER_VERSION >= 声明下限`；或明确写「MIN 只测保守下限」 |
| J-4 / issue / merge commit 是仪式 | 模板有 J-4 结论位但无机器检查；`gh issue list --state all` 仍为空；merge 方式无校验 | 保留则明确「靠 review」；要省事就把 J-4 降级为一行结论、把 issue-first 改成建议，避免读者以为有门禁 |
| 本地 `/tmp` 副本的 `dart run` 遥测 | 只影响无写权限 HOME 的沙箱；CI 正常 | 可选：CLI 测试的 `Process.run` 参数加 `--suppress-analytics`，让 `preflight --with-tests` 在沙箱也能跑 |

## 10. 建议（按 ROI，不新增门禁框架）

| 阶段 | 动作 | 关闭 | 成本 | 验收 |
| --- | --- | --- | --- | --- |
| 0 | `check_pr_scope`：PR 上下文区分空 body；至少一个勾选 | P1-1 | 30 min | 空 body / 全未勾选 → exit 1 |
| 0 | `check_version_bump`：merge-base + 不允许降级 | P1-2 | 40 min | main 前进不误报；降级 → exit 1 |
| 0 | `release_check --online`：404 fail-closed | P2-3 | 20 min | 单包 404 → exit 1；断网 → 2 |
| 0 | 三处文档漂移 | P3 | 20 min | `check_docs.sh` 全绿 + 抽查 |
| 1 | `--strict --package` 补快照不变量 | P2-1 | 30 min | 快照 9.9.9 / 本地 2.0.0 → exit 1 |
| 1 | 周检 workflow 的 schedule / step 条件断言 | P2-2 | 30 min | `if: false` / `continue-on-error` / 删 schedule → exit 1 |
| 1 | `PUBLIC_PATH` 扩到 CLI 的 bin / templates / catalog | P2-5 | 30 min | 只改模板 → 要么带段，要么公开变化 + CHANGELOG |
| 2 | 分支保护：`enforce_admins` / `strict` 或 push 版 api-bump | P2-4 | 30 min | 直推 main 不再能跳过版本门禁 |
| 2 | 新增工具包 / 根包 / filter 全量钉住 | P3 | 1 h | 新包清单可照做；删过滤器会失败 |

**不做**：再加一层新门禁框架、完整 semver API 门禁、J-4 强制矩阵、规则三副本强行收敛。
这些在前两轮已经论证过，收益低于维护成本。

## 11. 与二轮的关系

**本轮复核确认已修好**

- 空 API 基线 / `--snapshot-from` 空 surface 校验（实测空快照 exit 1）。
- `check_deprecations` 只认紧贴注释块。
- CI 路径过滤补了 goldens / fixture / schema / `.pubignore`；`git ls-files` 反算只剩
  LICENSE / `.gitignore` / `.metadata` / `devtools_options.yaml` / 两个 `run_demo.sh`
  这类非测试输入。
- `check_public_api_diff` 的构造器删除、旧 major migration 限制。
- `release_status` 的 `--require-local` 只约束根聚合包；周检 exit 3 / 404 / timeout。
- `publish_package.sh` 的 `--force --reason` 审计。
- `ci_matrix` 的 outputs / if / required / step 语义检查（`ci.yml` 这一侧）。

**仍然开着（前两轮已记录，本轮再次确认）**

- `release_check --online` 的 404 / 断网区分（一轮 P1-5 的 `release_check` 部分）。
- 根包 re-export 无 API 快照 / 版本门禁（一轮 P2-2）。
- `MIN_FLUTTER_VERSION` 与 pubspec 声明无一致性检查（一轮 P2-3）。
- J-4 不可机器验证、issue-first 零使用、merge 方式无校验（仪式类）。
- 规则三副本（`AGENTS` / `docs/agents` / templates）仍靠 6 组短语兜底。

**本轮新增**：P1-1 空 body / 全未勾选、P1-2 base tip / 降级、P2-1 单包 strict 跳过快照、
P2-2 周检可被静默关掉、P2-5 CLI 模板路径不在门禁内。

## 12. 验证限制

- 本机 `flutter analyze` / `flutter test` 因沙箱不能写 Flutter engine cache 而失败，
  与仓库代码无关；`preflight` 的其余步骤全绿，CI 在 PR #19 上成功。
- `packages/cli` 的 418 个测试需要可写 `HOME`（遥测文件），设置后全过；默认 shell 下
  93 个失败全部来自嵌套 `dart run` 的 `Operation not permitted`，不是断言失败。
- 对抗性验证都在 `/tmp` 的 git clone / worktree 里完成，未改本仓库工作区。

## 13. 三条 P1/P2 假绿的 ROI 复核（2026-11-07 追问）

结论先说：**P1-1 和 P1-2 值得修；P2-1 不建议按原方案改 `release_check` 的契约，
最多在发布脚本里加一个 5–10 行守卫，或接受风险并记录。**

| 项 | 真实假绿 | 触发概率 | 后果 | 修复成本 | 结论 |
| --- | --- | --- | --- | --- | --- |
| P1-1 空 body / 全未勾选 | 是 | 中低（模板默认全空；近期 7 个 lib PR 都勾了，PR #18 空 body 但不改 lib） | 行为变化无 CHANGELOG / 版本说明 | 30 min | **修** |
| P1-2 base tip / 降级 | 是 | 中（main 前进后 push 就会触发；降级本身低） | 误报返工；或降级放行，发布不可回滚 | 40 min | **修**（merge-base 必做，降级顺手） |
| P2-1 单包 strict 跳过快照 | 是 | 低（快照只会在发布成功后生成；回滚 / 手工生成快照才会出现） | 单包可带错误基线发布，根包 strict 事后才发现 | 30 min 改契约 / 10 min 守卫 | **不加契约**；守卫可选，或记录接受 |

### 13.1 P1-1：值得修，理由是「默认状态就是未勾选」

近期 PR 的事实是：`#12`–`#17`、`#19` 都用了模板并勾选；`#18` 是快照 PR，body 为空但
不涉及 `lib/`，当前规则放行是正确的。所以这不是「已经出过事故」，而是「模板默认全空 +
`gh pr create --fill` 路径真实存在」，行为变化一旦漏勾就会静默通过，而它恰好是
`check_version_bump` / `check_public_api_diff` 唯一的兜底。

建议只改两处：

- CI 传 `PR_CONTEXT=1`（或读 `GITHUB_EVENT_NAME=pull_request`）；PR 上下文 + body 为空 +
  改了 `lib/` → 失败。docs-only / snapshot PR 仍跳过。
- PR 上下文 + 改了 `lib/`，但四类勾选一个都没有 → 失败；有 `## 改动类型` 但全空不再等于
  「内部重构」。
- 本地无 PR body 仍然跳过，保持 `preflight` 可用。

风险：几乎为零；唯一摩擦是改 `lib/` 的 PR 必须勾选一项，而模板本来就要求。验收：
`PR_BODY=''` + 改 `lib/` → 1；模板段 + 全 `[ ]` → 1；只改 `scripts/` → 0。

### 13.2 P1-2：值得修；merge-base 是正确性，降级是廉价保险

比「误报」更严重的是**误放行**：main 把版本从 2.0.0 抬到 2.1.0 后，feature 仍写 2.0.0
并改了 API；`base_version=2.1.0`、`new=2.0.0`，`requires_bump` 因为「new != base」直接
放行。所以这不是一个纯粹的体验问题。

建议拆两步：

1. **改用 merge-base（必做）**：`git merge-base <base> HEAD` 后，surface / version 都从
   这个 commit 取；`check_pr_scope` 已经是这个做法，两边一致。
2. **加单调性检查（顺手做）**：`new` 的 release 段（major.minor.patch）小于 `base` 或
   `published` 时失败。注意用 release 段比较，不要把 `1.0.0-dev.1` 的 pre-release 数字
   当成更高版本（`_version_tuple` 目前会把 `1.0.0-dev.1` 读成 `(1,0,0,1)`）。
3. 补测试：main 前进、降级、已发布版本重复抬、pre-release → release。

不建议在这一步顺便做「根包 re-export 快照」：那是另一个问题（P3），混进来会让 PR 变大。

### 13.3 P2-1：不建议改 `--strict --package` 的语义

原建议「把快照检查移出 `if [ -z "$SELECTED" ]`」有两个问题：

- **新包 / 首发**没有快照是正常状态，`--strict --package` 如果一律要求快照，会把首发
  流程卡住；要区分「新包」就得再引入 `pending_first_release` 判定，契约变复杂。
- 正常发布路径里，快照只在**发布成功后**生成，所以「快照比本地新」基本只可能来自
  回滚或手工生成；而回滚本来就违反 ADR-0001。`pub publish` 对已发布版本还会 409 兜底。

真正值得防的是**本地快照丢失**：`--strict --package` 不检查 tracked，如果某个已发布包的
快照在本地被 reset / clean 掉（PR #8 的旧场景），单包发布会带着缺失基线继续，之后新
快照覆盖，旧基线再也回不来。完整 `--strict` 会挡根包，但工具包 / 不聚合包不经过它。

所以更划算的做法是：

- **不改 `release_check` 的通用契约**，在 `publish_package.sh` 正式发布前加 10 行：
  - 最新快照存在时：本地 release 段 < 快照 → 拒绝；快照未 tracked → 拒绝；
  - 最新快照不存在时：只有 `pending_first_release.txt` 里的包允许（新包首发），否则拒绝。
- 或者明确接受这个风险，在 `docs/releasing.md` 写「单包发布不检查快照，根包 strict 才查」，
  并依赖发布前的 `preflight --with-tests`（它会跑 `check_public_api_diff`，缺基线会红）。

**推荐**：如果本轮只做两条，做 P1-1 + P1-2；P2-1 用发布脚本守卫或文档说明，不动
`release_check` 的 `--package` 契约。这样既修了真正会静默放行的地方，又不把首发流程
搞复杂。

## 14. 落地记录（2026-11-07 处理三条假绿）

按 §13 的结论落地了 **P1-1、P1-2、P2-1 的窄守卫**；没有改 `release_check --package`
的通用契约，也没有动包版本 / 公开 API。

| 项 | 落点 | 行为 |
| --- | --- | --- |
| P1-1 空 body / 全未勾选 | `scripts/check_pr_scope.py` + `.github/workflows/ci.yml` | CI 传 `PR_CONTEXT=1`；空 body + 改 `lib/` → exit 1；段存在但四类全空 → exit 1；勾选只在「## 改动类型」段内匹配 |
| P1-1 公开类别 | `scripts/check_pr_scope.py` | 公开变化 / 删除废弃 / 新增包都算公开类别，都要求对应 CHANGELOG |
| P1-2 base tip | `scripts/check_version_bump.py` | surface / version 都从 `git merge-base <base> HEAD` 取；main 前进不再误报 / 误放行 |
| P1-2 版本降级 | `scripts/check_version_bump.py` | `release_parts(new) < release_parts(base)` 或 `<= published` → exit 1；pre-release 按 release 段比较 |
| P2-1 单包快照守卫 | `scripts/publish_package.sh` + `scripts/check_public_api_diff.py --latest-snapshot` | 子包正式发布前：快照必须 tracked；本地版本不得低于 / 等于快照（新包首发在 `pending_first_release.txt` 时除外）；`--dry-run` / `--force` / 根包不受影响 |
| 文档同步 | `AGENTS.md`、`CONTRIBUTING.md`、PR 模板、`scripts/README.md`、`docs/releasing.md`、`docs/ai-contract.md`、`docs/ai-maintainer-prompts.md` | 规则与脚本一致 |

新增测试：

```text
scripts/tests/test_check_pr_scope.py      # 空 body / 全空 / 段外勾选 / 公开类别 / main 流程
scripts/tests/test_check_version_bump.py  # merge-base、降级、已发布重复抬、pre-release
scripts/tests/test_check_public_api_diff.py  # --latest-snapshot
scripts/tests/test_publish_snapshot.py    # 发布脚本快照守卫
```

验证：

```bash
cd scripts/tests && python3 -m unittest discover -p 'test_*.py'   # 188 tests OK
bash scripts/check_docs.sh                                        # 18 步全 ✓
bash scripts/preflight.sh                                         # 除 analyze（沙箱）外全 ✓
bash scripts/release_check.sh                                     # 0 提醒
python3 scripts/check_version_bump.py --base main                 # 14 包通过
```

发布守卫手工验证（`/tmp` 的 git clone，未真的发布）：

```text
快照 9.9.9 / 本地 7.0.0        → ✗ 本地版本低于最新快照，exit 1
无快照 / 不在 pending 名单     → ✗ 缺 API 快照，exit 1
cli 1.15.0 / 快照 1.14.0       → ✓ 守卫通过（用 fake dart 跳过实际 publish）
```

未做（仍按 §13 的判断）：`release_check --package` 的契约改造、CLI 模板路径扩展、
周检 workflow 的 schedule / if 断言、`release_check --online` 的 404 区分。这些不在
「三条假绿」范围内，留作下一轮。

## 15. 修复后复核（2026-11-07，未提交工作区）

> 基线：`main @ 9350071` + §14 的未提交修改。目标不是再列一轮全部历史，而是确认
> 三条假绿是否真的关闭、修复本身有没有引入新的误报，以及还剩什么。

### 15.1 已确认关闭

| 项 | 实测 |
| --- | --- |
| 空 PR body + 改 lib | `/tmp` git clone，`PR_CONTEXT=1` → exit 1 |
| 模板段 + 全未勾选 + 改 lib | 同上 → exit 1 |
| 段外勾选（命名 / 自检）被误当成改动类型 | 单测覆盖，`has_checked_box` 只读「## 改动类型」段 |
| `check_version_bump` 在 main 前进后误报 | `/tmp` 分支实测 → exit 0（merge-base 生效） |
| 版本降级 + API 变化 | 2.0.0 → 1.9.0 → exit 1 |
| 单包发布带「快照比本地新」 | `publish_package.sh packages/ui`（clone + 假 origin）→ exit 1 |
| 单包发布带「快照丢失」 | 删掉 ui 快照 → exit 1，提示先提交基线 / 新包走 pending |

修复本身没有引入新的误报路径：空 body 但只改 docs / scripts / snapshots 仍返回 0；
正常的 `cli 1.15.0` 对快照 `1.14.0` 通过守卫；`--dry-run` / `--stage-only` 不触发守卫。

### 15.2 仍然存在的断点（按影响排序）

| 优先级 | 项 | 现状 / 建议 |
| --- | --- | --- |
| P2 | `release_check --strict --package` 仍会打印「检查通过」而快照比本地新 | 实际 `publish_package.sh` 已守住，但把 `release_check --package` 当发布前唯一门禁的人仍会被误导。建议把守卫抽成 `release_check --package` 可复用的检查，或在脚本输出里明确「快照基线由 publish 脚本检查」 |
| P2 | 周检 workflow 仍可被 `if: false` / `continue-on-error` / 删 `on.schedule` 静默关掉 | `ci_matrix.release_status_workflow_errors` 只查命令文本；建议断言 `on.schedule` 与 step 条件 |
| P2 | `release_check --online` 的 404 仍只 warn | `release_status` 已区分 404，`release_check` 没跟上；文档 `docs/releasing.md:247` 仍写「404 判失败」 |
| P2 | CLI 的 `bin/` / `templates/` / `catalog/` 不在 PR 分类门禁内 | 只改模板仍可按「内部重构」合并；CLI 没有 barrel，`check_version_bump` 也跳过它 |
| P2 | 直推 main / 落后分支合并仍可绕过 PR 门禁 | `enforce_admins=false`、`strict=false`，`api-bump` 只在 PR 事件跑；要么开保护，要么补 push 版版本门禁 |
| P3 | 根包 re-export 没有 API 快照 / 版本门禁 | 删除一条 export 只靠测试兜底；建议给 export 行建小基线 |
| P3 | 新工具包需要 header-only 快照，但新增包清单没写 | `check_public_api_diff` 缺快照会失败；补 AGENTS 清单或专门提示 |
| P3 | `MIN_FLUTTER_VERSION` 不与 pubspec 声明比对 | 抬 / 降 Flutter 下限时 min_sdk 可能名不副实 |
| P3 | `check_pr_scope` 标题必须精确是 `## 改动类型` | 作者写成 `## 改动类型（必填）` 会被当成没有段；可考虑放宽标题后缀 |
| P3 | `check_version_bump` 的 pre-release 只用 release 段比较 | `1.0.0-dev.2` vs `1.0.0-dev.1` 会被当同版本；当前没有 prerelease 发布，可先记录 |
| P3 | 发布守卫没有被 CI dry-run 覆盖 | CI 的 `--dry-run` 走不到守卫；目前靠 `test_publish_snapshot.py` 的文本断言 + 手工 clone 验证 |

### 15.3 验证记录

```text
scripts/tests unittest                          # 188 tests OK
bash scripts/check_docs.sh                      # 18 步全 ✓
bash scripts/preflight.sh                       # 除 analyze（沙箱）外全 ✓
bash scripts/release_check.sh                   # 0 提醒
python3 scripts/check_version_bump.py --base main  # 14 包通过
python3 scripts/ci_matrix.py --check            # 通过
python3 scripts/check_gate_coverage.py          # 通过
```

`release_check.sh --strict` 在未提交工作区会按设计失败（有未跟踪的审计文档 / 修改），
提交后应恢复；本机 Flutter analyze / test 仍受沙箱 engine cache 限制。

**结论**：三条假绿已经关闭，修复没有引入新的误报；下一轮优先处理「快照守卫的
`release_check` 复用 / 周检自检 / CLI 模板路径 / 分支保护」，不用再改门禁架构。

## 16. 剩余项 ROI 复核（2026-11-07）

判断标准不是「能不能加门禁」，而是：**有没有第二条兜底、触发概率、后果是否可逆、
修复成本、会不会引入新的误报。**

| 项 | 值得改？ | 关键理由 | 建议成本 |
| --- | --- | --- | --- |
| 周检 workflow 可被 `if: false` / 删 schedule 关掉 | **值得，优先级最高** | 没有第二条线上漂移兜底；meta 门禁只查命令文本 | 30 min |
| CLI 的 `bin/` / templates / catalog 不在 PR 分类门禁 | **值得，下一批** | AI 模板是主要交付物；CLI 没有 barrel，API diff 也跳过 | 30 min |
| `release_check --package` 仍打印「检查通过」而快照不对 | **值得做小修** | 实际 publish 已有守卫，不会不可逆；但会误导操作者；不建议改通用契约，输出提示或复用守卫即可 | 20 min |
| `release_check --online` 404 只 warn | **不值得改代码；值得改文档** | `release_status --online --check` 已区分 404 且是周检入口；两套实现应减少而不是继续加 | 10 min |
| 分支保护 `enforce_admins=false` / `strict=false` | **看运维取舍，不是代码问题** | 单人仓库直推 / 落后合并是真实口子，但打开后增加同步摩擦；pre-push 钩子也依赖安装 | 5 min 决策 |
| 根包 re-export 无 API 快照 | **不值得新增门禁** | `test/umbrella_test.dart` 已断言恰好 6 条 export，增删都会红；只缺版本号门禁，收益低于维护成本 | 0 |
| 新工具包缺 header-only 快照 | **只值得补文档** | `check_public_api_diff` 缺快照会直接失败；补 AGENTS 新增包清单即可，不需要改逻辑 | 5 min |
| `MIN_FLUTTER_VERSION` 不与 pubspec 比对 | **暂不值得** | 只在升级 Flutter 时触发；当前 MIN 3.38.4 高于声明 3.38.0，方向保守 | 0（下次升级再看） |
| `check_pr_scope` 标题必须精确 | **可顺手修** | `## 改动类型（必填）` 会被当成没有段；一行正则 + 一个测试即可 | 10 min |
| `check_version_bump` pre-release 只比 release 段 | **暂不值得** | 当前没有 prerelease 发布；真要用 prerelease 时连同 `latest_snapshot` 排序一起做 semver 比较 | 0（记录假设） |
| 发布守卫没有被 CI dry-run 覆盖 | **可选** | 守卫只有十几行，文本测试 + `/tmp` clone 已验证；等守卫变复杂再抽函数 | 0–20 min |

### 16.1 建议的实际落地批次

1. **本周做**：周检 workflow 断言；`release_check --package` 复用 / 提示快照守卫；
   `docs/releasing.md` 的 404 表述改成与 `release_status` 一致。
2. **下一批**：CLI `bin/` / `templates/` / `catalog/` 进 `PUBLIC_PATH`；同时决定这些路径
   是否强制 CHANGELOG（建议“公开变化”类强制，纯拼写修正允许内部重构）。
3. **等下次触发**：新增工具包时补快照文档；Flutter 升级时补 MIN 检查；真正引入
   prerelease 时再实现完整 semver。
4. **不做**：根包 API 快照、J-4 强制矩阵、再叠加一层门禁框架。

### 16.2 为什么「周检」排第一

它是唯一在平时（不发布、不改代码）也会跑、能发现「仓库落后 / 快照漂移 / 缺快照」的
门禁。`ci_matrix.release_status_workflow_errors()` 目前只把 workflow 的 `run` 文本拼起来
找命令；删掉 `on.schedule`、给 step 加 `if: false` / `continue-on-error` 都不会红。
修复只需解析 `on.schedule` + 复用 `_gate_step_errors()`，没有业务代码风险。

### 16.3 为什么「根包」不建议再加门禁

`test/umbrella_test.dart` 已经逐条列出 6 个 export 并断言排序后的集合；删除或新增
export 都会让测试失败。根包真正的缺口只是「版本号是否跟着抬」，而根包版本在发布时
由完整 `release_check --strict` + `pub publish` 的重复版本检查兜底。为它单独维护一份
export 快照，成本高于收益。

## 17. 第二批落地（2026-11-07，提交后继续）

按 §16 的 ROI 顺序做了 4 项，仍然没有新增门禁框架：

| 项 | 落点 | 行为 |
| --- | --- | --- |
| 周检自检 | `scripts/ci_matrix.py` + `test_ci_matrix_path_filters.py` | 断言 `on.schedule` 仍含每周一 cron、status job 无 `if`、周检步骤无 `if` / `continue-on-error`；删 schedule / 改 cron / 关 step 都会让 `ci_matrix --check` 红 |
| CLI 公开路径 | `scripts/check_pr_scope.py` + 测试 | `PUBLIC_PATH` / `public_packages` 覆盖 `lib/`、`bin/`、CLI `templates/` / `catalog/` / `schema/`；这些路径的 PR 必须带改动类型，公开类别时按包要求 CHANGELOG |
| `release_check --package` 快照基线 | `scripts/release_check.sh` + 测试 | 单包模式新增「API 快照基线」段：快照高于本地 → fail；等于 / 缺失 → warn；低于本地 → ok。不再只靠 publish 脚本兜底 |
| 文档与边角 | `docs/releasing.md`、`scripts/README.md`、`AGENTS.md`、`check_pr_scope` | `--online` 404 说明改成以 `release_status` 为准；`--package` 快照说明；标题允许 `## 改动类型（必填）`；新增工具包补 header-only 快照要求 |

验证：

```text
scripts/tests unittest                          # 200 tests OK
bash scripts/check_docs.sh                      # 18 步全 ✓
bash scripts/preflight.sh                       # 除 analyze（沙箱）外全 ✓
bash scripts/release_check.sh                   # 0 提醒
bash scripts/release_check.sh --package ui      # 1 条快照基线提醒（快照 == 本地）
bash scripts/release_check.sh --package cli     # 0 提醒（本地 1.15.0 > 快照 1.14.0）
python3 scripts/check_version_bump.py --base main  # 14 包通过
python3 scripts/ci_matrix.py --check            # 通过（含新 schedule / if 断言）
python3 scripts/check_gate_coverage.py          # 通过
```

手工对抗验证：

```text
release-status.yml 删 schedule / 改 cron / status.if / step.if / continue-on-error
  → ci_matrix --check 均 exit 1
release_check --package ui + w_tools_ui-9.9.9.txt
  → exit 1（快照高于本地）
check_pr_scope：只改 packages/cli/templates/...
  → 空 body exit 1；公开类别无 CHANGELOG exit 1；有 packages/cli/CHANGELOG 通过
```

**仍然保留（不作为本轮范围）**：分支保护 `enforce_admins` / `strict`（运维决策）、
根包版本门禁（已有 export 测试）、`MIN_FLUTTER_VERSION`、prerelease semver、
发布守卫的 dry-run 覆盖。当前判断没有新的架构级问题。
