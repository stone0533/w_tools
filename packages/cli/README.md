# w_tools_cli

`w_tools` 的接入工具（纯 Dart，不依赖 Flutter）。

它解决三类问题：

```text
接入：init      把约定装进项目
检查：doctor    扫出不合规的依赖 / import / 配置
学习：context   list   explain
```

---

## 5 分钟上手

安装到消费方项目：

```yaml
dev_dependencies:
  w_tools_cli: ^1.6.0
```

```bash
dart run w_tools_cli:init       # 1. 生成 toolkit / UI 规范 / AGENTS / doctor 配置
dart run w_tools_cli:doctor     # 2. 检查是否遵守接入约定
dart run w_tools_cli:list 表单   # 3. 找现成组件
dart run w_tools_cli:context --format=prompt   # 4. 给 AI 项目事实
```

典型结果：

```text
init  → 生成 lib/app/w/toolkit.dart、AGENTS.md、.w_tools_doctor.yaml
doctor → 0 error / 0 warning 才算通过
```

---

## 命令怎么选

| 场景 | 命令 |
|---|---|
| 第一次接入 | `init` |
| 接入后检查 / CI | `doctor` |
| 找现成组件 | `list` |
| 看某个组件怎么用 | `explain` |
| 给 AI 项目上下文 | `context --format=prompt` |
| 只检查不写文件 | `init --check` |
| 检查模板是否过期 | `init --check-drift` |
| 升级 CLI 后刷新生成物 | `init --force` |

命令入口都是：

```bash
dart run w_tools_cli:<command> --help
```

---

## init

```bash
dart run w_tools_cli:init
```

生成：

```text
lib/app/w/toolkit.dart             本项目能力清单（聚合入口）
.w_tools_doctor.yaml               doctor 配置（默认值与内置一致）
AGENTS.md / CLAUDE.md / ...        w_tools 指令片段（标记块）
lib/app/ui/                        页面规范（AppBars / AppBoxes / AppButtons / AppCard / AppScaffold）
lib/app/design_system/README.md    暂存层规则
```

`init` 不会修改 `pubspec.yaml`，只打印需要加入的依赖片段。

### Profile

| 参数 | 能力 |
|---|---|
| `--profile=minimal` | core |
| `--profile=ui` | core + ui + toast |
| `--profile=api` | core + api |
| `--profile=full` | core + app + form + ui + api + toast + qr + async（默认） |

单项覆盖：

```bash
dart run w_tools_cli:init --profile=ui
dart run w_tools_cli:init --no-ui
dart run w_tools_cli:init --no-async
dart run w_tools_cli:init --no-form
dart run w_tools_cli:init --no-app
dart run w_tools_cli:init --no-api
dart run w_tools_cli:init --no-toast
dart run w_tools_cli:init --no-qr
dart run w_tools_cli:init --map         # 会引入 google_maps_flutter
dart run w_tools_cli:init --no-map      # 显式关闭（默认关）
# --with-map 仍可用，等同 --map
```

### 指令文件目标

```bash
dart run w_tools_cli:init --targets=agents,claude --lang=en
```

支持：

```text
agents   AGENTS.md
claude   CLAUDE.md
cursor   .cursor/rules/w_tools.mdc
copilot  .github/copilot-instructions.md
```

默认值可以写在 `.w_tools_doctor.yaml` 的 `ai.targets` / `ai.language`。

`--no-instructions` 优先于 `--targets`；`--no-ui` 只关闭页面 UI 与 `w_tools_ui`，不会自动移除 `w_tools_toast`。

切换 profile / targets 后，不再生成的旧文件会在 `stale` 中提示，但不会自动删除。

### 检查模式

```bash
dart run w_tools_cli:init --check         # 只报告缺失；内容不同提示但不失败
dart run w_tools_cli:init --check-drift   # 模板过期也失败
```

CI 想追踪模板更新时用 `--check-drift`。

---

## doctor

```bash
dart run w_tools_cli:doctor
```

常见格式：

```bash
dart run w_tools_cli:doctor --format=markdown   # 贴 PR / AI
dart run w_tools_cli:doctor --json              # CI
dart run w_tools_cli:doctor --strict            # warning 也失败
```

规则：

| id | 级别 | 内容 |
| --- | --- | --- |
| R1 | error | `dependencies` 里出现聚合包 `w_tools` |
| R2 | error | 业务代码直接 import / export `package:w_tools_*`（聚合入口、`lib/app/ui/`、暂存层除外） |
| R3 | warn | 业务层硬编码语义色（`colors.palette` 为空时跳过） |
| R4 | error | 设计系统 import 了 `data/` / `modules/` / `routes/` / `services/` |
| R5 | warn | 暂存层文件缺 `// STAGED:` 标记 |
| R6 | warn | 禁用单位 `.h` / `.r`（项目专用，默认关，`rules.R6: true` 打开） |
| R7 | error | toolkit 的 `export` 与 pubspec 依赖不一致 |
| R8 | warn | 生成物由旧版 `w_tools_cli` 生成 |
| R9 | 配置 | 项目禁用 API（`banned`；默认空） |

