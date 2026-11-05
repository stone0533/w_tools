# 维护者 AI 提示词手册

本文给 **w_tools 包维护者**使用：改代码、加组件、删 API、加包、整理目录时，直接复制对应提示词给 AI。

配套规则见 [`docs/ai-contract.md`](ai-contract.md)。

---

## 新手先看这里

你不需要先读完 A~K。

### 只需三步

1. 用一句话说明任务；
2. 不知道该用哪个场景，先让 AI 帮你选；
3. AI 判断后，只复制对应场景块。

### 让 AI 帮你选场景

不确定选 A~K 时，先发这段：

```text
我是 w_tools 维护者，但不熟悉这些提示词。

请先读 docs/ai-maintainer-prompts.md 和 docs/ai-contract.md。

我的任务是：<用一句话描述>。
范围是：<包/组件/文件>。

请先判断应该用 A~K 哪个场景，并说明原因；
不要改代码；
确认后，给我一份已经填好包名、组件和范围的提示词。
```

### 默认工作流

```text
第 1 轮：只审计（G / J-0 / J-4 / K-1），不改文件
第 2 轮：只修 P0/P1（B / A / J-2）
第 3 轮：跑 preflight，检查 explain 输出 / 发布归档
```

不要第一轮就：

```text
审计 + 修复 + 改文档 + 跑全仓
```

### AI 完成后先看

```text
[ ] 真的运行了命令吗？
[ ] 有没有手改生成物？
[ ] 有没有改测试来“通过”？
[ ] explain 输出是否正确？
[ ] teach / 非 teach / 基线类型三类都查过吗？
[ ] 发布时：git status 干净？pub 归档 diff 看过？
[ ] 有没有改无关文件？
```

---

## 0. 固定前缀（每次先贴）

```text
你是 w_tools 的维护者，先读 docs/ai-contract.md、AGENTS.md 和
packages/<pkg>/README.md，再开始。

硬约束：
1. 先判断这是内部改动，还是公开 API / 行为变化。
2. 不要手改生成物：catalog.g.dart / templates.g.dart / components.md。
3. 不要为了让检查通过而降低测试、契约或文档标准。
4. 新增公开类型优先登记 catalog；不要直接塞进 uncataloged.yaml，除非说明它只是子 API。
5. 必须实际运行命令并贴结果；不能运行就明确说没运行，不要声称通过。
6. 不要改无关包、无关文档、无关测试。
7. 最后报告 changed files、实际命令结果、explain 输出、剩余风险。
```

然后从下面选一个任务块贴在后面。

## 填空说明

| 占位符 | 填什么 | 示例 |
|---|---|---|
| `<pkg>` | 包目录名 | `form` |
| `<包>` | 包名或目录 | `w_tools_form` |
| `<组件>` | 公开类名 | `WFormTextField` |
| `<API>` | 方法 / 构造 | `WForm.validate` |
| `<文件>` | 具体路径 | `packages/form/lib/src/...` |
| `<原因>` | 一句话目标 | 移除字段 `config` |

新手最容易漏的是 `<包>` 和 `<文件>`；能填具体路径就不要只写包名。

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

先问三个问题：

```text
我只是想检查，不想改？        → G / J-0
我想确认“教全了吗”？          → J-4
我要发布 / 批量发布？          → K / K-1M
我要改已有代码 / API？        → A / B
我要新增 / 删除 / 加包？      → C / D / E
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
| 全仓审计 / 全量整理 | I（先审计，再分批） |
| 单包全面审计（只读） | J |
| 审计“所有使用方式是否教给 AI” | J-4 |
| 审计多个包 / 包家族 | J-5 |
| 发布 Pub / 发布前检查 | K（默认只读或 dry-run） |
| 批量发布多个包 | K-1M / K-2M |
| AI 不能访问仓库 / 不能跑命令 | H |

---

## A. 内部重构 / Bug 修复

适用：

```text
私有实现、性能、日志、内部命名
公开 API 和默认行为不变
```

```text
任务：对 <包/文件> 做内部重构 / 修 bug。

要求：
1. 先说明为什么这是内部改动：哪些 public API 和默认行为没有变。
2. 只改必要代码 + 测试。
3. 如果发现确实有公开行为变化，停下来，改用场景 B。
4. 不要改 catalog / AGENTS / README / example。
5. 运行该包测试和全仓 preflight。
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
任务：修改 <包/组件/API>，原因是 <...>。

要求：
1. 先列清楚公开变化：API、默认行为、错误语义。
2. 代码 + 测试。
3. 更新 catalog/components.yaml：
   - usage
   - pitfalls
   - related
   - aliases（保留旧名时）
   - teach（入口组件必须）
4. 更新对应 AGENTS 模板，确保不再推荐旧写法。
5. 更新 README；必要时更新 example。
6. 如果是 breaking，写 migration，并检查 docs/migrations/README.md。
7. 先改源文件，再跑：
   cd packages/cli
   dart run tool/gen_catalog.dart
   dart run tool/gen_templates.dart
