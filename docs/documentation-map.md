# 文档地图与 AI 整理规则

本文回答两个问题：

```text
每个文档应该写什么？
AI 改代码后，应该把信息放到哪个文档？
```

配套规则：

- [AI 使用契约](ai-contract.md)
- [维护者 AI 提示词](ai-maintainer-prompts.md)
- [接入约定](conventions.md)

---

## 0. 读者模型

不要把“AI”当成与“包使用者 / 维护者”并列的单一读者。

更准确的是 **4 类读者**：

| 读者 | 典型任务 | 主要入口 |
|---|---|---|
| 包使用者（人） | 选包、安装、使用、升级、排错 | 根 README、包 README、modules、recipes、migrations |
| 包使用者（AI） | 找组件、生成代码、检查 API | 生成的 AGENTS、`context/list/explain --format=prompt`、pub.dev README |
| 包维护者（人） | 设计、改代码、review、发布 | CONTRIBUTING、conventions、releasing、ADR、scripts/README |
| 仓库内 AI | 改代码、补 catalog、改 AGENTS、跑门禁 | AGENTS、docs/agents、ai-contract、ai-maintainer-prompts、catalog、example |

`贡献者` 可以归入“包维护者”，不必单独成类。

### 包使用者 AI ≠ 仓库内 AI

消费方 AI 通常只能看到：

```text
init 生成的 AGENTS.md
pub.dev README
CLI context / list / explain 输出
```

它**看不到**：

```text
packages/<pkg>/example/
docs/agents/
docs/analysis/
scripts/
```

仓库内 AI 才能读源码、example、catalog、templates 和全部 docs。

所以：

```text
消费方 AI  → 依赖 AGENTS + CLI 查询
仓库内 AI  → 依赖 AGENTS + docs/ai-contract + catalog + example
维护者     → 依赖 docs + scripts/README
```

### 三个 surface

| surface | 面向 | 内容 |
|---|---|---|
| 使用面 | 包使用者（人 + AI） | 安装、API、组合场景、迁移、示例 |
| 维护面 | 维护者（人 + 仓库 AI） | 规范、ADR、发布、检查、反馈 |
| AI 检索面 | 消费方 AI + 仓库 AI | 组件事实、最短用法、坑、入口规则、查询命令 |

AI 检索面不是第三份完整文档，而是使用面 / 维护面的**可查询投影**。

---

## 1. 一张图

```text
根 README                 第一入口：安装 / 子包选择 / 快速开始
AGENTS.md                 仓库 AI 入口：任务路由 + 跨包硬规则
CONTRIBUTING.md           改组件的硬性要求

docs/
  README.md               文档总索引
  documentation-map.md    本文：文档定位 + AI 整理规则
  conventions.md          接入约定 / doctor R1~R9
  naming.md               命名规范（唯一事实源）
  releasing.md            发版流程
  ai-contract.md          AI 分层、更新、完整性检查
  ai-maintainer-prompts.md 维护者按场景使用的 AI 提示词

  modules/                使用者：包职责 / API / 用法
    components.md         生成物：组件目录表
  agents/                 AI/维护者：首选入口、硬规则、禁止项
  recipes/                跨包组合场景
  guides/                 横向指南（测试策略等）
  migrations/             版本迁移（历史）
  adr/                    架构决策（历史）
  analysis/               评审分析（历史）
  feedback/               使用反馈台账

packages/<pkg>/
  README.md               该包的用户事实源
  example/                可运行示例 + smoke test

packages/cli/
  catalog/components.yaml 组件事实源
  catalog/uncataloged.yaml 有意不登记公开类型基线
  templates/agents/       AGENTS 唯一源
  tool/gen_catalog.dart   生成 catalog.g.dart + components.md
  tool/gen_templates.dart 生成 templates.g.dart

scripts/README.md         scripts 运行手册
```

---

## 2. 文档定位表

