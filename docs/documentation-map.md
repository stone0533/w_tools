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

## 1. 一张图

```text
根 README                 第一入口：安装 / 子包选择 / 快速开始
CONTRIBUTING.md           改组件的硬性要求

docs/
  README.md               文档总索引
  documentation-map.md    本文：文档定位 + AI 整理规则
  conventions.md          接入约定 / doctor R1~R9
  releasing.md            发版流程
  figma-cli.md            Figma CLI 契约
  ai-contract.md          AI 分层、更新、完整性检查
  ai-maintainer-prompts.md 维护者按场景使用的 AI 提示词

  modules/                使用者：包职责 / API / 用法
    components.md         生成物：组件目录表
  agents/                 AI/维护者：首选入口、硬规则、禁止项
  recipes/                跨包组合场景
  migrations/             版本迁移（历史）
  adr/                    架构决策（历史）
  release/                发布记录（历史）
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

| 文档 | 受众 | 作用 | 什么时候改 | 不要放什么 |
|---|---|---|---|---|
| 根 `README.md` | 新用户 | 第一入口、安装、子包选择 | 改安装方式 / 包边界 / 快速开始 | 完整 API 表、包内部实现 |
| `CONTRIBUTING.md` | 贡献者 | 新增 / 修改组件的硬要求 | 组件规范变化 | 具体组件 API |
| `docs/README.md` | 所有人 | 文档总索引 | 新增文档目录 | 具体规则 |
| `docs/documentation-map.md` | 维护者 / AI | 文档定位与整理规则 | 文档结构变化 | 包 API 细节 |
| `docs/conventions.md` | 消费方 / 维护者 | 接入方式与 doctor 规则 | 接入规则 / R1~R9 变化 | 组件目录 |
| `docs/ai-contract.md` | 维护者 / AI | AI 分层、更新流程、完整性 | catalog / AGENTS 机制变化 | 单个组件教程 |
| `docs/ai-maintainer-prompts.md` | 维护者 | 按场景复制的提示词 | 工作流变化 | 完整规则副本 |
| `docs/modules/*.md` | 使用者 | 包职责、API、用法 | 包的公开行为变化 | 维护者内部流程 |
| `docs/modules/components.md` | 使用者 / AI | 组件目录 | **只由生成器改** | 手写内容 |
| `docs/agents/*.md` | 仓库 AI | 首选入口、硬规则、禁止项 | 规则 / 入口变化 | 完整教程、历史 |
| `docs/recipes/*.md` | 使用者 / AI | 跨包组合用法 | 多包协作方式变化 | 单包 API 全表 |
| `docs/migrations/*.md` | 升级用户 | 版本迁移 | 发布 breaking change 时新增 | 当前用法教程 |
| `docs/adr/*.md` | 维护者 | 架构决策记录 | 新决策时新增，旧决策不改 | 操作手册 |
| `docs/release/*.md` | 维护者 | 某次发布记录 | 发布时新增 | 当前版本声明 |
| `docs/analysis/*.md` | 维护者 | 某次评审记录 | 评审时新增 | 当前事实源 |
| `docs/feedback/*.md` | 维护者 / 用户 | 问题台账 | 通过 CLI 追加 | 当前 API 文档 |
| `docs/releasing.md` | 维护者 | 发布流程 | 发布流程变化 | 具体版本号 |
| `docs/figma-cli.md` | 工具使用者 | Figma CLI 契约 | 命令/输出契约变化 | 页面实现教程 |
| `packages/<pkg>/README.md` | 该包用户 | 安装、API、最小用法、限制 | 公开 API / 行为变化 | 跨包组合大全 |
| `packages/<pkg>/example/` | 该包用户 | 可运行场景 | 用法变化 / 新场景 | 隐藏内部实现 |
| `scripts/README.md` | 维护者 | 何时跑哪个脚本 | 脚本增删 / 流程变化 | 脚本内部实现 |
| `packages/cli/catalog/components.yaml` | 维护者 / AI | 组件事实源 | 组件新增/修改/删除 | 长教程 |
| `packages/cli/templates/agents/` | 维护者 / AI | AGENTS 唯一源 | 规则/入口变化 | 完整文档 |
| `packages/cli/catalog/uncataloged.yaml` | 维护者 | 有意不登记公开类型 | 新增子 API 时 | 逃逸登记 |

---

## 3. 唯一事实源

| 事实 | 唯一源 | 生成物 |
|---|---|---|
| 组件目录 | `packages/cli/catalog/components.yaml` | `catalog.g.dart`、`docs/modules/components.md` |
| AGENTS 片段 | `packages/cli/templates/agents/` | `templates.g.dart` |
| 包版本 | `packages/*/pubspec.yaml` | `release_check` 读取 |
| 包用法 | `packages/<pkg>/README.md` | 无 |
| 跨包场景 | `docs/recipes/` | 无 |
| AI 查询内容 | catalog + `explain` renderer | `explain` 输出 |
| 用户问题 | `docs/feedback/`（CLI 维护） | 无 |

**生成物不要手改。**

---

## 4. AI 应该把新信息放哪

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

### 新增架构决策

放：

```text
docs/adr/
```

ADR 记录决策，不记录当前操作手册。

### 新增版本迁移

放：

```text
docs/migrations/
```

并在 `docs/migrations/README.md` 加索引。

### 新增发布记录

放：

```text
docs/release/
```

不要改写历史发布记录。

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
4. 不改历史迁移 / ADR / release / analysis，除非修链接或错字。
5. 不写“已发布 / 待发布 x.y.z”；版本以 pubspec 为准。
6. 不手改生成物。
7. 新增公开 API 必须判断：catalog 还是 uncataloged。
8. 规则变化必须同步 AGENTS 模板。
9. 至少更新一个可运行 example 或测试，避免只写文档。
10. 改完跑 check_docs / preflight。
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

| 检查 | 覆盖 |
|---|---|
| `scripts/check_docs.sh` | 链接 / 旧命令 / 片段 / README / 版本声明 |
| `scripts/check_doc_symbols.py` | 文档里的 W* 符号 |
| `scripts/check_removed_api.py` | 已删除 API 残留 |
| `scripts/check_public_catalog.py` | 公开类型 → catalog |
| `scripts/check_package_docs.py` | README 版本 / example |
| `scripts/check_async_docs.py` | async 旧 API |
| `packages/cli/test/ai_contract_test.dart` | teach / prompt / AGENTS feature |
| `tool/gen_catalog.dart --check` | catalog 生成物 |
| `tool/gen_templates.dart --check` | AGENTS 生成物 |
| `scripts/preflight.sh --with-tests` | 全仓最终门禁 |

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
