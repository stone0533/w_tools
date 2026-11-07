# CLI 模板

`templates/` 是 `init` 生成内容的唯一来源；改完必须运行：

```bash
cd packages/cli
dart run tool/gen_templates.dart
```

## AGENTS 片段

AGENTS 已拆成可组合片段：

```text
templates/agents/zh/base.md
templates/agents/zh/ui.md
templates/agents/zh/form.md
templates/agents/zh/api.md
templates/agents/zh/app.md
templates/agents/zh/async.md
templates/agents/zh/toast.md
templates/agents/zh/core.md
templates/agents/zh/qr.md
templates/agents/zh/map.md
templates/agents/zh/figma.md
templates/agents/en/figma.md
templates/agents/zh/closing.md
```

`templates/agents/en/` 是英文对应文件。

`InitTemplates.agentsBlock` 按 feature 拼接；新增能力时新增片段，不要改回 full / no_ui 两套大模板。

## 消费方 AI 提示词

`templates/ai/consumer-prompts.md` / `.en.md` 生成到消费方：

```text
.w_tools/AI_PROMPTS.md
```

内容只面向**使用 w_tools 的项目**（读者是 Dart / Flutter 开发者、但对 AI 提示词不熟的人）。
编号体系与维护者手册 [A~N](https://github.com/stone0533/w_tools/blob/main/docs/ai-maintainer-prompts.md) 相同（字母 = 任务族、
数字 = 工序），但场景内容不复用；两份文件的字母会重名，仓库内讨论时写「消费方 A-1」。

### 结构

```text
新手先看这里（三步 / 让 AI 选场景 / 默认工作流 / 完成后先看）
0. 固定前缀（每次先贴；选场景 / K-1 例外）
填空说明（占位符表）
一个填好的例子
1. 场景选择（＋从现象反查）
A. ~ K. 场景族，族内工序写成 `X-1` / `X-2`
2. 输出不对时，加一句话就够
3. AI 完成后你必须检查   ← 全文唯一的检查清单
4. 维护这份文档
```

编号规则：**字母 = 任务族，数字 = 族内工序**。有先后关系的才拆号
（`A-1` 只读计划 → `A-2` 实现；`E-1` 审计 → `E-2` 修复；`F-1` 计划 → `F-2` 替换 → `F-3` 验证），
单工序族也写成 `X-1`，以后补工序不用改名。

### 改这份模板时

1. 新增 / 删除场景：加 `## X.` 和 `### X-n.`，同一条 `@if:` 里同步改 §1 表格行；
2. **不要写静态交叉引用**——表行、默认工作流、反查表都指向具体编号，
   被 `@if` 裁掉后就是死链；测试会按 feature 逐个关闭来挡这种悬空编号；
3. `@if` 不支持嵌套，能力清单用平铺的多个 `@if` 块；
4. 新增占位符必须进「填空说明」表，且**不许带空格**（门禁正则匹配不到带空格的形式）；
5. 改完跑：

```bash
cd packages/cli
dart run tool/gen_templates.dart
dart test test/internal/ai_prompts_test.dart test/internal/init_test.dart
python3 scripts/check_prompt_docs.py
```

`scripts/check_prompt_docs.py` 把 `templates/ai/*.md` 当提示词手册级别检查：
flag 必须被 CLI 认识、占位符必须在填空表里、场景编号必须双向对得上。

form / api / async / ui / toast / app / qr / map 的场景或检查行带 `@if:` 标记，按 `InitFeatures` 条件生成。

固定前缀里的 `{{rulesFiles}}` / `{{toolkitImport}}` / `{{dependencyNote}}` /
`{{analyze}}` / `{{test}}` / `{{pubUpgrade}}` / `{{testFramework}}` / `{{integrationTest}}`
由 `InitTemplates.aiPrompts` 按本次 targets、`toolkit_entry` 与 pubspec 渲染：
- `rulesFiles` 来自实际写入的 targets（`AGENTS.md` / `CLAUDE.md` / …），不要写死；
- `isFlutter` 决定 `flutter` 还是 `dart` 命令；
- `usesAggregate` 决定是“具体子包”还是“已用聚合包 w_tools”的说明；
- `toolkitImport` 是 `package:<项目名>/<toolkit_entry>`。

模板里不要写死 `AGENTS.md`、`flutter analyze` 或聚合包假设；新增占位符时同步加渲染参数和测试。

## toolkit 可选标记

`toolkit.dart.tpl` 仍使用单行标记：

```html
<!-- @optional:qr -->
<!-- @optional:map -->
```

整行会在对应能力关闭时移除。
