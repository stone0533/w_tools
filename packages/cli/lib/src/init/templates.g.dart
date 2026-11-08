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
我是本项目的 Dart / Flutter 开发者，但不熟悉这些提示词。

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

小任务一轮就够（固定前缀照旧先贴）：B-1 / G-1 / H-1 / I-1。

不要第一轮就：

```text
实现 + 补测试 + 改文档 + 跑全仓
```

### AI 完成后先看

按文末「3. AI 完成后你必须检查」逐条核对 —— 全文只有这一份清单，不在这里另抄一份。

---

## 0. 固定前缀（每次先贴）

```text
你是本项目的 Dart / Flutter 开发者。

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
   直接 import package:w_tools_* 只出现在 toolkit 自身；启用 UI 时还包括 lib/app/ui/、lib/app/design_system/。
5. 只改 {{rulesFiles}} 中 `w_tools:begin/end` 标记块外的内容；块内保持生成原样。
6. 完成后运行 {{analyze}} / {{test}}，并贴实际输出；不能运行就明确说没运行。
7. 除非场景另有规定，默认输出 = 改动文件清单 + 关键代码片段 + {{analyze}} / {{test}} 原始输出。
```

固定前缀的例外：让 AI 选场景时只读 §1；K-1 不贴固定前缀；其余场景每次先贴。

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
2. 校验用字段 validator；WForm 统一传 validatorSettings；
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
对每个 w_tools 类型 / import 跑 `explain`；exit 1 记为“catalog 未收录或名字不对”，
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
1. 按包读 migration 文档
   （w_tools 仓库 docs/migrations/ 按包和版本找，例如 ui-7.0.md / form-5.1.md；或 pub.dev 上对应包的 CHANGELOG）；
2. 找出项目里所有旧 API 和需要改的调用点；
3. 列出按文件分组的改动计划。

输出：旧 API 清单（文件:行 + 替换方式） + 分文件改动计划 + 风险点。
我确认后再进入 F-2。
```

### F-2. 分文件替换

```text
按 F-1 的计划替换旧 API；同一会话继续，新会话先贴 F-1 的计划。本次只做：<范围>。

要求：
1. 按文件逐步替换，一个文件一次；
2. 不改变无关业务行为；
3. 遇到计划里没覆盖的调用点，停下来先报告，不要自己猜；
4. 每改完一批跑一次 {{analyze}}。

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

运行：
- {{integrationTest}}

需要真机时先看项目是否装了 w_tools_device：装了按它的文档操作，没装就跳过，
不要手写 adb 命令。

输出：测试文件 + 运行结果 + 失败时的截图 / 日志路径。
```

---

## J. 只审查改动

### J-1. 只读审查

```text
只审查本次改动，不要改代码。

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
- 退出码 1：catalog 未收录或名字不对（可能拼错，也可能是未登记的公开类型），
  先按 explain 实际列出的名字重写，再判断是否真的不存在。

同理，AI 说 analyze / test 都过了，但没贴原始输出，就当作没跑。

---

## 3. AI 完成后你必须检查

```text
[ ] 报告里说跑过的命令，都真的跑过；没跑就写明没跑
[ ] 声称的 analyze / test 结果是原文，不是复述
[ ] git diff 没有大范围无关改动
[ ] 没有手改生成物
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
[ ] 业务代码没有直接 import w_tools_*（toolkit / UI 暂存层除外）
[ ] 没有旧 API
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
I am a Dart / Flutter developer on this project, but I am not familiar with these prompts.

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

A small task is one round (still paste the fixed prefix first): B-1 / G-1 / H-1 / I-1.

Do not ask for this in round 1:

```text
implement + add tests + update docs + run the whole repo
```

### Check after the AI finishes

Work through "3. What you must check after the AI finishes" at the end —
there is exactly one checklist in this file, nothing is duplicated here.

---

## 0. Fixed prefix (paste first)

```text
You are a Dart / Flutter developer on this project.

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
   direct `package:w_tools_*` imports belong only in the toolkit itself; with UI enabled, also `lib/app/ui/` and `lib/app/design_system/`.
5. Edit only content outside the `w_tools:begin/end` block in {{rulesFiles}}; keep the block generated.
6. Run {{analyze}} / {{test}} and paste the actual output; if you cannot run them, say so.
7. Unless a scenario says otherwise, output = changed file list + key code snippets + raw {{analyze}} / {{test}} output.
```

Fixed-prefix exceptions: scenario selection reads only §1; K-1 does not paste the prefix; every other scenario pastes it first.

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
2. validate with field validator; pass validatorSettings to WForm;
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
For each w_tools type / import, run `explain`; treat exit 1 as "not in catalog or wrong name",
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
1. read the migration document per package
   (look up the matching version under docs/migrations/ in the w_tools repo, e.g. ui-7.0.md / form-5.1.md; or the package CHANGELOG on pub.dev);
2. find every outdated API and call site in this project;
3. list a per-file change plan.

Output: outdated API inventory (file:line + replacement) + per-file plan + risks.
Wait for my confirmation before F-2.
```

### F-2. Replace file by file

```text
Replace outdated APIs following the F-1 plan; stay in the same conversation, or paste the F-1 plan first in a new chat. This round only covers: <scope>.

Requirements:
1. go file by file, one file at a time;
2. do not change unrelated behavior;
3. stop and report any call site the plan missed; do not guess;
4. run {{analyze}} after each batch.

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

Run:
- {{integrationTest}}

If a real device is needed, first check whether the project depends on w_tools_device:
use it when present, skip it when not, and do not hand-write adb commands.

Output: test files + run result + screenshot / log paths on failure.
```

---

## J. Review changes only

### J-1. Read-only review

