// 由 tool/gen_templates.dart 生成，不要手改。
// 模板源文件在 templates/（唯一来源）；改完跑 `dart run tool/gen_templates.dart`。
//
// dart format off
// ignore_for_file: prefer_single_quotes, lines_longer_than_80_chars

const String aiPrompts = r'''
# w_tools 场景提示词

> 由 `w_tools_cli` v{{version}}（生成器版本）生成；重新生成请运行 `dart run w_tools_cli:w_tools init --force`。
>
> **本文件是生成物**：内容与模板不同时 `init` 不会覆盖、只报 drift；
> `init --force` 会直接覆盖，而且**没有备份**。
> 项目自己的提示词请另存（例如 `.w_tools/PROMPTS.local.md`），不要写进这里。
>
> 本文件只服务**使用 w_tools 的项目**，不是 w_tools 仓库维护提示词；项目规则以 `{{rulesFiles}}` 为准。

---

## 新手先看这里

### 只需三步

1. 用一句话说明任务；
2. 不知道该用哪段，先让 AI 帮你选；
3. AI 判断后，复制它填好的提示词，或复制对应场景块。

### 让 AI 帮你选场景

不确定用哪段时，先发这段：

```text
我是本项目的 {{role}} 开发者，但不熟悉这些提示词。

先只读 .w_tools/AI_PROMPTS.md 的「1. 场景选择」，选出场景编号并说明理由。

我的任务是：<任务>。
范围是：<范围>。

我确认编号后，你再只读该编号对应的一节，按原文把占位符换成具体值；
缺信息先问我，不要猜。
最后给我一份可以直接复制的完整提示词（放在一个代码块里）。
如果文件读不到，直接告诉我，我来贴。
```

### 默认工作流

复杂任务 / 范围不确定时，按轮次拆：

```text
第 1 轮：只读，不改文件        A-1 / E-1 / F-1
第 2 轮：只改一个范围          A-2 / E-2 / F-2
第 3 轮：只审不改 + 跑检查      F-3 / J-1，然后 {{analyze}} / {{test}}
```

多轮场景默认在同一会话进行。新开会话时，先把上一轮输出作为「交接材料」贴进来；
没有交接材料就回到上一步重新出计划。

小任务一轮就够（固定前缀照旧先贴）：B-1 / G-1 / H-1 / I-1 / N-1。

不要第一轮就：

```text
实现 + 补测试 + 改文档 + 跑全仓
```

### AI 完成后先看

按 §3「AI 完成后你必须检查」逐条核对 —— 全文只有这一份清单，不在这里另抄一份。

---

## 0. 固定前缀（每次先贴）

```text
你是本项目的 {{role}} 开发者。

先读 {{rulesFiles}} 和 pubspec.yaml；项目规则优先于本文件。
如存在 `.w_tools/PROMPTS.local.md`，也先读并按其中的项目约定执行。

规则：
1. 写代码前先运行：
   dart run w_tools_cli:w_tools context --format=prompt
2. 找组件运行：
   dart run w_tools_cli:w_tools list <关键词> --format=prompt
   查用法运行：
   dart run w_tools_cli:w_tools explain <组件名> --format=prompt
3. w_tools API 以 explain 输出为准。
4. 依赖与入口：{{dependencyNote}}
   业务代码统一从项目聚合入口（{{toolkitImport}}）取 API；
   直接 import package:w_tools_* 只出现在 toolkit 自身；启用 UI 时还包括 lib/app/ui/、lib/app/design_system/；
   测试 / 工具目录（test/、tool/、integration_test/）下的 dev-only 工具包 import 不算违规。
5. 需要改 {{rulesFiles}} 时，只改 `w_tools:begin/end` 标记块外的内容；块内保持生成原样。
6. 完成后运行 {{analyze}} / {{test}}，并跑：
   dart run w_tools_cli:w_tools doctor --format=json（0 error）
   贴实际输出；不能运行就明确说没运行。
7. 除非场景另有规定，默认输出 = 改动文件清单 + 关键代码片段 + {{analyze}} / {{test}} 原始输出。
```

固定前缀的例外：让 AI 选场景时只读 §1；K-1 不贴固定前缀；L-1 不跑 {{analyze}} / {{test}}；其余场景每次先贴。

---

## 填空说明

| 占位符 | 填什么 | 示例 |
|---|---|---|
| `<任务>` | 一句话目标 | 订单列表页 |
| `<页面>` | 页面名 / 菜单名 | 「我的订单」页 |
| `<路由>` | 路由 path | `/orders` |
| `<接口>` | 接口 path 或方法名 | `GET /api/orders` |
| `<组件名>` | 公开类名 | `WFormTextField` |
| `<关键词>` | 搜索词 | 表单 |
| `<范围>` | 这次只动哪些文件 / 功能 | `lib/orders/` |
| `<旧版本>` | 当前子包版本（各包独立，以 `pubspec.lock` 为准） | `w_tools_ui 7.0.0` |
| `<新版本>` | 目标子包版本 | `w_tools_ui 8.0.0` |
| `<核心流程>` | 要跑通的用户路径 | 登录 → 下单 → 返回 |
| `<现象>` | 看到的症状 | 键盘弹出后输入框被挡 |
| `<包>` | 子包名（`ui` / `w_tools_ui` 都行） | `ui` |

`w_tools_cli` 的版本是**生成器版本**，不是子包版本；升级场景按子包分别填。
标题里带 `X-n` 的是场景编号：字母是任务族，数字是族内工序，按顺序贴。
新手最容易漏 `<路由>` 和 `<接口>`：只写「做个列表页」，AI 就会自己编字段名。

---

## 一个填好的例子：B-1 列表页

❌ 太模糊，AI 只能猜：

```text
帮我用 w_tools 做个订单列表页
```

✅ 填到能验收：

```text
任务：实现「我的订单」列表页，路由 /orders，接口 GET /api/orders?page=&size=

先确认：
- 分页参数是 page / size，返回里有 total
- 支持下拉刷新，不做无限滚动

要求：
1. 先看项目里现有的列表页写法
2. 首屏 loading / empty / error 必须完整
3. 加载更多失败只更新 footer，不替换列表
4. 列表项使用稳定 key
5. 完成后 analyze + test，并补一个列表状态测试

输出：改动文件清单 + 关键代码片段 + analyze / test 原始输出。
```

差别只有三点：**给了路由和接口**、**划了范围（不做无限滚动）**、**写清了要交什么**。

---

## 1. 场景选择

| 我要做什么 | 用哪个 |
|---|---|
| 做一个新页面 / 功能 | A-1 → A-2 |
| 列表 / 分页 / 刷新 | B-1 |
<!-- @if:form -->
| 表单 / 校验 / 提交 | C-1 |
<!-- @endif -->
<!-- @if:api -->
| 接口 / 登录 / 401 | D-1 |
<!-- @endif -->
| 检查现有代码有没有用错 | E-1（查完再 E-2 修） |
| 升级 w_tools | F-1 → F-2 → F-3 |
| 页面 overflow / 卡顿 | G-1 |
| 补白盒测试 | H-1 |
| 补黑盒测试 | I-1 |
| 只审查 AI 改动 | J-1 |
| AI 读不到仓库 / 不能跑命令 | K-1 |
| 被 w_tools 卡住 / 有改进建议 | L-1 |
| 刚接入 / doctor 报错 | M-1 |
| 只想改一处 / 单文件修复 | N-1 |

### 从现象反查

| 症状 | 场景 |
|---|---|
| 列表加载更多把整个列表顶掉了 | B-1 |
<!-- @if:form -->
| 表单提交失败后，用户输入没了 | C-1 |
<!-- @endif -->
<!-- @if:api -->
| 401 之后一直重试 / 白屏 | D-1 |
<!-- @endif -->
| 键盘弹出字段被挡 / overflow | G-1 |
| AI 说改了，但拿不出 analyze 输出 | J-1 或 K-1 |
| 用 w_tools 时被卡住，想记一条反馈 | L-1 |
| init 后 doctor 一片红 | M-1 |
| 只想改一处，不想动别的 | N-1 |
| 不确定用哪段 | 上面「让 AI 帮你选场景」 |

---

## A. 新页面

### A-1. 只读计划

```text
任务：实现 <页面>，路由 <路由>。

先不要写代码，也不要改任何文件。先读：
- {{rulesFiles}} / pubspec.yaml
<!-- @if:ui -->
- lib/app/ui/ 与 lib/app/design_system/
<!-- @endif -->
- 2~3 个相似页面
- 路由注册文件

输出（只要这 7 项，不要代码）：
1. 可复用的现有页面 / 组件
2. 页面状态：loading / empty / error / ready
3. 路由与参数
4. 数据来源
5. 需要 explain 的 w_tools 组件
6. 文件改动计划
7. 测试计划

我确认后再进入 A-2。
```

### A-2. 按计划实现

```text
按上一条确认的计划实现 <页面>；同一会话继续，新会话先贴 A-1 的计划。范围：<范围>。

要求：
- 先运行 context，再用 list / explain 找组件；
- 不发明新的目录 / 状态管理方案；
- 不修改 w_tools 子包；
- 有请求就要有取消 / dispose 保护。
```

计划要改就回 A-1 重来，不要在 A-2 里边做边改方案。

---

## B. 列表 / 分页 / 刷新

### B-1. 实现列表页

```text
任务：实现 <页面> 列表，路由 <路由>，接口 <接口>。

先确认：
- 数据接口与分页参数
- 是否支持下拉刷新
- 空态 / 错误态 / 加载更多失败
<!-- @if:async -->
- 项目是否已使用 WAsyncPagedController
<!-- @endif -->

要求：
1. 先看项目现有列表页写法；
2. 首屏 loading / empty / error 必须完整；
3. 加载更多失败只更新 footer，不替换列表；
4. 列表项使用稳定 key；
5. 图片按需限制解码尺寸；
6. 完成后 analyze + test，并补一个列表状态测试。
```

---

<!-- @if:form -->
## C. 表单 / 校验 / 提交

### C-1. 实现表单页

```text
任务：实现 <页面> 表单，路由 <路由>。

要求：
1. 用 WForm + 直接字段，不传字段 config；
2. 校验用字段 validator；需要统一校验设置时放 WForm 的 validatorSettings，不要逐字段传（默认值够用就不传）；
3. 提交中禁用重复提交；
4. 接口失败保留用户输入；
5. 键盘弹出时字段可见；
6. readOnly / 编辑态正确；
7. 补一个校验 + 提交测试。
```
<!-- @endif -->

---

<!-- @if:api -->
## D. 接口 / 登录 / 401

### D-1. 实现接口 / 登录流程

```text
任务：实现 <接口> 与 <页面> 的登录流程。

要求：
1. 用 WApiConfig + DioRegistry，不直接 new Dio；
2. token 用 WToken；
3. 401 刷新只重试一次；
4. 请求失败要有业务错误提示；
5. 页面切换 / dispose 后不要 setState；
6. 完成后 analyze + test。
```
<!-- @endif -->

---

## E. 审计现有代码

### E-1. 只读审计

```text
只审计，不改任何文件。

检查当前项目：
1. 是否用了已删除 / 过期的 w_tools API；
2. 是否绕过 w_tools 直接用了底层库；
3. 是否有重复造组件；
4. 是否违反 {{rulesFiles}}；
5. 已启用的能力是否走对入口，不要绕过包装层直接用底层库。
   - core：优先用 WStorage / WToken / WValidator / WLogger，而不是裸 SharedPreferences / print
<!-- @if:ui -->
   - UI：WText / WButton / WImage，不要直接用 Text / ElevatedButton / Image
<!-- @endif -->
<!-- @if:form -->
   - 表单：WForm + 直接字段，不传 config
<!-- @endif -->
<!-- @if:api -->
   - 接口：WApiConfig + DioRegistry，token 用 WToken
<!-- @endif -->
<!-- @if:toast -->
   - Toast：WToast + WToastTheme，不要直接用 BotToast
<!-- @endif -->
<!-- @if:app -->
   - App：WApp.options / WAppPlugin，不要手工初始化插件
<!-- @endif -->
<!-- @if:async -->
   - Async：WAsyncController / WAsyncView，不要自己维护 loading / error 状态
<!-- @endif -->
<!-- @if:qr -->
   - 扫码：WQrView，不要直接用 QRView
<!-- @endif -->
<!-- @if:map -->
   - 地图：WMap / WMapZone，不要直接用 GoogleMap
<!-- @endif -->

先运行 `dart run w_tools_cli:w_tools doctor --format=json`，再用 context / list / explain 核对。
对每个 w_tools 类型 / import 跑 `explain`；exit 1 记为“catalog 未收录 / 名字不对 / 匹配到多个”，
再结合 `{{analyze}}` 的 deprecated 警告判断是否真的要替换。

输出一张表，按严重度排序：
| ID | 级别 | 文件:行 | 证据 | 问题 | 建议修复 | 验收 |
级别：P0 阻断（编译 / 主流程不可用）、P1 应修（错误入口 / 状态缺失）、P2 建议（一致性 / 可读性）。
本次只读，不改文件。
```

### E-2. 按清单修复

```text
按上一条审计输出的清单修复；同一会话继续，新会话先贴 E-1 的表格。本次范围：<范围>。

要求：
1. 一次只修一个级别，先 P0 再 P1；
2. 每修一条，标出对应的审计 ID；
3. 不改与清单无关的代码；
4. 修完重跑 doctor，对比修复前后的 error 数。

输出：修了哪些 ID + 改动文件清单 + doctor 前后对比 + {{analyze}} / {{test}} 原始输出。
```

---

## F. 升级 w_tools

### F-1. 升级计划与旧 API 清单

```text
任务：升级 w_tools 子包。先从 pubspec.lock 按包列出 <旧版本> 和 <新版本>（各包独立），再确定本次范围。

先不要改代码。先做三件事：
1. 按包读升级说明：优先看该包 CHANGELOG（pub.dev / GitHub），需要细节再看 w_tools 仓库 docs/migrations/
   （例如 ui-8.0.md / form-6.0.md；docs/ 不随包发布，不要假设本地有）；
2. 找出项目里所有旧 API 和需要改的调用点；
3. 列出按文件分组的改动计划。

输出：旧 API 清单（文件:行 + 替换方式） + 分文件改动计划 + 风险点。
我确认后再进入 F-2。
```

### F-2. 分文件替换

```text
按 F-1 的计划替换旧 API；同一会话继续，新会话先贴 F-1 的计划。本次只做：<范围>。

要求：
1. 先跑 `dart run w_tools_cli:w_tools upgrade`（只抬 w_tools 系包；跨 major 加 `--major` 或 `--only=<包>`，普通 `{{pubUpgrade}}` 不会跨 major），它会改 pubspec 并 pub get；
2. 按文件逐步替换，一个文件一次；
3. 不改变无关业务行为；
4. 遇到计划里没覆盖的调用点，停下来先报告，不要自己猜；
5. 每改完一批跑一次 {{analyze}}。

输出：本批改动文件 + 关键 diff + {{analyze}} 原始输出。
```

### F-3. 验证与残留报告

```text
升级收尾。

要求：
1. 跑 {{analyze}} + {{test}}，贴原始输出；
2. 按包报告旧 API 残留（有就列文件:行，没有就明确说没有）；
3. 刷新项目接入文件并检查 drift：
   {{pubUpgrade}}
   dart run w_tools_cli:w_tools init --check-drift
4. 有 drift 时再运行（会覆盖生成物，没有备份）：
   dart run w_tools_cli:w_tools init --force

输出：{{analyze}} / {{test}} 原始输出 + 残留清单 + drift 检查结果。
```

---

## G. 调试 UI / 性能

### G-1. 排查 UI / 性能问题

```text
任务：排查 <页面> 的 UI / 性能问题，现象：<现象>。

先收集：
- 复现步骤
- 设备与 SDK 版本
- 报错 / overflow 日志
- 相关页面代码
- explain 输出

重点检查：
1. overflow / 键盘遮挡 / SafeArea；
2. 暗色模式 / TextScaler；
3. 不必要的 rebuild；
4. 图片解码尺寸和缓存；
5. 列表 key / controller dispose；
6. 是否是 w_tools 用法问题。

先给复现和证据，再给结论；没有证据的结论标为推测。

输出：复现步骤 + 证据 + 根因 + 修复建议 + 验证方式。
```

---

## H. 白盒测试

### H-1. 补组件 / 单元测试

```text
任务：为 <页面> 补白盒测试。

优先覆盖：
- loading / empty / error / ready；
<!-- @if:form -->
- 表单校验、提交、只读；
<!-- @endif -->
- controller dispose / 请求取消；
- 列表刷新 / 加载更多 / footer；
<!-- @if:api -->
- 401 / 请求失败。
<!-- @endif -->

要求：
- 用 {{testFramework}}；
- 先读项目现有 test 写法；
- 断言覆盖真实行为；
- 用 mock / fake 替代真实网络；
- 完成后 {{test}}。

输出：新增 / 修改的测试文件 + {{test}} 原始输出。
```

---

## I. 黑盒测试

### I-1. 补 integration test

```text
任务：为核心流程「<核心流程>」补黑盒测试。

要求：
1. 从用户入口进入：启动 → 登录 → 页面 → 返回；
2. 用 Key / Semantics 定位，不依赖坐标和随机文案；
3. 使用测试账号 / 测试数据，不提交真实凭证；
4. 失败保留截图 / 日志；
5. 优先用项目已有的集成测试方案，坐标点击只作为兜底。

运行（没有对应测试目录就先问我；需要时换成具体测试文件）：
- {{integrationTest}}

需要真机时先看项目是否装了 w_tools_device：装了按它的文档操作，没装就跳过，
不要手写 adb 命令。

输出：测试文件 + 运行结果 + 失败时的截图 / 日志路径。
```

---

## J. 只审查改动

### J-1. 只读审查

```text
只审查本次改动，不要改代码。先以 `git diff`（或我贴的 diff）为输入；拿不到 diff 就先问我改了什么。

检查：
1. 是否用了正确入口；
2. 是否有旧 API / 重复组件；
3. 是否修改了无关文件；
4. 是否降低了测试标准；
5. 是否手改了生成物。

输出：阻断项 / 建议项 / 可保留风险，每项带文件:行和理由。
```

---

## K. AI 不能读仓库 / 不能跑命令

### K-1. 片段式协作

```text
本轮不贴固定前缀：你不能访问仓库或运行命令。

请基于我提供的代码片段工作，并明确标注：
1. 哪些结论来自我贴的内容；
2. 哪些需要我运行命令确认；
3. 不要声称 analyze / test 已通过。

我提供：
- 改动 diff
- 相关 pubspec 片段
- explain 输出
- 报错 / 测试输出
```

---

## L. 反馈给 w_tools

### L-1. 记一条反馈

```text
任务：把这次用 w_tools 被卡住的问题（或改进建议）记成一条反馈。

先跑 `dart run w_tools_cli:w_tools feedback status --json`，看返回的 channel：
- disabled → 停止：告诉我「项目没开启反馈通道」，并给出开启方法（在 `.w_tools_doctor.yaml` 的 `feedback:` 下写 `enabled: true`，
  等价于 `feedback.enabled: true`），重跑 status 确认；不要提交，也不要加 --issue；
- ledger / issue → 继续。

然后：
1. 查重：`dart run w_tools_cli:w_tools feedback search "<关键词>" --package=<包>`
   命中相同问题就把文件行号或 issue 编号给我，不要重复提交；
2. 按固定字段写正文（缺字段会被拒绝），先把草稿给我看：
   - 包/版本：<包> 的当前版本，以 pubspec.lock 为准
   - 环境：Flutter / Dart / 平台 / 设备
   - 命令 / 输入：触发的代码、命令或操作
   - 期望：应该怎样
   - 实际：实际怎样，报错贴原文
   - 影响：因此卡了多久 / 做错了什么；没有就写「无」
   - 建议：希望怎么改
   - 复现数据：最小 demo / 日志片段，先脱敏
   保存到 /tmp/w_tools_feedback.md；
3. 提交：`dart run w_tools_cli:w_tools feedback submit --package=<包> --title="<现象>" --body-file=/tmp/w_tools_feedback.md`
   默认路由：本机有 w_tools 仓库就写它的 docs/feedback/；没有才建 Issue；都没有则 exit 4（什么都没写）。

不要：
- 不要加 --issue（除非我明确说要公开提 issue）；
- 不要贴密钥 / token / 业务敏感数据；
- 一次会话最多 3–5 条，只记真正卡住的；
- 状态只写「待处理」，不要自己标「已修复」。

输出：提交结果（台账路径或 issue URL）+ 20 字以内的现象摘要；被拒绝时原样贴错误。
```

---

## M. 接入 / 体检

### M-1. 按 doctor 报告修到 0 error

```text
任务：项目刚接入或升级 w_tools，按 doctor 报告修到 0 error。

先跑：
dart run w_tools_cli:w_tools doctor --format=json

要求：
1. 先报总数：每条规则（R1~R9）的 error / warn 数，以及本次先修哪几条；
2. 一次只修一条规则，先 error 后 warn；
3. 只改报告指到的文件，不顺手重构、不改无关格式；
4. 报告里有 fix 的按 fix 执行；没有 fix 先读 hint，再给最小修改；
5. 每修完一条重跑 doctor，贴修复前后的 error / warn 数；
6. 认为某条是误报时停下来问我，不要用 ignore 糊过去；
7. 收尾跑 {{analyze}} / {{test}}，贴原始输出。

输出：doctor 前后摘要 + 每条规则改了什么 + 改动文件清单 + {{analyze}} / {{test}} 原始输出。
```

---

## N. 小改动

### N-1. 单文件 / 小范围修改

```text
任务：在 <范围> 做一个小改动：<任务>。

先读相关文件和现有测试，用一句话说明最小改法；我确认后直接改。
（我已经给了明确指令时，可以跳过确认。）

要求：
1. 只改 <范围>，不顺手重构、不调格式、不升依赖；
2. 行为有变化就补对应测试；纯文案 / 改名不补；
3. 完成后跑 {{analyze}} 和相关测试，贴原始输出；
4. 发现范围外的问题只报告，不修。

输出：diff + 一句话改动理由 + {{analyze}} / 测试原始输出。
```

---

## 2. 输出不对时，加一句话就够

不要重写整段提示词，按症状追加一句：

| 症状 | 追加这句 |
|---|---|
| 格式乱、啰嗦 | 按我给的输出要求再给一次，不要解释过程 |
| 改了不该改的文件 | 只改 <范围>，其他文件不要动 |
| 用了错 / 不存在的 API | 先跑 explain <组件名>，按输出重写用到它的那几处 |
| 说做了但拿不出证据 | 把 analyze 和 test 的原始输出贴出来；没跑就直说 |
| 越做越大 | 停下来，先只给计划，不要写代码 |

### AI 提到的组件，先用 explain 核一遍

AI 说「用某个组件就能解决」时，不要直接信：

```bash
dart run w_tools_cli:w_tools explain <组件名> --format=prompt
```

- 退出码 0：catalog 有记录，按输出核对参数名；
- 退出码 1：catalog 未收录、名字不对，或匹配到多个（会列出候选）；可能是拼错，也可能是未登记的公开类型。
  先按 explain 实际列出的名字重写，再判断是否真的不存在。

同理，AI 说 analyze / test 都过了，但没贴原始输出，就当作没跑。

---

## 3. AI 完成后你必须检查

```text
[ ] 报告里说跑过的命令，都真的跑过；没跑就写明没跑
[ ] 声称的 analyze / test 结果是原文，不是复述
[ ] git diff 没有大范围无关改动
[ ] 没有手改生成物（toolkit / AGENTS 标记块 / .w_tools/AI_PROMPTS.md / lib/app/ui/ starter）
[ ] loading / empty / error / ready 四态完整
[ ] 请求有取消 / dispose 保护（如涉及）
<!-- @if:form -->
[ ] 表单有校验、提交中、错误保留
<!-- @endif -->
[ ] 列表有刷新 / 分页 / footer（如涉及）
<!-- @if:ui -->
[ ] 图片用 WImage.source，限制解码尺寸
<!-- @endif -->
[ ] 路由参数和返回结果正确
[ ] 键盘 / SafeArea / overflow 检查
[ ] 暗色模式和 TextScaler 不溢出
[ ] 业务代码没有直接 import w_tools_*（toolkit / UI 暂存层 / test 下的 dev-only 工具包除外）
[ ] 没有旧 API
[ ] doctor --format=json 0 error
[ ] {{analyze}} 通过
[ ] {{test}} 通过
[ ] 新增 / 修改的组件有测试
```

逐条标 `✅` / `N/A（写理由）` / `❌`；`N/A` 不等于通过。

重点看两件事：**AI 有没有贴原始输出**、**有没有改到清单外的文件**。

---

## 4. 维护这份文档

本文件由 `init` 生成，不要手改：

- 内容与模板不同时，`init` 不覆盖，只报 drift；
- `init --force` 直接覆盖，没有备份；
- 项目自己的提示词另建文件，不要写进这里。

升级 w_tools 后刷新：

```bash
{{pubUpgrade}}
dart run w_tools_cli:w_tools init --check-drift
# 有 drift 时（会覆盖生成物）
dart run w_tools_cli:w_tools init --force
```

场景编号是「族字母-工序号」：字母是任务族，数字是族内工序，按顺序贴。
''';

