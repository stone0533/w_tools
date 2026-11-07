> 分析记录：带日期的历史评审，不代表当前状态。

# 全流程二轮审计：改动 → 门禁 → PR → 发布（2026-11-07）

> 基线 `main @ a645b17`（PR #11 合并后，工作区干净）。
> 范围：`AGENTS.md` / `CONTRIBUTING.md` / `README.md` / `docs/` / `scripts/` / `.github/workflows/`。
> 方法：文档与脚本对读 + 实跑门禁 + 在 `/tmp` 副本上做对抗性验证（工作区未改）。
> 环境限制：本机沙箱不能写 Flutter engine cache，`flutter analyze` 报 `Operation not permitted`
>（环境问题，不计入仓库缺陷；同一命令在 PR #11 的 CI 上成功）。
> 与上一轮的关系：`docs/analysis/2026-11-07-process-audit.md` 的 Phase 0/1 已基本落地
>（发布前 fetch、快照 pending 目录、`--require-tracked`、`--online` 返回 2、ci_matrix 接线断言）。
> 本文只写**仍然存在 / 新发现**的问题，§6 列出「已验证修好」的清单。

## 0. 结论

| 维度 | 评价 | 说明 |
| --- | --- | --- |
| 结构 | 好 | manifest 单一来源、`preflight` 单入口、CI 派生、生成物、API 快照、周检 |
| 形状门禁 | 好 | 链接 / 符号 / 生成物 / 版本 / 文档索引都有人守；当前 main 全绿（我实跑） |
| 语义门禁 | 中 | 多数检查只验「出现过」；本轮找到 5 处「特定输入下静默假绿」 |
| 发布状态机 | 中 | fail-closed 方向对，但「哪些包必须已发布」的假设与「工具包独立」冲突，会逼出 `--force` |
| 文档一致性 | 中 | 规则本身一致；仍有约 10 处措辞 / 路径 / 检查项与实际实现不符 |
| 可维护性 | 中 | 36 个脚本、202 个 md、单人维护；meta 门禁只校验文本，防不住一行 `if: false` |

**一句话：骨架成立，不建议改架构。真正值得修的是「会让门禁假绿」的 5 条（合计约 2 小时），
其次是发布状态机的 1 处越界和 ~10 处文档漂移；不建议再加新门禁。**

## 1. 流程全貌与断点

```text
改代码
  → catalog/components.yaml → gen_catalog → docs/modules/components.md + catalog.g.dart
  → templates/agents/{zh,en} → gen_templates → templates.g.dart
  → README / example / docs/agents
  → bash scripts/preflight.sh --with-tests        ← 本地唯一入口
  → PR（模板四类 + 命名 + J-4 + 版本物料）
  → CI: matrix / changes / docs / umbrella / packages / api-bump / min_sdk
  → Required checks → Merge commit
  → 发布：release_check --package → publish 子包（快照进 .w_tools/）
  → apply_snapshots + 快照 PR → release_check --strict（根）→ publish 根包
  → release_status --online / 每周一 CI
```

断点（详见 §2）：API 基线可能被写成空文件；路径过滤器覆盖不到 goldens / fixture；
版本门禁读不到 base 时静默当新包；根包发布被「未发布的工具包」卡住；PR 分类靠勾选可绕过。

## 2. 问题清单

### P1-1 空 API 基线会被判成「一致」，一个包的门禁永久空转

- **证据**：`scripts/check_public_api_diff.py:269-276` 的 `_load_snapshot` 把 0 字节 / 只有 header
  的文件读成 `{}`，`:353-355` 的 `diff_api({}, current)` 返回 `[]`，于是打印 ✓。
  实测（`/tmp` 副本，把 toast 快照清空）：

  ```text
  $ wc -c scripts/api_snapshots/w_tools_toast-2.0.0.txt
         0
  $ python3 scripts/check_public_api_diff.py --package toast
  ✓ toast 公开 API 与 w_tools_toast-2.0.0.txt 一致        exit=0
  ```

  这条链上没有第二道兜底：`apply_snapshots.sh` 只按文件名 `mv`；
  `release_status.py` 的 `--require-tracked/--require-local` 只读文件名里的版本，不读内容。
  所以空快照提交后，根包发布 `--strict` 也会放行。