```text
Review this change only; do not edit code.

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
- exit code 1: not in the catalog or the name is wrong (a typo, or a public type that is
  intentionally uncataloged); first rewrite using the names explain actually lists, then decide
  whether it truly does not exist.

Likewise, if the AI says analyze / test passed but pastes no raw output, treat it as not run.

---

## 3. What you must check after the AI finishes

```text
[ ] every command it claims to have run was actually run; if not, it says so
[ ] the analyze / test result is raw output, not a paraphrase
[ ] git diff has no large unrelated changes
[ ] no generated file was hand-edited
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
[ ] business code has no direct w_tools_* imports (toolkit / UI staging layer excepted)
[ ] no outdated APIs
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
<!-- generated by w_tools_cli {{version}}; 用 `dart run w_tools_cli:w_tools init --check-drift` 检查是否过期 -->
## 用 w_tools 的方式（给人和 AI 的约定）

1. **先拿事实**：`dart run w_tools_cli:w_tools context --format=prompt`
   （项目装了什么版本、toolkit 导出了什么、该跑哪些检查）
2. **先找现成的**：`dart run w_tools_cli:w_tools list <关键词>`，
   需要细节再 `dart run w_tools_cli:w_tools explain <组件名>`；**不要凭记忆造组件名**。
   业务代码统一 `import 'package:{{toolkitImport}}';`（本项目能力清单）。
3. **找不到 → 放待上移的通用组件** `lib/app/design_system/`，**不要**直接改 w_tools：
   - 只允许 import `dart:*` / `package:flutter*` / `package:w_tools*` / `package:get`
   - 文件头标 `// STAGED: 待上移到 w_tools_ui`；有设计稿时把实测尺寸写进注释
   - 默认值要能直接用；至少一个测试
   - 是否进包由维护者决定；真正进入 w_tools 时由包维护者补 CHANGELOG
   - API 参数优先 ≤ 3 个；超过 3 个先确认是否职责混合，不要机械拆组件
4. **业务层只放这个功能独有的组合**，不放通用组件。

## 项目规则
''';

const String agentsFeedback = r'''
## 使用反馈（默认关闭）

用 `w_tools_*` 撞到问题、或对能力有改进建议：**先查重；默认不提交，只有项目显式开启时才发。**

### 第一步：看项目是否开启

只有 `.w_tools_doctor.yaml` 里：

```yaml
feedback:
  issue: true
```

才允许创建 GitHub Issue。没有这个配置（或为 false）→ **什么都不做**，不要写本地文件、不要打开链接。

### 已开启时

1. **查重**

   ```bash
   dart run w_tools_cli:w_tools feedback search "<关键词>" --package=<包>
   ```

2. **写正文**（字段固定，缺字段会被拒绝；可先运行
   `dart run w_tools_cli:w_tools feedback submit --template` 打印骨架）

   ```md
   - 包/版本：
   - 环境：
   - 命令 / 输入：
   - 期望：
   - 实际：
   - 影响：
   - 建议：
   - 复现数据：
   ```

   保存为 `/tmp/w_tools_feedback.md`。

3. **提交**（`--issue` 可显式覆盖配置）

   ```bash
   dart run w_tools_cli:w_tools feedback submit \
     --package=<包> --title="<一句话现象>" --body-file=/tmp/w_tools_feedback.md --issue
   ```

   - 需要已安装 `gh`；gh 会读取 `GH_TOKEN` / `GITHUB_TOKEN`，或使用 `gh auth login`；
   - 提交成功会输出 issue URL；失败会明确报错，不生成人工链接。

### 边界

- 一次会话最多 3–5 条，只记**真正卡住你**的；
- 状态只写 `待处理`，**不要自己标「已修复」**；
- 不要把反馈写进业务代码或 `.w_tools/`；
- 维护者 triage 后才进入 `w_tools/docs/feedback/<包>.md`。
''';

const String agentsClosing = r'''
## 硬规则

- pubspec 只依赖具体子包，禁止聚合包 `w_tools`。
- 业务代码只 import 聚合入口，禁止直接 import `package:w_tools_*`。

## 检查项

> R6 需在 `.w_tools_doctor.yaml` 开启；R9 需配置 `banned`。
> 实际启用状态以项目配置为准。

{{doctorRules}}

## 完成前

- `dart run w_tools_cli:w_tools doctor --format=json` → 0 error（warning 看情况）
- `flutter analyze`、`flutter test`
- 本次用过 `w_tools_*` 且被卡住？→ 先看 `.w_tools_doctor.yaml` 的 `feedback.issue`；
  未开启就跳过（这是默认）；开启后按「使用反馈」search → submit。
<!-- w_tools:end -->
''';

const String agentsUi = r'''
- **分层**：`lib/app/ui/` 是项目永久 UI 层（AppBar / 按钮 / 页面骨架 / 盒子装饰），
  由 CLI 生成脚手架，**不走 STAGED、不计划上移**；只有待上移的通用组件才放
  `lib/app/design_system/`（受 R5 约束）。
- **页面骨架**：标准页面默认用 `AppScaffold`（`lib/app/ui/app_scaffold.dart`）；
  不要直接使用 `WScaffold` / `WAppBar`（本规则针对消费方项目；仓库内 example / 库测试可直接用 `WScaffold`）。特殊顶部栏用 `AppScaffold(appBar: WAppBar(...))`；
  需要 drawer / bottomSheet / 非标准安全区时用 `WScaffold` 或原生 `Scaffold`，并在 PR 说明。
  AppBar 默认样式只在 `AppBars.style` 修改。
- **底部导航**：用 `WNavBar` + `WNavController`；`WNavController` 需要 `vsync`，
  在页面 State 创建并 `dispose`；顶部 tab 用 `WTabBar`，它依赖
  `TabController` / `DefaultTabController`，不自带 controller。不要自己写 `BottomNavigationBar`。