| 文档 | 主要读者 | 作用 | 什么时候改 | 不要放什么 |
|---|---|---|---|---|
| 根 `README.md` | 包使用者（人/AI） | 第一入口、安装、子包选择 | 改安装方式 / 包边界 / 快速开始 | 完整 API 表、包内部实现 |
| `AGENTS.md` | 仓库 AI | 入口、任务路由、跨包硬规则 | 任务路由 / 跨包规则变化 | 包级详细教程；包级细节链到 `docs/agents/` |
| `CONTRIBUTING.md` | 维护者（人/AI） | 新增 / 修改组件的硬要求 | 组件规范变化 | 具体组件 API |
| `docs/README.md` | 所有人 | 文档总索引 | 新增文档目录 | 具体规则 |
| `docs/documentation-map.md` | 维护者（人/仓库 AI） | 文档定位与整理规则 | 文档结构变化 | 包 API 细节 |
| `docs/conventions.md` | 接入者 / 维护者 | 接入方式与 doctor 规则 | 接入规则 / R1~R9 变化 | 组件目录 |
| `docs/naming.md` | 维护者 / 仓库 AI | 包、文件、类型、成员的命名规则与存量例外 | 命名规则变化 | 组件 API、教程 |
| `docs/ai-contract.md` | 维护者 / 仓库 AI | AI 分层、更新流程、完整性 | catalog / AGENTS 机制变化 | 单个组件教程 |
| `docs/ai-maintainer-prompts.md` | 维护者（人/仓库 AI） | 按场景复制的提示词 | 工作流变化 | 完整规则副本；命令由 `check_prompt_docs.py` 守 |
| `docs/modules/*.md` | 包使用者（人/AI） | 包边界、架构、跨类关系；安装 / 最小用法以包 README 为准，逐参数 API 以 pub.dev API 文档 / 源码为准 | 包架构 / 边界变化 | 逐参数 API 表、安装示例（历史重叠按包逐步收敛） |
| `docs/modules/components.md` | 包使用者（人/AI） | 组件目录 | **只由生成器改** | 手写内容 |
| `docs/agents/*.md` | 仓库 AI | 包级详细规则、首选入口、禁止项（详细源） | 规则 / 入口变化 | 完整教程、历史 |
| `docs/recipes/*.md` | 包使用者（人/AI） | 跨包组合用法 | 多包协作方式变化 | 单包 API 全表 |
| `docs/guides/*.md` | 包使用者（人/AI） | 横向指南（测试策略 / 工程做法） | 指南做法变化 | 单包 API、跨包组合 |
| `docs/migrations/*.md` | 升级用户（人/AI） | 版本迁移 | 发布 breaking change 时新增 | 当前用法教程 |
| `docs/adr/*.md` | 维护者（人/仓库 AI） | 架构决策记录 | 新决策时新增，旧决策不改 | 操作手册 |
| `docs/analysis/*.md` | 维护者 | 某次评审记录 | 评审时新增 | 当前事实源 |
| `docs/feedback/*.md` | 维护者 / 用户 | 问题台账 | 通过 CLI 追加 | 当前 API 文档 |
| `docs/releasing.md` | 维护者（人/仓库 AI） | 发布流程 | 发布流程变化 | 具体版本号 |
| `packages/<pkg>/README.md` | 包使用者（人/AI） | 安装、最小用法、常用配方、限制（用法事实源） | 公开 API / 行为变化 | 跨包组合大全 |
| `packages/<pkg>/example/` | 包使用者（人）/ 仓库 AI | 可运行场景 | 用法变化 / 新场景 | 隐藏内部实现 |
| `scripts/README.md` | 维护者（人/仓库 AI） | 何时跑哪个脚本 | 脚本增删 / 流程变化 | 脚本内部实现 |
| `packages/cli/catalog/components.yaml` | 维护者 / 仓库 AI | 组件事实源 | 组件新增/修改/删除 | 长教程 |
| `packages/cli/templates/agents/` | 维护者 / 仓库 AI | AGENTS 唯一源 | 规则/入口变化 | 完整文档 |
| `packages/cli/catalog/uncataloged.yaml` | 维护者 | 有意不登记公开类型 | 新增子 API 时 | 逃逸登记 |