- **影响**：基线被写空 / 截断后，该包整条公开 API 门禁永久空转，`preflight` / CI 全绿。
- **最小修法**：`_load_snapshot` 之后 3 行——`if not baseline and package not in NO_PUBLIC_API: return 1`。

### P1-2 `--snapshot-from` 不校验来源与版本，能凭空写出空基线

- **证据**：`scripts/check_public_api_diff.py:312-323` + `_write_snapshot:279-291`，
  既没有「surface 非空」断言，也没有「`--version` == 来源 pubspec 版本」断言。
  实测（`/tmp` 副本）：

  ```text
  $ python3 scripts/check_public_api_diff.py --snapshot-from /tmp/empty --package toast --version 9.9.9
  ✓ 写入 API 快照 scripts/api_snapshots/w_tools_toast-9.9.9.txt    # 只有一行 header，exit=0
  $ ... --snapshot-from packages/toast --package toast --version 1.0.0   # pubspec 是 2.0.0
  ✓ 写入 API 快照 …-1.0.0.txt
  ```

- **影响**：一条写错的补基线命令就能永久关掉一个包的门禁；写错的版本号还会成为
  `latest_snapshot_version()` 的「已发布基线」，同时喂给 `check_version_bump` 与 `release_status`。
  `publish_package.sh:244-248` 调用的正是同一条命令。
- **最小修法**：该分支 4 行——空 surface 且非 `NO_PUBLIC_API` → exit 1；
  `_pubspec_version(来源目录) != --version` → exit 2。

### P1-3 CI 路径过滤器有真实盲区：goldens / fixture / schema / `.pubignore` 改动不跑测试

- **证据**：`.github/workflows/ci.yml` 的 `changes` 过滤器只有
  `packages/**/*.dart` / `pubspec.*` / `analysis_options.yaml` / `assets/**` /
  `templates/**` / `catalog/**` / `lib/**` / `test/**` / `example/**` 等正向规则。
  用同一组规则复算 838 个 tracked 文件：**199 个两组合都不命中**，其中非文档类 39 个，包括：

  ```text
  packages/ui/test/goldens/wimage_*.png        # 改 golden 不跑 ui 测试
  packages/figma/test/fixtures/nodes-frame.json
  packages/cli/schema/context.v1.json
  packages/figma/schema/*.json
  packages/map/.pubignore  packages/map_google/.pubignore
  .pubignore  .github/workflows/release-status.yml
  ```

  这些路径只命中轻量 `docs` job（不装 Flutter），`umbrella` / `packages` 全部 skip，`required` 仍绿。
- **影响**：只改 golden / fixture / schema / 发布白名单时，对应包的测试与 dry-run 一次都不跑，
  属于「正常改动」而不是注入，会静默积累。
- **最小修法**：`code` 组补 `packages/**/test/**`、`packages/**/schema/**`、`packages/**/*.json`、
  `packages/**/.pubignore`、`.pubignore`、`.github/**`；同步 `ci_matrix.REQUIRED_FILTERS`。

### P1-4 `check_version_bump` 读不到 base 时把包当「新包」，版本门禁静默消失

- **证据**：`scripts/check_version_bump.py:70-81` 的 `base_surface` 把所有非零返回 / 空 stdout
  归成 `None`，`:159-161` 的 `if base is None: continue # 新包` 直接跳过。
  实测（`/tmp` 副本，用包装器让 `git archive` 返回 128）：

  ```text
  ✓ 公开 API 变化的包都已抬版本（对比 0 个包）        exit=0
  ```