- **按钮**：统一用 `AppButtons.primary/secondary/text/danger(context)`；页面不要直接写
  `WButtonStyle`，除非是明确的局部一次性样式。真按钮用 `WButton`，任意 child/卡片点击用
  `WPressable`；不要用 `WButton` 包任意 child。
  按钮宽度由父布局决定，`WButtonStyle` 不含 `width`。`WButton` 没有 `variant`；
  样式用 `style`，`label` 和 `content` 不能同时传。`loading` 时同时设置 `enabled: !loading`；
  纯图标按钮提供 `semanticLabel`。状态色放 `AppButtons`。
- **徽标 / 裁剪 / 横向操作 / 步骤**：角标用 `WBadge(badgeContent:, child:)`；圆角裁剪用
  `WClipRRect(borderRadius: BorderRadius.circular(12), child: ...)`；横向操作行用 `WActionRow`；
  步骤条用 `WStep(labels:, current:)`，复用流程用 `WStepFlow`。App 级图片占位/错误用
  `WImageTheme`；自定义按钮尺寸用 `WButtonSize`。
- **图片**：统一用 `WImage.source` + `WImageSource`——网络图
  `WImage.source(source: WImageSource.network(url))`，资源图
  `WImage.source(source: WImageSource.asset(name, prefix: true))`；
  `WImage.network` / `WImage.asset` / `WImage(data:)` 已在 6.0 删除。
  视觉用 `WImageStyle`；加载 / 重试行为用 `WImageLoadOptions`；占位 / 错误 / 进度 UI 用 `WImageSlots`；App 级默认占位/错误用
  `WImageTheme(slots: WImageSlots(...))`，预加载用 `WImageSource.resolve(...)`。不要裸用
  `Image.network` / `Image.asset`。没有 `width` / `height` / `aspectRatio` 时必须由父级
  给约束（`SizedBox` / `Expanded` / `AspectRatio`），否则加载前是 0 尺寸（空白）。
- **文字**：新代码用 `WText(variant: WTextVariant.xxx)` + `WTextStyles`；字体/字号/行高放主题，
  `WTextConfig` 已移除；不要逐字段拼样式。局部用 `style` / `color` / `maxLines` / `overflow` 覆盖。
  最小示例：`WText(text: '标题', variant: WTextVariant.title)`。
  先复用已有 variant（含 `price` / `number` / `badge`）。variant 不够时：一次性差异用
  `variant + style`；项目内重复抽本地 helper；消费方不能自行新增 `WTextVariant` enum，
  稳定跨页面语义再提给 `w_tools_ui`。
- **扩展**：数字格式化用 `toThousandsSeparated` / `toCurrency` / `toPercent`；
  hex 颜色用 `WColorExtension.fromHex` 或 `'#rrggbb'.toColor()`；`EdgeInsets` 值用 `num.allPadding`；
  BoxDecoration 用 `withColor` / `withBorderRadius` / `withShadow` 组合。
- **工具**：屏幕 / 字体适配用 `WScreen.w/h/sp`；资源前缀用 `WAssets.imagePath`；
  `SizedBox` / `Padding` / `Row` / `Column` 直接用 Flutter 原生组件；需要 `EdgeInsets` 值时用 `num.allPadding`。
  `WSizeBox` / `WPadding` / `WRow` / `WColumn` 已在 5.0 删除，新代码不要再用。
- **列表 / 通知**：列表用 `WListView` / `WListViewSliver`；列表项保活用 `WKeepAliveWrapper`；
  滚动通知 / 百分比用 `WNotificationListener`（百分比只处理 depth 0 的 `ScrollUpdateNotification`）；
  进度用 `WGradientCircularProgressIndicator`。
- **初始化时机**：不要在 main / 顶层 final 中调用 `.sp`；`WTextStyles` 若用 `.sp`，
  在 `ScreenUtilInit.builder` / `WAppOptions.builder`（或自建插件的 `builderWrapper`）的 build 期构建。
  `wrapApp` 没有 Theme；需要 Theme 的排版扩展用 `builderWrapper`。
- **盒子**：重复 `BoxDecoration` 收进 `AppBoxes`；重复卡片用 `AppCard`；
  一次性盒子用 `Container` + `BoxDecoration`；需要 width/height/constraints/transform
  时直接用 `Container`。不要新增 `AppBox` / `AppContainer` 万能包装。
''';

const String agentsForm = r'''
- **表单**：新页面用 `WForm` + 直接字段（`WFormTextField` / `WFormDropdown` /
  `WFormMultiDropdown` / `WFormDatePicker` / `WFormCheckbox` / `WFormRadioGroup`），
  不要从 `Config.build` 开始。
  `WForm` 需要 `WFormController`，且必须一对一（同一个 controller 同时挂载两个
  `WForm` 会显示重复挂载提示）；页面级高度 / 内边距用 `WForm.fieldStyle`
  （`WFormFieldStyle`），校验设置用 `WFormValidatorSettings` / `WFormValidator`；
  整表变化用 `WForm(onChanged:)`；字段差异用直接参数，不要传字段 `config`。
- **只读**：整页只读用 `WForm(readOnly: true)`；单字段只读用字段的 `readOnly`，
  不要手写只读作用域。
- **表单字段按钮**：字段值选择用 `WFormButton`，不要用 `WButton` 承担表单字段值。
- **表单弹层**：锚定选择用 `WFormPopup`，它不是居中确认框。
- **边框**：默认跟随主题，不需要显式传 `borderStyle`；固定浅色页才用 `WFormBorderStyle.standard()`；不要手写 `WFormBorder`。
- **输入格式化 / 插槽动作**：`WFormInputFormatters.hkPhone()`；文本插槽用
  `WFormTextFieldPasswordToggle` / `WFormTextFieldClearButton`。