const String aiPromptsEn = r'''
# w_tools scenario prompts

> Generated by `w_tools_cli` v{{version}}; regenerate with `dart run w_tools_cli:w_tools init --force`.
>
> **This file is generated**: when content differs, `init` does not overwrite and only reports drift;
> `init --force` overwrites it directly, and there is **no backup**.
> Keep your own project prompts elsewhere (for example `.w_tools/PROMPTS.local.md`).
>
> This file is for projects **using** w_tools, not for maintaining the w_tools repo; project rules in
> `{{rulesFiles}}` take precedence.

---

## Start here

### Just three steps

1. Describe the task in one sentence;
2. If unsure which prompt to use, let the AI pick one;
3. Copy the filled-in prompt, or the matching scenario block.

### Let the AI pick a scenario

If unsure which prompt to use, send this first:

```text
I am a {{role}} developer on this project, but I am not familiar with these prompts.

Read only the "1. Scenario selection" section of .w_tools/AI_PROMPTS.md first,
pick a scenario ID, and explain why.

My task: <task>.
Scope: <scope>.

After I confirm the ID, read only that scenario's section and fill the placeholders
from the original text. Ask me first if information is missing, do not guess.
Then give me one copy-ready prompt inside a single code block.
If you cannot read the file, say so and I will paste the section.
```

### Default workflow

For complex or unclear-scope work, split it into rounds:

```text
Round 1: read-only, change no files     A-1 / E-1 / F-1
Round 2: change one scope only          A-2 / E-2 / F-2
Round 3: review only + run checks       F-3 / J-1, then {{analyze}} / {{test}}
```

Multi-round scenarios stay in the same conversation. If you start a new chat, paste the previous
round's output as a handoff first; without a handoff, go back to the previous round.

A small task is one round (still paste the fixed prefix first): B-1 / G-1 / H-1 / I-1 / N-1.

Do not ask for this in round 1:

```text
implement + add tests + update docs + run the whole repo
```

### Check after the AI finishes

Work through §3 "What you must check after the AI finishes" —
there is exactly one checklist in this file, nothing is duplicated here.

---

## 0. Fixed prefix (paste first)

```text
You are a {{role}} developer on this project.

Read {{rulesFiles}} and pubspec.yaml first; project rules take precedence over this file.
If `.w_tools/PROMPTS.local.md` exists, read it first and follow its project conventions.

Rules:
1. Before coding, run:
   dart run w_tools_cli:w_tools context --format=prompt
2. To find components, run:
   dart run w_tools_cli:w_tools list <keyword> --format=prompt
   To look up usage, run:
   dart run w_tools_cli:w_tools explain <Component> --format=prompt
3. Follow explain output for w_tools APIs.
4. Dependencies and entry points: {{dependencyNote}}
   Business code takes APIs from the project toolkit entry ({{toolkitImport}});
   direct `package:w_tools_*` imports belong only in the toolkit itself; with UI enabled, also `lib/app/ui/` and `lib/app/design_system/`;
   dev-only tool imports under `test/` / `tool/` / `integration_test/` are allowed.
5. When editing {{rulesFiles}}, only change content outside the `w_tools:begin/end` block; keep the block generated.
6. After finishing, run {{analyze}} / {{test}}, then:
   dart run w_tools_cli:w_tools doctor --format=json (0 errors)
   Paste the actual output; if you cannot run them, say so.
7. Unless a scenario says otherwise, output = changed file list + key code snippets + raw {{analyze}} / {{test}} output.
```

Fixed-prefix exceptions: scenario selection reads only §1; K-1 does not paste the prefix; L-1 does not run {{analyze}} / {{test}}; every other scenario pastes it first.

---

## Fill-in guide

| Placeholder | What to fill in | Example |
|---|---|---|
| `<task>` | one-sentence goal | order list page |
| `<page>` | page / menu name | "My orders" page |
| `<route>` | route path | `/orders` |
| `<api>` | API path or method name | `GET /api/orders` |
| `<Component>` | public class name | `WFormTextField` |
| `<keyword>` | search term | form |
| `<scope>` | files / feature this round touches | `lib/orders/` |
| `<oldversion>` | current sub-package version (per package; use `pubspec.lock`) | `w_tools_ui 7.0.0` |
| `<newversion>` | target sub-package version | `w_tools_ui 8.0.0` |
| `<flow>` | user path that must work | login -> order -> back |
| `<symptom>` | what you observe | input hidden by keyboard |
| `<package>` | sub-package name (`ui` or `w_tools_ui`) | `ui` |

The `w_tools_cli` version is the **generator version**, not a sub-package version; fill upgrade prompts per package.
Headings carrying `X-n` are scenario IDs: the letter is a task family, the number is a step
inside it; paste them in order.
Beginners most often forget `<route>` and `<api>`: writing only "make a list page" makes the AI
invent field names.

---

## A filled-in example: B-1 list page

Too vague, the AI can only guess:

```text
Use w_tools to make an order list page
```

Filled in enough to verify:

```text
Task: implement the "My orders" list page, route /orders, API GET /api/orders?page=&size=

Confirm first:
- pagination params are page / size, the response has total
- pull-to-refresh yes, infinite scroll no

Requirements:
1. follow the existing list pages in this project
2. first-screen loading / empty / error must be complete
3. load-more failure updates the footer only, do not replace the list
4. use stable keys for list items
5. run analyze + test, and add a list-state test

```

Only three differences: **it gives the route and API**, **it bounds the scope (no infinite scroll)**,
and **it says what to deliver**.

---

## 1. Scenario selection

| What I need | Use |
|---|---|
| A new page / feature | A-1 -> A-2 |
| A list / pagination / refresh | B-1 |
<!-- @if:form -->
| A form / validation / submit | C-1 |
<!-- @endif -->
<!-- @if:api -->
| An API / login / 401 flow | D-1 |
<!-- @endif -->
| Audit existing usage | E-1 (then E-2 to fix) |
| Upgrade w_tools | F-1 -> F-2 -> F-3 |
| Page overflow / jank | G-1 |
| Add white-box tests | H-1 |
| Add black-box tests | I-1 |
| Review AI changes only | J-1 |
| AI cannot read the repo / run commands | K-1 |
| Blocked by w_tools / has a suggestion | L-1 |
| Just adopted / doctor reports errors | M-1 |
| One small change / single-file fix | N-1 |

### Reverse lookup by symptom

| Symptom | Scenario |
|---|---|
| Load-more replaces the whole list | B-1 |
<!-- @if:form -->
| User input is lost after a failed form submit | C-1 |
<!-- @endif -->
<!-- @if:api -->
| Endless retry / blank screen after 401 | D-1 |
<!-- @endif -->
| Field hidden by keyboard / overflow | G-1 |
| AI says it changed things but shows no analyze output | J-1 or K-1 |
| Blocked by w_tools and want to file feedback | L-1 |
| Doctor is all red after init | M-1 |
| Only want to change one spot, nothing else | N-1 |
| Not sure which block to use | "Let the AI pick a scenario" above |

---

## A. New page

### A-1. Read-only plan

```text
Task: implement <page>, route <route>.

Do not write code yet and do not change any file. Read first:
- {{rulesFiles}} / pubspec.yaml
<!-- @if:ui -->
- lib/app/ui/ and lib/app/design_system/
<!-- @endif -->
- 2-3 similar pages
- route registration

Output (only these 7 items, no code):
1. reusable existing pages / components
2. page states: loading / empty / error / ready
3. route and arguments
4. data source
5. w_tools components that need explain
6. file change plan
7. test plan

Wait for my confirmation before A-2.
```

### A-2. Implement the plan

```text
Implement <page> following the plan I confirmed in the previous step; stay in the same conversation, or paste the A-1 plan first in a new chat. Scope: <scope>.

Requirements:
- run context first, then find components with list / explain;
- do not invent a new directory / state architecture;
- do not modify w_tools sub-packages;
- requests need cancel / dispose protection.
```

If the plan must change, go back to A-1; do not redesign inside A-2.

---

## B. List / pagination / refresh

### B-1. Implement the list page

```text
Task: implement the <page> list, route <route>, API <api>.

Confirm first:
- data API and pagination params
- pull-to-refresh
- empty / error / load-more failure
<!-- @if:async -->
- whether the project already uses WAsyncPagedController
<!-- @endif -->

Requirements:
1. follow existing list pages in this project;
2. first-screen loading / empty / error must be complete;
3. load-more failure updates the footer only, do not replace the list;
4. use stable keys for list items;
5. limit image decode size;
6. run analyze + test, and add a list-state test.
```

---

<!-- @if:form -->
## C. Form / validation / submit

### C-1. Implement the form page

```text
Task: implement the <page> form, route <route>.

Requirements:
1. use WForm + direct fields; do not pass field config;
2. validate with field validator; pass validatorSettings to WForm only when you need unified settings (defaults are enough);
3. disable duplicate submit while submitting;
4. preserve user input when the API fails;
5. keep fields visible when the keyboard opens;
6. handle readOnly / edit mode correctly;
7. add a validation + submit test.
```
<!-- @endif -->

---

<!-- @if:api -->
## D. API / login / 401

### D-1. Implement the API / login flow

```text
Task: implement <api> and the login flow for <page>.

Requirements:
1. use WApiConfig + DioRegistry; do not create Dio directly;
2. store tokens with WToken;
3. refresh on 401 and retry only once;
4. show business errors on failure;
5. do not setState after page switch / dispose;
6. run analyze + test.
```
<!-- @endif -->

---

## E. Audit existing code

### E-1. Read-only audit

```text
Audit only; do not modify any file.

Check this project:
1. deleted / outdated w_tools APIs;
2. bypassing w_tools and using underlying libraries directly;
3. duplicated components;
4. violations of {{rulesFiles}};
5. whether enabled capabilities use the right entry point instead of bypassing the wrappers.
   - core: prefer WStorage / WToken / WValidator / WLogger over raw SharedPreferences / print
<!-- @if:ui -->
   - UI: WText / WButton / WImage instead of raw Text / ElevatedButton / Image
<!-- @endif -->
<!-- @if:form -->
   - forms: WForm + direct fields, no config
<!-- @endif -->
<!-- @if:api -->
   - network: WApiConfig + DioRegistry, tokens with WToken
<!-- @endif -->
<!-- @if:toast -->
   - toast: WToast + WToastTheme instead of BotToast directly
<!-- @endif -->
<!-- @if:app -->
   - app: WApp.options / WAppPlugin instead of manual plugin setup
<!-- @endif -->
<!-- @if:async -->
   - async: WAsyncController / WAsyncView instead of hand-maintained loading / error state
<!-- @endif -->
<!-- @if:qr -->
   - QR: WQrView, not QRView directly
<!-- @endif -->
<!-- @if:map -->
   - maps: WMap / WMapZone, not GoogleMap directly
<!-- @endif -->

Run `dart run w_tools_cli:w_tools doctor --format=json` first, then verify with context / list / explain.
For each w_tools type / import, run `explain`; treat exit 1 as "not in catalog / wrong name / ambiguous match",
then check `{{analyze}}` deprecated warnings before deciding to replace it.

Output one table, sorted by severity:
| ID | Severity | File:line | Evidence | Problem | Suggested fix | Acceptance |
Severity: P0 blocking (compile / main flow unusable), P1 should fix (wrong entry / missing state), P2 suggestion (consistency / readability).
Read-only; do not modify files.
```

### E-2. Fix from the list

```text
Fix what the audit above reported; stay in the same conversation, or paste the E-1 table first in a new chat. This round's scope: <scope>.

Requirements:
1. fix one severity at a time, P0 before P1;
2. tag each fix with its audit ID;
3. do not touch code outside the list;
4. rerun doctor afterwards and compare error counts.

Output: which IDs were fixed + changed file list + doctor before/after + raw {{analyze}} / {{test}} output.
```

---

## F. Upgrade w_tools

### F-1. Upgrade plan and outdated API inventory

```text
Task: upgrade the w_tools sub-packages. First list <oldversion> and <newversion> per package from pubspec.lock (versions are independent), then choose this round's scope.

Do not change code yet. Do three things first:
1. read the upgrade notes per package: prefer that package's CHANGELOG (pub.dev / GitHub); for details see
   docs/migrations/ in the w_tools repo (e.g. ui-8.0.md / form-6.0.md; docs/ is not published with the package, so do not assume it is local);
2. find every outdated API and call site in this project;
3. list a per-file change plan.

Output: outdated API inventory (file:line + replacement) + per-file plan + risks.
Wait for my confirmation before F-2.
```

### F-2. Replace file by file

```text
Replace outdated APIs following the F-1 plan; stay in the same conversation, or paste the F-1 plan first in a new chat. This round only covers: <scope>.

Requirements:
1. run `dart run w_tools_cli:w_tools upgrade` first (it bumps w_tools packages and runs pub get; add `--major` or `--only=<package>` to cross a major — a plain `{{pubUpgrade}}` never will);
2. go file by file, one file at a time;
3. do not change unrelated behavior;
4. stop and report any call site the plan missed; do not guess;
5. run {{analyze}} after each batch.

Output: changed files in this batch + key diff + raw {{analyze}} output.
```

### F-3. Verify and report leftovers

```text
Wrap up the upgrade.

Requirements:
1. run {{analyze}} + {{test}} and paste raw output;
2. report leftover outdated APIs per package (file:line if any, otherwise say there are none);
3. refresh the project integration files and check drift:
   {{pubUpgrade}}
   dart run w_tools_cli:w_tools init --check-drift
4. on drift run this (overwrites generated files, no backup):
   dart run w_tools_cli:w_tools init --force

Output: raw {{analyze}} / {{test}} output + leftover list + drift result.
```

---

## G. Debug UI / performance

### G-1. Diagnose UI / performance

```text
Task: diagnose UI / performance issues on <page>; symptom: <symptom>.

Collect first:
- reproduction steps
- device and SDK version
- error / overflow logs
- relevant page code
- explain output

Check:
1. overflow / keyboard obstruction / SafeArea;
2. dark mode / TextScaler;
3. unnecessary rebuilds;
4. image decode size and cache;
5. list keys / controller disposal;
6. whether this is a w_tools usage issue.

Give reproduction and evidence first, then conclusions; mark conclusions without evidence as speculation.

Output: reproduction steps + evidence + root cause + suggested fix + verification.
```

---

## H. White-box tests

### H-1. Add component / unit tests

```text
Task: add white-box tests for <page>.

Prioritize:
- loading / empty / error / ready;
<!-- @if:form -->
- form validation, submit, read-only;
<!-- @endif -->
- controller disposal / request cancellation;
- list refresh / load more / footer;
<!-- @if:api -->
- 401 / request failure.
<!-- @endif -->

Requirements:
- use {{testFramework}};
- follow the existing test style;
- assertions cover real behavior;
- use mocks / fakes instead of the real network;
- run {{test}}.

Output: added / changed test files + raw {{test}} output.
```

---

## I. Black-box tests

### I-1. Add an integration test

```text
Task: add a black-box test for the core flow "<flow>".

Requirements:
1. enter through the user-facing flow: launch -> login -> page -> back;
2. locate by Key / Semantics, not coordinates or random text;
3. use test accounts / test data; never commit real credentials;
4. keep screenshots / logs on failure;
5. prefer the project's existing integration-test setup; coordinate taps only as a fallback.

Run (ask me first if the test directory is missing; use a specific test file when needed):
- {{integrationTest}}

If a real device is needed, first check whether the project depends on w_tools_device:
use it when present, skip it when not, and do not hand-write adb commands.

Output: test files + run result + screenshot / log paths on failure.
```

---

## J. Review changes only

### J-1. Read-only review

```text
Review this change only; do not edit code. Start from `git diff` (or the diff I paste); if you cannot get the diff, ask me what changed.

Check:
1. correct entry points;
2. outdated APIs / duplicated components;
3. unrelated files touched;
4. weakened test standards;
5. hand-edited generated files.

Output: blockers / suggestions / acceptable risks, each with file:line and rationale.
```

---

## K. AI cannot read the repo / run commands

### K-1. Work from snippets

```text
Do not paste the fixed prefix this round: you cannot access the repository or run commands.

Work from the snippets I provide and clearly label:
1. what is based on the snippets;
2. what I must verify by running commands;
3. do not claim analyze / test passed.

I provide:
- the diff
- the relevant pubspec snippet
- explain output
- error / test output
```

---

## L. Feedback to w_tools

### L-1. File one feedback entry

```text
Task: record what blocked you in w_tools (or a capability suggestion) as one feedback entry.

Run `dart run w_tools_cli:w_tools feedback status --json` first and read channel:
- disabled -> stop: tell me "the project has not enabled feedback" and how to enable it (`enabled: true`
  under `feedback:` in .w_tools_doctor.yaml, i.e. `feedback.enabled: true`), then rerun status;
  do not submit, and do not pass --issue;
- ledger / issue -> continue.

Then:
1. Search first: `dart run w_tools_cli:w_tools feedback search "<keyword>" --package=<package>`
   If the same problem exists, give me the file:line or issue number; do not submit a duplicate;
2. Write the body with the fixed fields (missing fields are rejected); show me the draft first:
   - package/version: current version of <package> from pubspec.lock
   - environment: Flutter / Dart / platform / device
   - command / input: the code, command or action that triggers it
   - expected: what should happen
   - actual: what happens; paste the error verbatim
   - impact: time lost / what it broke; write "none" if not applicable
   - suggestion: what you want changed
   - repro data: minimal demo / log excerpt, redacted first
   Save it as /tmp/w_tools_feedback.md;
3. Submit: `dart run w_tools_cli:w_tools feedback submit --package=<package> --title="<symptom>" --body-file=/tmp/w_tools_feedback.md`
   Default route: a local w_tools checkout -> its docs/feedback/; otherwise a GitHub Issue;
   neither -> exit 4 and nothing is written.

Do not:
- add --issue unless I explicitly ask for a public issue;
- paste secrets, tokens or business-sensitive data;
- exceed 3-5 entries per session, and only what actually blocked you;
- write any status other than "pending".

Output: the result (ledger path or issue URL) + a symptom summary under 20 words;
if rejected, paste the error verbatim.
```

---

## M. Setup / health check

### M-1. Fix doctor issues to 0 errors

```text
Task: the project just adopted or upgraded w_tools; fix the doctor report to 0 errors.

Run first:
dart run w_tools_cli:w_tools doctor --format=json

Requirements:
1. report the totals first: error / warn counts per rule (R1-R9), and which rules you will fix first;
2. fix one rule at a time, errors before warnings;
3. only touch files named in the report; no drive-by refactors or formatting;
4. apply the reported `fix` when present; otherwise read `hint` and make the minimal change;
5. rerun doctor after each rule and paste error / warn counts before and after;
6. if you believe an issue is a false positive, stop and ask me; do not silence it with an ignore;
7. finish with {{analyze}} / {{test}} and paste raw output.

Output: doctor before/after + what changed per rule + changed file list + raw {{analyze}} / {{test}} output.
```

---

## N. Small change

### N-1. Single-file / small-scope change

```text
Task: make a small change in <scope>: <task>.

Read the relevant files and existing tests first, then state the minimal change in one sentence;
after I confirm, make the change. (Skip the confirmation if my instruction is already explicit.)

Requirements:
1. only change <scope>; no drive-by refactors, formatting or dependency bumps;
2. add or update a test when behavior changes; no test for pure copy / rename changes;
3. run {{analyze}} and the relevant tests afterwards, and paste raw output;
4. report out-of-scope problems; do not fix them.

Output: diff + one-line rationale + raw {{analyze}} / test output.
```

---

## 2. When the output is wrong, one sentence is enough

Do not rewrite the whole prompt; append one line matching the symptom:

| Symptom | Append this |
|---|---|
| Messy format, too verbose | Re-answer in the output format I gave, without narrating |
| Touched files it should not | Only change <scope>; leave every other file alone |
| Wrong / non-existent API | Run explain <Component> first, then rewrite only where it is used |
| Claims work but shows no evidence | Paste the raw analyze and test output; say so if you did not run them |
| Keeps growing the scope | Stop; give me the plan only, do not write code |

### Verify any component the AI mentions

When the AI says "just use some component", do not trust it:

```bash
dart run w_tools_cli:w_tools explain <Component> --format=prompt
```

- exit code 0: the catalog has it; check the parameter names in the output;
- exit code 1: not in the catalog, the name is wrong, or the query is ambiguous (candidates are
  listed); it may be a typo or an intentionally uncataloged public type. First rewrite using the
  names explain actually lists, then decide whether it truly does not exist.

Likewise, if the AI says analyze / test passed but pastes no raw output, treat it as not run.

---

## 3. What you must check after the AI finishes

```text
[ ] every command it claims to have run was actually run; if not, it says so
[ ] the analyze / test result is raw output, not a paraphrase
[ ] git diff has no large unrelated changes
[ ] no generated file was hand-edited (toolkit / AGENTS block / .w_tools/AI_PROMPTS.md / lib/app/ui/ starter)
[ ] loading / empty / error / ready are all handled
[ ] requests have cancel / dispose protection (when applicable)
<!-- @if:form -->
[ ] forms validate, show submitting state, and keep input on failure
<!-- @endif -->
[ ] lists have refresh / pagination / footer (when applicable)
<!-- @if:ui -->
[ ] images use WImage.source with decode limits
<!-- @endif -->
[ ] route arguments and results are correct
[ ] keyboard / SafeArea / overflow checked
[ ] dark mode and TextScaler do not overflow
[ ] business code has no direct w_tools_* imports (toolkit / UI staging layer / dev-only tools under test excepted)
[ ] no outdated APIs
[ ] doctor --format=json reports 0 errors
[ ] {{analyze}} passes
[ ] {{test}} passes
[ ] new / changed components have tests
```

Mark every item `✅` / `N/A (with reason)` / `❌`; `N/A` is not a pass.

Watch two things above all: **whether the AI pasted raw output**, and **whether it touched files
outside the list**.

---

## 4. Maintaining this file

This file is generated by `init`; do not edit it by hand:

- when content differs, `init` does not overwrite, it only reports drift;
- `init --force` overwrites it directly, with no backup;
- keep your own project prompts in a separate file.

Refresh after upgrading w_tools:

```bash
{{pubUpgrade}}
dart run w_tools_cli:w_tools init --check-drift
# on drift (this overwrites generated files)
dart run w_tools_cli:w_tools init --force
```

Scenario IDs are "family letter - step number": the letter is a task family, the number is a step
inside it; paste them in order.
''';