- **影响**：局部克隆、对象缺失、环境异常时不是 exit 2，而是悄悄把该包（严重时全部包）
  移出版本门禁；只有「对比 0 个包」这行字提示。
- **最小修法**：用 `git cat-file -e {ref}:packages/{pkg}/pubspec.yaml` 判断「base 里有没有这个包」；
  archive 失败就报错或 exit 2（约 6 行）。

### P1-5 `check_deprecations`：相邻弃用项可以互借 `remove-in`

- **证据**：`scripts/check_deprecations.py:26` 的 `window = 8`，`:66-74` 在 `index±8` 的全窗口里
  找**第一个** `remove-in`，不校验归属。实测（`/tmp` 副本，3.0.0 包）：

  ```text
  两个相邻 @Deprecated，第二个没写 remove-in（第一个写 4.0.0，未到期）
    ✓ 弃用项都有到期版本，且没有到期未删的        exit=0
  只留缺 remove-in 的那条 → ✗ 缺 remove-in        exit=1
  ```

- **影响**：漏写 `remove-in` 的弃用项只要旁边有另一条弃用就能混过，到期删除永远不提醒。
- **最小修法**：只在紧贴声明的连续注释块里找（从 `index-1` 向上，遇空行 / 非 `///` / 非 `@` 停）；
  版本读不到时从 `continue` 改成报错。

### P2-1 快照滞后一个版本时，「删已发布 API」在 PR 上两门全绿

- **证据**：`check_version_bump.py:171-175` 用**仓库快照**当已发布基线，`:114-118` 把
  「新版本 > 基线」直接当未发布；`check_public_api_diff.py` 也只看快照里已有的 key。
  实测（`/tmp` 临时 git 仓库）：main 6.1.0、快照只有 6.0.0（文档允许的批量窗口），
  PR 删掉 6.1.0 新增的 `WExtra`、版本仍写 6.1.0：

  ```text
  ✓ 公开 API 变化落在未发布版本里：demo 6.1.0
  ✓ demo 公开 API 与 w_tools_demo-6.0.0.txt 一致
  ```

- **影响**：PR 级两门全绿。正常情况下问题会在快照 PR 落地时暴露（基线 6.1.0 仍含 `WExtra`），
  但如果快照被从当前 main 重新生成、或跳过 6.1.0 快照，这次删除就永远不会被记录。
- **最小修法**（不联网，约 8 行）：`new_version == old_version` 且 `published < new_version` 时，
  对「base 有、快照没有、本次被删/改」的 key 报错，提示先 `apply_snapshots.sh` 或抬版本。
  或在 CI 的 `api-bump` job 加 `--online`（runner 有网），拿 pub.dev 做真实基线。

### P2-2 PR 分类门禁可被四种方式绕过

- **证据**：`check_pr_scope.py:51-55` 任意 `packages/*/CHANGELOG.md` 都算；
  `:83-92` 没有 PR body / 没有勾选项就整条跳过。实测（`/tmp` 临时 git 仓库）：

  | 场景 | 结果 |
  | --- | --- |
  | ui 代码 + form CHANGELOG | ✓ exit=0 |
  | PR body 为空 / `gh pr create --fill`（无勾选框） | ✓ exit=0（整条跳过） |
  | 只把说明追加进已发布的旧段 `## 7.0.0` | ✓ exit=0 |
  | pubspec 停在已发布 7.0.0 + 行为改动 | ✓ exit=0 |

- **影响**：行为变化（没有 API diff）唯一的兜底可被「写错包 / 写进旧段 / 不用模板」满足或绕过。
- **最小修法**：① body 里没有 `## 改动类型` 就失败（CI 侧 3 行，本地无 body 仍跳过）；
  ② 被改 CHANGELOG 的包必须属于本次改动的包集合（约 6 行）；
  ③ 旧段 / 版本号按上一轮 §8 保持搁置，但模板别再承诺 CI 查版本。