### `docs/modules/*.md` 与包 README 的分工

- 包 README 是安装、最小用法、常用配方的事实源；逐参数 API 以 pub.dev API 文档 / 源码为准；
- modules 文档只写包边界、架构、跨类关系与设计取舍；需要参数表时链接 README / pub.dev API 文档 / 源码，不再复制；
- 历史 modules 文档里的逐参数表是存量，按包逐步收敛（`ui` / `form` 已收敛）；新增内容不要再复制。

---

### 读者矩阵

| 文档组 | 包使用者(人) | 包使用者(AI) | 维护者(人) | 仓库 AI |
|---|---|---|---|---|
| 根 README / 包 README | ✅ | ✅ | ✅ | ✅ |
| modules / recipes / migrations | ✅ | ✅ | 参考 | 参考 |
| CONTRIBUTING / conventions | 贡献者 | 部分 | ✅ | ✅ |
| agents / ai-contract / prompts | ❌ | 生成摘要 | ✅ | ✅ |
| ADR / analysis | ❌ | ❌ | ✅ | 参考 |
| scripts / catalog / templates | ❌ | 查询结果 | ✅ | ✅ |

### 判断规则

```text
先问“谁在什么任务下需要这条信息”
再问“这条信息应该由谁维护”
最后问“它是事实源，还是生成物 / 投影”
```

---

## 3. 唯一事实源

| 事实 | 唯一源 | 生成物 |
|---|---|---|
| 组件目录 | `packages/cli/catalog/components.yaml` | `catalog.g.dart`、`docs/modules/components.md` |
| AGENTS 片段 | `packages/cli/templates/agents/` | `templates.g.dart` |
| 包版本 | `packages/*/pubspec.yaml` | `release_check` 读取 |
| 包用法 | `packages/<pkg>/README.md` | 无 |
| 参数 API | `packages/<pkg>/lib` 源码 / pub.dev API 文档 | 无 |
| 跨包场景 | `docs/recipes/` | 无 |
| AI 查询内容 | catalog + `explain` renderer | `explain` 输出 |
| 用户问题 | `docs/feedback/`（CLI 维护） | 无 |

**生成物不要手改。**

---

## 4. AI 应该把新信息放哪

### 新增包

先改：

```text
scripts/packages.manifest
  → name / path / runner / root_aggregate / example_test
```

再补：

```text
workspace
pubspec / README / CHANGELOG / LICENSE / .pubignore
example（有真实入口时）
templates/agents/{zh,en}/<feature>.md（init feature）
context.capabilities
docs/modules/README.md
release 约束 / 版本
```

`preflight` / `release_check` 都从 `scripts/packages.manifest` 取包列表。

### 新增组件

```text
packages/cli/catalog/components.yaml
  → name / package / section
  → useFor / dontUseFor
  → teach 判断
  → usage / pitfalls / related（teach）
```

然后：

```text
packages/<pkg>/README.md
packages/<pkg>/example/
```

如果它改变包级规则：

```text
packages/cli/templates/agents/{zh,en}/<feature>.md
```

### 新增禁止项 / 推荐入口

放：

```text
docs/agents/<pkg>.md
packages/cli/templates/agents/{zh,en}/<feature>.md
```

不要只写进 README。

### 新增跨包组合

放：

```text
docs/recipes/
```

并在 `docs/recipes/README.md` 加索引。

### 新增使用指南

放：

```text
docs/guides/<topic>.md
docs/guides/README.md（索引）
```

指南回答「一类工程问题怎么做」，不绑定单个包；单包用法进 modules，跨包组合进 recipes。

### 新增 / 修改命名规则

放：

