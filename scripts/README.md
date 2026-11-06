# scripts 运行手册

本文只回答三个问题：

```text
这个脚本做什么？
什么时候该跑？
被谁调用？
```

详细规则不在这里重复，见 [AI 使用契约](../docs/ai-contract.md)、
[接入约定](../docs/conventions.md)、[发布流程](../docs/releasing.md)。

---

## 只记一条命令

日常提交前 / 合并前：

```bash
bash scripts/preflight.sh --with-tests
```

只跑一个包（静态门禁 + 该包测试 + example）：

```bash
bash scripts/preflight.sh --package ui
```

这一条覆盖：

```text
format / analyze / docs / AI 契约（含 feedback）
公开类型 catalog / 弃用 / 风格
catalog / templates 生成物新鲜度
release check
CI 包矩阵与门禁步骤 ↔ manifest / preflight 一致性
全部包 + example + root 测试 + root example 测试 + 模板编译
```

CI 的静态门禁直接调用 `preflight.sh`（不再手抄步骤），包矩阵由
`scripts/ci_matrix.py` 从 `packages.manifest` 生成。两边不再各维护一份清单。
重量级 job（packages / min-sdk）由 `changes` job 按路径门控：纯文档改动只跑 umbrella。

---

## 脚本分类

### 总门禁

| 脚本 | 作用 | 何时跑 |
|---|---|---|
| `preflight.sh` | 全仓门禁总入口（CI 直接调用它） | 提交前 / 合并前 |
| `check_docs.sh` | 文档与 AI 资产检查总入口（每步会打名字） | 只改文档时可单独跑 |
| `ci_matrix.py` | 从 `packages.manifest` 生成 CI 包矩阵；`--check` 查漂移 | preflight / CI matrix job |
| `packages.manifest` | 包名 / 路径 / runner / root / example 的单一清单 | 新增包 / 改测试入口 |

`check_docs.sh` 是 `preflight` 的子集，**不要只跑它就说全仓通过**。

`packages.manifest` 是 CI 矩阵、preflight、release_check 的共同来源；新增包时先改它。

### 文档 / AI 契约

| 脚本 | 作用 | 调用方 |
|---|---|---|
| `check_doc_symbols.py` | 文档 `W*` 符号是否存在（含 root `README.md` / `AGENTS.md`） | preflight |
| `check_docs_snippets.py` | 已证伪 API / components 表格列数 | check_docs |
| `check_docs_duplicates.py` | `docs/modules` 与包 README 不再复制同一段 dart 示例 | check_docs |
| `check_docs_versions.py` | 文档不得声明已发布/待发布版本 | check_docs |
| `check_async_docs.py` | async 公开文档旧 API | check_docs |
| `check_package_docs.py` | 子包 + 根 README 安装约束（caret 语义）/ example 链接 | check_docs |
| `check_docs_facts.py` | 规模数字（从 pubspec 推导）/ 文档索引完整性 / ADR 编号与状态 / doctor 规则表一致性 / 旧命令 | check_docs |
| `check_agents_consistency.py` | `docs/agents` 索引与规则页的入口名一致 | check_docs |
| `check_prompt_docs.py` | 维护者提示词的命令可执行（脚本 / flag / cwd / 占位符 / 场景编号） | check_docs |
| `check_public_catalog.py` | 公开类型 → catalog 反向检查 | preflight |
| `check_removed_api.py` | 已删除 API 是否还在推荐文档（含 root + `packages/*/AGENTS.md`） | preflight |

### API / 风格

| 脚本 | 作用 | 何时跑 |
|---|---|---|
| `check_deprecations.py` | `@Deprecated` 的 `remove-in` 是否到期 | preflight |
| `list_removals.py` | 列出所有待删除弃用项 | 准备大版本 |
| `check_style_literals.py` | form/toast/async 默认样式禁止硬编码颜色 | preflight |
| `check_feedback.sh` | `docs/feedback/` 台账检查 | check_docs |

