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

这一条覆盖：

```text
format / analyze / docs / AI 契约（含 feedback）
公开类型 catalog / 弃用 / 风格
release check
全部包 + example + root 测试 + root example 测试 + 模板编译
```

---

## 脚本分类

### 总门禁

| 脚本 | 作用 | 何时跑 |
|---|---|---|
| `preflight.sh` | 全仓门禁总入口 | 提交前 / 合并前 |
| `check_docs.sh` | 文档与 AI 资产检查总入口 | 只改文档时可单独跑 |
| `packages.manifest` | 包名 / 路径 / runner / root / example 的单一清单 | 新增包 / 改测试入口 |

`check_docs.sh` 是 `preflight` 的子集，**不要只跑它就说全仓通过**。

`packages.manifest` 是 preflight / release_check 的包清单来源；新增包时先改它。

### 文档 / AI 契约

| 脚本 | 作用 | 调用方 |
|---|---|---|
| `check_doc_symbols.py` | 文档 `W*` 符号是否存在 | preflight |
| `check_docs_snippets.py` | 已证伪 API / components 表格列数 | check_docs |
| `check_docs_versions.py` | 文档不得声明已发布/待发布版本 | check_docs |
| `check_async_docs.py` | async 公开文档旧 API | check_docs |
| `check_package_docs.py` | 子包 README 版本 / example 链接 | check_docs |
| `check_docs_facts.py` | 当前文档事实（包数量 / 旧命令） | check_docs |
| `check_public_catalog.py` | 公开类型 → catalog 反向检查 | preflight |
| `check_removed_api.py` | 已删除 API 是否还在推荐文档 | preflight |

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
| `packages/cli/tool/check_templates_compile.dart` | init 模板生成后能否通过 Flutter analyze | `preflight --with-tests` |

### 检查边界

这些是启发式检查，不是完整编译器/analyzer：

- `check_doc_symbols.py`：正则匹配符号和成员；
- `check_docs_snippets.py`：只拦截已知错误写法；
- `check_public_catalog.py`：基于 export/part 的静态扫描 + `uncataloged.yaml` 基线；
- `check_docs_facts.py`：只校验当前文档的包数量/聚合/旧命令规则。

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