''';

const String agentsApi = r'''
- **网络**：优先用 `WApiConfig` + `DioRegistry.forBaseUrl`；裸 `Dio()` 必须传 `dio:`；
  同一 baseUrl 只初始化一次；命中后传不同配置会报错，需要先 dispose。Token 存 `w_tools_core` 的 `WToken`，通过
  `WTokenInterceptor` 的 `tokenGetter` / `tokenClearer` / `tokenRefresher` 注入；
  401 重试依赖 DioRegistry。日志用 `WLogInterceptor`，默认脱敏敏感头。
''';

const String agentsApp = r'''
- **启动**：入口用 `WApp.options(WAppOptions(...)).start()`，不要手写 runApp + 初始化顺序；
  必须提供 `home`，或 `initialRoute` + `getPages`。插件需要顺序时用 `WAppPlugin.dependsOn`。
  `builderWrapper` 在 MaterialApp 内，`wrapApp` 在外且没有 Theme / MediaQuery；
  `WRouteObserver` 已由 WApp 自动追加，不要重复添加。
- **插件**：实现 `WAppPlugin`，`onInit` 参与分层初始化；有顺序要求必须显式声明 `dependsOn`。
  非 GetX 启动器可直接用 `WAppPluginRunner`（`w_tools_app`）。
- **多语言**：支持语言 / 首次语言 / 回退语言用 `WLocaleConfig`（`WAppOptions.localeConfig`）；
  运行期用 `app.language`（`WLanguage`）的 `changeLanguage(...)`，监听 `languageChanges` 或 `languageListenable`；
  不要自己保存第二份 currentLanguage。
- **路由栈**：用 `app.routeStack`；`WRouteStack` / `WRouteObserver` 由 WApp 维护，
  没有全局 `defaultStack`。操作栈用 `app.routeStack.popUntilRoute(...)`。
- **底部面板**：用 `WBottomSheet.show(...)`，不要直接用 `showModalBottomSheet`。
- **应用外观**：`theme` / `darkTheme` / `themeMode` / `systemUiOverlayStyle` 用 `WAppTheme`，
  通过 `WAppOptions.theme` 传入。
- **全局主题 / 默认视图**：用 `WAppOptions.appWrapper` 组合对应包的主题 Widget；
  需要 Theme / MediaQuery 的插件用 `builderWrapper`；不要为此让 app 依赖其它子包。
''';

const String agentsAsync = r'''
- **异步区块**：页面统一 `WAsyncController + WAsyncView`；不要手写
  `ValueNotifier<WAsyncState>`，也不要每页重复 `when + RetryView`。
  每个独立区块一个 Controller；全局默认 loading/empty/error 用 `WAsyncTheme`，
  放在 App 根节点（`WAppOptions.appWrapper`；或消费方自建插件的 `wrapApp`），不要只放页面 body。
  普通页面区块用 `WAsyncView`；滚动页面 / `SmartRefresher` 用 `WAsyncStateBuilder`，
  不要把 `SmartRefresher` 包在 `WAsyncView` 外面；分页用 `WAsyncPagedController`，
  `loadMore` 失败写 `loadMoreError` / footer，不要用 `WAsyncController.failed` 替换列表。
  `WAsyncStateBuilder.builder` 必须始终返回同一个 `SmartRefresher + CustomScrollView`；
  loading/empty/error 只能作为 slivers 分支。Sliver 页面默认视图用 `WAsyncTheme` 的 `sliver*Builder`，
  `CustomScrollView` 四态用 `WAsyncStateSliver`；`readySliverBuilder` 必须返回 sliver。
  纯执行、不要 UI 用 `WAsync.tryRun` + `WAsyncResult`，或 `WAsync.run`（失败抛异常）；
  不要用已删除的 `WAsync.run(onSuccess:)` / `runValue` / `WAsyncLoading`。

  最小页面：

  ```dart
  final c = WAsyncController.list(() => api.list());
  c.load();
  WAsyncView(state: c.state, onRetry: c.load, readyBuilder: (_, data) => ...);
  ```

  结果分支与取消：

  ```dart
  switch (result) {
    case WAsyncSuccess(:final value): use(value);
    case WAsyncFailure(:final error, :final stackTrace): log(error, stackTrace);
    case WAsyncCancelled(:final reason): log(reason);
  }
  ```

  `WAsyncStatus`（`state.status`）是四态枚举；`WAsyncStrings` 通过
  `WAsyncTheme(strings: ...)` 注入默认文案；取消异常用 `WCancellationException`。
  `WAsyncActivity` 只用于同一批并行任务，不要拿它合并多个独立区块。

  查用法：`dart run w_tools_cli:w_tools explain WAsync --format=prompt`。
''';

const String agentsToast = r'''
- **初始化**：`MaterialApp(builder: BotToastInit(), navigatorObservers: [BotToastNavigatorObserver()])`；
  未初始化时所有提示会静默失败。
- **轻提示**：用 `WToast.showSuccess/showError/showWarning/showText`；确认框用 Flutter `showDialog`。
- **加载**：用 `WToast.runWithLoading`；不要手写遮罩。
- **样式**：单个提示的样式用 `WToastStyle`，全局主题用 `WToastTheme`；不要写死颜色。
''';

const String agentsCore = r'''
- **基础工具**：`WStorage` 读取前先 `await WStorage.init()`；`WStorage` / `WToken`
  是明文存储。`WValidator` 做业务语义校验，纯正则用 `WRegExp`；日志用 `WLogger`；
  防抖 / 节流用 `WDebounce`。
''';

const String agentsQr = r'''
- **扫码**：用 `WQrView`，不要直接用 `QRView`；默认 `scanOnce=true`，
  重新扫描用 `GlobalKey<WQrViewState>.restartScan()`。