### 发布

| 脚本 | 作用 | 注意 |
|---|---|---|
| `release_check.sh` | 版本 / CHANGELOG / 根约束 / README / pub.dev 漂移 | 发布前先跑 `--strict` |
| `publish_package.sh` | 在去掉 workspace 的暂存副本里发布 | **真正发布会执行，不是 dry-run** |
| `install-gh.sh` | GitHub CLI 安装 / 登录向导 | 一次性 |

### 包内检查

| 工具 | 作用 | 何时跑 |
|---|---|---|
| `packages/cli/tool/gen_catalog.dart --check` | `catalog.g.dart` / `components.md` 与 `components.yaml` 一致 | preflight / 改 catalog |
| `packages/cli/tool/gen_templates.dart --check` | `templates.g.dart` 与 `templates/` 一致 | preflight / 改 templates |
| `packages/cli/tool/check_templates_compile.dart` | init 模板生成后能否通过 Flutter analyze | `preflight --with-tests` |
| `packages/cli/test/ai_contract_test.dart` | teach / prompt / AGENTS feature 契约 | `preflight --with-tests` |

### 检查边界

这些是启发式检查，不是完整编译器/analyzer：

- `check_doc_symbols.py`：正则匹配符号和成员（只扫 ```dart 代码块）；
- `check_docs_snippets.py`：只拦截已知错误写法；
- `check_public_catalog.py`：基于 export/part 的静态扫描 + `uncataloged.yaml` 基线；
- `check_docs_facts.py`：规模数字与索引完整性，不校验 API 细节；
- `check_agents_consistency.py`：只比入口名，不比措辞；
- `check_package_docs.py`：只校验 caret 下界与主版本，不校验具体 patch；
- `ci_matrix.py --check`：查清单是否同源，不查 workflow 语义。

发布前：

```bash
bash scripts/release_check.sh --strict
bash scripts/publish_package.sh packages/<pkg> --dry-run
```

真正发布：

```bash
bash scripts/publish_package.sh packages/<pkg>
bash scripts/publish_package.sh .
```

不要直接：

```bash
flutter pub publish
```

原因见 [`publish_package.sh`](publish_package.sh) 顶部说明。

---

## 推荐工作流

### 改代码

```bash
bash scripts/preflight.sh --with-tests
```

### 只改文档

```bash
bash scripts/check_docs.sh
```

### 改公开 API

```bash
cd packages/cli
dart run tool/gen_catalog.dart
cd ../..
python3 scripts/check_public_catalog.py
bash scripts/preflight.sh --with-tests
```

### 改弃用

```bash
python3 scripts/list_removals.py
python3 scripts/check_deprecations.py
```

### 发布前

```bash
bash scripts/release_check.sh --strict
bash scripts/release_check.sh --online
bash scripts/publish_package.sh packages/<pkg> --dry-run
```

### 真正发布

```bash
bash scripts/publish_package.sh packages/<pkg>
bash scripts/publish_package.sh .
```

---

## 不要做

- 不要直接 `flutter pub publish`；
- 不要只跑 `check_docs.sh` 就认为全仓通过；
- 不要手改 `catalog.g.dart` / `templates.g.dart` / `components.md`；
- 不要为了通过 `check_public_catalog.py` 直接 `--write` 基线，先 review 新类型；
- 不要把 `publish_package.sh` 当 dry-run 使用。

---

## 相关文档

- [AI 使用契约](../docs/ai-contract.md)
- [维护者 AI 提示词](../docs/ai-maintainer-prompts.md)
- [接入约定](../docs/conventions.md)
- [发布流程](../docs/releasing.md)
- [CLI 使用](../packages/cli/README.md)
- [组件目录源](../packages/cli/catalog/components.yaml)
- [模板生成器](../packages/cli/tool/gen_templates.dart)
- [目录生成器](../packages/cli/tool/gen_catalog.dart)