### P2-3 删除公开构造器免检；旧 major 的 migration 会顶掉新版本说明

- **证据**：`check_public_api_diff.py:238-239` 对 `key.endswith('.new')` 只要 Breaking/migration
  里出现类名就算已记录；实测删 `WButton.new`、Breaking 只写了 `WButton.text` → `[]`（放行），
  删 `WButton.icon` 则正常报错。另 `:362` 固定取 `{pkg}-{major}.0.md`，7.1.0 的变更只要在
  `ui-7.0.md` 里提过就算记录（实测 `WColorExtension.fromHex` → `[]`）。
- **影响**：构造器删除 / 小版本破坏性变更可以零 CHANGELOG 通过。
- **最小修法**：删掉 `.new` 的 2 行免检；仅当 `major(当前) > major(已发布快照)` 时把 migration
  计入 notes（约 4 行）。

### P2-4 根包发布要求「每个包快照 == 本地版本」，包括工具包与不聚合的包

- **证据**：`release_status.py:176-199` 对 manifest **所有行**做 `--require-local`；
  `release_check.sh:273-281` 只在完整 `--strict` 调用；`publish_package.sh:231-235` 发根包时
  跑完整 `--strict`。实测（`/tmp` 假仓库，cli 本地 1.14.0、快照 1.13.0）：

  ```text
  异常：✗ cli: API 快照 1.13.0 ≠ 本地版本 1.14.0——先发布子包并提交快照，再发根包
  ```

- **影响**：`docs/releasing.md:69-71` 说工具包独立、不需要跟根包同批；但只要 `cli` / `qr` 等
  合并了一个未发布的版本，下一次根包发布就会被这条拦住，且提示语会误导人去「发子包」。
  操作者很容易改用 `--force`，而 `--force` 会跳过**全部**保护。
- **最小修法**：`--require-local` 只对 `root_aggregate == root` 的包生效（其余只要求快照已 tracked）；
  或明确把文档改成「根包发布前所有包（含工具包）都必须先发布」，并在 `--force` 时打印跳过了哪些检查。

### P2-5 meta 门禁只校验「文本出现过」，一行 `if: false` 就能让门禁静默失效

- **证据**：`ci_matrix.py:95-115` 用子串匹配过滤器规则，`:118-157` 只查 `required.needs`、
  门控 job 的 `if` 是否包含某个子串、docs job 的 `run` 文本是否包含命令；
  `check_gate_coverage.py:58-75` 只做「同一行有 bash/python3 + 脚本名」的匹配。
  在 `/tmp` 副本上实测以下改法两个检查都 EXIT=0：

  ```text
  required 的 run 换成 echo ok; exit 0
  matrix 的生成步骤换成手写 include JSON
  changes 的 output 改成 'false' / code 与 static 互换
  umbrella.if 加 && false；packages.if 加 == 'true' && false
  umbrella 的 preflight step 加 if: false
  api-bump 两步加 continue-on-error: true
  ```

- **影响**：`required` 是分支保护唯一要求的 check；掏空它或让门控 job 永久 skip，全部门禁退化为建议。
  对单人仓库，这不是「有人恶意改」，而是「调试时加了个 `if: false` 忘了删」。
- **最小修法**：用 PyYAML 解析 `ci.yml`，精确断言三条 `outputs` 表达式、三条门控 `if`、
  `required` 的 run 引用 7 个 `needs.*.result`，且调用 preflight / `check_*` 的 step 不带
  `if` / `continue-on-error`（约 40 行，替换现有子串匹配）。

### P2-6 周检（release-status）的三个洞

- **证据**：`release_status.py:161-168` 对「`--check` 但没带 `--online` / `--require-*`」返回 **2**，
  而 `.github/workflows/release-status.yml:32-35` 把所有 2 都当「pub.dev 不可达」跳过 → 配置写错永久绿。
  `:205-210` 单包取不到只记「未核对」，只有全部取不到才 exit 2 → 包名拼错 / 单包 404 静默通过。
  `:102-115` 单请求 timeout 10s × 3 次 + 退避，17 个请求最坏 ≈ 9.4 分钟，job `timeout-minutes: 10`。