const String toolkitTemplate = r'''
// w_tools:begin
// generated by w_tools_cli {{version}}; 需要刷新时运行 `dart run w_tools_cli:w_tools init`。
//
// 本项目实际用到的 w_tools 能力清单（聚合入口）。
//
// 业务代码统一 import 这里，不要直接 import 各个子包 ——
// 将来换依赖方式（分包 / 精简聚合）只改这一个文件。
//
// 为什么不用聚合包 w_tools：根包已移除 app/map/qr，能力按需依赖，
// 原生地图/扫码不会被无关项目带入。理由见 https://github.com/stone0533/w_tools/blob/main/docs/adr/0002-consumers-depend-on-subpackages.md 。
library;

export 'package:w_tools_core/w_tools_core.dart';
export 'package:w_tools_app_getx/w_tools_app_getx.dart'; // @optional:app
export 'package:w_tools_form/w_tools_form.dart'; // @optional:form
export 'package:w_tools_ui/w_tools_ui.dart'; // @optional:ui
export 'package:w_tools_api/w_tools_api.dart'; // @optional:api
export 'package:w_tools_toast/w_tools_toast.dart'; // @optional:toast
export 'package:w_tools_qr/w_tools_qr.dart'; // @optional:qr
export 'package:w_tools_map/w_tools_map.dart'; // @optional:map
export 'package:w_tools_map_google/w_tools_map_google.dart'; // @optional:map
export 'package:w_tools_async/w_tools_async.dart'; // @optional:async

// 项目级页面规范
export '../ui/app_bars.dart'; // @optional:ui
export '../ui/app_boxes.dart'; // @optional:ui
export '../ui/app_buttons.dart'; // @optional:ui
export '../ui/app_card.dart'; // @optional:ui
export '../ui/app_scaffold.dart'; // @optional:ui

// w_tools:end
''';

