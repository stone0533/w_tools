# W Tools AI 使用契约

本文是 w_tools 面向 AI 的统一契约：**AI 怎么发现组件、怎么查用法、代码变更后怎么更新、怎么检查有没有漏。**

它同时服务两类读者：

- **消费方 AI**：通过 `init` 生成的 `AGENTS.md` 和 CLI 查询工作；
- **仓库维护者 / 仓库内 AI**：改代码、改 catalog、改模板、跑门禁。

核心原则：**catalog 是唯一事实源；explain / AGENTS / README·example 是它的三种投影。**

```text
catalog（唯一事实源：组件入口 / 用途 / 最短用法 / 坑 / 关联）
  ├─ explain     按需教学：catalog 字段 + import / 文档锚点 / example / 包版本
  ├─ AGENTS      入口规则与路由：templates/agents → init 写入消费方
  └─ README/example  完整参考与可运行场景

entrypoints.yaml  教学覆盖契约（核心入口必须出现在上述载体）
context / AI_PROMPTS  项目事实 / 人用场景提示词（不是组件事实或规则源）
```

四层不是四份平级文档：只有 catalog 是事实源，其余三层是不同粒度、不同载体的**投影**。
所以改教学先改 catalog；改完了再同步 explain 能读到的字段、AGENTS 的路由、README/example 的完整说明。

---

## 1. 为什么需要这层

w_tools 是 monorepo，子包多、版本独立、API 会演进。

如果只靠 README：

- AI 不知道当前项目装了哪些能力；
- AI 容易凭记忆写旧 API；
- 文档和代码容易漂移；
- 同一问题在多个包重复解释。

所以把“AI 需要知道的事实”拆成 **1 个事实源 + 3 种投影**（explain / AGENTS / README·example）：

| 层 | 角色 | 主要文件 | 与其他层的关系 |
|---|---|---|---|
| catalog | **唯一事实源**：组件入口 / 用途 / 最短用法 / 坑 / 关联 | [`packages/cli/catalog/components.yaml`](../packages/cli/catalog/components.yaml) | `list` / `explain` / `components.md` 都从它生成或读取 |
| explain | **投影**：按需教学 | [`packages/cli/lib/src/explain/render_explain.dart`](../packages/cli/lib/src/explain/render_explain.dart) | 只渲染 catalog 字段 + import / 文档 / example / 包版本，不维护第二份教学内容 |
| AGENTS | **投影**：入口规则 / 路由 | [`packages/cli/templates/agents/`](../packages/cli/templates/agents/) | `init` 生成消费方四段摘要（怎么用 / 硬规则 / 每包一行 / 完成前）；仓库 `AGENTS.md` + `docs/agents/` 是维护者更深一层 |
| README / example | **投影**：完整说明与真实场景 | `packages/<pkg>/README.md`、`packages/<pkg>/example/` | 读者按需深入；不是事实源，门禁只校验链接 / 符号 / 安装下界 / 入口名 |

这四层（一个事实源 + 三种投影）都在解决“AI 怎么知道事实”。另有两个人用的入口：消费方 `.w_tools/AI_PROMPTS.md`
（源模板 [`packages/cli/templates/ai/`](../packages/cli/templates/ai/)，场景编号 `A-1` / `B-1` …）
和 `context.capabilities`。前者**不是规则源**，而是开发者复制、填空、贴给 AI 的场景提示词；
后者是**项目事实**（装了哪些能力），不是组件事实。两者都不替代 catalog。


---

## 2. 消费方 AI 的工作流

人先选场景：`.w_tools/AI_PROMPTS.md` 的 §1 场景选择（`A-1` 计划 → `A-2` 实现、
`E-1` 审计 → `E-2` 修复、`F-1`→`F-2`→`F-3` 升级），填好占位符再贴给 AI。

AI 侧从拿事实开始：

### 第一步：拿项目事实

```bash
dart run w_tools_cli:w_tools context --format=prompt
```

输出包括：

- 项目名、是否 Flutter；
- 已安装的 w_tools 包与版本；
- toolkit 路径与导出；
- doctor 结果；
- 统一命令；
- 已安装能力摘要（capabilities）；
- 组件目录查询入口。

### 第二步：找组件

```bash
dart run w_tools_cli:w_tools list <关键词> --format=prompt
```

只返回：

- 组件名；
- 包名；
- 用途；
- usage 首行。

### 第三步：查具体用法

```bash
dart run w_tools_cli:w_tools explain <组件名> --format=prompt
```

标准输出应包含：

```text
import
用法：
注意：
相关：
文档：
```

也可以使用：

```bash
dart run w_tools_cli:w_tools explain WAsync --format=json
```

### 第四步：写完自检

```bash
dart run w_tools_cli:w_tools doctor --format=json
```