只跑部分规则：

```bash
dart run w_tools_cli:doctor --only=R1,R2,R9
dart run w_tools_cli:doctor --include-tests
```

### 项目禁用 API（R9）

```yaml
banned:
  - id: no-wform-showbottomsheet
    pattern: 'WForm\.showBottomSheet'
    mode: regex
    use: 'AppForm.showBottomSheet'
    reason: '包内没有这个 API'
    level: warn
    paths: ['lib/app/modules/**']
    ignore: ['lib/app/ui/**']
```

`mode` 支持 `literal` / `regex`，默认 `literal`。
`paths` / `ignore` 支持 `*` / `**`。

行级豁免：

```dart
// w_tools:ignore R9 reason: design-system fallback
Image.asset('logo.png');
```

文件级：

```dart
// w_tools:ignore-file R9 reason: generated UI
```

没有 `reason:` 的豁免不生效。

> R9 是文本级检查：整行注释和行尾 `//` 注释会跳过，但字符串仍可能命中；
> 需要精确排除时用 `paths` / `ignore` / inline ignore。

### 配置

```bash
dart run w_tools_cli:doctor --print-config    # 打印默认配置
dart run w_tools_cli:doctor --write-config    # 写入 .w_tools_doctor.yaml
```

`--json` 的 issue 带可选 `fix`：

```json
{"kind": "run",  "command": "dart run w_tools_cli:init --force"}
{"kind": "edit", "file": "pubspec.yaml", "path": "dependencies.w_tools_core", "value": "any"}
```

---

## context / list / explain

### context

```bash
dart run w_tools_cli:context
dart run w_tools_cli:context --format=prompt --max-tokens=1500
dart run w_tools_cli:context --format=json
```

输出项目事实：依赖、toolkit 导出、暂存层、规则与检查结果。

JSON 顶层包含：

```json
{
  "schema": "w_tools.context",
  "schemaVersion": 1
}
```

契约策略：

- 新增字段属于兼容变更，不 bump `schemaVersion`。
- 消费方必须忽略未知字段。
- 删除 / 重命名 / 改类型 / 改语义才 bump。
- v1 结构见 [`schema/context.v1.json`](schema/context.v1.json)。

### list

```bash
dart run w_tools_cli:list             # 列出全部组件
dart run w_tools_cli:list 下拉        # 按关键词搜索
dart run w_tools_cli:list --format=json
```

### explain

```bash
dart run w_tools_cli:explain WImage
dart run w_tools_cli:explain WFormDropdown
```

输出用途、反例、import、文档；项目配置了 `banned` 时会提示禁用项和替代方案。
`banned` 读取 `--root` 或当前工作目录的 `.w_tools_doctor.yaml`。

---

## 给 AI 的工作流

```bash
dart run w_tools_cli:context --format=prompt   # 先拿事实
dart run w_tools_cli:list <关键词>              # 找组件
dart run w_tools_cli:explain <组件名>           # 看用法 / 反例
dart run w_tools_cli:doctor --json             # 写完自检
```

`init` 生成的 `AGENTS.md` 已包含这条闭环。生成物头部带
`generated by w_tools_cli x.y.z`，R8 会检查是否过期。

---

## 升级与重新生成

CLI 模板会随版本变化。升级后执行：

```bash
flutter pub upgrade w_tools_cli

dart run w_tools_cli:init --check-drift
# 有 drift 时再覆盖生成物
dart run w_tools_cli:init --force
dart run w_tools_cli:doctor
```

注意：

```text
--force 会覆盖生成的 AGENTS / toolkit / UI starter
不会删除当前 profile 不再生成的文件
```

---

## 退出码

| 命令 | 0 | 1 | 2 |
|---|---|---|---|
| `init --check` | 没有缺失 / drift | 有缺失或 drift | 参数错误 |
| `doctor` | 无 error（`--strict` 时也无 warning） | 有失败 | 参数 / 项目错误 |
| `list` / `explain` | 找到 | 未找到 | 参数错误 |
| `context` | 成功 | — | 参数 / 项目错误 |

---

## 示例

命令演示与可复现的最小消费方项目见 [`example/`](example/)：

```bash
cd packages/cli
bash example/run_demo.sh
```

---

## 维护者

模板唯一来源是 `templates/`，目录唯一来源是 `catalog/components.yaml`：

```bash
cd packages/cli
dart run tool/gen_templates.dart
dart run tool/gen_catalog.dart
dart run tool/gen_templates.dart --check
dart run tool/gen_catalog.dart --check
dart test
```

> 改 CLI 版本号时同步 `lib/src/common/version.dart` 的 `cliVersion`；
> `test/version_test.dart` 会拦住漂移。

设计依据与接入约定见仓库 [`docs/conventions.md`](https://github.com/stone0533/w_tools/blob/main/docs/conventions.md)
与 [ADR-0002](https://github.com/stone0533/w_tools/blob/main/docs/adr/0002-consumers-depend-on-subpackages.md)。