- **影响**：网络半死时周检会失败（正是它想避免的误报）；配置写错时永远不报。
- **最小修法**：用法错误改成 exit 3；404 与网络错误分开；单次 timeout 降到 3s 或并发 fetch；
  把 `.github/workflows/**` 加进 `static` 过滤并给 workflow 加语法检查。

### P2-7 「新增包」清单对工具包不完整，工具包身份硬编码在 3 个脚本

- **证据**：`AGENTS.md:23` 的清单只列 manifest / workspace / README / example / feature 模板 /
  context capabilities / release。但新增一个**工具包**（无 barrel）还会撞上：
  `check_public_api_diff.py:28` 的 `NO_PUBLIC_API`、`check_docs_facts.py:38` 的 `TOOLS`、
  `check_naming.py:28` 的 `TOOL_PACKAGES`、`release_check.sh:178` 的 `case cli|figma|device|e2e`。
  `check_docs_facts` 会把新工具包当库包，要求它出现在 `docs/modules/README.md`。
- **影响**：照 AGENTS 的新增包清单做，CI 会红在两处没写进清单的地方。
- **最小修法**：把「工具包」判定收敛到一个地方（读 manifest 新列或 `_manifest.py`），
  并在 AGENTS 的新增包清单里补一行「工具包：登记 NO_PUBLIC_API / TOOLS」。

### P3 文档漂移（会误导照做的人 / AI，不影响当前门禁）

| 位置 | 问题 | 建议 |
| --- | --- | --- |
| `scripts/README.md:30-40` | preflight 覆盖清单漏了 `check_public_api_diff` / `check_test_imports` / `scripts/tests`；也未注明 `check_version_bump` / `check_pr_scope` 是 CI-only | 补三项 + 一行「CI-only」 |
| `scripts/README.md:271` | 说快照「发布成功后自动写入」（`api_snapshots`），实际先写 `.w_tools/release-snapshots/` | 与 :117-118 对齐 |
| `scripts/README.md:145` | 说 `check_package_docs`「不校验具体 patch」，实际三段版本整体比较 | 删掉半句 |
| `scripts/README.md:116` | `--check`「只把落后 / 快照漂移判失败」，缺快照也判失败 | 补「缺快照」 |
| `docs/releasing.md:56` | 没写脚本名：`release_check --online` 对待发布非 0，`release_status --online` 是 0 | 写死脚本名 |
| `docs/releasing.md:227-241` | 检查项表漏了「重复版本段」「CHANGELOG 第一段必须最新」 | 补两行 |
| `CONTRIBUTING.md:14` | 抬根约束后让跑 `release_check`（非 strict 只 warn） | 改 `--strict` 或注明 |
| `CONTRIBUTING.md:127` | 指向不存在的 `docs/agents/w_tools.md` | 改成「在消费方 issue/PR 注明」 |
| `CONTRIBUTING.md:79` / `.github/PULL_REQUEST_TEMPLATE.md:24` | `templates/agents/{zh,en}/<pkg>.md` 不存在；实际是 `<feature>.md`，app_getx/map_google 共用 app/map | 改成 `<feature>.md` + 映射说明 |
| `docs/conventions.md:110` | ①②③④ 指向已被删除的四条 grep 命令 | 删编号或恢复命令 |
| `docs/naming.md:320` | helper 放 `test/_helpers/` 没写「只能 import barrel」；需要 `src` 的要放 `test/internal/` | 补边界 |
| `docs/adr/0001-package-versioning.md:75-76` | 「写当前未发布的 minor 会被判到期」只在 `remove-in <= 当前版本` 时成立 | 改成「等于或低于」 |
| `AGENTS.md:191` | 说根目录有 `GLOSSARY.md`，实际没有（按需创建） | 加「按需创建」 |