''';

const String agentsMap = r'''
- **地图**：用 `WMap` + `WMapZone`（配置放 `WMapOptions`），不要直接用 `GoogleMap`；
  markerId 必须稳定，`json_serializable` 模型用 `WMapItemMapper`；需要 Google Maps API Key。
''';

const String agentsFigma = r'''
## Figma → Flutter（可选）

需要从设计稿取规格 / token 时使用 `w_tools_figma`：

```bash
{{figmaInstall}}
dart run w_tools_figma:figma init
export FIGMA_TOKEN=figd_xxx
# 或把 token 写入 ~/.config/w_tools/figma-token（0.8.0 起不在项目里）

dart run w_tools_figma:figma url '<figma-url>' --json
dart run w_tools_figma:figma frames
dart run w_tools_figma:figma frames --name=<子串> --page=<页面>
dart run w_tools_figma:figma fetch nodes <fileKey> <nodeId>
dart run w_tools_figma:figma spec <nodeId> --json --node-depth=2
dart run w_tools_figma:figma spec <id1>,<id2> --json
dart run w_tools_figma:figma spec <nodeId> --json --node-only
dart run w_tools_figma:figma tokens <nodeId> --map=figma_tokens.yaml
dart run w_tools_figma:figma diff <fileKey> <nodeId> --if-stale
```

- `spec` / `tokens` 只读缓存；默认会自动选择包含目标 nodeId 的缓存，缓存缺失才 `fetch`。
- 不要默认 `--refresh`；确认要更新才加。
- `spec --json` 的 `node` 是结构化节点，`markdown` 只用于人读。
- 写页面时先查现有组件：

```bash
dart run w_tools_cli:w_tools list <关键词>
dart run w_tools_cli:w_tools explain <组件名>
```

- 不要凭记忆造 `W*` 组件名；实现后跑 `dart run w_tools_cli:w_tools doctor`。

完整命令（额度 / 退出码见 https://github.com/stone0533/w_tools/blob/main/packages/figma/README.md）：

```bash
dart run w_tools_figma:figma fetch file <fileKey> --depth=3
dart run w_tools_figma:figma fetch images <fileKey> <nodeId> --scale=2
dart run w_tools_figma:figma get '<signed-url>' <outfile>
dart run w_tools_figma:figma me
dart run w_tools_figma:figma usage
dart run w_tools_figma:figma cache stats
dart run w_tools_figma:figma cache clean --all --yes
dart run w_tools_figma:figma budget --set=15
dart run w_tools_figma:figma help fetch
dart run w_tools_figma:figma version
```
''';

const String agentsDevice = r'''
## 设备验证（可选）

需要模拟器 / Android / 真机截图、点击、等待稳定或 E2E 自动登录时，先读 `docs/agents/device-testing.md`。

- 设备操作使用 `w_tools_device`；不要手写 adb / DeviceHub 标定。
- E2E 自动登录使用 `w_tools_e2e`；只使用测试账号，凭证不要复用真实密码。
- `w_tools_e2e` 只能放 `tool/main_e2e.dart`；不要把测试依赖 import 到生产 `lib/main.dart`。

常用命令（完整参数见 `docs/agents/device-testing.md`）：

```bash
dart run w_tools_device:device list
dart run w_tools_device:device boot "<名称|udid>"
dart run w_tools_device:device shot --out=/tmp/a.png
dart run w_tools_device:device calibrate
dart run w_tools_device:device tap <x> <y>
dart run w_tools_device:device drag <x1> <y1> <x2> <y2>
dart run w_tools_device:device type "hello"
dart run w_tools_device:device size
dart run w_tools_device:device foreground --android
dart run w_tools_device:device wait
dart run w_tools_device:device verify <x> <y>
```
''';

const String agentsBaseEn = r'''
<!-- w_tools:begin -->
<!-- generated by w_tools_cli {{version}}; refresh check: `dart run w_tools_cli:w_tools init --check-drift` -->
## Working with w_tools (for humans and AI)

1. **Get facts first**: `dart run w_tools_cli:w_tools context --format=prompt`
   (installed versions, toolkit exports, checks to run)
2. **Reuse before writing**: `dart run w_tools_cli:w_tools list <keyword>`,
   then `dart run w_tools_cli:w_tools explain <Component>`; **do not invent component names**.
   Business code imports `package:{{toolkitImport}}` only.
3. **If missing, stage generic candidates for promotion** in `lib/app/design_system/`
   (do not modify w_tools directly):
   - imports: `dart:*` / `package:flutter*` / `package:w_tools*` / `package:get`
   - header `// STAGED: move to w_tools_ui`, plus measured specs when a design exists
   - working defaults; at least one test
   - maintainers decide promotion; when it actually enters w_tools, the package maintainers add the CHANGELOG entry
   - prefer ≤ 3 API parameters; if more, first check whether responsibilities are mixed
     rather than splitting mechanically
4. Business layer keeps feature-specific composition only.

## Project rules
''';

const String agentsFeedbackEn = r'''
## Usage feedback (off by default)

When `w_tools_*` blocks you, or a capability could be better: **search first; submit only if the project enables it.**

### Step 1: check whether it is enabled

Only when `.w_tools_doctor.yaml` contains:

```yaml
feedback:
  issue: true
```

may you create a GitHub Issue. Without it (or false) → **do nothing**: no local file, no link.

### When enabled

1. **Search**

   ```bash
   dart run w_tools_cli:w_tools feedback search "<keywords>" --package=<package>
   ```

2. **Write the body** (fields are validated; run
   `dart run w_tools_cli:w_tools feedback submit --template` to print the skeleton)

   ```md
   - package/version:
   - environment:
   - command / input:
   - expected:
   - actual:
   - impact:
   - suggestion:
   - repro data:
   ```

   Save it as `/tmp/w_tools_feedback.md`.

