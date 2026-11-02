# Figma 取数与规格导出（agent）

工具：`packages/figma`，包名 `w_tools_figma`。
契约：[`docs/figma-cli.md`](../figma-cli.md)。

## 什么时候用

需要从 Figma 设计稿回答这些问题时：

```text
这个节点的尺寸 / 间距 / 圆角是多少？
这里的颜色 / 字体 / 行高是什么？
设计 token 有哪些？
设计稿改版后改了什么？
```

## 工作流

```bash
# 1. 链接 → fileKey / nodeId
dart run w_tools_figma:figma url '<figma-url>'

# 2. 缓存不存在时先取数（消耗 1 次 Tier 1）
dart run w_tools_figma:figma fetch nodes <fileKey> <nodeId>

# 3. 读规格（0 额度）
dart run w_tools_figma:figma spec <nodeId>
dart run w_tools_figma:figma spec <nodeId> --json

# 4. 汇总设计 token（0 额度）
dart run w_tools_figma:figma tokens <nodeId> --out=docs/design-tokens.md

# 5. 设计稿改版后（消耗 1 次 Tier 1）
dart run w_tools_figma:figma diff <fileKey> <nodeId>
```

## 规则

- **先读缓存**：`spec` / `tokens` 不联网；只有缓存缺失或明确要更新时才 `fetch`。
- **不要默认 `--refresh`**：会消耗 Tier 1。
- **`--check-stale` 只提示，不重拉**；需要更新时再 `--refresh`。
- **`fetch images` 只返回下载地址**，不下载图片。
- **`spec --json` 同时包含 `node`（原始结构化节点）和 `markdown`**；优先读 `node`。
- **token 只放 `.figma-token`**；不要打印、不要提交。
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

## 帮助

```bash
dart run w_tools_figma:figma --help
dart run w_tools_figma:figma help fetch
dart run w_tools_figma:figma help spec
```