### 仪式类（无机器落点，已在上一轮讨论过，保持现状或降级）

- **J-4 八列矩阵**：`CONTRIBUTING.md:75-80` 要求贴矩阵，但 PR 模板没有矩阵位置，也没有脚本读它。
  建议降级为「一行结论」，或给模板固定一行并由 `check_pr_scope` 要求非空。
- **issue 先开**：`gh issue list --state all` 仍为空（11 个 PR、0 个 issue），`ISSUE_TEMPLATE/`
  只有 `feedback.md`。要么补 bug / feature 模板真的用起来，要么按上一轮结论降级为建议。
- **Merge commit**：仓库内零校验；实测历史 merge 都是 2 个 parent。若要保持
  `git log --first-parent` 作为发布说明来源，可在 `releasing.md` 第 6 步加一条
  `git log -1 --format=%p <merge-sha>` 的抽查。

## 3. 建议（按 ROI，不新增门禁）

| 阶段 | 动作 | 关闭 | 成本 | 验收 |
| --- | --- | --- | --- | --- |
| 0 | 空基线 fail-closed + `--snapshot-from` 校验来源 / 版本 | P1-1/2 | 15 min | 空基线 → exit 1；错版本 → exit 2 |
| 0 | `check_deprecations` 只认紧贴注释块 | P1-5 | 20 min | 相邻两条弃用、第二条漏写 → 报错 |
| 0 | 补 `code` 过滤盲区（goldens / fixture / schema / pubignore / .github） | P1-3 | 20 min | 只改 golden 的 PR 会跑 ui 测试 |
| 1 | `check_version_bump`：archive 失败 fail-closed；快照滞后时对「删/改已发布 key」报错 | P1-4 / P2-1 | 40 min | 构造 lag 窗口 → exit 1 |
| 1 | `check_pr_scope`：无模板勾选失败 + CHANGELOG 包 ⊆ 改动包 | P2-2 | 40 min | 四种绕过场景全部 exit 1 |
| 1 | `--require-local` 限定 root 聚合包；`--force` 打印跳过项 | P2-4 | 30 min | 假仓库里 cli 未发布不再挡根包 |
| 2 | ci_matrix 语义化断言（outputs / if / required steps / step 禁用） | P2-5 | 1–2 h | 一行 `if: false` 会被 --check 拦住 |
| 2 | 周检：exit 3、404 区分、timeout 收敛 | P2-6 | 40 min | 去掉 `--online` → 周检红 |
| 3 | 文档漂移 13 处 | P3 | 1 h | `check_docs.sh` 全绿 + 抽查链接 |
| 3 | 新增包清单补工具包项；TOOLS 收敛 | P2-7 | 30 min | 新工具包只改 manifest + 一处常量 |

不做：三副本收敛、J-4 强制、semver API 门禁（0.x 策略未定）、通用发布编排器、再加大批新脚本。

## 4. 验证记录

```bash
bash scripts/check_docs.sh                      # 18 步全 ✓
bash scripts/preflight.sh                       # 除 analyze（沙箱）外全 ✓
bash scripts/release_check.sh --strict          # 通过（0 提醒）；含 fetch / upstream / 快照 tracked
python3 scripts/release_status.py               # 15 包 + root 全部与快照对齐（离线）
python3 scripts/ci_matrix.py --check            # 通过（15 个包）
python3 scripts/check_gate_coverage.py          # 通过
cd scripts/tests && python3 -m unittest discover -p 'test_*.py'   # 92 tests OK
```

对抗性验证（均在工作区外的副本上）：