3. **Submit** (`--issue` explicitly overrides the config)

   ```bash
   dart run w_tools_cli:w_tools feedback submit \
     --package=<package> --title="<one-line symptom>" --body-file=/tmp/w_tools_feedback.md --issue
   ```

   - Requires `gh` installed; gh reads `GH_TOKEN` / `GITHUB_TOKEN` or uses `gh auth login`;
   - Prints the issue URL on success; fails loudly otherwise (no manual-link fallback).

### Boundaries

- At most 3–5 entries per session, only what **actually blocked you**;
- Status is only `pending`; **never mark it fixed yourself**;
- Do not put feedback in business code or `.w_tools/`;
- Maintainers triage into `w_tools/docs/feedback/<package>.md`.
''';

const String agentsClosingEn = r'''
## Hard rules

- Depend on subpackages, never the aggregate `w_tools`.
- Business code imports only the toolkit entry, never `package:w_tools_*` directly.

## Checks

> R6 must be enabled in `.w_tools_doctor.yaml`; R9 requires `banned`.
> The project config is the source of truth for activation.

{{doctorRules}}

## Before done

- `dart run w_tools_cli:w_tools doctor --format=json` → 0 error (warnings are contextual)
- `flutter analyze`, `flutter test`
- Used `w_tools_*` and got blocked? → check `feedback.issue` in `.w_tools_doctor.yaml`;
  if off, skip (default); if on, follow "Usage feedback" (search → submit).
<!-- w_tools:end -->
''';

const String agentsUiEn = r'''
- **Layering**: `lib/app/ui/` is the permanent project UI layer
  (app bar / buttons / page shell / boxes), generated by the CLI. It is **not**
  a staging area and is not planned for promotion. Only generic candidates for
  promotion belong in `lib/app/design_system/` (R5 applies there).