### 查询示例

```bash
dart run w_tools_cli:w_tools explain WAsync --format=prompt
dart run w_tools_cli:w_tools explain WAsyncController --format=prompt
dart run w_tools_cli:w_tools explain WImage --format=prompt
dart run w_tools_cli:w_tools explain WFormTextField --format=prompt
dart run w_tools_cli:w_tools explain DioRegistry --format=prompt
```

`tryRun` / `run` / `map` / `retry` 等方法名可以作为别名直接查询：

```bash
dart run w_tools_cli:w_tools explain tryRun --format=prompt
```

---

## 3. 维护者的更新流程

### 3.1 改了公开 API 或行为

按顺序改：

1. 代码；
2. `catalog/components.yaml` 的 `usage` / `pitfalls` / `related` / `aliases`；
3. 对应 AGENTS 模板；
4. README；
5. example；
6. 测试；
7. 生成器和门禁。

### 3.2 只改组件目录

```bash
cd packages/cli
dart run tool/gen_catalog.dart
```

生成：

```text
lib/src/catalog/catalog.g.dart
../../docs/modules/components.md
```

不要手改这两个生成物。

### 3.3 改 AGENTS 模板

消费方 AGENTS 是**常驻上下文**（每个 turn 都付 token），所以只收「不查任何东西也必须遵守」的内容：

| 想加的东西 | 该去哪 |
| --- | --- |
| 某个组件的用法 / 反例 / 参数形状 | `catalog/components.yaml` 的 `usage` / `pitfalls`（`explain` 的输出） |
| 某个 API 被删 / 改名 | catalog `pitfalls` + 迁移说明；AGENTS 只在「AI 很可能照旧记忆写」时留一句 |
| 一整个分支的流程（Figma / 设备 / 反馈 / 场景提示） | `templates/ai/` 或工具 README；AGENTS 只留 1–3 行路由 |
| 跨组件的项目约定（用哪个入口、生成物别手改） | AGENTS 的「硬规则」或「组件约定」一行 |

判据只有一句：**新规则先问「能不能进 catalog / explain」，能进就不进 AGENTS。**
`test/internal/templates_fresh_test.dart` 有一组结构预算门禁（行数 / 字符数 / 段落顺序 / zh-en 符号一致），
防止模板随版本单调膨胀。

```bash
cd packages/cli
dart run tool/gen_templates.dart
```

生成：

```text
lib/src/init/templates.g.dart
```

### 3.4 改了 context 能力

当前 `context.capabilities` 在：

[`packages/cli/lib/src/context/context_project.dart`](../packages/cli/lib/src/context/context_project.dart)

新增包或能力时要同步摘要。

摘要只收录**消费入口包**（6 个聚合子包 + `app_getx` / `map_google` / `qr`）。
`w_tools_app` / `w_tools_map` 是契约层，分别由 `app_getx` / `map_google` 代表，不单列；
`cli` / `figma` / `device` / `e2e` 是工具包，也不在能力摘要里。

### 3.5 检查生成物没有漂移

```bash
cd packages/cli
dart run tool/gen_catalog.dart --check
dart run tool/gen_templates.dart --check
```

---

## 4. 目录条目契约

每个组件条目至少有：

```yaml
- name: '`WXxx`'
  package: 'w_tools_xxx'
  section: '…'
  useFor: '…'
  dontUseFor: '…'
```

`teach: true` 的入口组件还必须有：

```yaml
  usage: |
    ...
  pitfalls:
    - ...
  related:
    - '`WYyy`'
```

可选：

```yaml
  aliases:
    - 'tryRun'
    - 'run'
```

### 分层规则

```text
teach: true   入口组件：必须 usage / pitfalls / related
teach: false  普通组件：至少 useFor / dontUseFor
```

不要要求所有组件都有 usage。

### `related` 要求

- 优先指向 catalog 中已有的组件名或别名；
- 子 API 如果暂不单独登记，必须进入 [`uncataloged.yaml`](../packages/cli/catalog/uncataloged.yaml) 基线；
- 已由 `ai_contract_test` 检查可解析。

---

## 5. 完整性检查

“全不全”拆成下面这些维度。**这里只列维度与入口**——脚本细节和纪律见
[`scripts/README.md`](../scripts/README.md)，不维护第二份门禁清单，也不写死数量。