const String designSystemReadme = r'''
<!-- generated by w_tools_cli {{version}} -->

# lib/app/design_system —— 通用组件暂存层

> **这里不是终点，是「等着上移到 w_tools 的候车室」。**
> 判定方法与上移流程见 [w_tools 的接入约定](https://github.com/stone0533/w_tools/blob/main/docs/conventions.md)。

## 项目永久 UI 规范

页面壳、AppBar、按钮规范在 `lib/app/ui/README.md`。
本目录只放**待上移的通用组件**，不要放 AppScaffold / AppBars / AppButtons。

## 什么该放这里

只描述「长什么样」、完全不知道业务的组件：弹窗壳、品牌 logo 方块、图标+文字一行、
虚线分隔、空态/加载态、语义颜色。

**不该放**：知道业务概念的（交易卡、点数徽章、会员等级条）—— 留在 `lib/app/modules/`。

## 四条硬约束

1. **import 边界**：只允许 `dart:*`、`package:flutter*`、`package:w_tools*`、`package:get`；
   禁止 `data/`、`modules/`、`routes/`、`services/`
2. 文件头标 `// STAGED: 待上移到 w_tools_ui`
3. 注释写清设计稿实测尺寸（宽/高/圆角/颜色/行距）
4. 至少一个测试

> 这一层**可以**直接 import 子包（`package:w_tools_ui/...`）：它将来要整体搬进包里。

## 检查

```bash
dart run w_tools_cli:w_tools doctor      # R4 / R5 会检查这一层
```
''';

