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

```bash
dart pub add dev:w_tools_cli
```

```bash
dart run w_tools_cli:w_tools init       # 1. 生成 toolkit / UI 规范 / AGENTS / doctor 配置
dart run w_tools_cli:w_tools doctor     # 2. 检查是否遵守接入约定
dart run w_tools_cli:w_tools list 表单   # 3. 找现成组件
dart run w_tools_cli:w_tools context --format=prompt   # 4. 给 AI 项目事实
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
| 用 w_tools 撞到问题，要记一条反馈 | `feedback submit --package=<包>` |
| 只检查不写文件 | `init --check` |
| 检查模板是否过期 | `init --check-drift` |
| 升级 CLI 后刷新生成物 | `init --force` |
| 显式恢复默认 `.w_tools_doctor.yaml` | `init --force-config`（先 `.bak`） |
| 回到默认 profile/targets/lang | `init --reset` |
| 明确刷新 UI / device starter | `init --force-starters` |

退出码约定：`0` 成功 · `1` findings · `2` 参数/配置错误 · `3` 外部不可用。

命令入口：

```bash
# 统一入口（推荐）
dart run w_tools_cli:w_tools <command>

# 兼容入口（仍保留）
dart run w_tools_cli:<command>
```

```bash
dart run w_tools_cli:w_tools doctor --help
```


---

## init

```bash
dart run w_tools_cli:w_tools init
```

生成：

```text
lib/app/w/toolkit.dart             本项目能力清单（w_tools:begin/end 标记块，块外追加项不会被 --force 覆盖）
.w_tools/init.json                  上次 init 的 flags；--check 用它回放参数
.w_tools/AI_PROMPTS.md             消费方场景提示词库（默认生成）
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
dart run w_tools_cli:w_tools init --profile=ui
dart run w_tools_cli:w_tools init --no-ui
dart run w_tools_cli:w_tools init --no-async
dart run w_tools_cli:w_tools init --no-form
dart run w_tools_cli:w_tools init --no-app
dart run w_tools_cli:w_tools init --no-api
dart run w_tools_cli:w_tools init --no-toast
dart run w_tools_cli:w_tools init --no-qr
dart run w_tools_cli:w_tools init --map         # 会引入 google_maps_flutter
dart run w_tools_cli:w_tools init --no-map      # 显式关闭（默认关）
# --with-map 仍可用，等同 --map
```

### 设备验证

```bash
# 生成通用设备文档 + Gradle 镜像（不再生成 device_smoke）
dart run w_tools_cli:w_tools init --device
```

`--device` 的 pubspec 片段会补 `w_tools_device`。
通用 UI keep-alive 集成测试不再由 init 生成；参考
[`docs/recipes/keepalive-integration-test.md`](https://github.com/stone0533/w_tools/blob/main/docs/recipes/keepalive-integration-test.md)。

### Figma 片段

```bash
dart run w_tools_cli:w_tools init --figma
```

只在 AGENTS 中追加 Figma → Flutter 说明，不会修改 toolkit 或 pubspec。

是否生成按以下优先级：

```text
--figma / --no-figma
  > .w_tools_doctor.yaml 的 ai.figma
  > pubspec 是否依赖 w_tools_figma
  > false
```

`ai.figma`：

```yaml
ai:
  figma: auto  # auto | true | false
```

如果 pubspec 已有 `w_tools_figma`，生成的安装命令沿用该约束；path/git 依赖时
不生成错误的 pub 版本命令。

### 指令文件目标

```bash
dart run w_tools_cli:w_tools init --targets=agents,claude --lang=en
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

### AI 任务提示词

默认生成：

```text
.w_tools/AI_PROMPTS.md
```

给**使用 w_tools 的开发者**用（Dart / Flutter 开发者、对写提示词不熟）：按场景编号复制一段、填空、贴给 AI。
文件结构：

```text
新手先看这里（三步 / 让 AI 选场景 / 默认工作流 / 完成后先看）
0. 固定前缀（每次先贴）
填空说明（占位符表）
一个填好的例子
1. 场景选择（＋从现象反查）
```

场景编号是「族字母-工序号」，有先后关系的拆成多轮：

```text
A-1 只读计划 → A-2 实现
B-1 列表 / 分页 / 刷新
C-1 表单 / 校验 / 提交（启用 form 时）
D-1 接口 / 登录 / 401（启用 api 时）
E-1 审计 → E-2 按清单修复
F-1 计划 → F-2 分文件替换 → F-3 验证（升级 w_tools 子包）
G-1 调试 UI / 性能
H-1 白盒测试
I-1 黑盒测试
J-1 只审查改动
K-1 AI 不能读仓库
```