| 维度 | 查什么 | 入口 |
|---|---|---|
| 5.1 可发现性 | 公开导出类型必须进 catalog 或 `uncataloged.yaml` 基线 | [`check_public_catalog.py`](../scripts/check_public_catalog.py) |
| 5.2 教学覆盖 | teach 必须有 usage / pitfalls / related；每个库包至少一个 teach；prompt 含「用法 / 注意 / 相关」 | [`ai_contract_test.dart`](../packages/cli/test/internal/ai_contract_test.dart) |
| 5.3 路由覆盖 | 每个 `InitFeature` 有 zh / en 模板，且不推荐旧命令 | 同上 |
| 5.4 文档覆盖 | 每个包有 README；所有当前文档的安装示例下界等于当前版本（含跨包示例）；有 example 要在 README 提及 | [`check_package_docs.py`](../scripts/check_package_docs.py) |
| 5.5 生成物新鲜度 | `catalog.g.dart` / `templates.g.dart` / `components.md` 与源文件一致 | `gen_catalog.dart --check`、`gen_templates.dart --check` |
| 5.6 查询正确性 | `list` / `explain` / `context`、三种输出格式、别名命中、README 快速开始 | [`cli_test.dart`](../packages/cli/test/cli_test.dart)、[`catalog_test.dart`](../packages/cli/test/internal/catalog_test.dart)、[`context_test.dart`](../packages/cli/test/internal/context_test.dart) |
| 5.7 文档入口一致性 | 文档索引完整、`docs/agents` 索引与规则页一致、高频规则短语在 docs/agents 与 zh/en 模板一致、doctor 规则表两处一致、root / 各包 `AGENTS.md` 的符号、import / re-export 边界与已删除 API、文档里的命令可执行（提示词手册 + 当前文档的脚本 / flag） | [`check_docs_facts.py`](../scripts/check_docs_facts.py)、[`check_agents_consistency.py`](../scripts/check_agents_consistency.py)、[`check_doc_symbols.py`](../scripts/check_doc_symbols.py)、[`check_removed_api.py`](../scripts/check_removed_api.py)、[`check_prompt_docs.py`](../scripts/check_prompt_docs.py) |
| 5.8 命名约定 | 公开 `W*Config` 必须在 [naming_baseline.yaml](../scripts/naming_baseline.yaml) 内；库包公开类型 `W` 前缀；规则见 [docs/naming.md](naming.md) | [`check_naming.py`](../scripts/check_naming.py) |
| 5.9 清单同源 | CI 包矩阵从 `packages.manifest` 生成，静态门禁调用 `preflight.sh`；关键路径过滤器 / required 接线 / docs job meta 检查由 `ci_matrix --check` 守；每个检查脚本都必须有真实入口（preflight / check_docs / release_check / workflow）且在 `scripts/README.md` 登记 | [`ci_matrix.py`](../scripts/ci_matrix.py)、[`check_gate_coverage.py`](../scripts/check_gate_coverage.py) |
| 5.10 核心入口教学覆盖 | `entrypoints.yaml` 里的入口必须出现在 docs/agents / 模板 zh+en / README（有 example 还要出现在 example/lib）；覆盖 11 个库包，app_getx/map_google 共用 app/map 规则页（J-4A） | [`check_teaching_coverage.py`](../scripts/check_teaching_coverage.py) |
| 5.11 PR 分类 ↔ CHANGELOG | 改了公开代码（`lib/` / `bin/` / CLI `templates/` / `catalog/` / `schema/`）的 PR 必须带 PR 模板的「## 改动类型」段并至少勾选一项（空 body / 全未勾选会失败）；勾了公开类别（公开变化 / 删除废弃 / 新增包）时，**每个改了公开代码的包**都要改自己的 CHANGELOG（根包改 `lib/` / `pubspec.yaml` 时用根 `CHANGELOG.md`），且本地版本要高于已发布基线（CI 带 `--online` 时用 pub.dev，取不到回退快照；或 CHANGELOG 有非空 `## Unreleased`）；行为变化没有 API diff，靠这条兜底 | [`check_pr_scope.py`](../scripts/check_pr_scope.py) |
| 5.12 发布物链接 | 会随发布物发出的 Markdown（README / CHANGELOG / CONTRIBUTING / example / 包内 Markdown）不得用相对链接指向不随包发布的路径；pub.dev 会改写相对链接，但 tarball / pub cache 不会 | [`check_published_links.py`](../scripts/check_published_links.py) |

重建基线用 `python3 scripts/check_public_catalog.py --write`；它是**基线**，不是「全了」的证明，
新增类型仍要人工判断进 catalog 还是 `uncataloged.yaml`。

---

## 6. 新增组件的流程

```text
1. 代码 + 测试
2. catalog 加条目
3. 判断是否 teach
4. teach 则补 usage / pitfalls / related
5. 必要时补 aliases
6. 如果影响规则，改 AGENTS 模板
7. 改 README / example
8. 跑生成器
9. 跑 ai_contract / cli / docs / preflight
```

### 新增包

除了上面步骤，还要：