```text
清空 toast 快照 → check_public_api_diff 打印 ✓（P1-1）
--snapshot-from 空目录 / 错版本 → 写出 header-only 快照，exit 0（P1-2）
git archive 返回 128 → check_version_bump 打印「对比 0 个包」，exit 0（P1-4）
相邻弃用、第二条漏 remove-in → check_deprecations ✓（P1-5）
快照滞后 + 删已发布 API → 两个门禁都 ✓（P2-1）
PR body 无勾选 / 跨包 CHANGELOG / 写旧段 → check_pr_scope ✓（P2-2）
release_status --require-local + cli 未发布 → 根包发布被挡（P2-4）
ci.yml 的 required / matrix / outputs / if / step 分别改坏 → 两个 meta 检查均 EXIT=0（P2-5）
```

## 5. 不是问题、别误判

- **`preflight` 全绿 ≠ 内容正确**：它只覆盖形状（链接、符号、生成物、版本），文档自己也这么写。
- **`check_teaching_coverage` 是 J-4A（子串）**：通过不代表讲清楚，这是设计边界。
- **`cli` 的 header-only 快照是显式设计**：`NO_PUBLIC_API` 登记后只打 `!`「不适用」。
- **子包发布阶段 `--all` 会失败**：根包 dry-run 要求依赖已发布，文档已说明。
- **`--force` 存在本身不是 bug**：问题是粒度太粗（一次跳过全部保护）。
- **分支保护没有 review / enforce_admins**：单人维护的取舍；`Required checks` 是真实生效的。
- **`docs/agents/workspace.yaml`**：是工具配置，不是文档，docs/README 已注明。
- **根 example 的 analyze**：`dart analyze` 在 workspace 根会分析嵌套 `example/`（已用 /tmp
  workspace 实测），CI 的 `flutter analyze` 覆盖它，不需要额外步骤。

## 6. 与上一轮的差异

**已验证修好（本轮复核）**

- 缺基线不再静默跳过（`check_public_api_diff.py:327-337`，删文件 → exit 1）。
- 空 `current` surface（barrel 缺失）不再假绿（`:340-352`）；`cli` 显式「不适用」。
- 发布前 `git fetch` + `HEAD == origin/main`（`publish_package.sh:213-225`、
  `check_git_sync.sh:14-20`）。
- 快照先写 `.w_tools/release-snapshots/`，一批一个快照 PR（`apply_snapshots.sh`）。
- 根包发布前要求快照 tracked 且版本一致（`release_check.sh:255-283`）。
- `release_check --online` 全部取不到时 exit 2；`release_status --check` 无核对目标时 exit 2。
- `ci_matrix --check` 能拦：删关键正向规则、quantifier、`!` 排除、`required.needs` 少 job、
  docs job 少 meta、manifest / workspace / root 聚合 / example 列不一致。
- 根 CHANGELOG 只有在同时改根 `lib/` 或根 `pubspec.yaml` 时才算（`check_pr_scope.py:53-55`）。

**仍开（本轮再次确认）**

- 空基线 / `--snapshot-from` 校验（上一轮 P1-8 第 1 条的后半，PR #11 只修了 `current` 侧）。
- 快照当已发布基线（上一轮 P1-8 第 2 条）。
- PR 分类的跨包 / 空 body（上一轮 P1-8 第 3 条与 §8 的搁置项）。
- `MIN_FLUTTER_VERSION` 与 pubspec 声明下限的一致性（上一轮 P2-3）。
- 周检的「配置错误当断网」「404 静默」（上一轮 P1-5 / P2-9 的残余）。
- 规则三副本、J-4 强制、issue 流程（上一轮已决定不做 / 降级，文档未跟进）。

---

## 7. 落地记录（2026-11-07 二轮修复）

本轮按 §3 的 Phase 0–3 落地，全部改动集中在 `scripts/`、`.github/` 与文档；不涉及公开
API，因此没有版本号 / CHANGELOG 变更（`packages/` 未改）。