固定前缀里的规则文件、toolkit 入口、`flutter` / `dart` 命令、聚合包 / 子包说明，会按本次 `init` 的 targets、`toolkit_entry` 与 pubspec 渲染；纯 Dart 项目不会拿到 `flutter` 命令，`--targets=claude` 也不会指向 `AGENTS.md`。

文末「3. AI 完成后你必须检查」是全文唯一一份自检清单；每条要求标 `✅` / `N/A（写理由）` / `❌`。

它是生成物：内容与模板不同时 `init` 不覆盖、只报 drift；`init --force` 直接覆盖且没有备份，
项目自己的提示词请另存。

关闭：

```bash
dart run w_tools_cli:w_tools init --no-ai-prompts
```

`--no-instructions` 会同时关闭 AGENTS 与 AI_PROMPTS；两者不能同时显式开启。

升级注意：1.10.0 起默认生成 AI_PROMPTS。已有项目升级后 `init --check` 会报告缺失，
运行一次 `init` 即可；不想保留该文件时用 `init --no-ai-prompts`。

### 检查模式

```bash
dart run w_tools_cli:w_tools init --check         # 只报告缺失；内容不同提示但不失败
dart run w_tools_cli:w_tools init --check-drift   # 模板过期也失败
```

CI 想追踪模板更新时用 `--check-drift`。

---

## doctor

```bash
dart run w_tools_cli:w_tools doctor
```

常见格式：

```bash
dart run w_tools_cli:w_tools doctor --format=markdown   # 贴 PR / AI
dart run w_tools_cli:w_tools doctor --json              # CI
dart run w_tools_cli:w_tools doctor --strict            # warning 也失败
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

> doctor 规则是文本级检查：注释会跳过；R3 的 `Color(...)` / R6 单位不会命中字符串字面量，
> 但 R9 与 `fromHex('#...')` 仍按字符串内容匹配。
> 完整规则细节与豁免语义以仓库里的
> [docs/conventions.md §7](https://github.com/stone0533/w_tools/blob/main/docs/conventions.md) 为准。

只跑部分规则：

```bash
dart run w_tools_cli:w_tools doctor --only=R1,R2,R9
dart run w_tools_cli:w_tools doctor --include-tests
```

### 无 CLI 时的手动兜底映射

消费方 AGENTS 里的 grep 只作为无 CLI 环境兜底，对应关系：

| 手动检查 | CLI | 说明 |
| --- | --- | --- |
| ① design_system / ui 不依赖业务 | R4 | 只覆盖 `data/` / `modules/` / `routes/` / `services/`；严格 import 白名单是项目特有，不在 CLI |
| ② 业务代码不直接 import `w_tools_*` | R2 | 默认扫 `lib/`，要覆盖 `test/` / `tool/` 加 `--include-tests` |
| ③ pubspec 不依赖聚合包 | R1 | 区分 `dependencies`、`dev_dependencies`、`dependency_overrides` |
| ④ 图片只走 `WImage` | R9 | 用 `banned` 配置，不新增默认 R10；路径白名单按项目配置 |

不要把这四条 grep 直接搬进 CLI：① 含项目特有 import 例外，④ 的允许路径也因项目而异。

### 项目禁用 API（R9）

```yaml
banned:
  - id: no-raw-image
    pattern: 'Image\.asset\('
    mode: regex
    use: 'WImage.source(source: WImageSource.asset(...))'
    reason: '项目要求统一图片入口'
    level: warn
    paths: ['lib/app/modules/**']
    ignore: ['lib/app/ui/**']