- 在 `scripts/packages.manifest` 加一行：包名 / 路径 / runner / 根聚合 / example 测试；
- 加入根 workspace；
- 补 README；
- 有 example 则补 example；
- 如果是 init feature，补 `templates/agents/{zh,en}/<feature>.md`；
- 如果是消费入口包，补 `context.capabilities`（契约层 `app` / `map` 与工具包不单列）；
- 补 `docs/modules` 索引；
- 补 release 约束 / 版本。

---

## 7. 删除 / 废弃 API 的流程

```text
1. 删除或废弃代码
2. 把删除的公开名补进 scripts/check_removed_api.py 的 names 列表
   （手写白名单：不登记，后续文档引用就拦不住）
3. 从 catalog 移除条目，或改 aliases / usage / pitfalls
4. 检查 related 是否还有引用
5. 更新 AGENTS 模板（明确新入口）
6. 更新 README / migration
7. 更新 example
8. 跑 check_removed_api / check_docs / preflight
```

如果 API 只是 deprecated：

- catalog `pitfalls` 要写清楚替代入口；
- AGENTS 不能继续推荐旧入口；
- `aliases` 可以保留旧名，便于 AI 查询到新说明。

---

## 8. 一条命令跑完检查

```bash
cd packages/cli
dart run tool/gen_catalog.dart --check
dart run tool/gen_templates.dart --check
dart test
```

```bash
cd ../..
python3 scripts/check_public_catalog.py
python3 scripts/check_package_docs.py
bash scripts/check_docs.sh
bash scripts/release_check.sh
bash scripts/preflight.sh --with-tests
```

日常只需要最后一条：

```bash
bash scripts/preflight.sh --with-tests
```

---

## 9. 当前已知边界

- `check_public_catalog.py` 基于 export/part 静态扫描，不是完整 analyzer；
- catalog 只登记**组件入口**，不是全部公开 API；子 API 要么进 `uncataloged.yaml` 基线，要么只在源码 / pub.dev API 文档里；
- `explain` 只是 renderer：不维护第二份教学；catalog 的 `usage` / `pitfalls` / `related` 为空时输出就会薄；
- `uncataloged.yaml` 是“有意不登记”清单，仍应定期 review；
- `usage` 是最短片段，不保证全量编译；
- 大部分 `teach: false` 组件仍只有 useFor / dontUseFor（具体比例见 catalog，不在文档里写死）；
- README / example 是“完整参考”，不是与当前安装版本一一对应的快照；`explain` 的仓库文档链接固定 main，API 文档才按 lock 版本拼接；
- `entrypoints.yaml` 是覆盖契约，只证明核心入口在 docs/agents / 模板 / README / example 里“提到过”，不证明讲清楚了；语义仍由 J-4 人工审计；
- `context.capabilities` 是静态映射，新增**消费入口包**时需同步（契约层 / 工具包不单列）；
- `check_pr_scope.py` 只读 PR 正文：改了公开代码（`lib/` / `bin/` / CLI `templates/` / `catalog/` / `schema/`）时要求「## 改动类型」段并至少勾选一项（空 body 也失败），勾了公开类别时要求每个被改包的 CHANGELOG 被改、根包公开面有根 CHANGELOG、本地版本高于已发布基线（CI 带 `--online` 时用 pub.dev，取不到回退快照；或 CHANGELOG 有非空 `## Unreleased`）；它无法验证改动**是否真的**是公开变化；
- `check_published_links.py` 只检查会随发布物发出的 Markdown；校验本仓库 GitHub 绝对 URL 的路径存在，不校验外部 URL / 锚点 / 引用式链接；
- Markdown 全量代码块编译尚未开启，只检查关键示例。

---

## 10. PR 检查表

以仓库的 [`.github/PULL_REQUEST_TEMPLATE.md`](../.github/PULL_REQUEST_TEMPLATE.md) 为准
（GitHub 开 PR 会自动带出）。分类、命名、教学同步、版本物料都只维护在模板里，
这里不再留第二份清单；J-4 的定义见 [ai-maintainer-prompts.md](ai-maintainer-prompts.md) 的 J-4 一节。

自动门禁由 `bash scripts/preflight.sh --with-tests` 覆盖，不需要在 PR 里逐项手抄结果。

---

## 11. 维护者提示词

按场景复制的提示词见 [`ai-maintainer-prompts.md`](ai-maintainer-prompts.md)。

## 12. 相关文档

- [CLI 使用规则](agents/cli.md)
- [Async 使用规则](agents/async.md)
- [组件目录](modules/components.md)
- [模块索引](modules/README.md)
- [Agent 文档索引](agents/README.md)
- [Async 5.0 迁移](migrations/async-5.0.md)
- [文档地图](documentation-map.md)
- [scripts 运行手册](../scripts/README.md)
- [根 AGENTS](../AGENTS.md)