| 项 | 落点 | 验收 |
| --- | --- | --- |
| 空基线 fail-closed | `check_public_api_diff.py`（`_load_snapshot` 之后 3 行） | 0 字节 / 只有 header 的快照 → exit 1；`cli` 仍按 `NO_PUBLIC_API` 跳过 |
| `--snapshot-from` 校验 | 同文件（来源必须是包目录、`--version` == 来源 pubspec、surface 非空） | 空目录 → exit 2；版本不符 → exit 2；不会再写出空基线 |
| 弃用 `remove-in` 归属 | `check_deprecations.py` 改为向上找**紧邻注释块**；版本读不到改 error | 相邻两条弃用不再互借；`test_check_deprecations.py` 7 例 |
| 删除构造器 / 旧 major migration | `check_public_api_diff.py`（去掉 `.new` 免检；migration 只在跨 major 时计入） | `check_notes` 单测覆盖两种免检通道 |
| 快照滞后 | `check_version_bump.py` 新增 `--online`（CI `api-bump` 使用，pub.dev 失败回退快照并提醒）；`git archive` 失败不再当新包 | 「同版本 + 快照滞后 + 删已发布 API」现在要求抬版本 |
| PR 分类 | `check_pr_scope.py`：改 `lib/` 的 PR 必须带「## 改动类型」段；每个改了 lib 的包都要改自己的 CHANGELOG | 跨包 CHANGELOG / `gh --fill` 无模板段 → exit 1；只改 scripts 的 PR 仍跳过 |
| 根发布 scope | `release_status.py`：`--require-local` 只要求 `root_aggregate == root` 的包；工具包 / 不聚合的包允许待发布；新增 `local_snapshot_errors` 单测 | 假仓库 cli 1.14.0 vs 快照 1.13.0 → 根发布检查 exit 0 |
| `--force` 审计 | `publish_package.sh` 在 `--force` 时打印跳过的保护项 | 发布日志可追溯 |
| CI 路径过滤 | `ci.yml` 的 `code` 补 `packages/**/test/**`、`schema/**`、`*.json`、`.pubignore`、根 `.pubignore`；`ci_matrix.REQUIRED_FILTERS` 同步 | 只改 golden / fixture / schema 会跑对应包矩阵 |
| meta 门禁语义化 | `ci_matrix.py` 新增 `wiring_errors` / `gate_step_errors` / `matrix_emit_errors` / `pr_template_errors` / `release_status_workflow_errors` | `outputs` 改 false、`if` 加 `&& false`、step 加 `if: false` / `continue-on-error`、required 被掏空、矩阵改手写 JSON、周检被删 → `--check` 全部报错 |
| 周检健壮性 | `release_status.py` 用法错误返回 3；404 判失败、网络错误才跳过；timeout 5s ×2 次；`release-status.yml` timeout 15 分钟 | 去掉 `--online` → 周检红；404 → 红；断网 → 跳过 |
| 文档漂移 | `scripts/README.md`、`docs/releasing.md`、`CONTRIBUTING.md`、`docs/conventions.md`、`docs/naming.md`、`docs/ai-contract.md`、`scripts/api_snapshots/README.md`、`AGENTS.md`、PR 模板 | `bash scripts/check_docs.sh` 18 步全绿 |

验证：

```text
scripts/tests unittest              # 126 tests OK（新增 34 条）
bash scripts/check_docs.sh          # 18 步全绿
python3 scripts/ci_matrix.py --check
python3 scripts/check_gate_coverage.py
bash scripts/release_check.sh       # 0 提醒
python3 scripts/check_version_bump.py --base main --online   # 14 包对比通过
逐包 check_public_api_diff          # 14 包一致 + cli 不适用
bash scripts/preflight.sh           # 除 analyze（沙箱写不了 fvm cache）外全绿
```

未做（保持上一轮 §6.4 的判断）：规则三副本收敛、J-4 强制矩阵、semver API 门禁、
`MIN_FLUTTER_VERSION` 与 pubspec 的自动比对（留到下次 Flutter 升级）。
