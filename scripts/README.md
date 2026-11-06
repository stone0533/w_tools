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
format / analyze / docs（含符号 / 已删除 API / 安装版本）
公开类型 catalog / 弃用 / 命名 / 风格
catalog / templates 生成物新鲜度
release check
CI 包矩阵与门禁步骤 ↔ manifest / preflight 一致性
全部包 + example + root 测试 + root example 测试 + 模板编译
```

CI 的静态门禁直接调用 `preflight.sh`（不再手抄步骤），包矩阵由
`scripts/ci_matrix.py` 从 `packages.manifest` 生成。两边不再各维护一份清单。
重量级 job（umbrella / packages / min_sdk）由 `changes` job 按路径门控：纯文档改动只跑
轻量 `docs` job（`check_docs.sh`），不安装 Flutter；只改 `scripts/` 时跑 umbrella 的静态门禁
+ docs，不跑 15 个包矩阵。分支保护只要求最后的 `Required checks` 聚合 job，避免 required
check 名字随包矩阵变化。

---

## 脚本分类

### 总门禁

| 脚本 | 作用 | 何时跑 |
|---|---|---|
| `preflight.sh` | 全仓门禁总入口（CI 直接调用它） | 提交前 / 合并前 |
| `check_docs.sh` | 文档与 AI 资产检查总入口（链接 / 旧命令 / 符号 / 已删除 API / 安装版本，每步会打名字） | 只改文档时可单独跑 |
| `ci_matrix.py` | 从 `packages.manifest` 生成 CI 包矩阵；`--check` 查漂移 | preflight / CI matrix job |
| `packages.manifest` | 包名 / 路径 / runner / root / example 的单一清单 | 新增包 / 改测试入口 |

`check_docs.sh` 是 `preflight` 的子集，**不要只跑它就说全仓通过**。

`packages.manifest` 是 CI 矩阵、preflight、release_check 的共同来源；新增包时先改它。

### 文档 / AI 契约

| 脚本 | 作用 | 调用方 |
|---|---|---|
| `check_doc_symbols.py` | 文档 `W*` 符号 / 成员是否存在，且 import 的包（根 barrel / 子包 / package 级 re-export）按 barrel 真正导出能提供该符号；用到未导出的内部类型会报错（含 root `README.md` / `AGENTS.md` / `packages/*/AGENTS.md`、`docs/naming.md` 行内示例） | check_docs / preflight |
| `check_docs_snippets.py` | 已证伪 API / components 表格列数 | check_docs |
| `check_docs_duplicates.py` | `docs/modules` 与包 README 不再复制同一段 dart 示例 | check_docs |
| `check_docs_versions.py` | 文档不得声明已发布/待发布版本 | check_docs |
| `check_async_docs.py` | async 公开文档旧 API | check_docs |
| `check_package_docs.py` | 当前文档安装约束（必须是 caret，且下界 == 当前版本；非 caret 直接失败）/ 跨包示例 / example 链接 | check_docs |
| `check_docs_facts.py` | 规模数字（从 pubspec 推导）/ 文档索引完整性（含每个 ADR 在 `docs/README.md` 留行）/ ADR 编号、状态、索引一致、补充日期 / doctor 规则表一致性 / 旧命令 | check_docs |
| `check_agents_consistency.py` | `docs/agents` 索引与规则页的入口名 + 高频规则短语一致 | check_docs |
| `check_prompt_docs.py` | 维护者提示词的命令可执行（脚本 / flag / cwd / 占位符 / 场景编号） | check_docs |
| `check_public_catalog.py` | 公开类型 → catalog 反向检查（双向：新类型要登记，基线里的旧名字也要删） | preflight |
| `check_catalog_anchors.py` | catalog 的 `docsAnchor` 必须能在 `docs/modules/*_module.md` 的标题里找到；提前到静态 preflight | preflight |
| `check_catalog_symbols.py` | catalog `usage` / `useFor` / `related` 里的 `W*` / `W*.member` 必须真实存在于公开 API | preflight |
| `check_public_api_diff.py` | 公开 API 快照 diff：删除 / 类型/可空性 / 方法 / 构造器变化必须出现在当前版本 CHANGELOG 的 Breaking/Removed 或 migration（构造器可选参数可记 Added） | preflight |
| `check_test_imports.py` | `package:w_tools_<pkg>/src/...` 只允许出现在 `test/internal/`；当前先覆盖 ui | preflight |
| `check_git_sync.sh` | 当前分支有 upstream 且 ahead/behind 都为 0；`release_check --strict` 调用 | release_check / 发布前 |
| `check_removed_api.py` | 已删除 API 是否还在推荐文档 / catalog（含 root + `packages/*/AGENTS.md` + `catalog/components.yaml`） | check_docs / preflight |
| `check_naming.py` | 规则在 `docs/naming.md`：公开 `W*Config` / 前缀例外读 `naming_baseline.yaml`；Dart 文件名 snake_case | preflight |

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

- `check_doc_symbols.py`：正则匹配符号和成员（扫 ```dart 代码块；`docs/naming.md` 额外扫行内代码；
  正文里的组件清单 / 行内 `` `WXxx` `` 不参与，别指望它发现散文里的旧名字）；
- `check_docs_snippets.py`：只拦截已知错误写法；
- `check_public_catalog.py`：基于 export/part 的静态扫描 + `uncataloged.yaml` 基线（双向）；
- `check_naming.py`：只认 barrel 导出的公开名字（`hide` / `lib/src` 内部实现不参与），
  例外读 `naming_baseline.yaml`；
- `check_docs_facts.py`：规模数字与索引完整性，不校验 API 细节；
- `check_agents_consistency.py`：比入口名 + 高频规则短语，不做全文语义比对；
- `check_package_docs.py`：只校验 caret 下界与主版本（非 caret 直接失败），不校验具体 patch；
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


### 公开 API 快照

`scripts/api_snapshots/w_tools_<pkg>-<version>.txt` 是上一次发布版本的公开 API 基线，
由脚本生成，不要手改：

```bash
python3 scripts/check_public_api_diff.py \
  --snapshot-from /tmp/<pkg>-<version> \
  --package <pkg> --version <version>
```

发布新版本后更新对应快照；否则 `preflight` 的 `public api diff` 会一直对比旧版本。
