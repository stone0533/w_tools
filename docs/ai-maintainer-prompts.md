# 维护者 AI 提示词手册

给 **w_tools 包维护者**：贴「固定前缀 + 一个场景块」给 AI，一次只做一类任务。

- 任务路由、跨包硬规则：[`AGENTS.md`](../AGENTS.md)
- 发布流程、版本规则、失败分支：[`docs/releasing.md`](releasing.md)
- 脚本 / 命令 / 参数：[`scripts/README.md`](../scripts/README.md)
- AI 资产契约：[`docs/ai-contract.md`](ai-contract.md)

> 本手册只放**可复制的提示词块**和场景索引；流程细节、脚本参数、版本规则一律以事实源为准。
> 命令由 `scripts/check_prompt_docs.py` 校验；改完跑 `bash scripts/check_docs.sh`。

## 怎么用

1. 先贴 §0 固定前缀；
2. 再贴 §1 里选中的一个场景块；
3. AI 完成后按 §3 逐条核对。

不确定选哪个：先走 G 或 J-0，不要第一轮就「审计 + 修复 + 改文档 + 跑全仓」。

## 0. 固定前缀（每次先贴）

```text
你是 w_tools 的维护者。先读 AGENTS.md、docs/ai-contract.md 和 packages/<pkg>/README.md，
再按 docs/agents/README.md 的索引读该包规则页；改公开类型时再读 CONTRIBUTING.md 与 docs/naming.md。

硬约束：
1. 先判断这是内部改动，还是公开 API / 行为变化。
2. 不要手改生成物：catalog.g.dart / templates.g.dart / components.md。
3. 不要为了让检查通过而降低测试、契约或文档标准。
4. 新增公开类型优先登记 catalog；不要直接塞进 uncataloged.yaml，除非说明它只是子 API。
5. 必须实际运行命令并贴结果；不能运行就明确说没运行，不要声称通过。
6. 命令在正确目录跑：`dart run tool/*` / `dart test test/*` 只在 packages/cli 下成立；
   scripts/*.sh 会自己 cd 到仓库根。贴命令时带上 cd。
7. 不要改无关包、无关文档、无关测试。默认只改工作区：不要 commit / push / 开 PR / 合并，
   除非任务块明确要求（K-0 / K-2 / K-2M）；不要用 `git reset --hard` / `git clean`。
8. 公开变化按 AGENTS.md「改动前先分类」第 2 条执行：抬子包版本 + 当前版本 CHANGELOG
   （根包 / CLI 无 API diff 的约束变化写非空 `## Unreleased`）；本次改到的库子包同步
   versions.dart（工具包除外），聚合子包再抬根 pubspec 的 `^x.y.z` 下界；
   PR 正文保留「## 改动类型」段并至少勾选一项。
9. 最后报告 changed files、实际命令结果、explain 输出、剩余风险。
```

## 填空说明

| 占位符 | 填什么 | 示例 |
|---|---|---|
| `<pkg>` | 包目录名（`packages/` 下） | `form` |
| `<包>` | 包名或目录 | `w_tools_form` / `form` |
| `<组件>` | 公开类名 | `WFormTextField` |
| `<API>` | 方法 / 构造 / 成员 | `WForm.validate` |
| `<文件>` | 具体路径 | `packages/form/lib/src/...` |
| `<原因>` | 一句话目标 | 移除字段 `config` |
| `<用途>` | 包 / 组件要解决的问题 | 地图围栏模型 |
| `<替代>` | 替代入口 | `WImageSource.network` |
| `<新包>` | 新包名 | `w_tools_geo` |
| `<feature>` | init 能力名 | `map`、`form` |
| `<PKG>` | 审计 ID 前缀（大写） | `FORM` → `FORM-001` |
| `<新版本>` | 新版本号 | `x.y.z`（按 semver 抬一位） |
| `<当前版本>` | 该包 `pubspec.yaml` 的版本 | 以文件为准 |
| `<标题>` | 反馈条目标题 | `cache clean --all 无确认` |
| `<关键词>` | 搜索词 | `cache` |
| `<runner>` | 测试 runner | 查 `scripts/packages.manifest` 第 3 列 |
| `<pkg1>` / `<pkg2>` | 多个包目录名 | `app`、`app_getx` |

`<runner>` 取 `scripts/packages.manifest` 第 3 列：纯 Dart 包用 `dart test` / `dart analyze`，
其余用 `flutter test` / `flutter analyze`。`<包>` 用于自然语言，`<pkg>` 用于路径 / `--package`。

### 验收命令怎么选

| 改动范围 | 验收命令 |
|---|---|
| 单个包 | `bash scripts/preflight.sh --package <pkg>` |
| 多个包 / 不确定 | `bash scripts/preflight.sh --changed` |
| 只改文档 / catalog | `bash scripts/preflight.sh` |
| 门禁脚本 / Flutter 升级 / 整波发布 | `bash scripts/preflight.sh --with-tests` |
| 本机没有 Flutter cache 写权限 | 在上面任一条后加 `--sandbox` |

`--package` / `--changed` 自带该范围测试；`--with-tests` 才是全仓完整档，一轮只需一次。
发布准备 PR 用 `bash scripts/preflight.sh --with-tests --with-flutter-analyze`。

## 1. 场景选择

| 任务 | 场景 |
|---|---|
| 私有方法、性能、内部重构 | A |
| 改现有公开组件 / API / 行为 | B |
| 新增公开组件 | C |
| 删除 / 废弃公开 API | D |
| 新增包 | E |
| 只整理 catalog / AGENTS / 文档 | F |
| 只审查，不改文件 | G |
| AI 不能访问仓库 / 不能跑命令 | H |
| 全仓审计 / 全量整理 | I |
| 单包快速审计 / 完整审计 | J-0 / J-1 |
| 把审计结果交给修复 AI | J-2 |
| 审计「所有使用方式是否教给 AI」 | J-4 |
| 多包 / 包家族审计 | J-5 |
| 发布波次总控（多包） | K-0 |
| 发布前审计（单包 / 多包） | K-1 / K-1M |
| 版本 / CHANGELOG 准备（单包 / 批量） | K-2 / K-2M |
| 发布 dry-run | K-3 |
| 实际发布（确认后执行） | K-4 |
| 发布后验证 | K-5 |
| 改 w_tools_cli / doctor / init 模板 | L |
| 处理 / 闭环反馈条目 | M |
| 门禁 / CI 红灯 | N |
| 升级 Flutter / 依赖 | N-1 |

CI 红灯先看 N；发布任务先读 [`docs/releasing.md`](releasing.md)，本手册只给任务卡。

## A. 内部重构 / Bug 修复

```text
任务：对 <包> 的 <文件> 做内部重构 / 修 bug。

要求：
1. 先说明为什么这是内部改动：哪些 public API 和默认行为没有变。
2. 只改必要代码 + 测试。
3. 发现确有公开行为变化就停下，改用场景 B。
4. 不要改 catalog / AGENTS / README / example。
5. 跑 `cd packages/<pkg> && <runner> test` 和 `bash scripts/preflight.sh --package <pkg>`
   （没有 Flutter cache 时加 `--sandbox`）。
6. 报告 changed files、为什么不需要文档更新、测试结果。
```

## B. 修改现有公开组件 / API / 行为

```text
任务：修改 <包> 的 <组件> / <API>，原因是 <原因>。

要求：
1. 先列清楚公开变化：API、默认行为、错误语义。
2. 定 semver：已发布 API 的删除 / 签名变化 → major；新增能力 → minor；修 bug → patch。
   已发布基线用 python3 scripts/release_status.py --online 确认（看「结论」列，
   exit 0 不代表无异常）或看最新快照；规则见 docs/releasing.md「发布窗口判断」，
   公开面预算见 docs/adr/0011-api-surface-budget.md。0.x 工具包破坏性变更抬 minor。
3. 抬 packages/<pkg>/pubspec.yaml 版本，写当前版本 CHANGELOG 段；本次改到的库子包同步
   versions.dart（工具包除外），聚合子包再抬根包下界（根包 / CLI 的约束变化写
   `## Unreleased`；AGENTS 第 2 条）。
4. 代码 + 测试；像素敏感的按 CONTRIBUTING §4 加 golden。
5. 更新 catalog：usage / pitfalls / related / dontUseFor / aliases / docsAnchor / teach。
6. 更新 templates/agents/{zh,en}/<feature>.md、README；必要时 example / migration。
7. 先改源文件再跑生成器，然后自测并贴输出：
   cd packages/cli
   dart run tool/gen_catalog.dart
   dart run tool/gen_templates.dart
   cd ../..
   python3 scripts/check_api_budget.py --package <pkg>
   dart run w_tools_cli:w_tools explain <组件> --format=prompt
   bash scripts/preflight.sh --package <pkg>
8. PR 正文保留「## 改动类型」段并至少勾选一项；勾公开类别时本包 CHANGELOG 必须被改。
```

## C. 新增公开组件

```text
任务：新增组件 <组件>，包是 <pkg>。

要求：
1. 先判断它是 teach 入口还是普通组件并说明理由；读 CONTRIBUTING §1 / §2 / §4。
2. 实现 + 测试（行为测试放 packages/<pkg>/test/，依赖写进该包 dev_dependencies）。
3. 新增公开类型先写 ADR，并在 scripts/api_budget.yaml 的 exceptions 登记（ADR 0011）；
   抬版本 + 写当前版本 CHANGELOG + 本次改到的库子包同步 versions.dart（工具包除外）/
   聚合子包的根包下界（根包 / CLI 的约束变化写 `## Unreleased`；AGENTS 第 2 条）。
4. catalog 增加 name / package / section / useFor / dontUseFor / teach / usage / pitfalls /
   related / docsAnchor / aliases；teach 入口同时在 catalog/entrypoints.yaml 登记。
5. related 优先指向已有 catalog 组件；子 API 才考虑 uncataloged 基线。
6. 影响包级规则时更新 templates/agents/{zh,en}/<feature>.md；更新 README / example。
7. 跑生成器与契约测试，再跑本包门禁：
   cd packages/cli
   dart run tool/gen_catalog.dart
   dart run tool/gen_templates.dart
   dart test test/internal/ai_contract_test.dart
   cd ../..
   bash scripts/preflight.sh --package <pkg>
8. 用 dart run w_tools_cli:w_tools explain <组件> --format=prompt 自测。
```

## D. 删除 / 废弃公开 API

```text
任务：删除或废弃 <包> 的 <API>，替代方案是 <替代>。

要求：
1. 先查已发布基线：删除 / 改名已发布 API 必须抬 major（0.x 工具包抬 minor）；
   只有上次发布后新增、从未发布的 API 能在当前版本直接删（releasing.md「发布窗口判断」）。
2. 代码层删除或加 @Deprecated，并在紧邻注释块写完整版本，例如 `/// remove-in: 9.0.0`
   （必须 x.y.z；写的是删除生效版本，通常是下一个 major）。
3. 抬版本，在当前版本 CHANGELOG 的 Breaking / Removed 写清 Type.member；必要时写 migration。
4. 把删除的公开名补进 scripts/check_removed_api.py 的名单。
5. catalog：删除条目或调整 usage / pitfalls / dontUseFor / aliases；清理 related 旧引用；
   AGENTS / README / example 不能继续推荐旧入口。
6. 在仓库根运行：
   python3 scripts/check_removed_api.py
   python3 scripts/check_deprecations.py
   python3 scripts/check_public_api_diff.py --package <pkg>
   python3 scripts/check_public_catalog.py
   bash scripts/preflight.sh --changed
7. 只是 deprecated 时，明确告诉 AI 现在该用什么，并保留 remove-in 到期版本。
```

## E. 新增包

```text
任务：新增包 <新包>，用途是 <用途>。

要求：
1. 在 scripts/packages.manifest 加一行：name / path / runner / root_aggregate / example_test。
2. 加入根 pubspec.yaml 的 workspace（ci_matrix --check 会校验）；只有聚合包才加根
   dependencies 的 `w_tools_<pkg>: ^x.y.z` 约束。
3. pubspec 写 `resolution: workspace`；补 CHANGELOG / README / LICENSE / .pubignore。
4. 首次发布前补 API 基线（否则 preflight 的 public api diff 会失败）：
   python3 scripts/check_public_api_diff.py --snapshot-from packages/<pkg> --package <pkg> --version <当前版本>
   工具包（无 barrel）改为登记 check_public_api_diff.py 的 NO_PUBLIC_API、check_docs_facts.py 的
   TOOLS、check_naming.py 的 TOOL_PACKAGES。
   首发窗口：合并前把裸名加进 scripts/pending_first_release.txt，合并后尽快发首版，
   首版成功后删掉该行。同一版本里再改 API 会被 check_version_bump 要求抬版本
   （bootstrap 基线被当成已发布基线）。
5. 有真实入口就加 example + smoke test；catalog 增加入口组件（teach: true）。
6. init feature 加 templates/agents/{zh,en}/<feature>.md 和 features.dart 映射。
7. 更新 context.capabilities、docs/modules/README.md、根 CHANGELOG。
8. 跑（生成器在 packages/cli 下）：
   cd packages/cli
   dart run tool/gen_templates.dart
   dart run tool/gen_catalog.dart
   cd ../..
   python3 scripts/ci_matrix.py --check
   python3 scripts/check_public_catalog.py
   bash scripts/preflight.sh --changed
9. 报告发布顺序和依赖关系。
```

## F. 只整理 catalog / AGENTS / 文档

```text
任务：只整理 <catalog / AGENTS / README / docs>，不改业务代码。

要求：
1. 先确认不涉及公开 API 或行为变化。
2. 只改源文件：catalog/components.yaml、templates/agents/**、README / docs。
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

## G. 只审查，不要修改

```text
任务：审查本次改动（git diff main...HEAD 或工作区改动），不要改任何文件。

请检查：
1. 是否有公开 API / 行为变化被漏掉？
2. catalog 的 usage / pitfalls / related / aliases 是否完整？
3. AGENTS 是否还推荐旧入口？README / example 是否跟得上？
4. 是否有生成物被手改、测试被削弱？
5. 运行 bash scripts/preflight.sh --changed 并贴结果。

输出：阻断问题 / 建议修复 / 可以保留的风险 / 相关文件路径。
```

## H. AI 不能访问仓库 / 不能跑命令

```text
你不能直接访问仓库或运行命令。请基于我提供的文件片段工作，并明确标注：
1. 哪些结论来自我贴的内容；
2. 哪些需要我运行命令确认；
3. 不要声称 preflight 已通过。

我提供：改动 diff、相关 catalog 条目、相关 README 段落、测试输出。
```

## I. 全仓审计 / 全量整理

不要一次改全仓。分三轮，每轮独立粘贴：

```text
第 1 轮（只读）：按 J-0 逐包审计，输出「包 | catalog 缺口 | teach 缺口 | AGENTS 缺口 |
README/example 缺口 | 风险」总表，并给出建议批次（每批一个包或一个 feature），不改文件。
第 2 轮（分批）：每批按 J-2 修 P0/P1，每批跑 bash scripts/preflight.sh --package <pkg>。
第 3 轮（验证）：按 J-4 复核教学覆盖，跑 bash scripts/preflight.sh --with-tests。
```

边界：代码重构 ≠ 文档整理；不要在同一条提示词里同时要求重构全部代码 + 重写全部
catalog / AGENTS / README / example。

## J. 单包全面审计（只读）

输出必须能直接交给另一个 AI 修复。

### J-0. 快速审计（默认）

日常先用这个，不要一上来复制 J-1。

```text
只读审计 <pkg>，不修改任何文件。

检查：功能/API 一致性、测试覆盖、example 真实场景、README/modules/agents/catalog 一致性、
explain --format=prompt 能否让 AI 写对代码。

运行（runner 以 scripts/packages.manifest 为准）：
- cd packages/<pkg> && <runner> test
- cd packages/<pkg> && <runner> analyze
- example 存在时：cd packages/<pkg>/example && <runner> test
- bash scripts/check_docs.sh
- python3 scripts/check_public_catalog.py（cli/device/e2e/figma 在 SKIP 中：注明“不适用”）

输出：| ID | 级别 | 文件:行 | 证据 | 问题 | 建议修复 | 验收命令 |

不要修改文件；不要为了让测试通过而改测试。
如果问题是“所有使用方式是否教给 AI”，直接用 J-4。
```

### J-1. 完整审计提示词（通用）

```text
任务：对 packages/<pkg> 做只读全面审计，输出一份“可交给另一个 AI 直接修复”的问题清单。
不要修改任何代码、测试、文档或生成物。

先读：AGENTS.md、docs/ai-contract.md、packages/<pkg>/README.md、pubspec.yaml、lib/、test/、
example/（存在时）、docs/modules/ 对应章节、docs/agents/<pkg>.md（app_getx → app.md、
map_google → map.md、cli → cli.md、figma → figma.md、device / e2e → device-testing.md；
工具包没有 modules 章节）、catalog 中该包条目与 uncataloged 基线、
templates/agents/{zh,en}/ 对应模板。

必须运行并贴实际输出（runner 以 manifest 为准）：
- cd packages/<pkg> && <runner> test
- cd packages/<pkg> && <runner> analyze
- example 存在时：cd packages/<pkg>/example && <runner> test
- bash scripts/check_docs.sh
- python3 scripts/check_public_catalog.py
- dart run w_tools_cli:w_tools list --package=<pkg> --format=prompt
- 对入口组件逐个运行 dart run w_tools_cli:w_tools explain <组件> --format=prompt

审计维度：
A. 功能与正确性：行为与注释 / README 一致？覆盖真实场景？有已删除 API 残留？异常被吞 / 状态不同步 / dispose 后更新？
B. API 设计：命名 / 参数 / 默认值一致？暴露了不该暴露的 Config / Core？高频参数缺失或低频参数污染入口？
C. 测试完整性：不要只看覆盖率；建立「行为 → 测试」矩阵，区分已有 / 缺失 / 仅 example 覆盖 / 必须真机验证。领域维度用该包的 docs/agents/<pkg>.md 补，不另抄清单。
D. 示例完整性：example 能否独立运行？覆盖真实场景？仍用旧 API？文档写了但 example 没有？
E. 用户文档：README 安装 / 最小用法 / API 说明与代码一致？modules 文档有旧 API 或错误示例？
F. AI 可用性：catalog 覆盖入口？teach 有 usage / pitfalls / related？explain 能写出正确代码？AGENTS / agents / modules / catalog 是否互相矛盾？
G. 维护与发布：生成物漂移？未登记公开类型？过期废弃项？文档声明不存在的参数 / 类型 / 成员？

输出：
1. 审计概览：实际命令和结果、测试数量、catalog / 基线数。
2. 问题清单：| ID | 级别 | 类型 | 文件:行 | 证据 | 问题 | 建议修复 | 验收命令 |
   ID 用 <PKG>-001；级别 P0–P3；每条必须有文件位置或命令输出；不要写“建议完善测试”。
3. 覆盖矩阵：| 能力 | 代码 | 测试 | example | 用户文档 | AI 文档 |
4. 建议修复批次：每批一个主题、标依赖顺序、给验收命令。
5. 不确定项标 NEEDS-VERIFY，不要猜 API 行为。

硬规则：不改文件；不为通过而改测试；以代码和命令输出为准；风格偏好不写成 P0；
文档和代码冲突时以代码为事实源，但把文档冲突单独列为问题。
```

### J-2. 把审计结果交给修复 AI

```text
只处理以下审计发现，不要扩展范围：

<粘贴 <PKG>-001 ~ <PKG>-00N>

要求：
1. 每条先复现，再修；先加失败测试，再改代码。
2. 不改变未列入问题的公开行为；不手改生成物。
3. 每条完成后跑对应验收命令；最后跑 bash scripts/preflight.sh --changed。
4. 报告：问题 ID、改动文件、测试结果、未解决项。
```

### J-4. AI 教学覆盖审计（只读）

```text
任务：只读审计 <pkg> 的 AI 教学覆盖。
范围：全部 catalog 条目与公开导出类型、catalog / uncataloged / AGENTS zh|en / README / example / explain。

运行：
- dart run w_tools_cli:w_tools list --package=<pkg> --format=prompt
- 对全部 teach 入口运行 dart run w_tools_cli:w_tools explain <组件> --format=prompt
- 对非 teach 与 uncataloged 基线抽查 explain（基线类型应返回「没有找到」）
- 运行该包测试 / bash scripts/check_docs.sh / python3 scripts/check_public_catalog.py（SKIP 包注明不适用）

检查：teach 的 usage 是否覆盖主要变体；非 teach 是否只有 useFor；基线类型是否 explain 不到；
AGENTS / README / example 是否覆盖真实用法；catalog / AGENTS / README 是否互相矛盾；
CLI 工具包（SKIP）是否走了 docs/templates 教学。

输出：问题表（<PKG>-001）+ 覆盖矩阵
（公开类型 | catalog | teach | AGENTS zh | AGENTS en | explain | README | example），
标出已教 / 只教一半 / 完全没教。

不要修改文件；不要为了让检查通过而改测试。
```

`python3 scripts/check_teaching_coverage.py` 是 J-4 的自动子集（入口名是否出现在
docs/agents、模板 zh+en、README、example），由 check_docs / preflight 自动跑；
通过不代表“讲清楚了”，人工矩阵仍要做。

### J-5. 多包 / 包家族审计（只读）

```text
任务：只读审计 <pkg1>, <pkg2>, ...（按 J-4 逐包输出矩阵），最后给跨包一致性结论。
不要合并成一个“平均覆盖”结论；按包分节。范围、命令、边界同 J-4；runner 以 manifest 为准。
```

## K. 发布 Pub

发布是高风险操作，必须拆成：审计 → 准备版本 → dry-run → 确认 → 发布 → 发布后验证。
本节只给**任务卡与边界**；命令细节、发布顺序、常见坑以 [`docs/releasing.md`](releasing.md) 为准。

先选路径：

| 情况 | 路径 |
|---|---|
| 代码未合并 | K-2M → PR → K-0 |
| 代码已合并、版本已准备 | K-0 plan → `release_wave.py run` |
| 单包 hotfix | K-1 → K-2 → K-3 → K-4 |
| 只补快照 | `bash scripts/apply_snapshots.sh` + 快照 PR |
| 只核对线上 | K-5 |

手动块和 `release_wave` 块二选一，不要混着走；整波优先 `release_wave`。

### K-0. 发布波次总控（多包）

单包按 K-1 → K-2 → K-3 → K-4 → K-5。同一波多个包：

```text
1. python3 scripts/release_wave.py plan --all --out .w_tools/release-plan.json
   （只读；默认只列 publish / blocked + 汇总，看全表加 --all-rows）
2. 审阅计划、确认版本提案与发布顺序（版本由 K-2 / K-2M 决定）。
3. 版本 / CHANGELOG PR 合并后：
   python3 scripts/release_wave.py run --plan .w_tools/release-plan.json --dry-run
   确认后 ... --yes；失败用 ... --resume --yes。
4. 快照 PR、根包、发布后核对由 run 串行完成；需要人工时再按 K-3 / K-4 / K-5 逐包做。
```

`run` 不会决定版本、不改 CHANGELOG、不 `--force`；要求 plan 已跑过 drift 核对。

### K-1. 发布前审计（只读，单包）

`--package` 只认 `scripts/packages.manifest` 里的裸名，不接受根包；审根包时去掉 `--package`。

```text
任务：审计 <pkg> 是否可以发布到 pub.dev。不要修改文件、不要真实发布、不要跑 dry-run。

先读：docs/releasing.md、packages/<pkg>/CHANGELOG.md、pubspec.yaml、README.md。

运行（快速档，约 1 分钟；不要在这里跑 --with-tests）：
- git status --porcelain（必须干净；不干净先停）
- git fetch origin main
- python3 scripts/check_publish_drift.py
- python3 scripts/release_status.py --online（看「异常：」段，不要只看退出码）
- bash scripts/release_check.sh --package <pkg>（根包去掉 --package）
- bash scripts/preflight.sh

检查：版本 ↔ CHANGELOG 一致；release_status 只证明版本号存在；漂移分类（code 必须抬版本，
docs / comment 可延后）；README 安装版本；根包约束覆盖；依赖包是否已先发；是否需要 migration；
工作区干净且已 push（--strict 同时要求干净、已 push、与 upstream 同步）。

输出：通过项 / 阻断项；建议版本号与依据；建议发布顺序；不要执行真实发布、不要改文件。
```

### K-1M. 多包 / 全量发布审计（只读）

```text
任务：审计所有待发布包（或指定列表），回答哪些包有未发布内容、能否发布、按什么顺序发。
范围：scripts/packages.manifest 中的包 + 根包（根包用不带 --package 的全量比对）。
每个包按 K-1 检查；漂移一列直接用 python3 scripts/check_publish_drift.py 的输出。

额外输出：
1. 发布状态总表：包 | 本地版本 | pub 版本 | 漂移 | 结论 | 建议版本
2. 未发布内容清单（按包）
3. 同版本漂移清单（code 必须抬版本；docs / comment 写清延后理由）
4. 发布顺序（无依赖 → 有依赖 → 根包；工具包独立）
5. 哪些包进 K-2、哪些跳过；波次风险（根包下界、快照 PR 依赖、cli 的 init 约束）

不要修改文件、不要 dry-run、不要发布。
```

### K-2. 版本 / CHANGELOG 准备（单包）

```text
任务：为 <pkg> 准备发布。

先看功能 PR 是否已抬过子包版本：抬过就沿用；没抬时才输出“版本提案表”等确认。
逃生口：任务文本里已给出确认过的版本提案表时，视为已确认，直接执行。

版本决策（无确认表时按此提案）：
| 改动 | 根包 | CLI |
| 子包 major / 删除根包 re-export 的公开类型 | 至少 major | 不适用 |
| 只改依赖约束 / 聚合版本 | patch 或 minor，看是否影响消费方行为 | minor |
| CLI init 约束 / 模板 / catalog 行为变化 | 不适用 | minor |
| 纯文档 / 内部脚本 | 不抬 | 不抬 |
根包没有符号级 API 快照；删重导出类型时不要只看 lib/w_tools.dart 的 export 行。

允许改：pubspec.yaml、CHANGELOG.md、README.md（只改安装示例的 caret 下界）、
库子包的 versions.dart 与聚合子包的根 pubspec（功能 PR 已抬过就沿用）、根包 / CLI 的
`## Unreleased`（折叠成版本段）、
必要的 migration、版本常量（cli / figma 的 version.dart）。
CLI 版本变化时记录 AGENTS 预算：cd packages/cli && dart run tool/agent_budget.dart --record。

不允许：执行 pub publish、手改生成物、改无关包。

要求：
1. 版本号与 CHANGELOG 的 ## 段一致；
2. README 安装示例的 caret 下界等于新版本，不要写死「当前 x.y.z」；
3. 跑 `python3 scripts/check_versions.py`、`bash scripts/release_check.sh --package <pkg>`
   （根包用 --strict）、`bash scripts/preflight.sh --with-tests --with-flutter-analyze`；
4. 提交前跑 bash scripts/check_pr_ready.sh /tmp/pr.md；提交到 feature 分支、push、开 PR
   （正文保留「## 改动类型」段，可用 bash scripts/ship.sh），用 bash scripts/check_pr_checks.sh
   确认 Required checks 通过后合并到 main；
5. 报告 changed files 和检查结果。
```

### K-2M. 批量版本准备

```text
任务：为以下包批量准备发布：<pkg1>, <pkg2>, ...

第一步只输出版本提案表（包 | 旧版本 | 新版本 | 级别 | 依据），等维护者确认；
任务文本已给确认表时视为已确认，直接执行。
确认后按 K-2 逐包改 pubspec / CHANGELOG / README / 库子包 versions.dart /
聚合子包的根包下界 / 版本常量（按包适用）；
CLI 版本变化时同步 cliVersion 并跑 cd packages/cli && dart run tool/agent_budget.dart --record。
不要改无关包。

最后统一跑：
python3 scripts/check_versions.py
bash scripts/release_check.sh
bash scripts/preflight.sh --with-tests --with-flutter-analyze
bash scripts/check_pr_ready.sh /tmp/pr.md
提交并 push，开 PR（正文保留「## 改动类型」段）并合并到 main。
```

### K-3. Dry-run（单包）

```text
任务：对 <pkg> 执行发布 dry-run。

运行：
- bash scripts/release_check.sh --strict --package <pkg>
- bash scripts/publish_package.sh packages/<pkg> --dry-run

不要执行真实 publish。根包额外前置：子包已发布且 pub.dev 可见、快照 PR 已合入、
main 已 git pull --ff-only；否则 dry-run 会因依赖解析失败。
输出：dry-run 结果、包大小 / 文件清单、依赖解析、是否还有阻断项。
```

批量时逐包执行 K-3；不要并行 publish。

### K-4. 实际发布（确认后执行）

```text
任务：发布 <pkg>。

前置：代码已在 main（还在 feature 分支先走 K-2 / K-2M + PR）；版本与范围已确认；
K-1 ~ K-3 已通过；工作区干净、main 且 HEAD == origin/main；发布顺序见 releasing.md。

执行（单包手动；整波用 K-0 的 release_wave）：
bash scripts/publish_package.sh packages/<pkg>

无 TTY / 自动化时加 --yes（只跳过 pub 的 y/N 确认，仍跑完整校验）；
需要 OAuth 域可达时加 --require-network。
禁止：直接在包目录 flutter pub publish / dart pub publish；未确认版本号就发布；
dry-run 未通过就发布；用 --force 代替正常保护（确需例外用 --force --reason "..."）；
不要用 `yes | ...`（会顺带批准任何意外提示）。
```

发布成功以脚本输出为准；pub.dev 最多 10 分钟才对外可见，不要立刻用 release_status 判失败。
快照、根包前置与失败处理见 [`docs/releasing.md`](releasing.md)。

### K-5. 发布后验证

```text
按 docs/releasing.md 的「发布后验证（两阶段）」执行。

阶段 1（快照还没 apply）：
- python3 scripts/release_status.py --online（不加 --check；看「异常：」段）
- python3 scripts/check_publish_drift.py --package <pkg>（code drift 必须为零）

阶段 2（快照 PR 合入、main 已 pull 之后）：
- python3 scripts/release_status.py --online --check
- 根包再跑 bash scripts/release_check.sh --strict，并用临时工程 flutter pub get
  （纯 Dart 包用 dart pub get）验证依赖可解析

不要修改代码；只报告验证结果。
```

K 的硬边界：不要直接 `flutter pub publish` / `dart pub publish`；不要自动决定 major / minor / patch；
不要把 pub 凭证写进提示词；不要把 `--yes` 当成跳过发布前保护；同版本内容漂移必须升版本，不能重发。

## L. 改 w_tools_cli / doctor / init 模板

```text
任务：修改 w_tools_cli 的 <文件>，原因是 <原因>。

先读：docs/agents/cli.md（维护者一节）、docs/conventions.md §7（doctor 的 R1~R9）、
packages/cli/README.md。

要求：
1. 规则只实现一次：检查逻辑写在 lib/，文档只描述。
2. 改 DoctorConfig 默认值 → 同步 renderDefaultConfig()（doctor --print-config）；
   packages/cli/test/internal/config_render_test.dart 会挡住漂移。
3. 改 templates/agents/** → cd packages/cli && dart run tool/gen_templates.dart。
4. 改 catalog/components.yaml → cd packages/cli && dart run tool/gen_catalog.dart。
5. 同步 init_test.dart 或 doctor_test.dart、docs/conventions.md §7、docs/agents/cli.md、
   packages/cli/CHANGELOG.md。
6. 在 packages/cli 跑 dart test；再回仓库根跑 bash scripts/preflight.sh --package cli。
7. 报告 changed files、命令结果、消费方会感知到的行为变化。
```

完成判据：`dart test` 全绿；`doctor --print-config` 与默认值一致；重新生成后的 diff 只反映
你改的源文件，没有额外漂移。

## M. 处理 / 闭环反馈条目

```text
任务：处理 <包> 的反馈条目「<标题>」。

先读：docs/feedback/README.md（状态机与索引规则）、docs/feedback/<pkg>.md 中的该条目。

要求：
1. 先查重与现状：dart run w_tools_cli:w_tools feedback search "<关键词>" --package=<pkg>
2. 先复现，再修；修代码走 A / B，不要顺手改公开 API。
3. 状态只由维护者确认：待处理 → 已确认（链 issue）→ 已修复（版本 + commit）/ 不修（写理由）。
   AI 不要把条目标成「已修复」；发布后由维护者补版本号。
4. 新条目用 feedback submit ... --ledger（自动建档 / 更新索引）；状态变更手工改
   docs/feedback/<pkg>.md，并同步 README 索引表的待处理数量（CI 会核对）。
5. 已闭环压成「## 已闭环」一行，细节写 CHANGELOG。
6. 提交前跑 bash scripts/check_feedback.sh；报告：条目、改动文件、版本、验证命令。
```

## N. 门禁 / CI 红灯

```text
任务：处理门禁失败（范围：<包> / <文件> / 无），或修改门禁脚本。

先读：scripts/README.md（每个脚本做什么 / 谁调用）、.github/workflows/ci.yml（job 与 required
接线）、失败 job 的完整日志（不是只看 GitHub 摘要）。

要求：
1. 先复现：在本地跑失败 job 里的同一条命令，贴完整输出。
2. 定位到唯一入口：静态门禁是 scripts/preflight.sh，文档是 scripts/check_docs.sh，
   发布是 scripts/release_check.sh；不要另写一套检查，也不要让 CI 手抄步骤。
3. 修根因。禁止为了让检查变绿而删检查、加 if: false / continue-on-error、放宽
   ci_matrix 的 REQUIRED_FILTERS、用 --force、改旧版本 CHANGELOG 段。
4. 改门禁脚本时同步 scripts/tests 与 scripts/README.md 登记；改 ci.yml 时跑
   python3 scripts/ci_matrix.py --check；改脚本时再跑 python3 scripts/check_gate_coverage.py。
5. 跑并贴结果：`bash scripts/check_docs.sh`、`bash scripts/preflight.sh --with-tests`。
6. 报告：失败原因、改了哪些文件、为什么不是绕过、剩余风险。
```

常见的红灯入口：

| 症状 | 场景 | 第一条命令 |
|---|---|---|
| `api-bump` 红：API 变了但版本没抬 | B | `python3 scripts/check_version_bump.py --base origin/main` |
| `public api diff` 红：缺基线 / 删改未记录 | D / E | `python3 scripts/check_public_api_diff.py --package <pkg>` |
| docs 链接 / 锚点 / 符号红 | F | `bash scripts/check_docs.sh` |
| `check_prompt_docs` 红（flag / 占位符 / 场景编号 / 路径） | F / N | `python3 scripts/check_prompt_docs.py` |
| 本地 preflight 绿但 PR 红 | N | 看 CI-only：`check_version_bump` / `check_pr_scope` / dry-run |
| `pub publish` 长时间无输出 | K-4 / K-5 | 先查代理；不要直接重试；确认 pub.dev 是否已有版本 |

### N-1. 升级 Flutter / 依赖

```text
任务：升级 Flutter 到目标版本，或升级依赖 <包>。

要求：
1. 同步版本 pin：.fvmrc、.github/workflows/ci.yml 的 FLUTTER_VERSION 与 MIN_FLUTTER_VERSION、
   根 / 各子包 pubspec 的 environment.flutter 下限。
2. 只抬声明下限时，MIN_FLUTTER_VERSION 必须 >= 声明的下限（理想 == 可用最高 patch）；
   ci_matrix --check 只校验 .fvmrc ↔ FLUTTER_VERSION，MIN 要人看。
3. 跑 flutter pub get → flutter analyze → bash scripts/preflight.sh --with-tests；
   有条件再跑 CI 的 min_sdk job。
4. 报告：版本矩阵（声明 / CI 实跑 / .fvmrc）、改了哪些包、剩余风险。
```

## 2. 填好的例子

| 场景 | 填什么 |
|---|---|
| B | `<包>` → `w_tools_async`；`<API>` → `WAsync.timeout`；`<原因>` → 超时错误需要显式区分 |
| C | `<组件>` → `WAsyncRetry`；`<pkg>` → `async` |
| D | `<包>` → `w_tools_ui`；`<API>` → `WImage.network`；`<替代>` → `WImageSource.network` |
| J-4 | 只读审计 `w_tools_ui` 的 AI 教学覆盖，按 J-4 输出覆盖矩阵 |

## 3. AI 完成后你必须检查

```text
[ ] 报告里的每条命令都真的跑过；没跑就写明没跑
[ ] git diff 没有大范围无关改动
[ ] catalog 改的是 components.yaml，不是 catalog.g.dart
[ ] AGENTS 改的是 templates，不是 templates.g.dart
[ ] 新公开类型已进 catalog 或 uncataloged 基线（并说明理由）
[ ] teach 组件有 usage / pitfalls / related，并在 catalog/entrypoints.yaml 登记
[ ] explain <组件> --format=prompt 输出正确
[ ] README / example 已更新；docs 索引已同步
[ ] 公开变化 PR：正文有「## 改动类型」段；每个改了公开代码的包都改了 CHANGELOG
[ ] 子包发布后快照已写入 .w_tools/release-snapshots/；根包发布前快照 PR 已合入；
    没有未说明理由的 --force
[ ] CLI 版本变化：docs/metrics/agents_budget.jsonl 已 --record
[ ] 按改动范围跑 preflight 实际通过
[ ] 没有削弱测试；改守卫 / 错误分支时做过一次定向变异（bash scripts/mutate_guard.sh）
```

重点看 `explain` 输出与发布归档，而不是只看“preflight 通过”。

## 4. 维护这份文档

- 只放**可复制的提示词块**和场景索引。流程步骤、脚本参数、版本规则写进事实源：
  [`docs/releasing.md`](releasing.md) / [`scripts/README.md`](../scripts/README.md) /
  [`AGENTS.md`](../AGENTS.md) / [`CONTRIBUTING.md`](../CONTRIBUTING.md)。
- 新增场景：加 `## X.` 标题 + §1 一行；删除场景：两处同时删，并检查 PR 模板 /
  CONTRIBUTING 是否还引用它。
- 预算：全文 ≤ 800 行（760 行起警告），单个场景块 ≤ 80 行（60 行起警告），
  由 `scripts/check_prompt_docs.py` 守（只作用于本手册）。超预算先问“这段是提示词，
  还是流程知识”；后者迁移到事实源，本手册只留链接。
- 改完跑 `bash scripts/check_docs.sh`；场景编号、占位符、命令 flag 由
  `check_prompt_docs.py` 机器校验，语义仍要人工 review。

## 5. 一句话

**固定前缀 + 一个场景块 + 证据要求 + preflight。**
