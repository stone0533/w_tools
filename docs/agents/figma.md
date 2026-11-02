# Figma 取数与 Flutter 页面开发（agent）

工具：`packages/figma`，包名 `w_tools_figma`，0.1.0 已发布；0.1.1 待发布。
消费方安装：`dart pub add dev:w_tools_figma:^0.1.0`。
契约：[`docs/figma-cli.md`](../figma-cli.md)。
消费方可复制的片段：[`packages/figma/AGENTS.md`](../../packages/figma/AGENTS.md)。

## 什么时候用

需要从 Figma 设计稿回答或实现这些事情时：

```text
这个节点的尺寸 / 间距 / 圆角是多少？
这里的颜色 / 字体 / 行高是什么？
设计 token 有哪些？
设计稿改版后改了什么？
把这一页实现成 Flutter 页面
```

## 从 Figma 到 Flutter 页面

```bash
# 1. 链接 → fileKey / nodeId
dart run w_tools_figma:figma url '<figma-url>'

# 2. 缓存不存在时先取数（消耗 1 次 Tier 1）
dart run w_tools_figma:figma fetch nodes <fileKey> <nodeId>

# 3. 读规格
dart run w_tools_figma:figma spec <nodeId> --json
dart run w_tools_figma:figma spec <nodeId>

# 4. 汇总设计 token（0 额度）
dart run w_tools_figma:figma tokens <nodeId> --out=docs/design-tokens.md

# 5. 设计稿改版后（消耗 1 次 Tier 1）
dart run w_tools_figma:figma diff <fileKey> <nodeId>

# 6. 下载 fetch images 返回的图片地址
dart run w_tools_figma:figma get '<signed-url>' assets/demo.png
```

`spec --json`：

```json
{
  "node": { "id": "...", "type": "FRAME", "children": [] },
  "markdown": "..."
}
```

- `node`：结构化数据，用来读层级 / 尺寸 / 颜色 / 文本 / 间距。
- `markdown`：人读规格表，适合贴 PR。
- 页面很大时，先 `spec` 目标子节点；不要整页 `node` 全量塞进上下文。

## 映射到 Flutter

先查项目已有组件，不要凭记忆造：

```bash
dart run w_tools_cli:list <关键词>
dart run w_tools_cli:explain <组件名>
```

按 [`docs/agents/ui.md`](ui.md)：

```text
页面骨架     AppScaffold
文本         WText + WTextStyles
图片         WImage.asset / WImage.network
普通按钮     WButton
表单         WForm + 直接字段
间距         WSizeBox / WPadding
异步         WAsyncController + WAsyncView
```

`tokens` 只提供设计值，不会自动生成代码。颜色 / 字号 / 间距要落到项目
`AppColors` / `WTextStyles` / 间距常量，而不是硬编码。

## 规则

- **先读缓存**：`spec` / `tokens` 不联网；只有缓存缺失或明确要更新时才 `fetch`。
- **不要默认 `--refresh`**：会消耗 Tier 1。
- **`--check-stale` 只提示，不重拉**；需要更新时再 `--refresh`。
- **`fetch images` 只返回下载地址**；需要文件时用 `get <url> <outfile>`。
- **`spec --json` 同时包含 `node` 和 `markdown`**；优先读 `node`。
- token 用 `FIGMA_TOKEN` 环境变量或 `.figma-token`；不要打印、不要提交。
- 输出 JSON 时用 `--json`，不要解析人读文本。
- JSON schema 在 `packages/figma/schema/`；schema 名称与 `--json` 输出的 `schema` 字段一致。

## 额度

```text
fetch file / nodes / images   1 次 Tier 1
diff                          1 次 Tier 1
缓存命中                       0
spec / tokens / url / usage    0
budget                         0
```

## 示例

离线运行：

```bash
cd packages/figma
./example/run_demo.sh
```

示例映射见 [`packages/figma/example/flutter/demo_page.md`](../../packages/figma/example/flutter/demo_page.md)。

## 帮助

```bash
dart run w_tools_figma:figma --help
dart run w_tools_figma:figma help fetch
dart run w_tools_figma:figma help spec
```

## CI / agent token

优先：

```bash
export FIGMA_TOKEN=figd_xxx
```

没有环境变量时才读：

```text
.figma-token
```
