# W Tools AI 使用契约

本文是 w_tools 面向 AI 的统一契约：**AI 怎么发现组件、怎么查用法、代码变更后怎么更新、怎么检查有没有漏。**

它同时服务两类读者：

- **消费方 AI**：通过 `init` 生成的 `AGENTS.md` 和 CLI 查询工作；
- **仓库维护者 / 仓库内 AI**：改代码、改 catalog、改模板、跑门禁。

核心原则：

```text
AGENTS 指路
explain 教学
catalog 提供事实
README/example 提供完整参考
```

---

## 1. 为什么需要这层

w_tools 是 monorepo，子包多、版本独立、API 会演进。

如果只靠 README：

- AI 不知道当前项目装了哪些能力；
- AI 容易凭记忆写旧 API；
- 文档和代码容易漂移；
- 同一问题在多个包重复解释。

所以把“AI 需要知道的事实”拆成四层：

| 层 | 作用 | 主要文件 |
|---|---|---|
| catalog | 组件事实源 | [`packages/cli/catalog/components.yaml`](../packages/cli/catalog/components.yaml) |
| explain | 按需教学 | [`packages/cli/lib/src/explain/render_explain.dart`](../packages/cli/lib/src/explain/render_explain.dart) |
| AGENTS | 入口规则 / 路由 | [`packages/cli/templates/agents/`](../packages/cli/templates/agents/) |
| README / example | 完整说明与真实场景 | `packages/<pkg>/README.md`、`packages/<pkg>/example/` |

---

## 2. 消费方 AI 的工作流

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

“全不全”拆成六个维度。

### 5.1 可发现性

```text
公开类型 → catalog
```

由 [`scripts/check_public_catalog.py`](../scripts/check_public_catalog.py) 检查：

- 扫描包导出的公开类型；
- 减去 catalog 已登记；
- 与 `uncataloged.yaml` 基线比较；
- 新公开类型未登记则失败。

基线重建：

```bash
python3 scripts/check_public_catalog.py --write
```

注意：这是**基线**，不是自动证明。新增类型仍然要人工判断应该进 catalog 还是基线。

### 5.2 教学覆盖

由 [`packages/cli/test/ai_contract_test.dart`](../packages/cli/test/ai_contract_test.dart) 检查：

- 至少覆盖主要入口组件；
- 每个库包至少一个 `teach`；
- `teach` 组件必须有 usage / pitfalls / related；
- `related` 可解析；
- prompt 必须包含：
  - `用法：`
  - `注意：`
  - `相关：`

### 5.3 路由覆盖

同一测试检查：

- 每个 `InitFeature` 有 zh / en AGENTS 模板；
- 所有模板非空；
- 不出现旧命令：
  ```text
  w_tools_cli:context
  w_tools_cli:list
  w_tools_cli:explain
  ```

### 5.4 文档覆盖

由 [`scripts/check_package_docs.py`](../scripts/check_package_docs.py) 检查：

- 每个子包有 README；
- README 安装主版本与 pubspec 一致；
- 有 `example/` 的包必须在 README 提到示例。

### 5.5 生成物新鲜度

```bash
dart run tool/gen_catalog.dart --check
dart run tool/gen_templates.dart --check
```

### 5.6 查询正确性

- [`packages/cli/test/cli_test.dart`](../packages/cli/test/cli_test.dart)
- [`packages/cli/test/catalog_test.dart`](../packages/cli/test/catalog_test.dart)
- [`packages/cli/test/context_test.dart`](../packages/cli/test/context_test.dart)
- [`packages/async/test/docs_examples_test.dart`](../packages/async/test/docs_examples_test.dart)

覆盖：

- `list` / `explain` / `context`；
- text / json / prompt；
- usage / pitfalls / related；
- 别名精确命中；
- context capabilities；
- README 快速开始。

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

- 加入根 workspace；
- 补 README；
- 有 example 则补 example；
- 如果是 init feature，补 `templates/agents/{zh,en}/<feature>.md`；
- 补 `context.capabilities`；
- 补 `docs/modules` 索引；
- 补 release 约束 / 版本。

---

## 7. 删除 / 废弃 API 的流程

```text
1. 删除或废弃代码
2. 从 catalog 移除条目，或改 aliases / usage / pitfalls
3. 检查 related 是否还有引用
4. 更新 AGENTS 模板（明确新入口）
5. 更新 README / migration
6. 更新 example
7. 跑 check_removed_api / check_docs / preflight
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
- `uncataloged.yaml` 是“有意不登记”清单，仍应定期 review；
- `usage` 是最短片段，不保证全量编译；
- 39 个非 teach 组件仍只有 useFor / dontUseFor；
- `context.capabilities` 是静态映射，新增包需同步；
- Markdown 全量代码块编译尚未开启，只检查关键示例。

---

## 10. PR 检查表

```text
[ ] 公开 API 变化已反映到 catalog
[ ] teach 组件的 usage / pitfalls / related 完整
[ ] related 可解析
[ ] AGENTS 模板已更新
[ ] README 已更新
[ ] example 已更新
[ ] 生成器已跑
[ ] ai_contract / cli / docs / preflight 通过
[ ] 破坏性变更已写 migration
```

---

## 11. 相关文档

- [CLI 使用规则](agents/cli.md)
- [Async 使用规则](agents/async.md)
- [组件目录](modules/components.md)
- [模块索引](modules/README.md)
- [Agent 文档索引](agents/README.md)
- [Async 5.0 迁移](migrations/async-5.0.md)
- [根 AGENTS](../AGENTS.md)