const String designSystemReadmeEn = r'''
<!-- generated by w_tools_cli {{version}} -->

# lib/app/design_system — staging area for shared components

> **This is not the destination — it is the waiting room before moving into w_tools.**
> See the [w_tools conventions](https://github.com/stone0533/w_tools/blob/main/docs/conventions.md).

## Permanent project UI conventions

Page shells, app bars, and button conventions live in `lib/app/ui/README.md`.
This directory only holds **components waiting for promotion**; do not put
AppScaffold / AppBars / AppButtons here.

## What belongs here

Components that only describe “what it looks like” and know nothing about business:
dialog shells, brand logo tiles, icon+label rows, dashed dividers, empty/loading states,
semantic colors.

**Does not belong**: things that know business concepts (transaction cards, points badges,
membership tiers) — keep them in `lib/app/modules/`.

## Four hard rules

1. **Import boundary**: only `dart:*`, `package:flutter*`, `package:w_tools*`, `package:get`;
   never `data/`, `modules/`, `routes/`, `services/`
2. Header `// STAGED: move to w_tools_ui`
3. Comments include measured design specs (width/height/radius/color/line-height)
4. At least one test

> This layer **may** import subpackages directly (`package:w_tools_ui/...`):
> it will be moved into the package as a whole.

## Check

```bash
dart run w_tools_cli:w_tools doctor      # R4 / R5 check this layer
```
''';