8. 运行 explain <组件> --format=prompt，贴输出。
9. 运行 preflight --with-tests，贴结果。
```

---

## C. 新增公开组件

```text
任务：新增组件 <WXxx>，包是 <pkg>。

要求：
1. 先判断它是 teach 入口还是普通组件，并说明理由。
2. 实现 + 测试；如果需要 async / 状态，先查 async 规则。
3. 在 catalog/components.yaml 增加：
   - name / package / section
   - useFor / dontUseFor
   - teach（入口组件）
   - usage / pitfalls / related（teach 时）
   - aliases（有方法名查询需求时）
4. related 优先指向已有 catalog 组件；子 API 才考虑 uncataloged 基线。
5. 如果影响包级规则，更新 AGENTS 模板。
6. 更新 README；有真实场景就更新 example。
7. 跑生成器、ai_contract、cli 测试、preflight。
8. 用 explain <WXxx> --format=prompt 自测。
```

---

## D. 删除 / 废弃公开 API

```text
任务：删除或废弃 <包/API>，替代方案是 <...>。

要求：
1. 代码层删除或加 deprecated，写清 remove-in。
2. catalog：
   - 删除条目，或调整 usage / pitfalls / aliases；
   - 清理 related 中指向旧 API 的引用。
3. AGENTS 不能继续推荐旧入口。
4. README / migration / example 更新。
5. 运行 check_removed_api / check_public_catalog / preflight。
6. 如果只是 deprecated，明确告诉 AI 现在应该用什么。
```

---

## E. 新增包

```text
任务：新增包 <w_tools_xxx>，用途是 <...>。

要求：
1. 在 scripts/packages.manifest 加一行：name / path / runner / root_aggregate / example_test。
2. 加入根 workspace 和根约束（如果属于聚合范围）。
3. pubspec / CHANGELOG / README / LICENSE / .pubignore。
4. 有真实入口就加 example，并加 smoke test。
5. catalog 增加入口组件；入口组件 teach: true。
6. 如果是 init feature，加 templates/agents/{zh,en}/<feature>.md 和 features.dart 映射。
7. 更新 context.capabilities、docs/modules/README.md、docs/releases。
8. 跑 gen_templates / gen_catalog / check_public_catalog / preflight。
9. 报告发布顺序和依赖关系。
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
4. 跑：
   - gen_catalog
   - gen_templates
   - ai_contract
   - check_docs
   - check_public_catalog
5. 报告改了哪些事实、哪些是生成结果。
```

---

## G. 只审查，不要修改

```text
任务：审查本次改动，不要改任何文件。

请检查：
1. 是否有公开 API / 行为变化被漏掉？
2. catalog 的 usage / pitfalls / related / aliases 是否完整？
3. AGENTS 是否还推荐旧入口？
4. README / example 是否跟得上？
5. 是否有生成物被手改？
6. 是否有测试被削弱？
7. 运行 preflight --with-tests 并贴结果。

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
- docs/ai-maintainer-prompts.md
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
- dart run tool/gen_catalog.dart --check
- dart run tool/gen_templates.dart --check
- bash scripts/check_docs.sh

不要运行会改文件的生成器或 init。

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
- 组件：<...>
- 允许改的文件：<...>

要求：
1. 不改变本批之外的公开 API / 行为；
2. 先改 catalog / templates 源文件，再跑生成器；
3. 不手改生成物；
4. 更新 README / example（仅本批相关）；
5. 跑本批验收 + preflight；
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
- docs/ai-maintainer-prompts.md
- packages/<pkg>/README.md
- packages/<pkg>/pubspec.yaml
- packages/<pkg>/lib/
- packages/<pkg>/test/
- packages/<pkg>/example/（存在时）
- 对应的 modules 文档（ui/form/async/app/device 等；app 与 app_getx 共用 app_module.md）
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
- 对该包入口组件逐个运行 explain --format=prompt

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

| 包 | 额外检查 |
|---|---|
| ui | WImage 尺寸/来源、WText variant、WScaffold/WAppBar、WButton/WPressable、WListView、WScreen |
| form | WForm/WFormController 生命周期、validator、readOnly、border、字段矩阵、WFormPopup |
| async | 四态、分页 loadMore/loadMoreError、刷新、取消、WAsyncTheme、sliver |
| app / app_getx | 启动顺序、插件 dependsOn、wrapApp/builderWrapper、路由、语言、底部弹窗 |
| device | 平台矩阵、坐标/标定、退出码、CLI flag、真机不可测边界 |

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
6. 最后跑 preflight --with-tests。
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
- 对全部 teach 入口运行 explain --format=prompt
- 对非 teach 抽样 explain
- 对 uncataloged 基线抽查 explain
- 运行该包测试 / check_docs / check_public_catalog（SKIP 包注明不适用）

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

不要用一条“帮我发布”的提示词完成全部步骤。

