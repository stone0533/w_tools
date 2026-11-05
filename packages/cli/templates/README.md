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

内容只面向使用 w_tools 的项目，不复用维护者 A~J。
form / api 场景带 `@if:` 标记，按 `InitFeatures` 条件生成。

## toolkit 可选标记

`toolkit.dart.tpl` 仍使用单行标记：

```html
<!-- @optional:qr -->
<!-- @optional:map -->
```

整行会在对应能力关闭时移除。
