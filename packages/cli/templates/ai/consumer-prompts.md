# w_tools AI 任务提示词

> 由 `w_tools_cli` v{{version}} 生成；重新生成请运行 `dart run w_tools_cli:w_tools init --force`。
> 本文件只服务**使用 w_tools 的项目**，不是 w_tools 仓库维护提示词。

## 先读

- 本项目的 `AGENTS.md`
- 本项目的 `pubspec.yaml`

## 先选场景（新手）

不知道用哪个提示词时，先看这张表：

| 我要做什么 | 用哪个 |
|---|---|
| 写一个新页面 / 功能 | C-A |
| 写列表 / 分页 / 刷新 | C-B |
<!-- @if:form -->
| 写表单 / 校验 / 提交 | C-C |
<!-- @endif -->
<!-- @if:api -->
| 写接口 / 登录 / 401 | C-D |
<!-- @endif -->
| 检查现有代码有没有用错 | C-E |
| 升级 w_tools | C-F |
| 页面 overflow / 性能问题 | C-G |
| 补测试 | C-H |
| 只审查 AI 改动 | C-I |
| AI 不能读仓库 / 不能跑命令 | C-J |

还是不确定，直接把这段发给 AI：

```text
我不知道该用 C-A 到 C-J 哪个场景。

请先读：
- AGENTS.md
- pubspec.yaml
- .w_tools/AI_PROMPTS.md

我的任务是：<用一句话描述>。
范围是：<页面 / 文件 / 功能>。

请先判断应该用哪个场景，并说明原因。
不要写代码；
确认后，把该场景的提示词填好项目名、页面和范围，再给我。
```

## 固定前缀（每次先贴）

```text
你是本项目的 Flutter 开发者。

先读 AGENTS.md 和 pubspec.yaml。

规则：
1. 写代码前先运行：
   dart run w_tools_cli:w_tools context --format=prompt
2. 找组件先运行：
   dart run w_tools_cli:w_tools list <关键词> --format=prompt
3. 查用法运行：
   dart run w_tools_cli:w_tools explain <组件名> --format=prompt
4. 不要凭记忆猜 w_tools API；以 explain 输出为准。
5. 只使用项目已安装的包；业务代码按项目约定 import。
6. 先看项目现有相似页面 / 路由 / 状态管理，不要发明新架构。
7. 不要手改生成的 AGENTS.md。
8. 完成后运行 flutter analyze / flutter test，并贴实际输出。
9. 不能运行命令就明确说没运行，不要声称通过。
```

## C-A 新页面：先计划，再实现

```text
任务：实现 <页面/功能>。

先不要写代码。先读：
- AGENTS.md / pubspec.yaml
- lib/app/ui/ / lib/app/design_system/
- 2~3 个相似页面
- 路由注册文件

先输出：
1. 可复用的现有页面 / 组件
2. 页面状态：loading / empty / error / ready
3. 路由与参数
4. 数据来源
5. 需要 explain 的 w_tools 组件
6. 文件改动计划
7. 测试计划

等我确认后再写代码。

实现要求：
- 先运行 context，再用 list / explain 找组件；
- 不发明新的目录 / 状态管理方案；
- 不修改 w_tools 子包；
- 有请求就要有取消 / dispose 保护；
- 有表单就要有校验、提交中、错误保留；
- 有列表就要考虑刷新和加载更多；
- 完成后 flutter analyze + flutter test。
```

## C-B 列表 / 分页 / 刷新

```text
任务：实现 <列表页>。

先确认：
- 数据接口与分页参数
- 是否支持下拉刷新
- 空态 / 错误态 / 加载更多失败
- 项目是否已使用 WAsyncPagedController

要求：
1. 先看项目现有列表页写法；
2. 首屏 loading / empty / error 必须完整；
3. 加载更多失败只更新 footer，不替换列表；
4. 列表项使用稳定 key；
5. 图片按需限制解码尺寸；
6. 完成后 analyze + test，并补一个列表状态 widget test。
```

<!-- @if:form -->
## C-C 表单 / 校验 / 提交

```text
任务：实现 <表单页>。

要求：
1. 用 WForm + 直接字段，不传字段 config；
2. 校验用字段 validator + WFormValidatorSettings；
3. 提交中禁用重复提交；
4. 接口失败保留用户输入；
5. 键盘弹出时字段可见；
6. readOnly / 编辑态正确；
7. 补一个校验 + 提交测试。
```
<!-- @endif -->

<!-- @if:api -->
## C-D 接口 / 登录 / 401

```text
任务：实现 <接口 / 登录流程>。

要求：
1. 用 WApiConfig + DioRegistry，不直接 new Dio；
2. token 用 WToken；
3. 401 刷新只重试一次；
4. 请求失败要有业务错误提示；
5. 页面切换 / dispose 后不要 setState；
6. 完成后 analyze + test。
```
<!-- @endif -->

## C-E 审计现有代码

```text
只审计，不要修改。

检查当前项目：
1. 是否用了已删除 / 过期的 w_tools API；
2. 是否绕过 w_tools 直接用了底层库；
3. 是否有重复造组件；
4. 是否违反 AGENTS.md；
5. 页面状态 / 表单 / 网络 / 地图 / 扫码是否用错入口。

先运行 context / list / explain 核对。
输出：
| ID | 级别 | 文件:行 | 证据 | 问题 | 建议修复 | 验收 |
不要修改文件。
```

## C-F 升级 w_tools

```text
任务：把 w_tools 从 <旧版本> 升到 <新版本>。

要求：
1. 先读对应 migration 文档；
2. 找出项目里所有旧 API；
3. 先列改动计划，不要直接改；
4. 按文件逐步替换；
5. 不改变无关业务行为；
6. 完成后 flutter analyze + flutter test；
7. 报告旧 API 残留。
```

## C-G 调试 UI / 性能

```text
任务：排查 <页面> 的 UI / 性能问题。

先收集：
- 复现步骤
- 设备与 Flutter 版本
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

不要靠猜；先给复现和证据。
```

## C-H 补测试

```text
任务：为 <页面/组件> 补测试。

优先覆盖：
1. loading / empty / error / ready；
2. 表单校验与提交；
3. 列表刷新 / 加载更多 / footer；
4. 401 / 请求失败；
5. 关键交互和回调。

要求：
- 先读项目现有 test 写法；
- 不为了通过而降低断言；
- 完成后 flutter test。
```

## C-I 只审查改动

```text
只审查本次改动，不要改代码。

检查：
1. 是否用了正确入口；
2. 是否有旧 API / 重复组件；
3. 是否修改了无关文件；
4. 是否降低了测试标准；
5. 是否手改了生成物。

输出阻断项、建议项、可保留风险。
```

## C-J AI 不能读仓库 / 不能跑命令

```text
你不能直接访问仓库或运行命令。

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

## 页面完成自检

```text
[ ] loading / empty / error / ready 四态完整
[ ] 请求有取消 / dispose 保护
[ ] 表单有校验、提交中、错误保留
[ ] 列表有刷新 / 分页 / footer
[ ] 图片用 WImage.source，限制解码尺寸
[ ] 路由参数和返回结果正确
[ ] 键盘 / SafeArea / overflow 检查
[ ] 暗色模式和 TextScaler 不溢出
[ ] 没有直接 import w_tools_*
[ ] 没有旧 API
[ ] flutter analyze 通过
[ ] flutter test 通过
[ ] 新增/修改的 widget 有测试
```