const String agentsBase = r'''
<!-- w_tools:begin -->
<!-- generated by w_tools_cli {{version}}; 本块由 init 生成，手改会被覆盖；过期检查 `dart run w_tools_cli:w_tools init --check-drift` -->
## 怎么用 w_tools

1. **先拿事实**：`dart run w_tools_cli:w_tools context --format=prompt`
   （装了哪些包与版本、toolkit 导出了什么、该跑哪些检查）。
2. **先找现成的**：`dart run w_tools_cli:w_tools list <关键词>`，需要细节再
   `dart run w_tools_cli:w_tools explain <组件名>`；**不要凭记忆造组件名**，组件事实以 explain 为准。
3. **业务代码只 import 聚合入口**：`import 'package:{{toolkitImport}}';`。
4. **找不到 → 先落暂存层** `{{designSystemDir}}/`，**不要**直接改 w_tools。
5. **场景提示词**在 `.w_tools/AI_PROMPTS.md`：按 `A-1` / `B-1` / `C-1` / `E-1` 读一节，不要整份贴。

## 硬规则（`doctor` 会拦）

- **依赖**：只依赖具体子包，不用聚合包 `w_tools`（R1）。
- **import**：业务代码只 import 聚合入口；例外：{{importExceptions}}（R2）。
- **生成物不要手改**：`{{toolkitEntry}}`、本标记块、`{{projectUiDir}}/`；刷新用 `init --force`，
  UI 脚手架用 `init --force-starters`。
- **升级依赖**：`dart run w_tools_cli:w_tools upgrade --check` 看落后哪几个包；写入用 `upgrade`
  （只动 `w_tools*`，跨 major 需 `--major`）。
- **新组件先暂存**：`{{designSystemDir}}/` + 文件头 `// STAGED: 待上移到 w_tools_ui`；
  默认值要能直接用、至少有测试、API 参数优先 ≤ 3 个；是否进包由维护者决定，进包时由包维护者补 CHANGELOG（R4 / R5）。
- **禁用 API** 见 `.w_tools_doctor.yaml` 的 `banned`（R9）；未登记的旧写法仍需人工评审。

## 组件约定（一句话规则；细节用 `explain`，不要在这里背 API）
''';

const String agentsClosing = r'''
## 完成前

- `dart run w_tools_cli:w_tools doctor --format=json` → 0 error；规则清单与启用状态（R1~R9）也在这里看。
- `{{analyze}}`、`{{test}}`；跑不了就明确说没跑，不要贴假输出。
- 用 w_tools 遇到问题 / 有改进建议时：先查重；仅当
  `.w_tools_doctor.yaml` 的 `feedback.enabled: true` 时才提交：
  `dart run w_tools_cli:w_tools feedback search "<关键词>" --package=<包>` → `feedback submit ...`；
  默认关闭时跳过（不写文件、不建 Issue、不加 `--issue`）；完整流程见 `.w_tools/AI_PROMPTS.md` 的 L-1。
<!-- w_tools:end -->
''';

const String agentsUi = r'''
- **页面与 UI**（`{{projectUiDir}}/` 是项目永久 UI 层，由 CLI 生成、不走 STAGED、不计划上移）：
  页面壳 `AppScaffold`（原生 `WScaffold` / `WAppBar` 只在特殊顶部栏或非标准安全区用）；
  `AppButtons` / `WButton` / `WPressable`；`WText(variant:)` / `WText.rich` / `WIconText`；`WImage.source`；`WListView` /
  `WKeepAliveWrapper` / `WNotificationListener` / `WGradientCircularProgressIndicator`；
  `WNavBar` / `WTabBar` / `WStep` / `WBadge`（`WBadge.count` / `WBadge.dot`）/ `WActionRow`；`WScreen` / `WAssets`；
  `WSizeBox` / `WPadding` 已在 5.0 删除，用原生 `SizedBox` / `Padding`。细节：`explain WImage` / `explain WText` / `explain WIconText` / `{{projectUiDir}}/README.md`。
''';

const String agentsForm = r'''
- **表单**（`explain WForm`）：`WForm` + 直接字段 `WFormTextField` / `WFormDropdown` / `WFormMultiDropdown` /
  `WFormDatePicker` / `WFormCheckbox` / `WFormRadioGroup`；`WFormController` 必须一对一；整页只读 `readOnly`；
  校验 `WFormValidator` / `WFormValidatorSettings`；字段值选择 `WFormButton`；不要从 `Config.build` 开始。
''';

const String agentsApi = r'''
- **接口**（`WApiConfig` + `DioRegistry.forBaseUrl`）：不要直接 `Dio()`，裸 Dio 必须传 `dio:`；
  token 用 `WToken` + `WTokenInterceptor`，日志用 `WLogInterceptor`。细节：`explain WApiConfig`。
- **调用**（`WApiClient`）：GET/POST/PUT/PATCH/DELETE 用 `WApiClient`；`decode` 必须显式传，
  不要手写 `response.data as Map`。细节：`explain WApiClient`。
''';

const String agentsApp = r'''
- **启动 / 插件**（`explain WApp`）：`WApp.options(WAppOptions(...)).start()`；插件 `WAppPlugin` + `dependsOn`，
  非 GetX 用 `WAppPluginRunner`；语言 `WLanguage` / `WLocaleConfig`；路由栈 `WRouteStack`（`app.routeStack`）；
  外观 `WAppTheme`；底部面板 `WBottomSheet`。
  插件里注册服务用 `registerService(() => Svc().init())`；`Future<void> onInit() => Get.putAsync(...)`
  会把泛型推成 `void`，实例注册到 `void` 下，`Get.find` 找不到且 analyzer 不报。
''';

const String agentsAsync = r'''
- **异步区块**（`explain WAsyncPagedController`）：`WAsyncController` + `WAsyncView`，滚动页 `WAsyncStateBuilder`，
  sliver 用 `WAsyncStateSliver`；`WAsyncStatus` / `WAsyncStrings` 走 `WAsyncTheme`（放 App 根节点）；
  结果分支 `WAsyncSuccess` / `WAsyncFailure` / `WAsyncCancelled`，取消异常 `WCancellationException`；
  纯执行（不要 UI）用 `WAsync.tryRun` / `WAsync.run`；独立区块用 `WAsync.settle` 保留每个结果；
  单区块本地替换用 `WAsyncController.replaceData`；分页 `WAsyncPagedController`，`loadMore` 失败只写 `loadMoreError`，
  footer 直接读 `footerStatus`（hidden / loading / failed / noMore / loadMore），重建用 `changes`；
  默认 loading / empty / error 视图带 `liveRegion`，自定义 builder 要自己保留语义。
  `WAsync` 的 `state` 是 `ValueListenable` 不是 `Rx`：换成 `WAsyncStateBuilder` 后外层 `Obx` 还得包着，
  删掉不报错，但页面里其它 Rx 状态不再触发重建。
''';

const String agentsToast = r'''
- **提示**（`WToast` + `WToastStyle` / `WToastTheme`）：根节点一次 `BotToastInit` +
  `BotToastNavigatorObserver`，否则静默失败；遮罩提示用 `WToast.showModal`，不要用 `showCustomDialog`。
  细节：`explain WToast`。
''';

const String agentsCore = r'''
- **基础工具**（`WStorage` 读前先 `await WStorage.init()`；`WValidator` / `WRegExp` / `WLogger` / `WDebounce`）：
  `WStorage` / `WToken` 是明文存储。细节：`explain WStorage`。
''';

const String agentsQr = r'''
- **扫码**（`WQrView` + `WQrController`，页面创建并 `dispose`）：重扫用 `controller.restart()`；
  连续扫描 `scanOnce: false` + `scanInterval`。细节：`explain WQrView`。
''';

const String agentsMap = r'''
- **地图**（`WMap` / `WMapZone`，配置放 `WMapOptions`）：`markerId` 必须稳定，`json_serializable` 模型用
  `WMapItem` / `WMapItemMapper`；需要 Google Maps API Key。细节：`explain WMap`。
''';

const String agentsFigma = r'''
- **设计稿取数**（`w_tools_figma`，可选）：`{{figmaInstall}}` → `dart run w_tools_figma:figma init`；
  常用 `spec <nodeId> --json` / `tokens` / `diff --if-stale`，不要默认 `--refresh`；
  完整命令 `dart run w_tools_figma:figma help`，额度 / 退出码见 packages/figma/README.md。
''';

const String agentsDevice = r'''
- **设备 / 真机验证**（`w_tools_device`，可选）：先读 `docs/agents/device-testing.md`，不要手写 adb / DeviceHub。
  子命令：`dart run w_tools_device:device list|boot|shot|calibrate|tap|drag|type|size|foreground|wait|verify`。
  E2E 自动登录用 `w_tools_e2e`（只放 `tool/main_e2e.dart`，凭证只用测试账号）。
''';

const String agentsBaseEn = r'''
<!-- w_tools:begin -->
<!-- generated by w_tools_cli {{version}}; generated by init — edits inside this block are overwritten; stale check: `dart run w_tools_cli:w_tools init --check-drift` -->
## Working with w_tools

1. **Get facts first**: `dart run w_tools_cli:w_tools context --format=prompt`
   (installed packages and versions, toolkit exports, checks to run).
2. **Reuse before writing**: `dart run w_tools_cli:w_tools list <keyword>`, then
   `dart run w_tools_cli:w_tools explain <Component>`; **do not invent component names** —
   `explain` is the source of truth.
3. **Business code imports the toolkit entry only**: `import 'package:{{toolkitImport}}';`.
4. **Nothing fits → stage it first** in `{{designSystemDir}}/`; **do not** modify w_tools directly.
5. **Scenario prompts** live in `.w_tools/AI_PROMPTS.md`: read one section (`A-1` / `B-1` / `C-1` / `E-1`),
   not the whole file.

## Hard rules (`doctor` enforces)

- **Dependencies**: specific sub-packages only, never the aggregate `w_tools` (R1).
- **Imports**: business code imports the toolkit entry only; exceptions: {{importExceptions}} (R2).
- **Do not hand-edit generated files**: `{{toolkitEntry}}`, this block, `{{projectUiDir}}/`;
  refresh with `init --force` (`init --force-starters` for UI starters).
- **Upgrading dependencies**: `dart run w_tools_cli:w_tools upgrade --check` lists what is behind;
  write with `upgrade` (touches `w_tools*` only; cross-major needs `--major`).
- **Stage new components first**: `{{designSystemDir}}/` + header `// STAGED: move to w_tools_ui`;
  working defaults, at least one test, prefer ≤ 3 API parameters; promotion is the maintainers' call,
  and package maintainers add the CHANGELOG entry (R4 / R5).
- **Banned APIs** live in `.w_tools_doctor.yaml` (`banned`, R9); unregistered legacy forms still need review.

## Component conventions (one line each; details via `explain`, not memorised here)
''';