- **Page shell**: standard pages default to `AppScaffold`
  (`lib/app/ui/app_scaffold.dart`); do not use `WScaffold` / `WAppBar` directly (this rule targets consumer apps; the repo's example/library tests may use `WScaffold` directly).
  Use `AppScaffold(appBar: WAppBar(...))` for a custom app bar; use `WScaffold` or plain
  `Scaffold` for drawers/bottom sheets/non-standard safe areas, and note why in the PR.
  Change app-bar defaults only in `AppBars.style`.
- **Bottom navigation**: use `WNavBar` + `WNavController`; `WNavController` needs `vsync`,
  is created in the page State and disposed there; use `WTabBar` for top tabs. It requires
  `TabController` / `DefaultTabController` and does not own one. Do not hand-roll `BottomNavigationBar`.
- **Buttons**: use `AppButtons.primary/secondary/text/danger(context)`; do not write
  `WButtonStyle` in pages unless it is an explicit one-off style. Use `WButton` for real buttons
  and `WPressable` for arbitrary card/child taps.
  Button width comes from the parent; `WButtonStyle` has no `width`. `WButton` has no `variant`;
  use `style`; do not pass both `label` and `content`. With `loading`, also set `enabled: !loading`;
  provide `semanticLabel` for icon-only buttons. Put state colors in `AppButtons`.
- **Badges / clipping / action rows / steps**: use `WBadge(badgeContent:, child:)` for badges,
  `WClipRRect(borderRadius: BorderRadius.circular(12), child: ...)` for rounded clipping,
  `WActionRow` for horizontal action rows, and `WStep(labels:, current:)` (or `WStepFlow`
  for reuse) for steps. Use `WImageTheme` for app-level image placeholders/errors
  and `WButtonSize` for custom button sizes.
- **Images**: always use `WImage.source` + `WImageSource` —
  `WImage.source(source: WImageSource.network(url))` for network images and
  `WImage.source(source: WImageSource.asset(name, prefix: true))` for assets;
  `WImage.network` / `WImage.asset` / `WImage(data:)` were removed in 6.0.
  Use `WImageStyle` for visuals, `WImageLoadOptions` for loading/retry behavior,
  and `WImageSlots` for placeholder/error/progress UI.
  Use `WImageTheme(slots: WImageSlots(...))` for app-level placeholders/errors and
  `WImageSource.resolve(...)` for preloading.
  Do not use `Image.network` / `Image.asset` directly. Without `width` / `height` /
  `aspectRatio`, the parent must constrain it (`SizedBox` / `Expanded` / `AspectRatio`);
  otherwise it is 0-sized before load (blank).
- **Text**: use `WText(variant: WTextVariant.xxx)` + `WTextStyles`; keep fonts/sizes/line heights
  in the theme; `WTextConfig` has been removed. Override with `style` / `color` / `maxLines` /
  `overflow` locally. Reuse existing variants first (`price` / `number` / `badge`). If a variant is
  not enough: use `variant + style` for one-offs; extract a local helper for repeated styles.
  Consumers cannot add `WTextVariant` enum values.
  Minimal: `WText(text: 'Title', variant: WTextVariant.title)`.
- **Extensions**: use `toThousandsSeparated` / `toCurrency` / `toPercent` for number formatting;
  `WColorExtension.fromHex` or `'#rrggbb'.toColor()` for colors; use `num.allPadding` for `EdgeInsets`;
  compose `BoxDecoration` with `withColor` / `withBorderRadius` / `withShadow`.
- **Tools**: use `WScreen.w/h/sp` for screen/font adaptation and `WAssets.imagePath` for asset
  prefixes; use native `SizedBox` / `Padding` / `Row` / `Column`, and `num.allPadding` for `EdgeInsets`.
  `WSizeBox` / `WPadding` / `WRow` / `WColumn` were removed in 5.0.
- **Lists / notifications**: use `WListView` / `WListViewSliver` for lists,
  `WKeepAliveWrapper` for list-item keep-alive, `WNotificationListener` for scroll
  notifications/percentage (depth 0 only), and `WGradientCircularProgressIndicator`
  for progress.
- **Init timing**: never call `.sp` in `main` / top-level finals. Build `WTextStyles` with `.sp`
  in `ScreenUtilInit.builder` / `WAppOptions.builder` (or a custom plugin's `builderWrapper`); `wrapApp` has no Theme.
- **Boxes**: put repeated `BoxDecoration` values in `AppBoxes`; use `AppCard` for repeated cards;
  use `Container` + `BoxDecoration` for one-off boxes. Do not add an `AppBox` / `AppContainer` wrapper.
''';

const String agentsFormEn = r'''
- **Forms**: use `WForm` + direct fields (`WFormTextField` / `WFormDropdown` /
  `WFormMultiDropdown` / `WFormDatePicker` / `WFormCheckbox` / `WFormRadioGroup`);
  do not start from `Config.build`.
  `WForm` requires a `WFormController` and must be one-to-one (mounting two `WForm`s
  on one controller shows a duplicate-mount notice); page-level height/padding use
  `WForm.fieldStyle` (`WFormFieldStyle`); validation uses `WFormValidatorSettings` /
  `WFormValidator`; form-wide changes use `WForm(onChanged:)`; field differences use
  direct parameters, never a field `config`.
- **Read-only**: use `WForm(readOnly: true)` for a whole form; use the field's
  `readOnly` for a single field; do not hand-write the read-only scope.
- **Field buttons**: use `WFormButton` for field value selection; do not use `WButton`
  to hold a form field value.
- **Form popups**: use `WFormPopup` for anchored selection; it is not a centered dialog.
- **Borders**: the default already follows the theme, so do not pass `borderStyle`
  unless you need `standard()` for a fixed light page; do not hand-write `WFormBorder`.
- **Input formatters / slot actions**: `WFormInputFormatters.hkPhone()`; text slots use
  `WFormTextFieldPasswordToggle` / `WFormTextFieldClearButton`.
''';

const String agentsApiEn = r'''
- **Network**: prefer `WApiConfig` + `DioRegistry.forBaseUrl`; a bare `Dio()` must receive `dio:`;
  initialize each baseUrl once; different options/interceptors after the first call throw ArgumentError (dispose first to change config). Store tokens with `w_tools_core`'s `WToken` and inject via
  `WTokenInterceptor` (`tokenGetter` / `tokenClearer` / `tokenRefresher`); 401 retry depends
  on DioRegistry. Use `WLogInterceptor` for logs; sensitive headers are redacted by default.
''';

const String agentsAppEn = r'''
- **Startup**: use `WApp.options(WAppOptions(...)).start()` as the entry point, not a hand-written
  runApp/init sequence; provide `home`, or `initialRoute` + `getPages`. Declare plugin order with
  `WAppPlugin.dependsOn`. `builderWrapper` lives inside MaterialApp; `wrapApp` is outside and has no
  Theme/MediaQuery. `WRouteObserver` is appended automatically.
- **Plugins**: implement `WAppPlugin`; `onInit` participates in layered initialization. Declare
  `dependsOn` when order matters. For non-GetX shells use `WAppPluginRunner` (`w_tools_app`).
- **Localization**: use `WLocaleConfig` (`WAppOptions.localeConfig`) for supported / initial /
  fallback languages. Switch at runtime with `app.language` (`WLanguage`).`changeLanguage(...)` and listen to
  `languageChanges` or `languageListenable`; do not keep a second writable currentLanguage.
- **Route stack**: use `app.routeStack`; `WRouteStack` / `WRouteObserver` are maintained by WApp and
  there is no global `defaultStack`. Use `app.routeStack.popUntilRoute(...)`.
- **Bottom sheet**: use `WBottomSheet.show(...)`, not `showModalBottomSheet`.
- **Appearance**: put `theme` / `darkTheme` / `themeMode` / `systemUiOverlayStyle` in `WAppTheme`,
  passed via `WAppOptions.theme`.
- **Global theme / defaults**: compose theme widgets with `WAppOptions.appWrapper`; plugins that need
  Theme/MediaQuery use `builderWrapper`; do not make the app package depend on other subpackages.
''';

const String agentsAsyncEn = r'''
- **Async blocks**: use `WAsyncController + WAsyncView` for pages; do not hand-write
  `ValueNotifier<WAsyncState>` or repeat `when + RetryView` per page. One Controller per
  independent block; use `WAsyncTheme` at the app root. Use `WAsyncView` for normal
  blocks; use `WAsyncStateBuilder` for scroll pages / `SmartRefresher`, never wrap
  `SmartRefresher` around `WAsyncView`. `builder` must always return the same
  `SmartRefresher + CustomScrollView`; loading/empty/error go inside slivers. Use
  `WAsyncTheme`'s `sliver*Builder` / `WAsyncStateSliver` for sliver pages; `readySliverBuilder` returns a sliver.
  Pagination: use `WAsyncPagedController`; on `loadMore` failure write `loadMoreError` / footer,
  never replace the list with `WAsyncController.failed`.
  For pure execution without UI use `WAsync.tryRun` + `WAsyncResult`, or `WAsync.run` (throws on failure);
  do not use the removed `WAsync.run(onSuccess:)` / `runValue` / `WAsyncLoading`.

  Minimal page:

  ```dart
  final c = WAsyncController.list(() => api.list());
  c.load();
  WAsyncView(state: c.state, onRetry: c.load, readyBuilder: (_, data) => ...);
  ```

  Result branches and cancellation:

  ```dart
  switch (result) {
    case WAsyncSuccess(:final value): use(value);
    case WAsyncFailure(:final error, :final stackTrace): log(error, stackTrace);
    case WAsyncCancelled(:final reason): log(reason);
  }
  ```

  `WAsyncStatus` (`state.status`) is the four-state enum; inject default copy with
  `WAsyncStrings` via `WAsyncTheme(strings: ...)`; cancellation throws
  `WCancellationException`. `WAsyncActivity` is only for one batch of parallel
  tasks, never for merging independent blocks.

  Look up usage: `dart run w_tools_cli:w_tools explain WAsync --format=prompt`.
''';

const String agentsToastEn = r'''
- **Setup**: `MaterialApp(builder: BotToastInit(), navigatorObservers: [BotToastNavigatorObserver()])`;
  without it every toast fails silently.
- **Light feedback**: use `WToast.showSuccess/showError/showWarning/showText`; use Flutter
  `showDialog` for confirmations.
- **Loading**: use `WToast.runWithLoading`; do not hand-roll an overlay.
- **Styling**: `WToastStyle` styles a single toast; `WToastTheme` provides the global theme;
  do not hardcode colors.
''';

const String agentsCoreEn = r'''
- **Core utilities**: call `await WStorage.init()` before reads; `WStorage` / `WToken`
  are plaintext storage. Use `WValidator` for semantic validation and `WRegExp` for pure regex;
  log through `WLogger`; use `WDebounce` for debounce/throttle.
''';

const String agentsQrEn = r'''
- **Scanning**: use `WQrView`, not the raw `QRView`; `scanOnce` defaults to true, and restart via
  `GlobalKey<WQrViewState>.restartScan()`.
''';

const String agentsMapEn = r'''
- **Maps**: use `WMap` + `WMapZone` (configure via `WMapOptions`), not raw `GoogleMap`;
  marker ids must be stable, and `json_serializable` models should use `WMapItemMapper`;
  Google Maps API key required.
''';

const String agentsFigmaEn = r'''
## Figma → Flutter (optional)

Use `w_tools_figma` when you need specs or design tokens from Figma:

```bash
{{figmaInstall}}
dart run w_tools_figma:figma init
export FIGMA_TOKEN=figd_xxx
# or put the token in ~/.config/w_tools/figma-token (outside the project since 0.8.0)

dart run w_tools_figma:figma url '<figma-url>' --json
dart run w_tools_figma:figma frames
dart run w_tools_figma:figma frames --name=<substring> --page=<page>
dart run w_tools_figma:figma fetch nodes <fileKey> <nodeId>
dart run w_tools_figma:figma spec <nodeId> --json --node-depth=2
dart run w_tools_figma:figma spec <id1>,<id2> --json
dart run w_tools_figma:figma spec <nodeId> --json --node-only
dart run w_tools_figma:figma tokens <nodeId> --map=figma_tokens.yaml
dart run w_tools_figma:figma diff <fileKey> <nodeId> --if-stale
```

- `spec` / `tokens` read the cache and auto-select the cache containing the target nodeId; only `fetch` when the cache is missing.
- Do not use `--refresh` by default; use it only when you intend to update.
- In `spec --json`, `node` is structured; `markdown` is for humans.
- Reuse existing components before writing new ones:

```bash
dart run w_tools_cli:w_tools list <keyword>
dart run w_tools_cli:w_tools explain <Component>
```

- Do not invent `W*` component names; run `dart run w_tools_cli:w_tools doctor` after implementation.

Full command list (quota / exit codes: https://github.com/stone0533/w_tools/blob/main/packages/figma/README.md):

```bash
dart run w_tools_figma:figma fetch file <fileKey> --depth=3
dart run w_tools_figma:figma fetch images <fileKey> <nodeId> --scale=2
dart run w_tools_figma:figma get '<signed-url>' <outfile>
dart run w_tools_figma:figma me
dart run w_tools_figma:figma usage
dart run w_tools_figma:figma cache stats
dart run w_tools_figma:figma cache clean --all --yes
dart run w_tools_figma:figma budget --set=15
dart run w_tools_figma:figma help fetch
dart run w_tools_figma:figma version
```
''';

const String agentsDeviceEn = r'''
## Device validation (optional)

When you need simulator / Android / real-device screenshots, taps, stability waits, or E2E auto-login, read `docs/agents/device-testing.md` first.

- Use `w_tools_device`; do not hand-roll adb or DeviceHub calibration.
- Use `w_tools_e2e` for E2E auto-login; test accounts only, never real passwords.
- Keep `w_tools_e2e` in `tool/main_e2e.dart`; never import test dependencies into production `lib/main.dart`.

Common commands (full flags: `docs/agents/device-testing.md`):

```bash
dart run w_tools_device:device list
dart run w_tools_device:device boot "<name|udid>"
dart run w_tools_device:device shot --out=/tmp/a.png
dart run w_tools_device:device calibrate
dart run w_tools_device:device tap <x> <y>
dart run w_tools_device:device drag <x1> <y1> <x2> <y2>
dart run w_tools_device:device type "hello"
dart run w_tools_device:device size
dart run w_tools_device:device foreground --android
dart run w_tools_device:device wait
dart run w_tools_device:device verify <x> <y>
```
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
- `verify` 默认比较整屏，动画/轮播会误判；用 `--region` 只看会变的区域；
- `--scale` 只用于 iOS 模拟器的 calibrate/tap/drag/size/wait/verify；
- 退出码：`0` 成功 · `1` 参数/执行错误 · `2` verify 没变化 · `3` wait 超时；
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

    final hasCustomAppBar = appBar != null;

    return WScaffold(
      appBar: appBar,
      title: hasCustomAppBar ? null : title,
      titleWidget: hasCustomAppBar ? null : titleWidget,
      leading: hasCustomAppBar ? null : leading,
      actions: hasCustomAppBar ? const <Widget>[] : actions,
      onBack: hasCustomAppBar ? null : onBack,
      appBarStyle: hasCustomAppBar ? null : AppBars.style(context),
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
''';