```text
docs/naming.md（规则 + 存量例外说明）
scripts/naming_baseline.yaml（可放行名字的基线，只减不增）
scripts/check_naming.py（其中可判定的部分）
```

命名规则不进 ADR：ADR 只记录为什么这样定。可放行的存量名字维护在
`scripts/naming_baseline.yaml`，`check_naming.py` 读它并双向检查（漏登记 / 已删除未删行）。

### 新增架构决策

放：

```text
docs/adr/NNNN-kebab-title.md
docs/adr/README.md（索引 + 模板 + 状态词）
```

- ADR 记录决策，不记录当前操作手册；
- **旧 ADR 不改决策**：新决策开新编号，并在旧 ADR 顶部加一行指向新 ADR（被完全覆盖时状态改「已取代」）；
- 编号四位、唯一且递增；退役编号留空不复用（`scripts/check_docs_facts.py` 检查命名、递增与状态行）；
- 新增后同步 `docs/README.md` 的 ADR 索引。

### 新增版本迁移

放：

```text
docs/migrations/
```

并在 `docs/migrations/README.md` 加索引。

### 新增反馈

用 CLI：

```bash
dart run w_tools_cli:w_tools feedback submit --package=<包> --title=<标题> --body-file=<file>
```

不要手改索引。

### 改检查 / 脚本

放：

```text
scripts/README.md
```

只在“何时跑 / 风险”变化时改。

---

## 5. AI 整理文档的硬规则

```text
1. 先判断信息类型，再选文档。
2. 能用 catalog / explain 表达的事实，不要复制成长篇。
3. 不重复维护第二份组件清单。
4. 不改历史迁移 / ADR / analysis，除非修链接或错字。
5. 不写“已发布 / 待发布 x.y.z”；版本以 pubspec 为准。
6. 不手改生成物。
7. 新增公开 API 必须判断：catalog 还是 uncataloged。
8. 规则变化必须同步 AGENTS 模板。
9. 至少更新一个可运行 example 或测试，避免只写文档。
10. 改完跑 check_docs / preflight。
11. 新增顶层文档 / 子目录 README / ADR，必须加进 `docs/README.md` 索引（check_docs_facts 会拦）。
12. 在 `docs/agents/README.md` 写的首选入口，必须能在该包规则页找到（check_agents_consistency 会拦）。
```

---

## 6. 更新顺序

```text
1. 代码 + 测试
2. catalog / templates 源文件
3. 生成器
4. README / example
5. docs 索引
6. check_docs
7. preflight --with-tests
```

不要反过来“先写文档，再补代码”。

---

## 7. 自动检查

**门禁清单的唯一来源是 [`scripts/README.md`](../scripts/README.md)** —— 这里只给最常用的入口，
不重复维护完整清单。历史上这里维护过一张清单，漏过 `check_feedback.sh` /
`check_deprecations.py` / `check_style_literals.py`，于是“文档说有哪些检查”和
“CI 实际跑什么”分叉了。

```text
提交前 / 合并前：bash scripts/preflight.sh --with-tests
只改文档：      bash scripts/check_docs.sh
发布前：        bash scripts/release_check.sh --strict
```

`check_docs.sh` 是 `preflight` 的子集，**不要只跑它就说全仓通过**。

---

## 8. 判断“文档该不该改”的问题

```text
1. 公开 API 变了吗？
2. 默认行为变了吗？
3. 新组件应该 teach 吗？
4. 规则 / 禁止项变了吗？
5. 用户会需要新场景吗？
6. 旧写法还在被推荐吗？
7. 生成物是否已经同步？
```

如果 1 / 2 / 3 / 4 / 5 / 6 任一为“是”，通常就需要改文档；不能只跑测试。

---

## 9. 相关文档

- [文档总索引](README.md)
- [AI 使用契约](ai-contract.md)
- [维护者 AI 提示词](ai-maintainer-prompts.md)
- [模块索引](modules/README.md)
- [Agent 索引](agents/README.md)
- [scripts 运行手册](../scripts/README.md)
