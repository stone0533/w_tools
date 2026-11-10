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
1. 先按 <新版本> 改 pubspec 约束并 pub get（跨 major 时普通 pub upgrade 不会生效；可手动改约束或用 `{{pubUpgrade}} --major-versions`）；
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