const String agentsClosingEn = r'''
## Before done

- `dart run w_tools_cli:w_tools doctor --format=json` → 0 error; the rule list and activation state (R1–R9) live there.
- `{{analyze}}`, `{{test}}`; if you cannot run them, say so — never paste fake output.
- If you hit a problem or have a suggestion while using w_tools: search first; submit only when
  `.w_tools_doctor.yaml` has `feedback.enabled: true`:
  `dart run w_tools_cli:w_tools feedback search "<keywords>" --package=<package>` → `feedback submit ...`;
  skip when off (no files, no Issue, no `--issue`). Full flow: `.w_tools/AI_PROMPTS.md` L-1.
<!-- w_tools:end -->
''';

const String agentsUiEn = r'''
- **Pages and UI** (`{{projectUiDir}}/` is the permanent project UI layer, generated by the CLI; not a
  staging area, not planned for promotion): page shell `AppScaffold` (use raw `WScaffold` /
  `WAppBar` only for custom app bars or non-standard safe areas); `AppButtons` / `WButton` /
  `WPressable`; `WText(variant:)` / `WText.rich` / `WIconText`; `WImage.source`; `WListView` / `WKeepAliveWrapper` /
  `WNotificationListener` / `WGradientCircularProgressIndicator`; `WNavBar` / `WTabBar` / `WStep` /
  `WBadge` / `WActionRow`; `WScreen` / `WAssets`;
  `WSizeBox` / `WPadding` were removed in 5.0 — use native `SizedBox` / `Padding`.
  Details: `explain WImage` / `explain WText` / `explain WIconText` / `{{projectUiDir}}/README.md`.
''';

const String agentsFormEn = r'''
- **Forms** (`explain WForm`): `WForm` + direct fields `WFormTextField` / `WFormDropdown` /
  `WFormMultiDropdown` / `WFormDatePicker` / `WFormCheckbox` / `WFormRadioGroup`; `WFormController`
  must be one-to-one; whole-form read-only via `readOnly`; validation with `WFormValidator` /
  `WFormValidatorSettings`; `WFormButton` for field values; never start from `Config.build`.
''';

const String agentsApiEn = r'''
- **Network** (`WApiConfig` + `DioRegistry.forBaseUrl`): never a bare `Dio()`; a raw Dio must receive
  `dio:`; tokens via `WToken` + `WTokenInterceptor`, logging via `WLogInterceptor`.
  Details: `explain WApiConfig`.
- **Calls** (`WApiClient`): GET/POST/PUT/PATCH/DELETE via `WApiClient`; always pass an explicit
  `decode`; never hand-cast `response.data`. Details: `explain WApiClient`.
''';

const String agentsAppEn = r'''
- **Startup / plugins** (`explain WApp`): `WApp.options(WAppOptions(...)).start()`; plugins implement
  `WAppPlugin` and declare `dependsOn`; `WAppPluginRunner` for non-GetX shells; language via
  `WLanguage` / `WLocaleConfig`; route stack via `WRouteStack` (`app.routeStack`); appearance via
  `WAppTheme`; bottom sheets via `WBottomSheet`.
  Register services with `registerService(() => Svc().init())`; `Future<void> onInit() => Get.putAsync(...)`
  infers the generic as `void`, the instance lands under `void`, and `Get.find` misses it without an analyzer error.
''';

const String agentsAsyncEn = r'''
- **Async blocks** (`explain WAsyncPagedController`): `WAsyncController` + `WAsyncView`;
  `WAsyncStateBuilder` for scroll pages, `WAsyncStateSliver` for slivers; `WAsyncStatus` /
  `WAsyncStrings` come from `WAsyncTheme` (at the app root); branch on `WAsyncSuccess` /
  `WAsyncFailure` / `WAsyncCancelled`, cancellation throws `WCancellationException`; for execution
  without UI use `WAsync.tryRun` / `WAsync.run`; use `WAsync.settle` for independent sections so
  every result survives; replace one block locally with `WAsyncController.replaceData`; paginate
  with `WAsyncPagedController` and write `loadMoreError` on failure; render the paged footer from
  `footerStatus` (hidden / loading / failed / noMore / loadMore) and rebuild via `changes`;
  default loading / empty / error views carry `liveRegion`, keep semantics in custom builders.
  `WAsync`'s `state` is a `ValueListenable`, not `Rx`: after switching to `WAsyncStateBuilder` the
  outer `Obx` still has to wrap it; deleting it compiles, but other Rx state stops rebuilding.
''';

const String agentsToastEn = r'''
- **Toasts** (`WToast` + `WToastStyle` / `WToastTheme`): install `BotToastInit` +
  `BotToastNavigatorObserver` once at the root, otherwise every toast fails silently; use
  `WToast.showModal` for barrier hints, not `showCustomDialog`. Details: `explain WToast`.
''';

const String agentsCoreEn = r'''
- **Core utilities** (`WStorage`: call `await WStorage.init()` before reads; `WValidator` /
  `WRegExp` / `WLogger` / `WDebounce`): `WStorage` / `WToken` are plaintext storage.
  Details: `explain WStorage`.
''';

const String agentsQrEn = r'''
- **Scanning** (`WQrView` + `WQrController`, created and disposed by the page): restart with
  `controller.restart()`; for continuous scanning use `scanOnce: false` + `scanInterval`.
  Details: `explain WQrView`.
''';

const String agentsMapEn = r'''
- **Maps** (`WMap` / `WMapZone`, configure via `WMapOptions`): marker ids must be stable, and
  `json_serializable` models use `WMapItem` / `WMapItemMapper`; a Google Maps API key is required.
  Details: `explain WMap`.
''';

const String agentsFigmaEn = r'''
- **Design specs** (`w_tools_figma`, optional): `{{figmaInstall}}`, then
  `dart run w_tools_figma:figma init`; common commands `spec <nodeId> --json` / `tokens` /
  `diff --if-stale`, never `--refresh` by default; full list via
  `dart run w_tools_figma:figma help`, quota / exit codes in `packages/figma/README.md`.
''';

const String agentsDeviceEn = r'''
- **Device validation** (`w_tools_device`, optional): read `docs/agents/device-testing.md` first; never
  hand-roll adb / DeviceHub. Subcommands:
  `dart run w_tools_device:device list|boot|shot|calibrate|tap|drag|type|size|foreground|wait|verify`.
  Use `w_tools_e2e` for E2E login (keep it in `tool/main_e2e.dart`, test accounts only).
''';

const String uiReadme = r'''
<!-- generated by w_tools_cli {{version}} -->

# lib/app/ui —— 项目永久 UI 规范

这里放项目自己的设计系统与页面约定，**不用于上移到 w_tools_ui**。

- `app_bars.dart`：AppBar 默认样式，唯一入口 `AppBars.style`
- `app_boxes.dart`：盒子装饰注册表（`AppBoxes.card(context)` / `AppBoxes.warning(context)`）
- `app_buttons.dart`：按钮样式注册表，页面只使用 `AppButtons`
- `app_card.dart`：重复卡片入口 `AppCard`
- `app_scaffold.dart`：标准页面入口 `AppScaffold`

## 主题

`WText(variant:)` 的 `price` / `number` / `badge` 依赖主题里的语义样式；App 启动时装一次：

```dart
final base = ThemeData(colorScheme: scheme, useMaterial3: true);
theme: base.withWTextStyles(WTextStyles.fromTextTheme(base.textTheme)),
```

图片需要 App 级占位 / 错误兜底时，在根节点包 `WImageTheme(slots: WImageSlots(...))`。
不要在页面里逐个 `WText(style: ...)` 覆盖全局字体。

## 页面

```dart
AppScaffold(
  title: '标题',
  body: ...,
)
```

特殊顶部栏：

```dart
AppScaffold(
  appBar: WAppBar(...),
  body: ...,
)
```

## 按钮

```dart
WButton(
  style: AppButtons.primary(context),
  label: '提交',
  onTap: submit,
)
```

真按钮用 `WButton`；任意 child/卡片点击用 `WPressable`；不要用 `WButton` 包任意 child。

## 盒子与卡片

重复的 `BoxDecoration` 收进 `AppBoxes`：

```dart
Container(
  decoration: AppBoxes.card(context),
  padding: const EdgeInsets.all(16),
  child: ...,
)
```

重复卡片：

```dart
AppCard(
  child: ...,
)
```

圆角卡片包含图片等子内容时，显式裁剪：

```dart
AppCard(
  clipBehavior: Clip.antiAlias,
  padding: EdgeInsets.zero,
  child: WImage.asset('cover.png'),
)
```

一次性盒子直接用 `Container` + `BoxDecoration`；需要 width / height / constraints /
transform 时也直接用 `Container`。

`AppScaffold` 内部使用 `WScaffold`；业务页面不要绕过 `AppScaffold` 直接使用 `WScaffold`。
需要 drawer / bottomSheet / 非标准安全区时，用 `WScaffold` 或原生 `Scaffold`，并在 PR 说明。

> 待上移的通用组件放 `lib/app/design_system/`，不要混进这里。
''';

const String uiReadmeEn = r'''
<!-- generated by w_tools_cli {{version}} -->

# lib/app/ui — permanent project UI conventions

Project-owned design system and page conventions live here.
These files are **not** candidates for moving into `w_tools_ui`.

- `app_bars.dart`: default app-bar style, entry point `AppBars.style`
- `app_boxes.dart`: box decoration registry (`AppBoxes.card(context)` / `AppBoxes.warning(context)`)
- `app_buttons.dart`: button style registry, pages use `AppButtons`
- `app_card.dart`: repeated-card entry `AppCard`
- `app_scaffold.dart`: standard page entry `AppScaffold`

## Theme

`WText(variant:)` resolves `price` / `number` / `badge` from the theme; install once at app start:

```dart
final base = ThemeData(colorScheme: scheme, useMaterial3: true);
theme: base.withWTextStyles(WTextStyles.fromTextTheme(base.textTheme)),
```

For app-level image placeholder/error fallbacks, wrap the root with
`WImageTheme(slots: WImageSlots(...))`. Do not override global typography with
per-page `WText(style: ...)`.

## Pages

```dart
AppScaffold(
  title: 'Title',
  body: ...,
)
```

Custom app bar:

```dart
AppScaffold(
  appBar: WAppBar(...),
  body: ...,
)
```

## Buttons

```dart
WButton(
  style: AppButtons.primary(context),
  label: 'Submit',
  onTap: submit,
)
```

Use `WButton` for real buttons and `WPressable` for arbitrary card/child taps.
`AppScaffold` uses `WScaffold` internally; business pages must not bypass `AppScaffold` and use `WScaffold` directly.

Use `WScaffold` or plain `Scaffold` for drawers/bottom sheets/non-standard safe areas,
and explain why in the PR.

## Boxes and cards

Put repeated `BoxDecoration` values in `AppBoxes`:

```dart
Container(
  decoration: AppBoxes.card(context),
  padding: const EdgeInsets.all(16),
  child: ...,
)
```

Use `AppCard` for repeated cards:

```dart
AppCard(
  child: ...,
)
```

Clip rounded cards when the child is an image or other overflowing content:

```dart
AppCard(
  clipBehavior: Clip.antiAlias,
  padding: EdgeInsets.zero,
  child: WImage.asset('cover.png'),
)
```

Use `Container` + `BoxDecoration` for one-off boxes, and `Container` directly when you
need width / height / constraints / transform.

> Components waiting for promotion belong in `lib/app/design_system/`, not here.
''';

