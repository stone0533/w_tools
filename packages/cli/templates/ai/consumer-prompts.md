# w_tools AI 任务提示词

> 由 `w_tools_cli` v{{version}} 生成；重新生成请运行 `dart run w_tools_cli:w_tools init --force`。
> 本文件只服务**使用 w_tools 的项目**，不是 w_tools 仓库维护提示词。

## 先读

- 本项目的 `AGENTS.md`
- 本项目的 `pubspec.yaml`

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
5. 只用项目已安装的子包；业务代码按项目约定 import。
6. 不要手改生成的 AGENTS.md。
7. 完成后运行 flutter analyze / flutter test，并贴实际输出。
8. 不能运行命令就明确说没运行，不要声称通过。
```

## C-A 实现页面 / 功能

```text
任务：用 w_tools 实现 <页面/功能>。

要求：
1. 先运行 context，确认已安装能力和版本；
2. 先 list / explain 找现成组件，不要重复造；
3. 只 import 项目已安装的子包；
4. 找不到通用组件时放 lib/app/design_system/，并标 STAGED；
5. 不修改 w_tools 子包；
6. 完成后 flutter analyze + flutter test；
7. 报告：用了哪些 w_tools 组件、为什么、explain 依据。
```

## C-B 审计现有代码

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

## C-C 升级 w_tools

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

## C-D 排查问题

```text
任务：排查 <页面/功能> 的问题。

先收集：
- w_tools 版本
- 相关组件
- explain 输出
- 报错堆栈
- 最小复现

不要先猜。
先判断是项目用法问题、w_tools bug，还是版本不匹配。
```

## C-E 只审查改动

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

## C-F AI 不能读仓库 / 不能跑命令

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
