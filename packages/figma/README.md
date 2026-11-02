# w_tools_figma

> `v0.3.0` 已发布，推荐安装 `^0.3.0`。

只读的 Figma 取数 / 规格导出 CLI。

- 契约：https://github.com/stone0533/w_tools/blob/main/docs/figma-cli.md
- AI / agent 使用说明：https://github.com/stone0533/w_tools/blob/main/docs/agents/figma.md

## Library / CLI

```text
lib/w_tools_figma.dart   稳定导出：命令类型 / renderer / collector
lib/src/cli/             CLI 内部实现，可能随版本变化
```

CLI 用户直接用 `dart run w_tools_figma:figma`；库用户只依赖 `lib/w_tools_figma.dart` 的导出。

## AI / agent 使用

消费方 AI 需要手动获得入口：

```text
1. 复制本包的 AGENTS.md 到消费方项目
2. 或让 AI 先读包内 AGENTS.md
```

本包 `AGENTS.md` 包含：

```text
Figma -> Flutter 页面流程
W* 组件映射
缓存 / 额度 / token 规则
```

本仓库内的 AI 入口见根 `AGENTS.md` 和
[`docs/agents/figma.md`](https://github.com/stone0533/w_tools/blob/main/docs/agents/figma.md)。

## 5 分钟上手

### 1. 安装

已发布版本：

```bash
dart pub add dev:w_tools_figma:^0.3.0
```

等价于：

```yaml
dev_dependencies:
  w_tools_figma: ^0.3.0
```

开发版使用 path 依赖：

```yaml
dev_dependencies:
  w_tools_figma:
    path: ../w_tools/packages/figma
```

git 依赖：

```yaml
dev_dependencies:
  w_tools_figma:
    git:
      url: https://github.com/stone0533/w_tools.git
      path: packages/figma
      ref: main
```

monorepo 内可直接在 `packages/figma/` 下运行命令。

### 2. 初始化

```bash
dart run w_tools_figma:figma init
```

生成：

```text
.figma-token         # 填 figd_ 个人令牌
.figma-cache/        # 节点 / 图片 / 用量 / 预算缓存
.gitignore           # 自动追加 token 与缓存
```

token 从 Figma：

```text
Settings → Security → Personal access tokens
```

只读权限即可。token 可以：

```text
1. CI / agent：export FIGMA_TOKEN=figd_xxx
2. 本地：写入 .figma-token
```

环境变量优先于文件。POSIX 上 `init` 会把 `.figma-token` 权限设为 600。

从 Figma 页面到 Flutter 实现的流程见
[`docs/agents/figma.md`](https://github.com/stone0533/w_tools/blob/main/docs/agents/figma.md)。

### 3. 从链接解析 fileKey / nodeId

```bash
dart run w_tools_figma:figma url 'https://www.figma.com/design/<key>/app?node-id=1862-9222'
dart run w_tools_figma:figma url '<link>' --json
# fileKey=<key>  nodeId=1862:9222
```

### 4. 先取数

```bash
dart run w_tools_figma:figma fetch nodes <fileKey> 1862:9222
```

`spec` / `tokens` 只读缓存，不先 fetch 会失败。

### 5. 读规格 / 汇总 token

```bash
dart run w_tools_figma:figma spec 1862:9222
dart run w_tools_figma:figma spec 1862:9222 --json
dart run w_tools_figma:figma spec 1862:9222 --json --node-depth=2

dart run w_tools_figma:figma tokens 1862:9222,1862:9226 --out=docs/design-tokens.md
dart run w_tools_figma:figma tokens 1862:9222 --min=3
dart run w_tools_figma:figma tokens 1862:9222 --map=figma_tokens.yaml
```

`figma_tokens.yaml`：

```yaml
colors:
  "#3F3F3F": textPrimary
  "#3366E6": brandBlue
```

## 示例

离线示例（不需要 token）：

```bash
cd packages/figma
./example/run_demo.sh
```

见 [`example/README.md`](example/README.md)。

## 命令

| 命令 | 作用 | 额度 |
| --- | --- | --- |
| `init` | token 模板 / `.gitignore` / 缓存目录 / 预算文件 | 0 |
| `fetch file` | 拉文件结构，`--depth` | 1 次 Tier 1 |
| `fetch nodes` | 拉节点树，批量 ids 只算 1 次 | 1 次 Tier 1 |
| `fetch images` | 拿图片下载地址，不下载文件 | 1 次 Tier 1 |
| `get` | 下载图片 URL 到本地文件 | 0 |
| `me` | 校验 token | 0 |
| `spec` | 节点 → Markdown / JSON | 0（读缓存） |
| `tokens` | 颜色 / 文字 / 圆角 / 间距汇总 | 0（读缓存） |
| `url` | Figma 链接 → fileKey + nodeId | 0 |
| `diff` | 对比旧缓存与最新节点；`--if-stale` 可 0 次 | 1 次 Tier 1；`--if-stale` 未变 0 |
| `usage` | 本月调用次数 / 最近记录 | 0 |
| `budget` | 查看 / 设置月度预算 | 0 |

完整帮助：

```bash
dart run w_tools_figma:figma --help
dart run w_tools_figma:figma help fetch
dart run w_tools_figma:figma fetch --help
```

## 缓存与额度

```text
缓存命中          → 不请求、不写日志、不需要 token
缓存未命中        → 1 次 Tier 1
--refresh         → 删除缓存并重拉
--check-stale     → 调 Tier 3 的 /meta，只提示不自动重拉
```

`--check-stale` 即使用缓存也需要 token，因为会访问 `/meta`。
第一次 `--check-stale` 只建立版本基线；之后线上版本变化才会报 stale。

旧版本 `file-<key>-s<depth>.json` 缓存不会再命中，升级后可清理一次 `.figma-cache/`。

缓存目录：

```text
.figma-cache/
  file-<key>-d<depth>.json
  nodes-<key>-<ids>.json
  images-<key>-<ids>-s<scale>.json
  _meta-<key>.json
  _usage.log
  _budget.json
```

## 典型工作流

```bash
# 首次
dart run w_tools_figma:figma init
dart run w_tools_figma:figma fetch nodes <fileKey> 1862:9222

# 看规格
dart run w_tools_figma:figma spec 1862:9222

# 汇总设计 token
dart run w_tools_figma:figma tokens 1862:9222 --out=docs/design-tokens.md

# 设计稿改版后
dart run w_tools_figma:figma diff <fileKey> 1862:9222

# 额度
dart run w_tools_figma:figma usage
dart run w_tools_figma:figma budget --set=15

# 图片地址下载 / token 校验
dart run w_tools_figma:figma get '<signed-url>' assets/demo.png
dart run w_tools_figma:figma me
```

## 输出

`--json` 输出带 schema：

```text
w_tools_figma.fetch/1
w_tools_figma.spec/1
w_tools_figma.tokens/1
w_tools_figma.diff/1
w_tools_figma.usage/1
w_tools_figma.budget/1
```

schema 文件在 [`schema/`](schema/)，包含：

```text
fetch.v1.json
spec.v1.json
tokens.v1.json
diff.v1.json
usage.v1.json
budget.v1.json
```

`spec --json` 同时返回原始节点和 Markdown：

```json
{"schema":"w_tools_figma.spec/1","source":"...","nodeId":"...","markdown":"...","node":{...}}
```

`node` 是原始 Figma 节点，适合结构化解析；`markdown` 适合贴 PR / AI 阅读。

## 退出码

```text
0 成功
1 一般错误 / 节点不存在
2 参数错误
3 额度受限 429
4 token 缺失 / 非法
5 网络错误 / 超时
```

## 限制

```text
fetch images 只保存下载地址，不下载图片
tokens 只统计 SOLID 颜色
spec --json 的 node 可用 --node-depth 控制深度；markdown 仍完整
diff 只对比指定节点，不对比整个文件
usage 不含座位类型
```