const String deviceTestingDoc = r'''
# 设备验证（w_tools_device）

> 项目：`{{projectName}}`
> 本文件由 `dart run w_tools_cli:w_tools init --device` 生成，只包含通用设备命令；项目自己的
> 设备、账号、tab 布局请写到项目文档，不要改这份通用说明。
> 完整参数以 [`packages/device/README.md`](https://github.com/stone0533/w_tools/blob/main/packages/device/README.md) 为准。

## 平台支持

| 平台 | list | shot | tap / drag / verify | foreground |
| --- | --- | --- | --- | --- |
| iOS 模拟器 | ✅ | ✅ | ✅ | ❌ |
| iOS 真机 | ✅ | ✅ | ❌（需 idb / XCUITest） | ❌ |
| Android 模拟器 / 真机 | ✅ | ✅ | ✅（adb） | ✅ |

## 安装

```bash
dart pub add dev:w_tools_device
```

## 常用命令

```bash
# 模拟器
dart run w_tools_device:device list
dart run w_tools_device:device boot "<名称>"
dart run w_tools_device:device shot --out=/tmp/shot.png
dart run w_tools_device:device calibrate
dart run w_tools_device:device tap <x> <y>
dart run w_tools_device:device drag <x1> <y1> <x2> <y2>
dart run w_tools_device:device verify <x> <y> --region=<x,y,w,h>
dart run w_tools_device:device wait --region=<x,y,w,h>

# iOS 真机（只读）
dart run w_tools_device:device list --real
dart run w_tools_device:device shot --real --device=<名称>

# Android（坐标 = 截图像素）
dart run w_tools_device:device list --android
dart run w_tools_device:device size --android
dart run w_tools_device:device shot --android --out=/tmp/shot.png
dart run w_tools_device:device tap --android <x> <y>
dart run w_tools_device:device foreground --android
```

## 注意事项

- iOS 模拟器点击需要 cliclick，并给宿主 App 开「辅助功能」+「屏幕录制」；
- iOS 真机只能 list/shot，点击需要 idb/XCUITest；
- Android 不需要 cliclick/标定，`tap` 坐标就是截图像素；
- 多台 Android 就绪且未指定 `--device`（或型号子串命中多台）会报错并列出设备，用 `--device=` 指定；
- `verify` 默认比较整屏，动画/轮播会误判；用 `--region` 只看会变的区域；
- `--scale` 只用于 iOS 模拟器的 calibrate/tap/drag/size/wait/verify；
- 退出码：`0` 成功 · `1` verify 没变化 · `2` 参数/配置错误 · `3` 外部不可用 / 超时 · `4` 未分类执行错误；
- 标定缓存：`~/.cache/w_tools_device/<udid>.json`。

## 可选 recipe

- Tab 型 App 的冒烟示例（不是 init 生成物）：
  <https://github.com/stone0533/w_tools/blob/main/packages/device/example/tool/device_smoke.dart>
- Keep-alive / TickerMode 集成测试：
  <https://github.com/stone0533/w_tools/blob/main/docs/recipes/keepalive-integration-test.md>
- E2E 免登录：
  <https://github.com/stone0533/w_tools/blob/main/docs/recipes/e2e-login.md>

## 项目自检清单

- [ ] 能列出至少一台已启动设备
- [ ] 能截图，且不是全黑
- [ ] 能用 `verify --region` 确认一次真实 UI 变化
- [ ] iOS 真机已解锁并信任；Android 已授权调试
''';

const String deviceGradleMirror = r'''
// 本机 Gradle 镜像（仅影响这台机器，不改项目配置）。
//
// 原因：JVM 到 dl.google.com / repo1.maven.org 的 TLS 握手被网络设备终止
// （curl 能通、Java 不通），表现为 "server may not support the client's requested
// TLS protocol versions"。aliyun 镜像可正常访问，且包含同样的构件。
//
// 作用：把所有 google() / mavenCentral() / gradlePluginPortal() 换成 aliyun 镜像。

// included build（如 flutter_tools/gradle 的 composite build）有自己的仓库策略，
// 往它们的 project.repositories 里加仓库会触发
// "prefer settings repositories over project repositories" 报错 —— 直接跳过。
if (gradle.parent != null) {
    return
}

def MIRRORS = [
    'https://maven.aliyun.com/repository/google',
    'https://maven.aliyun.com/repository/central',
    'https://maven.aliyun.com/repository/gradle-plugin',
]

def isBlocked = { repo ->
    if (!(repo instanceof org.gradle.api.artifacts.repositories.MavenArtifactRepository)) return false
    def u = repo.url.toString()
    return u.contains('dl.google.com') ||
           u.contains('maven.google.com') ||
           u.contains('repo1.maven.org') ||
           u.contains('repo.maven.apache.org') ||
           u.contains('plugins.gradle.org')
}

def rewrite = { handler ->
    // 已经存在的先摘掉
    def existing = []
    handler.each { r -> if (isBlocked(r)) existing << r }
    existing.each { r -> handler.remove(r) }
    // 之后再声明 google()/mavenCentral() 也直接摘掉，避免它们排在镜像前面
    handler.whenObjectAdded { r ->
        if (isBlocked(r)) {
            try { handler.remove(r) } catch (ignored) { }
        }
    }
    MIRRORS.each { m -> handler.maven { url = m } }
}

settingsEvaluated { settings ->
    rewrite(settings.pluginManagement.repositories)
}

allprojects { project ->
    rewrite(project.repositories)
    rewrite(project.buildscript.repositories)
}
''';

const String appBarsTemplate = r'''
// generated by w_tools_cli {{version}}; refresh check: `dart run w_tools_cli:w_tools init --check-drift`
//
// 项目 AppBar 默认样式。所有页面统一从这里取，不要在页面里写 WAppBarStyle。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

abstract final class AppBars {
  static WAppBarStyle style(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return WAppBarStyle(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      height: 56,
      systemOverlayStyle: scheme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    );
  }
}
''';

const String appBoxesTemplate = r'''
// generated by w_tools_cli {{version}}; refresh check: `dart run w_tools_cli:w_tools init --check-drift`
//
// 项目盒子装饰注册表。重复的 BoxDecoration 放这里，页面不要到处写颜色/圆角。
import 'package:flutter/material.dart';

abstract final class AppBoxes {
  static BoxDecoration card(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: scheme.surface,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      border: Border.fromBorderSide(
        BorderSide(color: scheme.outlineVariant),
      ),
    );
  }

  /// 固定品牌警示色；如果项目要完全跟随主题，可改用 scheme.tertiaryContainer。
  static BoxDecoration warning(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: dark ? const Color(0xFF3A2A00) : const Color(0xFFFFF8E1),
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      border: const Border.fromBorderSide(
        BorderSide(color: Color(0xFFFFB300)),
      ),
    );
  }
}
''';

const String appButtonsTemplate = r'''
// generated by w_tools_cli {{version}}; refresh check: `dart run w_tools_cli:w_tools init --check-drift`
//
// 项目按钮样式注册表。页面只使用 AppButtons，不直接写 WButtonStyle。
import 'package:flutter/material.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

abstract final class AppButtons {
  static WButtonStyle primary(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return WButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.pressed)) {
          return scheme.primary.withValues(alpha: 0.82);
        }
        if (states.contains(WidgetState.hovered)) {
          return scheme.primary.withValues(alpha: 0.92);
        }
        return scheme.primary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.38);
        }
        return scheme.onPrimary;
      }),
      borderRadius: BorderRadius.circular(8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      disabledOpacity: 1,
    );
  }

  static WButtonStyle secondary(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return WButtonStyle.outlined(
      foregroundColor: scheme.primary,
      borderColor: scheme.primary,
    );
  }

  static WButtonStyle text(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return WButtonStyle.text(foregroundColor: scheme.primary);
  }

  static WButtonStyle danger(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return WButtonStyle.filled(
      backgroundColor: scheme.error,
      foregroundColor: scheme.onError,
      borderRadius: BorderRadius.circular(8),
    );
  }
}
''';

const String appCardTemplate = r'''
// generated by w_tools_cli {{version}}; refresh check: `dart run w_tools_cli:w_tools init --check-drift`
//
// 项目重复卡片入口。特殊尺寸/约束/transform 请直接用 Container。
import 'package:flutter/material.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

import 'app_boxes.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.decoration,
    this.clipBehavior = Clip.none,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BoxDecoration? decoration;
  final Clip clipBehavior;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: decoration ?? AppBoxes.card(context),
      padding: padding,
      clipBehavior: clipBehavior,
      child: child,
    );

    if (onTap == null) return card;

    return WPressable(
      onTap: onTap,
      child: card,
    );
  }
}
''';

const String appScaffoldTemplate = r'''
// generated by w_tools_cli {{version}}; refresh check: `dart run w_tools_cli:w_tools init --check-drift`
//
// 项目页面默认入口。标准页面只传 title/actions/body；
// 特殊顶部栏用 appBar: WAppBar(...)，其他例外用 WScaffold 并在 PR 说明。
import 'package:flutter/material.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

import 'app_bars.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions = const <Widget>[],
    this.onBack,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    required this.body,
  });

  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final WAppBar? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    assert(
      appBar == null ||
          (title == null &&
              titleWidget == null &&
              leading == null &&
              actions.isEmpty &&
              onBack == null),
      'AppScaffold: 传了 appBar 时不要再传 title/leading/actions/onBack',
    );

    if (appBar != null) {
      return WScaffold(
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
      );
    }

    final hasTopBar =
        title != null || titleWidget != null || leading != null || actions.isNotEmpty || onBack != null;
    if (!hasTopBar) {
      return WScaffold(
        body: body,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
      );
    }

    return WScaffold.basic(
      title: title ?? '',
      titleWidget: titleWidget,
      leading: leading,
      actions: actions,
      onBack: onBack,
      appBarStyle: AppBars.style(context),
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
''';

