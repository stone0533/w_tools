# 维护者 AI 提示词手册

本文给 **w_tools 包维护者**使用：改代码、加组件、删 API、加包、整理目录、处理门禁红灯或发布问题时，直接复制对应提示词给 AI。

配套规则见 [`docs/ai-contract.md`](ai-contract.md)。

> 最后核对：2026-11-07。机器能查什么见 [`scripts/README.md`](../scripts/README.md) 的
> `check_prompt_docs.py` 一行；流程语义仍以 [`AGENTS.md`](../AGENTS.md)、
> [`CONTRIBUTING.md`](../CONTRIBUTING.md)、[`docs/releasing.md`](releasing.md) 为准。

> 快速跳转：[A](#a-内部重构--bug-修复) · [B](#b-修改现有公开组件--api--行为) · [C](#c-新增公开组件) ·
> [D](#d-删除--废弃公开-api) · [E](#e-新增包) · [F](#f-只整理-catalog--agents--文档) ·
> [G](#g-只审查不要修改) · [H](#h-ai-不能访问仓库--不能跑命令) · [I](#i-全仓审计--全量整理) ·
> [J](#j-单包全面审计只读) · [K](#k-发布-pub) · [L](#l-改-w_tools_cli--doctor--init-模板) ·
> [M](#m-处理--闭环反馈条目) · [N](#n-门禁--ci-红灯) · [N-1](#n-1-升级-flutter--依赖)

---

## 新手先看这里

你不需要先读完 A~N（含 N-1）。

### 只需三步

1. 用一句话说明任务；
2. 不知道该用哪个场景，先让 AI 帮你选；
3. AI 判断后，只复制对应场景块。

### 让 AI 帮你选场景

不确定选 A~N（含 N-1）时，先发这段：

```text
我是 w_tools 维护者，但不熟悉这些提示词。

请只读 docs/ai-maintainer-prompts.md 的「§1 场景选择」和「§0 固定前缀」，
以及 docs/ai-contract.md；不要通读全文。

我的任务是：<原因>。
范围是：<包> / <组件> / <文件>。

请先判断应该用 A~N（含 N-1）哪个场景，并说明原因；
不要改代码；
确认后，给我一份已经填好包名、组件和范围的提示词。
```

### 默认工作流

复杂改动 / 范围不确定时，按轮次拆：

```text
第 1 轮：只审计（G / J-0 / J-4 / K-1），不改文件
第 2 轮：只修 P0/P1（B / A / J-2）
第 3 轮：跑 bash scripts/preflight.sh --with-tests，检查 explain 输出；发布任务再加归档核对
```

小修 / 文档 / 内部重构可以直接走 A / F，不必先审计。

不要第一轮就：

```text
审计 + 修复 + 改文档 + 跑全仓
```

### AI 完成后先看

按本文 §3「AI 完成后你必须检查」逐条核对 —— 全文只有这一份清单，不在这里另抄一份。

---

## 0. 固定前缀（每次先贴）

```text
你是 w_tools 的维护者，先读 docs/ai-contract.md、AGENTS.md 和
packages/<pkg>/README.md（存在时），再开始；改具体包时读 docs/agents/<pkg>.md
（app_getx → app.md、map_google → map.md）；新增 / 修改公开类型时，
再读 CONTRIBUTING.md 与 docs/naming.md。

硬约束：
1. 先判断这是内部改动，还是公开 API / 行为变化。
2. 不要手改生成物：catalog.g.dart / templates.g.dart / components.md。
3. 不要为了让检查通过而降低测试、契约或文档标准。
4. 新增公开类型优先登记 catalog；不要直接塞进 uncataloged.yaml，除非说明它只是子 API。
5. 必须实际运行命令并贴结果；不能运行就明确说没运行，不要声称通过。
6. 命令在正确目录跑：`dart run tool/*`、`dart test test/*` 只在 `packages/cli` 下成立；
   `scripts/*.sh` 会自己 cd 到仓库根。贴命令时带上 cd，别让下一个人复现失败。
7. 不要改无关包、无关文档、无关测试。
8. 默认只改工作区：不要 commit / push / 开 PR / 合并，除非任务块明确要求（如 K-2 / K-2M）；
   不要用 `git reset --hard` / `git clean` 清理未提交内容。
9. 公开变化：抬子包版本 + 在当前版本 CHANGELOG 段写变更；聚合子包同时抬根 pubspec 的
   `^x.y.z` 下界。PR 正文保留「## 改动类型」段；勾了「公开变化」时，每个改了 lib 的包
   都要改自己的 CHANGELOG（CI 的 check_pr_scope 强制）。
10. 最后报告 changed files、实际命令结果、explain 输出、剩余风险。
```

然后从下面选一个任务块贴在后面。

## 填空说明

| 占位符 | 填什么 | 示例 |
|---|---|---|
| `<pkg>` | 包目录名（`packages/` 下） | `form`、`app_getx` |
| `<包>` | 包名或目录 | `w_tools_form` / `form` |
| `<组件>` | 公开类名 | `WFormTextField` |
| `<API>` | 方法 / 构造 / 成员 | `WForm.validate`、`WImage.network` |
| `<文件>` | 具体路径 | `packages/form/lib/src/...` |
| `<原因>` | 一句话目标 | 移除字段 `config` |
| `<用途>` | 包 / 组件要解决的问题 | 地图围栏模型 |
| `<替代>` | 替代入口 | `WImageSource.network` |
| `<新包>` | 新包名 | `w_tools_geo` |
| `<feature>` | init 能力名 | `map`、`form` |
| `<批次名>` | 审计后的批次名 | `form-p0-validator` |
| `<PKG>` | 审计 ID 前缀（大写） | `FORM` → `FORM-001` |
| `<新版本>` | 新版本号 | `7.1.0` |
| `<当前版本>` | 当前 pubspec 版本 | `7.0.0` |
| `<major>` | 主版本号 | `8` |
| `<标题>` | 反馈 / 条目标题 | `cache clean --all 无确认` |
| `<关键词>` | 搜索词 | `cache` |

`<runner>` 必须替换：查 [`scripts/packages.manifest`](../scripts/packages.manifest) 第 3 列
（`flutter` / `dart`）；纯 Dart 包用 `dart test` / `dart analyze`，其余用
`flutter test` / `flutter analyze`。
`<包目录>` 指 `packages/<pkg>`（根包用 `.`）；`<pkg1>` / `<pkg2>` 就是多个 `<pkg>`。
`<包>` 用于自然语言（可写 `w_tools_form` 或 `form`）；`<pkg>` 用于路径 / `--package`（只写 `form`）。

新手最容易漏的是 `<包>` 和 `<文件>`；能填具体路径就不要只写包名。
正文除上表与上面说明的 `<runner>` / `<包目录>` / `<pkg1>` / `<pkg2>` 外，不应出现其它占位符；
出现表外占位符说明模板没填完，按上下文换成对应的一行。

### 一个填好的例子：审计 form

```text
我是 w_tools 维护者。

任务：检查 packages/form 的功能是否合适、测试是否完整、
example 是否覆盖真实场景、用户和 AI 是否知道怎么用。

范围：
- 只审计 packages/form
- 不修改任何文件
- 输出 FORM-001 格式的问题清单

请先读：
- docs/ai-contract.md
- docs/agents/form.md
- docs/modules/form_module.md
- packages/form/README.md

然后运行：
- cd packages/form && flutter test
- cd packages/form/example && flutter test
- bash scripts/check_docs.sh
- python3 scripts/check_public_catalog.py

不要修改文件。
不要为了让测试通过而改测试。
输出每条问题的文件:行、证据、修复建议、验收命令。
```



---

## 1. 场景选择

先问这几个问题：

```text
我只是想检查，不想改？           → G / J-0
我想确认“教全了吗”？             → J-4
我要发布 / 批量发布？             → K / K-1M
我要改已有代码 / API？           → A / B
我要新增 / 删除 / 加包？         → C / D / E
我要改 CLI / doctor / init 模板？ → L
我要闭环一条用户反馈？            → M
我要改门禁 / CI，或 CI 红了？     → N
我要升级 Flutter / 依赖？         → N-1
```

| 你的改动 | 用哪个 |
|---|---|
| 私有方法、性能、内部重构 | A |
| 改现有公开组件 / API / 行为 | B |
| 新增公开组件 | C |
| 删除 / 废弃公开 API | D |
| 新增包 | E |
| 只整理 catalog / AGENTS / 文档 | F |
| 只让 AI 审查，不要改 | G |
| AI 不能访问仓库 / 不能跑命令 | H |
| 全仓审计 / 全量整理 | I（I-1 审计 → I-2 分批 → I-3 单批 → I-4 最终验证） |
| 单包全面审计（只读） | J-0 / J-1（按 J-1E 补领域维度） |
| 审计“所有使用方式是否教给 AI” | J-4 |
| 审计多个包 / 包家族 | J-5 |
| 把审计结果交给修复 | J-2 |
| 发布 Pub / 发布前检查 | K-1（审计） |
| 准备版本 / CHANGELOG | K-2（批量用 K-2M） |
| 发布 dry-run | K-3 |
| 实际发布（人工确认后） | K-4 |
| 发布后验证 | K-5 |
| 批量发布多个包 | K-1M / K-2M |
| 改 w_tools_cli / doctor / init 模板 | L |
| 处理 / 闭环反馈条目 | M |
| 改门禁脚本 / CI / 处理 CI 红灯 | N |
| 升级 Flutter / 依赖 | N-1 |

### 从报错反查场景

| 症状 | 场景 | 第一条命令 |
|---|---|---|
| `api-bump` 红：API 变了但版本没抬 | B / §0 硬约束 9 | `bash scripts/preflight.sh --with-tests` |
| `public api diff` 红：缺基线 / 删改未记录 | D（删改）/ E（新包） | `python3 scripts/check_public_api_diff.py --package <pkg>` |
| `check_removed_api` / `check_deprecations` 红 | D | `python3 scripts/check_deprecations.py` |
| docs 链接 / 锚点 / 符号红 | F | `bash scripts/check_docs.sh` |
| `check_prompt_docs` 红（flag / 占位符 / 场景编号 / 路径） | F / N | `python3 scripts/check_prompt_docs.py` |
| `check_pr_scope` 红（PR 正文 / 某包 CHANGELOG） | B / §0 硬约束 9 | `gh pr view --json body` |
| `publish --dry-run` 红 | E / K-3 | `bash scripts/publish_package.sh packages/<pkg> --dry-run` |
| `ci_matrix --check` / `Required checks` 红 | N | `python3 scripts/ci_matrix.py --check` |
| `release_status` 报「快照 ≠ 线上」 | K-4 / K-5 | `bash scripts/apply_snapshots.sh` |
| 新包 `public api diff` 红 | E | `python3 scripts/check_public_api_diff.py --snapshot-from packages/<pkg> --package <pkg> --version <当前版本>` |
| 本地 `preflight` 绿但 PR 红 | N | 看 CI-only：`check_version_bump` / `check_pr_scope` / dry-run |

---

## A. 内部重构 / Bug 修复

适用：

```text
私有实现、性能、日志、内部命名
公开 API 和默认行为不变
```

```text
任务：对 <包> 的 <文件> 做内部重构 / 修 bug。

要求：
1. 先说明为什么这是内部改动：哪些 public API 和默认行为没有变。
2. 只改必要代码 + 测试。
3. 如果发现确实有公开行为变化，停下来，改用场景 B。
4. 不要改 catalog / AGENTS / README / example。
5. 运行 `cd packages/<pkg> && <runner> test` 和 `bash scripts/preflight.sh --with-tests`。
6. 报告 changed files、为什么不需要文档更新、测试结果。
```

---

## B. 修改现有公开组件 / API / 行为

适用：

```text
改方法签名
改默认行为
改输入/输出
新增可选参数
新增公开方法
```

```text
任务：修改 <包> 的 <组件> / <API>，原因是 <原因>。

要求：
1. 先列清楚公开变化：API、默认行为、错误语义。
2. 判断 semver：已发布 API 的删除 / 签名变化 → major；新增能力 → minor；修 bug → patch。
   已发布基线看 python3 scripts/release_status.py --online（「待发布」正常；
   看总表的「结论」列，exit 0 不代表无异常），
   或 scripts/api_snapshots/ 的最新快照；没有网络时以快照为准并注明。
3. 抬 packages/<pkg>/pubspec.yaml 版本，并在 CHANGELOG 最上面写 `## <新版本>` 段
   （Fixed / Added / Changed / Breaking / Removed）；聚合子包同时抬根 pubspec 的 `^x.y.z` 下界。
4. 代码 + 测试；像素敏感的按 CONTRIBUTING §4 加 golden。
5. 更新 catalog/components.yaml：
   - usage
   - pitfalls
   - related
   - dontUseFor
   - aliases（保留旧名时）
   - teach（入口组件必须）
6. 更新对应 AGENTS 模板（templates/agents/{zh,en}/<feature>.md，不是 <pkg>.md），
   确保不再推荐旧写法。
7. 更新 README；必要时更新 example。
8. 如果是 breaking，写 migration，并检查 docs/migrations/README.md。
9. 先改源文件，再跑：
   cd packages/cli
   dart run tool/gen_catalog.dart
   dart run tool/gen_templates.dart
10. 运行 dart run w_tools_cli:w_tools explain <组件> --format=prompt，贴输出。
11. 运行 bash scripts/preflight.sh --with-tests，贴结果。
12. PR 正文保留「## 改动类型」段；勾「公开变化」时本包 CHANGELOG 必须被改。
```

---

## C. 新增公开组件

```text
任务：新增组件 <组件>，包是 <pkg>。

要求：
1. 先判断它是 teach 入口还是普通组件，并说明理由；读 CONTRIBUTING §1 / §2 / §4。
2. 实现 + 测试（行为测试放 packages/<pkg>/test/，依赖写进该包 dev_dependencies）；
   如果需要 async / 状态，先查 async 规则。
3. 抬 packages/<pkg>/pubspec.yaml 版本，在 CHANGELOG 最上面写 `## <新版本>`；
   聚合子包同时抬根 pubspec 的 `^x.y.z` 下界。
4. 在 catalog/components.yaml 增加：
   - name / package / section
   - useFor / dontUseFor
   - teach（入口组件）
   - usage / pitfalls / related（teach 时）
   - aliases（有方法名查询需求时）
5. related 优先指向已有 catalog 组件；子 API 才考虑 uncataloged 基线。
6. 如果影响包级规则，更新 templates/agents/{zh,en}/<feature>.md。
7. 更新 README；有真实场景就更新 example。
8. 跑生成器与契约测试，再跑全仓门禁：
   cd packages/cli
   dart run tool/gen_catalog.dart
   dart run tool/gen_templates.dart
   dart test test/internal/ai_contract_test.dart
   cd ../..
   bash scripts/preflight.sh --with-tests
9. 用 dart run w_tools_cli:w_tools explain <组件> --format=prompt 自测。
```

---

## D. 删除 / 废弃公开 API

```text
任务：删除或废弃 <包> 的 <API>，替代方案是 <替代>。

要求：
1. 先查已发布基线：删除 / 改名已发布 API 必须抬 major；只有上次发布后新增、
   从未发布的 API 才能在当前版本直接删（见 docs/releasing.md「发布窗口判断」）。
2. 代码层删除或加 @Deprecated，并在紧邻注释块写 `/// remove-in: <下一个 major>`。
3. 抬版本，并在当前版本 CHANGELOG 的 `### Breaking` / `### Removed` 写清 `Type.member`；
   必要时写 docs/migrations/<pkg>-<major>.0.md。
4. 把删除的公开名补进 scripts/check_removed_api.py 的名单。
5. catalog：删除条目，或调整 usage / pitfalls / dontUseFor / aliases；清理 related 里的旧引用。
6. AGENTS / README / example 不能继续推荐旧入口。
7. 在仓库根运行：
   python3 scripts/check_removed_api.py
   python3 scripts/check_deprecations.py
   python3 scripts/check_public_api_diff.py --package <pkg>
   python3 scripts/check_public_catalog.py
   bash scripts/preflight.sh --with-tests
8. 如果只是 deprecated，明确告诉 AI 现在应该用什么，并保留 remove-in 到期版本。
```

---

## E. 新增包

```text
任务：新增包 <新包>，用途是 <用途>。

要求：
1. 在 scripts/packages.manifest 加一行：name / path / runner / root_aggregate / example_test。
2. 加入根 pubspec.yaml 的 workspace（所有新包都必须，ci_matrix --check 会校验）；
   只有聚合包才加根 dependencies 的 `w_tools_<pkg>: ^x.y.z` 约束。
3. pubspec 写 `resolution: workspace`；补 CHANGELOG / README / LICENSE / .pubignore。
4. 首次发布前补 API 基线（否则 preflight 的 public api diff 会失败）：
   python3 scripts/check_public_api_diff.py \
     --snapshot-from packages/<pkg> --package <pkg> --version <当前版本>
   工具包（无 barrel）改为登记：check_public_api_diff.py 的 NO_PUBLIC_API、
   check_docs_facts.py 的 TOOLS、check_naming.py 的 TOOL_PACKAGES。
   **首发窗口**：这个基线只用于让 preflight 通过；合并后尽快发首版（publish 要求
   main 干净且 HEAD == origin/main）。首发前 release_status --online --check 会因
   pub.dev 404 判红（周检也会），属预期；同一版本里再改 API 会被 check_version_bump
   要求抬版本（bootstrap 基线被当成已发布基线）。
5. 有真实入口就加 example，并加 smoke test。
6. catalog 增加入口组件；入口组件 teach: true。
7. 如果是 init feature，加 templates/agents/{zh,en}/<feature>.md 和 features.dart 映射。
8. 更新 context.capabilities（packages/cli/lib/src/context/context_project.dart）、
   docs/modules/README.md、根 CHANGELOG。
9. 跑（生成器在 packages/cli 下）：
   cd packages/cli
   dart run tool/gen_templates.dart
   dart run tool/gen_catalog.dart
   cd ../..
   python3 scripts/ci_matrix.py --check
   python3 scripts/check_public_catalog.py
   bash scripts/preflight.sh --with-tests
10. 报告发布顺序和依赖关系。
```

---

## F. 只整理 catalog / AGENTS / 文档

```text
任务：只整理 <catalog / AGENTS / README / docs>，不改业务代码。

要求：
1. 先确认不涉及公开 API 或行为变化。
2. 只改源文件：
   - catalog/components.yaml
   - templates/agents/**
   - README / docs
3. 不要手改生成物。
4. 跑（生成器只认 packages/cli 目录）：
   cd packages/cli
   dart run tool/gen_catalog.dart
   dart run tool/gen_templates.dart
   dart test test/internal/ai_contract_test.dart
   cd ../..
   bash scripts/check_docs.sh
   python3 scripts/check_public_catalog.py
5. 报告改了哪些事实、哪些是生成结果。
```

---

## G. 只审查，不要修改

```text
任务：审查本次改动（git diff main...HEAD 或工作区改动），不要改任何文件。

请检查：
1. 是否有公开 API / 行为变化被漏掉？
2. catalog 的 usage / pitfalls / related / aliases 是否完整？
3. AGENTS 是否还推荐旧入口？
4. README / example 是否跟得上？
5. 是否有生成物被手改？
6. 是否有测试被削弱？
7. 运行 bash scripts/preflight.sh --with-tests 并贴结果。

输出：
- 阻断问题
- 建议修复
- 可以保留的风险
- 相关文件路径
```

---

## H. AI 不能访问仓库 / 不能跑命令

```text
你不能直接访问仓库或运行命令。

请基于我提供的文件片段工作，并明确标注：
1. 哪些结论来自我贴的内容；
2. 哪些需要我运行命令确认；
3. 不要声称 preflight 已通过。

我提供：
- 改动 diff
- 相关 catalog 条目
- 相关 README 段落
- 测试输出
```

---

## I. 全仓审计 / 全量整理

不要直接说：

```text
请分析全部代码，重新整理所有 catalog、AGENTS、README 和 example。
```

这会让 AI 一次改几十个包、几百个文件，风险很高。

正确方式是两阶段：

```text
阶段 1：只审计，不改文件
阶段 2：按包 / 按 feature 分批整理
阶段 3：全仓验证
```

### I-1. 审计提示词（只读）

```text
你是 w_tools 的维护者。现在只做全仓审计，不要修改任何文件。

先读：
- docs/ai-contract.md
- AGENTS.md
- packages/cli/catalog/components.yaml
- packages/cli/templates/agents/

请检查：
1. 公开类型是否都进入 catalog 或 uncataloged 基线；
2. teach 入口是否覆盖所有库包；
3. teach 组件的 usage / pitfalls / related 是否完整；
4. related 是否都能解析；
5. AGENTS 是否覆盖所有 InitFeature；
6. AGENTS 是否还在推荐旧命令 / 旧 API；
7. README 安装版本 / example 链接是否正确；
8. gen_catalog / gen_templates 是否 drift；
9. 关键 explain prompt 是否真的可执行。

只运行不会写文件的命令，例如：
- python3 scripts/check_public_catalog.py
- python3 scripts/check_package_docs.py
- bash scripts/check_docs.sh
- cd packages/cli && dart run tool/gen_catalog.dart --check
- cd packages/cli && dart run tool/gen_templates.dart --check

`gen_*` 只在 `packages/cli` 下找得到（在仓库根直接跑会报 `Could not find file`）；
`--check` 是只读模式，不加才会写文件。不要运行会改文件的生成器或 init。

输出：
- 按包列出：catalog 缺口 / teach 缺口 / AGENTS 缺口 / README 或 example 缺口 / 风险等级
- 需要新增或修改的文件
- 建议的批次划分（每批一个包或一个 feature）
- 每批的验收命令
- 明确说明“本次没有修改文件”
```

### I-2. 分批计划提示词

```text
基于上面的审计，给我一个分批整理计划。

要求：
- 每批只处理一个包或一个 feature；
- 每批列出要改的 catalog / AGENTS / README / example / 测试；
- 每批给出验收命令；
- 先做风险低、收益高的批次；
- 不要一次列出全仓改写；
- 不要开始改文件，等我确认批次。
```

### I-3. 单批执行提示词

```text
只执行批次：<批次名>。

范围：
- 包：<pkg>
- 组件：<组件>（没有就写「无」）
- 允许改的文件：<文件>

要求：
1. 不改变本批之外的公开 API / 行为；
2. 先改 catalog / templates 源文件，再跑生成器；
3. 不手改生成物；
4. 更新 README / example（仅本批相关）；
5. 跑本批验收 + bash scripts/preflight.sh --with-tests；
6. 如果发现需要跨批改动，停下来说明，不要顺手改；
7. 报告 changed files、命令结果、explain 输出。
```

### I-4. 全仓最终验证提示词

```text
只做验证，不要修改文件。

请运行：
- python3 scripts/check_public_catalog.py
- python3 scripts/check_package_docs.py
- bash scripts/check_docs.sh
- cd packages/cli && dart run tool/gen_catalog.dart --check
- cd packages/cli && dart run tool/gen_templates.dart --check
- bash scripts/preflight.sh --with-tests

然后检查：
1. catalog 是否覆盖所有公开类型或基线；
2. 每个库包是否有 teach 入口；
3. 每个 InitFeature 是否有 zh/en AGENTS；
4. README 版本 / example 链接；
5. explain prompt 是否包含用法 / 注意 / 相关；
6. 是否还有旧命令 / 旧 API。

输出：
- 通过项
- 失败项
- 仍需人工判断的项
- 不要声称通过；以实际命令输出为准
```

### I-5. 全仓整理时的边界

```text
代码重构 ≠ 文档整理
```

不要在同一条提示词里同时要求：

```text
重构全部代码
+ 重写全部 catalog
+ 重写全部 AGENTS
+ 重写全部 README
+ 重写全部 example
```

推荐顺序：

```text
1. 只审计
2. 只整理文档 / catalog（不改代码行为）
3. 按包做小重构
4. 每批更新教学资产
5. 全仓验证
```

---

## J. 单包全面审计（只读）

适用：

```text
想确认某个包的功能是否合适
测试用例是否完整
example 是否覆盖真实场景
用户文档和 AI 教学是否准确
但暂时不想改任何文件
```

输出必须能直接交给另一个 AI 修复。

### J-0. 快速审计（默认）

日常先用这个，不要一上来复制完整 J-1。

```text
只读审计 <pkg>，不修改任何文件。

检查：
1. 功能是否正确、API 是否一致；
2. 测试是否覆盖主要行为；
3. example 是否覆盖真实场景（有 example 才跑）；
4. README / modules / agents / catalog 是否一致；
5. explain --format=prompt 是否能让 AI 写对代码。

运行（runner 以 scripts/packages.manifest 为准：flutter / dart）：
- cd packages/<pkg> && <runner> test
- cd packages/<pkg> && <runner> analyze
- example 存在时：cd packages/<pkg>/example && <runner> test
- bash scripts/check_docs.sh
- python3 scripts/check_public_catalog.py
  （cli / device / e2e / figma 在 SKIP 中：注明“不适用”，改查模板 / agents）

输出：
| ID | 级别 | 文件:行 | 证据 | 问题 | 建议修复 | 验收命令 |

不要修改文件；不要为了让测试通过而改测试。
如果问题是“所有使用方式是否教给 AI”，直接用 J-4，不要硬套 J-0。
```

如果发现需要深入审计，再使用下面的 J-1；日常先用 J-0。

### J-1. 完整审计提示词（通用）

```text
任务：对 packages/<pkg> 做只读全面审计。

不要修改任何代码、测试、文档或生成物。
目标是输出一份“可交给另一个 AI 直接修复”的问题清单。

先读：
- AGENTS.md
- docs/ai-contract.md
- packages/<pkg>/README.md
- packages/<pkg>/pubspec.yaml
- packages/<pkg>/lib/
- packages/<pkg>/test/
- packages/<pkg>/example/（存在时）
- 对应的 modules 文档（ui/form/async/app 等；app 与 app_getx 共用 app_module.md；
  device 是工具包，没有 modules 文档，只看 device-testing.md）
- 对应的 agents 文档（ui.md / form.md / async.md / app.md / device-testing.md 等）
- packages/cli/catalog/components.yaml 中 package: w_tools_<pkg> 的条目
- packages/cli/catalog/uncataloged.yaml 中该包的基线
- packages/cli/templates/agents/{zh,en}/ 下对应模板（app 与 app_getx 共用 app.md）

必须运行并贴实际输出（runner 以 manifest 为准）：
- cd packages/<pkg> && <runner> test
- cd packages/<pkg> && <runner> analyze
- example 存在时：cd packages/<pkg>/example && <runner> test
- bash scripts/check_docs.sh
- python3 scripts/check_public_catalog.py
- dart run w_tools_cli:w_tools list --package=<pkg> --format=prompt
- 对该包入口组件逐个运行 dart run w_tools_cli:w_tools explain <组件> --format=prompt

审计维度：

A. 功能与正确性
- 公开 API 的行为是否和注释 / README 一致？
- 是否覆盖该包的真实使用场景（按 J-1E 的领域清单补充）？
- 是否存在已删除 API 仍被文档 / example / test 使用？
- 是否有异常被吞掉、状态不同步、dispose 后仍更新等问题？

B. API 设计与一致性
- 命名、参数、默认值是否一致？
- 是否暴露了不该暴露的内部 Config / Core？
- 是否有缺失的高频参数，或低频参数污染入口？
- 是否存在只能通过内部实现才能完成的常见需求？

C. 测试完整性
- 不要只看覆盖率数字。
- 建立“行为 → 测试”矩阵；明确已有 / 缺失 / 仅 example 覆盖 / 完全没覆盖。
- 区分可在 CI 跑的单元测试与必须真机验证的行为。

D. 示例完整性
- example 是否能独立运行？
- 是否覆盖真实场景？
- 是否仍使用旧 API？
- 是否有“文档写了但 example 没有”的场景？

E. 用户文档准确性
- README 的安装、最小用法、API 说明是否和代码一致？
- docs/modules/<pkg>_module.md 是否有旧 API、内部 Config、错误示例？
- 版本 / 导入路径 / 示例链接是否正确？

F. AI 可用性
- catalog 是否覆盖入口组件？
- teach 是否有 usage / pitfalls / related？
- explain --format=prompt 是否能直接写出正确代码？
- AGENTS / 对应的 docs/agents 文档是否还有旧写法？
- 对同一问题，AGENTS、agents 文档、modules 文档、catalog 是否互相矛盾？

G. 维护与发布
- 是否有生成物漂移？
- 是否有未登记的公开类型？
- 是否有过期废弃项？
- 是否有文档声明了不存在的参数 / 类型 / 成员？

输出格式：

1. 审计概览
   - 实际运行的命令和结果
   - 测试数量 / 覆盖率
   - catalog 条目数 / 基线数
   - 公开字段 / 组件清单

2. 问题清单
   | ID | 级别 | 类型 | 文件:行 | 证据 | 问题 | 建议修复 | 验收命令 |
   - ID: <PKG>-001
   - 级别: P0 / P1 / P2 / P3
   - 类型: bug / API 设计 / 测试缺口 / 示例缺口 / 文档漂移 / AI 可用性
   - 每条必须有文件位置或命令输出
   - 不要写“建议完善测试”，要写“缺少 X 场景，建议加 Y 测试”

3. 覆盖矩阵
   | 能力 | 代码 | 测试 | example | 用户文档 | AI 文档 |

4. 建议修复批次
   - 每批只处理一个主题
   - 标出依赖顺序
   - 每批给出验收命令

5. 不确定项
   - 标 NEEDS-VERIFY
   - 不要猜 API 行为

硬规则：
- 不要修改任何文件。
- 不要为了让测试通过而改测试。
- 以代码和实际命令输出为准，不以文档为准。
- 不要把“风格偏好”写成 P0；设计建议标 P2。
- 发现文档和代码冲突时，代码是事实源，但要把文档冲突单独列为问题。
```

### J-1E. 领域补充清单（按包补充 J-1 的 A~G）

下表覆盖所有包，每行只列最常见的额外检查，不替代 J-1 的 A~G 通用维度。

| 包 | 额外检查 |
|---|---|
| ui | WImage 尺寸/来源、WText variant、WScaffold/WAppBar、WButton/WPressable、WListView、WScreen |
| form | WForm/WFormController 生命周期、validator、readOnly、border、字段矩阵、WFormPopup |
| async | 四态、分页 loadMore/loadMoreError、刷新、取消、WAsyncTheme、sliver |
| app / app_getx | 启动顺序、插件 dependsOn、wrapApp/builderWrapper、路由、语言、底部弹窗 |
| core | WStorage.init 前置、明文存储边界、WEncrypt AES-CBC 无完整性、WValidator/WRegExp、WLogger |
| api | WApiConfig + DioRegistry.forBaseUrl 单例与 dispose、WToken 注入、WLogInterceptor 职责边界 |
| toast | BotToastInit / BotToastNavigatorObserver 挂载、WToast.showXxx、样式覆盖 |
| qr | WQrView scanOnce 默认 true、restartScan、相机权限、onScanned 仅在 code 非空时触发 |
| map / map_google | 模型与实现分层、markerId 稳定性、WMapItemMapper、WMapController、Google key 与 init --map 默认关 |
| device | 平台矩阵、坐标/标定、退出码、CLI flag、真机不可测边界 |
| cli / figma / e2e | 工具包：教学走 docs/agents 与模板，不走 catalog explain（check_public_catalog 对它们 SKIP） |

### J-2. 把审计结果交给修复 AI

```text
只处理以下审计发现，不要扩展范围：

<粘贴 <PKG>-001 ~ <PKG>-00N>

要求：
1. 每条先复现，再修。
2. 先加失败测试，再改代码。
3. 不改变未列入问题的公开行为。
4. 不手改生成物。
5. 每条完成后跑对应验收命令。
6. 最后跑 bash scripts/preflight.sh --with-tests。
7. 报告：问题 ID、改动文件、测试结果、未解决项。
```

### J-3. 单包审计的边界

```text
只审计 packages/<pkg>，不顺手改其他包。
只输出问题，不在同一轮修复。
代码是事实源，文档冲突单独列问题，不要反向改代码迁就文档。
覆盖率是参考，不是“测试完整”的证明。
```

### J-4. AI 教学覆盖审计（只读）

适用：回答“<pkg> 的所有使用方式，都教给 AI 了吗”。

```text
任务：只读审计 <pkg> 的 AI 教学覆盖。

范围：
- <pkg> 的全部 catalog 条目与公开导出类型
- catalog / uncataloged / AGENTS zh|en / README / example / explain

运行：
- dart run w_tools_cli:w_tools list --package=<pkg> --format=prompt
- 对全部 teach 入口运行 dart run w_tools_cli:w_tools explain <组件> --format=prompt
- 对非 teach 抽样运行 explain <组件> --format=prompt
- 对 uncataloged 基线抽查 explain <组件> --format=prompt
- 运行该包测试 / bash scripts/check_docs.sh / python3 scripts/check_public_catalog.py（SKIP 包注明不适用）

检查：
1. teach 的 usage 是否覆盖主要变体（不是单行）；
2. 非 teach 是否只有 useFor；
3. 基线类型是否可 explain；
4. AGENTS/README/example 是否覆盖真实用法；
5. catalog / AGENTS / README 是否互相矛盾；
6. CLI 工具包（SKIP）是否走了 docs/templates 教学。

输出：
- 问题表（<PKG>-001）
- 覆盖矩阵：公开类型 | catalog | teach | AGENTS zh | AGENTS en | explain | README | example
- 已教 / 只教一半 / 完全没教

不要修改文件；不要为了让检查通过而改测试。
```

### J-5. 多包 / 包家族审计（只读）

适用：app + app_getx、map + map_google，或“所有分包”的一次性教学审计。

```text
任务：只读审计以下包（列出）：<pkg1>, <pkg2>, ...
每个包按 J-4 输出一张矩阵；最后给跨包一致性结论。
不要合并成一个“平均覆盖”结论；按包分节。
范围、命令、边界同 J-4；runner 以 manifest 为准。
```

> **J-4A** 是 J-4 的自动子集，不是新场景：`python3 scripts/check_teaching_coverage.py`
> 检查 `packages/cli/catalog/entrypoints.yaml` 里的入口名是否出现在 docs/agents、模板 zh+en、
> README（有 example 时再加 example/lib）这些载体里（子串匹配；app_getx / map_google 共用
> app / map 规则页）。它由 `check_docs.sh` / `preflight` 自动跑，通过不代表“讲清楚了”；
> J-4 的人工矩阵仍然要做。

J 的边界：

```text
J-0 快速看功能/测试/文档
J-4 只回答“教全了吗”
J-1 设计/API/测试/文档/教学的全维度审计
J-5 多包/家族
不要用 J-0 回答“所有使用方式都教了吗”。
```

## K. 发布 Pub

发布是高风险操作，必须拆成：

```text
审计 → 准备版本 → dry-run → 人工确认 → 发布 → 发布后验证
```

> 本节是给 AI 的任务卡与边界；**操作细节（脚本参数、顺序、常见坑）以
> [`docs/releasing.md`](releasing.md) 为准**，两边冲突时以那份文档为准。

不要用一条“帮我发布”的提示词完成全部步骤。

### K-1. 发布前审计（只读，单包）

`--package` 只认 `scripts/packages.manifest` 里的裸名（`map` / `form` / `cli`…），
**不接受根包**；审根包时去掉 `--package`，做全量比对。

```text
任务：审计 <pkg> 是否可以发布到 pub.dev。
不要修改文件，不要执行真实发布，不要跑 dry-run（dry-run 是 K-3）。

先读：
- docs/releasing.md
- packages/<pkg>/CHANGELOG.md
- packages/<pkg>/pubspec.yaml
- packages/<pkg>/README.md
- scripts/release_check.sh
- scripts/publish_package.sh

运行：
- git status --porcelain（必须干净；不干净先停）
- git fetch origin main（确认本地 main 没有落后；发布脚本也会自己 fetch）
- bash scripts/release_check.sh --package <pkg>
- python3 scripts/release_status.py --online
  （「待发布」是正常状态；线上比较以它为准。release_check --online 断网时返回 2。
   发布波次中——上一包已发布、快照还没 apply——只忽略刚发布包的「快照 ≠ 线上」；
   其它「落后 / 缺快照」要停；404 只有「从未发布、本次首发的新包」不算异常，
   其它 404 要停。--check 留给快照 PR 合入后 / 周检。
   不加 --check 时它总是 exit 0，异常只打印在「异常：」段——必须读输出，不要只看退出码。
- bash scripts/preflight.sh --with-tests
- 从 pub.dev API 取 latest.archive_url，下载归档到 /tmp，解压后与本地比较：
  pubspec.yaml / lib/** / README.md / CHANGELOG.md / LICENSE / example/**
  （排除 test / docs / scripts 等仓库专用内容）

审根包时换成：
- bash scripts/release_check.sh
- python3 scripts/release_status.py --online
（根包版本 ↔ CHANGELOG ↔ 子包 caret 约束都在这一轮看，K-1M 会把它们并进总表；
  同样看「异常：」段、不要只看退出码；波次中不要加 --check）

检查：
1. 版本号与 CHANGELOG 是否一致；
2. release_status 只证明“版本号存在”，不能证明内容已发布；
3. 同版本归档与本地是否有差异（有差异 = 同版本漂移，必须 K-2 升版本）；
4. README 安装版本 / 示例是否过期；
5. 根包约束是否覆盖新版本（仅聚合包）；
6. 依赖包是否已先发布；
7. 是否需要 migration；
8. 工作区是否干净、是否已 push（`--strict` 同时要求干净、已 push、且与 upstream 同步，见 `check_git_sync.sh`）。

输出：
- 通过项
- 阻断项（必须修 / 建议修）
- 建议版本号与依据
- 建议发布顺序
- 不要执行真实发布
- 不要修改文件
```

### K-1M. 多包 / 全量发布审计（只读）

```text
任务：审计所有待发布包（或指定列表），回答哪些包有未发布内容、能否发布、按什么顺序发。

范围：scripts/packages.manifest 中的包 + 根包。
（根包不在 manifest 里：子包用 `--package <pkg>`，根包用不带 `--package` 的全量比对。）
对每个包执行 K-1 的检查；
额外输出：
1. 发布状态总表：包 | 本地版本 | pub 版本 | CHANGELOG | README | 归档 diff | 工作区受影响 | 结论 | 建议版本
2. 未发布内容清单（按包）
3. 同版本漂移清单（这些包不能按当前版本发布）
4. 发布顺序（无依赖 → 有依赖 → 根包；工具包独立）
5. 明确哪些包进 K-2，哪些跳过
不要修改文件、不要 dry-run、不要发布。
```

### K-2. 版本 / CHANGELOG 准备（单包）

```text
任务：为 <pkg> 准备发布。

先看功能 PR 是否已经抬过版本：抬过就沿用现有版本（`release_check` 会校验 CHANGELOG 段）。
还没抬时才输出“版本提案表”（旧版本 → 新版本、major/minor/patch、依据），
等维护者确认后再改文件。

允许改：
- packages/<pkg>/pubspec.yaml
- packages/<pkg>/CHANGELOG.md
- packages/<pkg>/README.md（只改安装示例的 caret 下界；不要写「当前 x.y.z」）
- 根包约束（聚合子包的功能 PR 里应已抬下界；这里只确认，不重复改）
- 必要的 migration
- 版本常量（cli/figma 的 lib/src/common/version.dart 等，仅用于版本一致性测试）

不允许：
- 执行 pub publish
- 手改生成物
- 改无关包

要求：
1. 版本号必须与 CHANGELOG 的 ## 段一致；
2. 更新 README 安装示例的 caret 下界（必须等于新版本），不要写死「当前 x.y.z」——
   release_check 会判失败；安装命令用 pub add，不写死版本；
3. 跑 bash scripts/release_check.sh --package <pkg>（发布根包前用 --strict）
   与 bash scripts/preflight.sh --with-tests；
4. 完成后提交到 feature 分支并 push，开 PR（正文保留「## 改动类型」段）；
   等 Required checks 通过后**合并到 main**（K-3 / K-4 的发布保护要求 `main` 且 `HEAD == origin/main`）；
5. 报告 changed files 和检查结果。
```

### K-2M. 批量版本准备

```text
任务：为以下包批量准备发布：<pkg1>, <pkg2>, ...

第一步只输出版本提案表（包 | 旧版本 | 新版本 | 级别 | 依据），等维护者确认。
确认后按 K-2 逐包改 pubspec / CHANGELOG / README；
版本常量按需同步；不要改无关包。
最后统一跑：
bash scripts/release_check.sh
bash scripts/preflight.sh --with-tests
提交并 push，开 PR（正文保留「## 改动类型」段）并合并到 main。
```

### K-3. Dry-run（单包）

```text
任务：对 <pkg> 执行发布 dry-run。

运行：
- bash scripts/release_check.sh --strict --package <pkg>
- bash scripts/publish_package.sh packages/<pkg> --dry-run

不要执行真实 publish。

输出：
- dry-run 结果
- 包大小 / 文件清单（如果有）
- 依赖解析是否正常
- 是否还有阻断项
```

批量时逐包执行 K-3；不要并行 publish。

### K-4. 实际发布（人工确认）

```text
任务：发布 <pkg>。

前置条件：
1. 人已确认版本号和发布范围；
2. K-1 ~ K-3 已通过；
3. 工作区干净；
4. 已确认发布顺序。

执行：
bash scripts/publish_package.sh packages/<pkg>

禁止：
- 直接在包目录 flutter pub publish
- 直接在包目录 dart pub publish
- 未确认版本号就发布
- 在 dry-run 未通过时发布
```

批量发布：

```text
一次只执行一个 publish 命令。
同一批可以连续发：每包发完至少确认版本可见（python3 scripts/release_status.py --online，
不要加 --check；看输出里的版本与「异常：」段——exit 0 不代表无异常）；
归档 diff 可以在批末统一做，避免每个包都下载一次归档。
K-5 的归档核对不依赖快照。

快照会先写到 .w_tools/release-snapshots/（gitignored），不会挡住下一个包；
全部发完后运行 bash scripts/apply_snapshots.sh，按它打印的命令开一个快照 PR 并合入。
发根包前必须合入（否则 publish_package.sh . 与 release_check --strict 都会拦住）。
不要用 --force 绕过这一步：它会同时跳过干净树 / main / HEAD==origin/main / release_check。
```

发布顺序：

```text
1. 先发被依赖的核心包
2. 再发依赖它们的包
3. app_getx / map_google 在 app / map 之后
4. 全部子包上线后，再发根包
5. w_tools_cli / figma / device / e2e 独立
```

发根包：

```bash
bash scripts/publish_package.sh .
```

### K-5. 发布后验证

```text
任务：验证 <pkg> 发布结果。

运行：
- python3 scripts/release_status.py --online（总表；快照还没 apply 时不要加 --check；
  看「异常：」段——exit 0 不代表无异常）
- bash scripts/release_check.sh --package <pkg> --online
- 下载 pub.dev 最新归档，确认 README / CHANGELOG / lib 与仓库一致

快照：publish 成功后先写到 .w_tools/release-snapshots/；一批发完
bash scripts/apply_snapshots.sh 并合入快照 PR。根包发布前必须合入。

检查：
1. pub.dev 版本可见；
2. 归档内容与仓库一致（不是只看版本）；
3. 依赖包版本可解析；
4. 根包约束（如适用）可解析；
5. 发布记录 / release 文档是否需要更新。

不要修改代码；只报告验证结果。
```

### K 的硬边界

```text
不要执行 flutter pub publish
不要执行 dart pub publish
不要在包目录直接发布
不要在未跑 dry-run 时发布
不要自动决定 major / minor / patch
不要把 pub 凭证写进提示词
同版本内容漂移必须升版本，不能重发
```

必须使用：

```bash
bash scripts/publish_package.sh <包目录>
```

原因见 [`docs/releasing.md`](releasing.md)：仓库的 `workspace:` / `resolution: workspace`
不能直接发布。

## L. 改 w_tools_cli / doctor / init 模板

适用：

```text
改 CLI 子命令 / flag
改 doctor 规则（R1~R9）或默认配置
改 init 生成的模板 / AGENTS 片段
```

这不是“在消费方项目里用 CLI”——那部分看 [`docs/agents/cli.md`](agents/cli.md)。

```text
任务：修改 w_tools_cli 的 <文件>，原因是 <原因>。

先读：
- docs/agents/cli.md（维护者一节）
- docs/conventions.md §7（doctor 的 R1~R9 规则表）
- packages/cli/README.md

要求：
1. 规则只实现一次：检查逻辑写在 lib/，文档只描述；不要两边各写一份。
2. 改 DoctorConfig 默认值 → 同步 renderDefaultConfig()（doctor --print-config），
   packages/cli/test/internal/config_render_test.dart 会挡住漂移。
3. 改 templates/agents/** → cd packages/cli && dart run tool/gen_templates.dart。
4. 改 catalog/components.yaml → cd packages/cli && dart run tool/gen_catalog.dart。
5. 同步：packages/cli/test/internal/init_test.dart 或 doctor_test.dart、
   docs/conventions.md §7、docs/agents/cli.md、packages/cli/CHANGELOG.md。
6. 在 packages/cli 跑 dart test；再回仓库根跑 bash scripts/preflight.sh --with-tests。
7. 报告 changed files、命令结果、消费方会感知到的行为变化。
```

完成判据：`dart test` 全绿；`doctor --print-config` 与默认值一致；
模板 / catalog 重新生成后的 diff **只反映你改的源文件**，没有额外漂移。

## M. 处理 / 闭环反馈条目

适用：

```text
docs/feedback/<pkg>.md 里有 [待处理] / [已确认] 条目要修、要定状态
```

```text
任务：处理 <包> 的反馈条目「<标题>」。

先读：
- docs/feedback/README.md（状态机与索引规则）
- docs/feedback/<pkg>.md 中的该条目

要求：
1. 先查重与现状：
   dart run w_tools_cli:w_tools feedback search "<关键词>" --package=<pkg>
2. 先复现，再修；修代码走 A / B，不要顺手改公开 API。
3. 状态只由维护者确认：待处理 → 已确认（链 issue）→ 已修复（版本 + commit）/ 不修（写理由）。
   AI 不要把条目标成「已修复」；发布后由维护者补版本号。
4. 新条目用 feedback submit ... --ledger（自动建档 / 更新索引）；状态变更手工改
   docs/feedback/<pkg>.md，并同步 README 索引表的待处理数量（CI 会核对）。
5. 已闭环压成「## 已闭环」一行，细节写 CHANGELOG。
6. 提交前跑 bash scripts/check_feedback.sh。
7. 报告：条目、改动文件、版本、验证命令。
```

完成判据：条目状态合法、`check_feedback.sh` 通过、CHANGELOG 里有一句对应说明。

## N. 门禁 / CI 红灯

适用：

```text
PR 的 Required checks 红了
本地 preflight / check_docs 失败
要改 scripts/ 或 .github/workflows/
```

```text
任务：处理门禁失败（范围：<包> / <文件> / 无），或修改门禁脚本。

先读：
- scripts/README.md（每个脚本做什么 / 谁调用）
- .github/workflows/ci.yml（job 与 required 接线）
- 失败 job 的完整日志（不是只看 GitHub 摘要）

要求：
1. 先复现：在本地跑失败 job 里的同一条命令，贴完整输出。
2. 定位到唯一入口：静态门禁是 scripts/preflight.sh，文档是 scripts/check_docs.sh，
   发布是 scripts/release_check.sh；不要另写一套检查，也不要让 CI 手抄步骤。
3. 修根因。禁止为了让检查变绿而：删检查、加 `if: false` / `continue-on-error`、
   放宽 ci_matrix 的 REQUIRED_FILTERS、用 `--force`、改旧版本 CHANGELOG 段。
4. 改门禁脚本时同步 scripts/tests（脚本单测）与 scripts/README.md 登记；
   改 ci.yml 时跑 python3 scripts/ci_matrix.py --check；改脚本时再跑
   python3 scripts/check_gate_coverage.py。
5. 跑并贴结果：
   bash scripts/check_docs.sh
   bash scripts/preflight.sh --with-tests
6. 报告：失败原因、改了哪些文件、为什么不是绕过、剩余风险。
```

完成判据：对应命令本地通过；`ci_matrix --check` 与 `check_gate_coverage` 通过；
没有新增 `if: false` / `continue-on-error` / `--force`。

### N-1. 升级 Flutter / 依赖

```text
任务：升级 Flutter 到目标版本，或升级依赖 <包>。

要求：
1. 同步版本 pin：.fvmrc、.github/workflows/ci.yml 的 FLUTTER_VERSION 与
   MIN_FLUTTER_VERSION、根 / 各子包 pubspec 的 environment.flutter 下限。
2. 只抬声明下限时，MIN_FLUTTER_VERSION 必须 >= 声明的下限；理想是 == 声明下限
   （取可用的最高 patch），高于声明只算保守，不会真正测到声明的最低版本。
   ci_matrix --check 目前只校验 .fvmrc ↔ FLUTTER_VERSION，MIN 要人看。
3. 跑 flutter pub get → flutter analyze → bash scripts/preflight.sh --with-tests；
   有条件再跑 CI 的 min_sdk job。
4. 报告：版本矩阵（声明 / CI 实跑 / .fvmrc）、改了哪些包、剩余风险。
```

完成判据：`.fvmrc`、`ci.yml`、pubspec 三处版本一致；全仓测试通过。

## 2. 提示词使用示例

### 改 WAsync 的超时行为

固定前缀 + 场景 B，把：

```text
<包> → w_tools_async
<API> → WAsync.timeout
<原因> → 超时错误需要显式区分
```

### 新增 WAsync 的 retry 辅助

固定前缀 + 场景 C，把：

```text
<组件> → WAsyncRetry
<pkg> → async
```

### 删除 WImage 旧构造器

固定前缀 + 场景 D，把：

```text
<包> → w_tools_ui
<API> → WImage.network
<替代> → WImageSource.network
```

### 审计 ui 的所有使用方式是否教给 AI

固定前缀 + 场景 J-4：

```text
任务：只读审计 w_tools_ui 的 AI 教学覆盖。
按 J-4 输出覆盖矩阵（公开类型 | catalog | teach | AGENTS zh | AGENTS en | explain | README | example）。
```

### 审计所有未发布包

固定前缀 + 场景 K-1M（实际发布走 K-2M → K-3 → K-4）：

```text
任务：审计所有包的发布状态，输出状态总表、同版本漂移清单、建议版本与发布顺序。
不要修改文件、不要 dry-run、不要发布。
```

### 单包发布

K-1 → K-2（确认版本）→ 提交并 push → K-3 → K-4 → K-5，逐包执行。
子包发完：bash scripts/apply_snapshots.sh → 快照 PR；根包发布前必须合入。

## 3. AI 完成后你必须检查

```text
[ ] 报告里的每条命令都真的跑过；没跑就写明没跑
[ ] git diff 没有大范围无关改动
[ ] catalog 改的是 components.yaml，不是 catalog.g.dart
[ ] AGENTS 改的是 templates，不是 templates.g.dart
[ ] 新公开类型已进 catalog 或 uncataloged 基线（并说明理由）
[ ] teach 组件有 usage / pitfalls / related
[ ] teach / 非 teach / 基线类型三类都查过 explain
[ ] explain <组件> --format=prompt 输出正确
[ ] README / example 已更新
[ ] docs/README.md 已索引新增文档；docs/agents 的首选入口能在该包规则页找到
[ ] 公开变化 PR：正文有「## 改动类型」段；每个改了 lib 的包都改了 CHANGELOG
[ ] 发布时：git status 干净、归档 diff 看过、lib/src/common/version.dart 与 pubspec 一致
[ ] 发布时：快照 PR 已合入（根包前）、没有用 --force、
    python3 scripts/release_status.py --online --check 通过
[ ] bash scripts/preflight.sh --with-tests 实际通过
[ ] 没有削弱测试
```

重点看 `explain` 输出与发布归档，而不是只看“preflight 通过”。

## 4. 为什么不是一条万能提示词

一条提示词同时要求：

```text
改代码 + 改 catalog + 改 AGENTS + 改 README
+ 改 example + 跑全仓门禁 + 审查
```

容易导致：

- AI 为了完成清单而改无关文件；
- 文档先于代码定稿，产生假事实；
- 测试被顺手改弱；
- 大 diff 难以 review。

所以推荐：

```text
固定前缀
+ 一个场景块
+ 一次只做一类任务
```

复杂改动的轮次顺序见本文开头的「默认工作流」，不要另记一套。

---

## 5. 这是最合适的方式吗？

对**人机协作**来说，这是当前最合适的方式：

```text
文档化提示词
+ 固定硬约束
+ 场景化任务块
+ 机器门禁
```

但它不是“万能保证”。

真正兜底的是：

```text
catalog 契约测试
explain prompt 契约测试
AGENTS 模板检查
公开类型反向检查
preflight
```

提示词负责让 AI 做对方向，测试负责防止它悄悄做错。

---

## 6. 维护这份文档

当以下内容变化时，更新本文件：

- CLI 命令 / flag；
- catalog 字段；
- AGENTS 模板规则；
- 完整性检查命令；
- 发布 / migration 流程；
- 新增场景（J-4 / J-5 / L / M / K-1M / K-2M）或 CLI 命令（list --package、explain 锚点）。

改完在仓库根跑：

```bash
bash scripts/check_docs.sh
```

它除了链接和旧命令，还会用 `check_prompt_docs.py` 核对本文引用脚本、flag、`cd packages/cli`、
占位符、CLI 子命令 flag（含 `\` 续行）、手册内 docs 路径、生成器 / 测试文件是否存在，
以及场景编号（§1 ↔ 标题双向、重复标题）。

**新增 / 删除场景时**（第 1–2 步由 `check_docs` 强制；第 3–4 步靠自觉）：

```text
1. 加 / 删 `## X.` 标题（子场景用 `### X-1.`）
2. 在 §1「场景选择」的问题列表和表里加 / 删一行
3. 在顶部「快速跳转」加 / 删链接
4. 把 `A~N（含 N-1）` 的终点改成新的范围
5. 跑 bash scripts/check_docs.sh，再手动看一遍 §3 清单
```

机器只校验命令可执行与编号存在；先后顺序、状态机、semver 判断仍要 review。

保持它和 [`docs/ai-contract.md`](ai-contract.md) 一致。

---

## 7. 一句话

**固定前缀 + 场景块 + 证据要求 + preflight。**

这就是给维护者使用 AI 的最合适方式。
