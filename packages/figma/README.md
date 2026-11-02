# w_tools_figma

只读的 Figma 取数 / 规格导出 CLI。契约见 [`docs/figma-cli.md`](../../docs/figma-cli.md)。

当前进度（v0.1 草案）：

| 命令 | 状态 |
| --- | --- |
| `spec <node-id>` | ✅ 已实现（读本地缓存 → Markdown / JSON） |
| `tokens <node-id[,id...]>` | ✅ 已实现（统计颜色 / 文字 / 圆角 / 间距 → Markdown，可 `--json` / `--out` / `--min=`） |
| `init` | ✅ 已实现（token 模板 / `.gitignore` / 缓存目录 / 预算文件，幂等） |
| `fetch file\|nodes\|images` | ✅ 已实现（缓存优先、`--refresh` 强制重拉、真实请求才写用量日志） |
| `usage` | ✅ 已实现（本月次数 / 上限 / 最近记录，可 `--json`） |
| `url` | ✅ 已实现（Figma 链接 → fileKey + nodeId） |
| `diff` | ✅ 已实现（对比上次缓存 vs 最新，列出属性变化 / 增删节点） |
| `budget` | ✅ 已实现（查看 / `--set=` 调整月度预算） |
| meta 自动失效（用 Tier 3 查 version） | ⏳ 按契约后续实现 |

```bash
# 从 .figma-cache/nodes-*.json 的缓存里导出一个画板的完整规格
dart run w_tools_figma:figma spec 1862:9222
dart run w_tools_figma:figma spec 1862:9222 --json

# 汇总多个节点的颜色 / 文字 / 圆角 / 间距（0 额度，只读缓存）
dart run w_tools_figma:figma tokens 1862:9222,1862:9226 --out=docs/design-tokens.md
dart run w_tools_figma:figma tokens 1862:9222 --min=3

# 取数（会消耗 Tier 1 额度；缓存命中不消耗）
dart run w_tools_figma:figma init
dart run w_tools_figma:figma fetch nodes UpyszH8lFtWYwrIXm1XAWw 1862:9222
dart run w_tools_figma:figma fetch nodes UpyszH8lFtWYwrIXm1XAWw 1862:9222 --refresh
dart run w_tools_figma:figma usage

# 设计稿改版后：看这一页到底改了什么（消耗 1 次 Tier 1）
dart run w_tools_figma:figma diff <fileKey> 1862:9222

# 预算调整
dart run w_tools_figma:figma budget --set=15
```