```

`mode` 支持 `literal` / `regex`，默认 `literal`。
`paths` / `ignore` 支持 `*` / `**`。

行级豁免：

```dart
// w_tools:ignore R2 reason: migration bridge
// w_tools:ignore-file R7 reason: legacy toolkit
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
dart run w_tools_cli:w_tools doctor --print-config    # 打印默认配置
dart run w_tools_cli:w_tools doctor --print-config --json   # JSON: { schema, config }
dart run w_tools_cli:w_tools doctor --write-config    # 写入 .w_tools_doctor.yaml
dart run w_tools_cli:w_tools doctor --write-config --json   # JSON: { schema, written, backup }
```

`--force` 只能配合 `--write-config` 使用（覆盖前写 `.bak`；`.bak` 已存在时写 `.bak.<timestamp>`）。

`--json` 的 issue 带可选 `fix`：

```json
{"kind": "run",  "command": "dart run w_tools_cli:w_tools init --force"}
{"kind": "edit", "file": "pubspec.yaml", "path": "dependencies.w_tools_core", "value": "any"}
```

---

## feedback

给 AI / 开发者的反馈入口：**记录 w_tools 本身的问题**（不是业务代码问题）。

**默认策略：本地台账优先；Issue 其次；都不满足就跳过（exit 4，什么都不写）。**

```bash
# 先查重（本机没有台账时会提示加 --gh 搜 GitHub）
dart run w_tools_cli:w_tools feedback search "WImage 缓存" --package=ui

# 打印字段骨架（可选）
dart run w_tools_cli:w_tools feedback submit --template > /tmp/feedback.md

# 默认路由：本机 w_tools 仓库 → 写它的 docs/feedback；没有仓库 → 建 Issue；都没有 → 跳过（exit 4）
dart run w_tools_cli:w_tools feedback submit --package=ui --title="..." --body-file=/tmp/f.md

# 显式覆盖
dart run w_tools_cli:w_tools feedback submit ... --ledger   # 强制写本地台账（需本机仓库检出）
# 相同标题 + 正文默认拒绝；确认重复时加 --allow-duplicate
dart run w_tools_cli:w_tools feedback submit ... --issue    # 强制建 Issue（需 feedback.enabled）

dart run w_tools_cli:w_tools feedback path --package=figma   # 该写哪个文件
dart run w_tools_cli:w_tools feedback lint --include-inbox   # 写完自检
```

| 子命令 | 作用 |
|---|---|
| `submit` | 默认本地台账 → Issue → 跳过（exit 4）；`--ledger` / `--issue` 显式覆盖 |
| `search` | 本地台账查重（本机无台账会提示加 `--gh`）；`--gh` 同时搜 GitHub issues |
| `status` | 查看通道（ledger / issue / disabled）+ gh 可用性 |
| `path` | 返回真实可写的台账路径；本机没有 w_tools 仓库时明确说未启用 |
| `lint` | 字段齐全 / 状态合法 / 已闭环带版本号 / 已确认链 issue / 索引与文件一致 / 待处理 stale 警告 |

- 本地台账存在时**不联网**；Issue 需 `.w_tools_doctor.yaml` 的 `feedback.enabled: true`（旧键 `feedback.issue` 兼容）
- 仓库 clone 在别处（依赖解析不到）时：`feedback.ledger: ../w_tools`（相对项目根或绝对路径；无效时提示一次并忽略）
- pub cache 里的 git 依赖不算本机库（不往缓存写台账）
- 开关是硬门禁：未开启时 `--issue` 拒绝（exit 2）；本机有台账时 `--issue` 才是「明确要公开提 issue」
- `feedback.enabled` 默认 `false`；`--issue` 需要已安装 `gh`（gh 会读取 `GH_TOKEN`/`GITHUB_TOKEN`，或 `gh auth login`）
- `feedback status --json` 可查当前通道：`ledger` / `issue` / `disabled`（issue 附带 `gh.ready`）
- `--ledger --linked-issue=123` 会在条目里写「关联 issue：#123」
- 反馈 Issue 模板：`.github/ISSUE_TEMPLATE/feedback.md`；Issue 正文不带台账的 `### [待处理]` / `状态变更` 元数据
- `lint --stale-days=<n>`：待处理超过 n 天给警告（默认 30，0 关闭），不影响退出码
- 本机没有台账时 `lint` 明确输出「跳过」而不是 `✓ 0 条`；`search` 会提示加 `--gh`
- 规则与文件格式见仓库 `docs/feedback/README.md`；CI 的 `scripts/check_feedback.sh` 就是这条命令的包装
- `--package` 只接受小写字母/数字/下划线（防路径穿越）

---

## context / list / explain

### context

```bash
dart run w_tools_cli:w_tools context
dart run w_tools_cli:w_tools context --format=prompt --max-tokens=1500
dart run w_tools_cli:w_tools context --format=json
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
dart run w_tools_cli:w_tools list             # 列出全部组件
dart run w_tools_cli:w_tools list 下拉        # 按关键词搜索
dart run w_tools_cli:w_tools list --format=json
dart run w_tools_cli:w_tools list async --format=prompt
```

### explain

