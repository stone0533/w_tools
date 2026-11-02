# w_tools_figma

只读的 Figma 取数 / 规格导出 CLI。契约见 [`docs/figma-cli.md`](../../docs/figma-cli.md)。

当前进度（v0.1 草案）：

| 命令 | 状态 |
| --- | --- |
| `spec <node-id>` | ✅ 已实现（读本地缓存 → Markdown / JSON） |
| `tokens <node-id[,id...]>` | ✅ 已实现（统计颜色 / 文字 / 圆角 / 间距 → Markdown，可 `--json` / `--out` / `--min=`） |
| `init` / `fetch` / `usage` / `url` / `diff` / `budget` | ⏳ 按契约后续实现 |

```bash
# 从 .figma-cache/nodes-*.json 的缓存里导出一个画板的完整规格
dart run w_tools_figma:figma spec 1862:9222
dart run w_tools_figma:figma spec 1862:9222 --json

# 汇总多个节点的颜色 / 文字 / 圆角 / 间距（0 额度，只读缓存）
dart run w_tools_figma:figma tokens 1862:9222,1862:9226 --out=docs/design-tokens.md
dart run w_tools_figma:figma tokens 1862:9222 --min=3
```