### K-1. 发布前审计（只读，单包）

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
- bash scripts/release_check.sh --package <pkg>
- bash scripts/release_check.sh --package <pkg> --online
- bash scripts/preflight.sh --with-tests
- 从 pub.dev API 取 latest.archive_url，下载归档到 /tmp，解压后与本地比较：
  pubspec.yaml / lib/** / README.md / CHANGELOG.md / LICENSE / example/**
  （排除 test / docs / scripts 等仓库专用内容）

检查：
1. 版本号与 CHANGELOG 是否一致；
2. --online 是否只证明“版本存在”，不能证明内容已发布；
3. 同版本归档与本地是否有差异（有差异 = 同版本漂移，必须 K-2 升版本）；
4. README 安装版本 / 示例是否过期；
5. 根包约束是否覆盖新版本（仅聚合包）；
6. 依赖包是否已先发布；
7. 是否需要 migration；
8. 工作区是否干净、是否已 push（--strict 只查干净，不查 push）。

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

范围：scripts/packages.manifest 中的包 + 根包（按需）。
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

先输出“版本提案表”（旧版本 → 新版本、major/minor/patch、依据），
等维护者确认后再改文件。不要自动决定版本号。

允许改：
- packages/<pkg>/pubspec.yaml
- packages/<pkg>/CHANGELOG.md
- packages/<pkg>/README.md
- 根包约束（仅发根包时）
- 必要的 migration
- 版本常量（cli/figma 的 version.dart 等，仅用于版本一致性测试）

不允许：
- 执行 pub publish
- 手改生成物
- 改无关包

要求：
1. 版本号必须与 CHANGELOG 的 ## 段一致；
2. 更新 README 安装版本；
3. 跑 release_check / preflight；
4. 完成后提交并 push（K-3 需要干净工作区）；
5. 报告 changed files 和检查结果。
```

### K-2M. 批量版本准备

```text
任务：为以下包批量准备发布：<pkg1>, <pkg2>, ...

第一步只输出版本提案表（包 | 旧版本 | 新版本 | 级别 | 依据），等维护者确认。
确认后按 K-2 逐包改 pubspec / CHANGELOG / README；
版本常量按需同步；不要改无关包。
最后统一跑 release_check / preflight，提交并 push。
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
一次只执行一个 publish 命令；每个包发布后做 K-5，再发下一个。
不要用一个命令/一个进程同时发多个包。
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
- bash scripts/release_check.sh --package <pkg> --online
- 下载 pub.dev 最新归档，确认 README / CHANGELOG / lib 与仓库一致

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

## 2. 提示词使用示例

### 改 WAsync 的超时行为

固定前缀 + 场景 B，把：

```text
<包/组件/API> → w_tools_async / WAsync.timeout
<...> → 超时错误需要显式区分
```

### 新增 WAsync 的 retry 辅助

固定前缀 + 场景 C，把：

```text
<WXxx> → WAsyncRetry
<pkg> → w_tools_async
```

### 删除 WImage 旧构造器

固定前缀 + 场景 D，把：

```text
<包/API> → w_tools_ui / WImage.network
<...> → WImageSource.network
```

### 审计 ui 的所有使用方式是否教给 AI

固定前缀 + 场景 J-4：

```text
任务：只读审计 w_tools_ui 的 AI 教学覆盖。
按 J-4 输出覆盖矩阵（公开类型 | catalog | teach | AGENTS zh | AGENTS en | explain | README | example）。
```

### 发布所有未发布包

固定前缀 + 场景 K-1M：

```text
任务：审计所有包的发布状态，输出状态总表、同版本漂移清单、建议版本与发布顺序。
不要修改文件、不要 dry-run、不要发布。
```

### 单包发布

K-1 → K-2（确认版本）→ 提交并 push → K-3 → K-4 → K-5，逐包执行。

## 3. AI 完成后你必须检查

```text
[ ] git diff 没有大范围无关改动
[ ] catalog 改的是 components.yaml，不是 catalog.g.dart
[ ] AGENTS 改的是 templates，不是 templates.g.dart
[ ] 新公开类型已进 catalog 或 uncataloged 基线（并说明理由）
[ ] teach 组件有 usage / pitfalls / related
[ ] 非 teach / 基线类型也查过 explain
[ ] explain <组件> --format=prompt 输出正确
[ ] README / example 已更新
[ ] 发布时：git status 干净、归档 diff 看过、版本常量已同步
[ ] preflight --with-tests 实际通过
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

复杂改动拆成：

```text
第 1 轮：代码 + 测试
第 2 轮：catalog + AGENTS
第 3 轮：README + example
第 4 轮：preflight + 审查
```

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

- CLI 命令；
- catalog 字段；
- AGENTS 模板规则；
- 完整性检查命令；
- 发布 / migration 流程；
- 新增场景（J-4 / J-5 / K-1M / K-2M）或 CLI 命令（list --package、explain 锚点）。

保持它和 [`docs/ai-contract.md`](ai-contract.md) 一致。

---

## 7. 一句话

**固定前缀 + 场景块 + 证据要求 + preflight。**

这就是给维护者使用 AI 的最合适方式。