```bash
dart run w_tools_cli:w_tools explain WImage
dart run w_tools_cli:w_tools explain WFormDropdown
dart run w_tools_cli:w_tools explain WAsync --format=prompt
```

输出用途、反例、import、用法、注意项、相关组件、文档；`--format=prompt` 是给 AI 的紧凑格式，
同样包含「不要用于」段。
项目配置了 `banned` 时会提示禁用项和替代方案。
`banned` 读取 `--root` 或当前工作目录的 `.w_tools_doctor.yaml`。

---

## 给 AI 的工作流

```bash
dart run w_tools_cli:w_tools context --format=prompt   # 先拿事实
dart run w_tools_cli:w_tools list <关键词>              # 找组件
dart run w_tools_cli:w_tools explain <组件名>           # 看用法 / 反例
dart run w_tools_cli:w_tools doctor --json           # 写完自检
```

`init` 生成的 `AGENTS.md` 已包含这条闭环。生成物头部带
`generated by w_tools_cli x.y.z`，R8 会检查是否过期。

---

## 升级与重新生成

CLI 模板会随版本变化。升级后执行：

```bash
dart pub upgrade w_tools_cli

dart run w_tools_cli:w_tools init --check-drift
# 有 drift 时再覆盖生成物
dart run w_tools_cli:w_tools init --force
dart run w_tools_cli:w_tools doctor
```

注意：

```text
--force 会覆盖生成的 AGENTS / toolkit 标记块；不覆盖 .w_tools_doctor.yaml
要覆盖项目配置用 --force-config（先 .bak）
toolkit 标记块外的项目追加项会保留
`.w_tools/init.json` 记录本次 init flags，普通 init 总是更新；--check 只比对不写
--force-starters 才会覆盖 UI / device starter，并先写 .bak
不会删除当前 profile 不再生成的文件

> `--force` 不覆盖 UI / device starter；需要覆盖 starter 用 `--force-starters`（先写 .bak）。
```

---

## 退出码

| 命令 | 0 | 1 | 2 |
|---|---|---|---|
| `init` | 成功（含“未覆盖 drift”提示） | — | 参数错误 |
| `init --check` | 没有缺失（内容不同只提示） | 有缺失 | 参数错误 |
| `init --check-drift` | 没有缺失且内容一致 | 有缺失或 drift | 参数错误 |
| `doctor` | 无 error（`--strict` 时也无 warning） | 有失败 | 参数 / 项目错误；`--write-config` 冲突 |
| `list` / `explain` | 找到 | 未找到 | 参数错误 |
| `context` | 成功 | — | 参数 / 项目错误 |
| `feedback path` / `lint` | 成功 / 无问题 / 没有可校验内容 | lint 有问题 | 参数 / 子命令错误 |
| `feedback submit` | 写入台账 / 创建 Issue | Issue 提交失败 | 参数 / 字段缺失 / 开关未开启 / 无 `--ledger` 目标 |
| `feedback search` | 找到 | 未找到 | 参数错误 |

`feedback submit` 没有可用通道时退出 `4`（什么都没写，跳过不等于成功）；
`feedback submit --issue` 在 `gh` 未安装 / 未登录时退出 `3`（外部不可用），不再抛栈。
`feedback search --gh` 在 `gh` 未安装 / 未登录时同样退出 `3`，本地结果不返回。

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
python3 ../../scripts/check_public_catalog.py
```

`catalog/uncataloged.yaml` 记录有意不进入 catalog 的公开子 API；
新增公开类型时，要么登记 catalog，要么更新基线：

```bash
python3 ../../scripts/check_public_catalog.py --write
```

AI 教学契约由 `test/ai_contract_test.dart` 检查：teach 组件必须有
usage / pitfalls / related，所有 AGENTS feature 必须有 zh/en 模板。

新增包时同步 `lib/src/feedback/feedback_ledger.dart` 的 `feedbackPackages` 与
`bin/explain.dart` 的 `_examplePackages`；`test/internal/package_lists_test.dart` 会挡住漂移。

> 改 CLI 版本号时同步 `lib/src/common/version.dart` 的 `cliVersion`；
> `test/version_test.dart` 会拦住漂移。

设计依据与接入约定见仓库 [`docs/conventions.md`](https://github.com/stone0533/w_tools/blob/main/docs/conventions.md)
与 [ADR-0002](https://github.com/stone0533/w_tools/blob/main/docs/adr/0002-consumers-depend-on-subpackages.md)。
