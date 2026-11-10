# w_tools_figma

只读的 Figma 取数 / 规格导出 CLI。

- 为什么独立成包：`w_tools_cli` 只管接入约定（`init` / `doctor`），Figma 塞进去会变成大杂烩；
  消费方可能只需要其中一个，独立包还能独立发版，不牵连其它包。
- 为什么只读：token 权限最小化，避免误改设计稿。
- AI / agent 使用说明：https://github.com/stone0533/w_tools/blob/main/docs/agents/figma.md

## Library / CLI

```text
lib/w_tools_figma.dart   稳定导出：命令类型 / renderer / collector
lib/src/cli/             CLI 内部实现，可能随版本变化
```

CLI 用户直接用 `dart run w_tools_figma:figma`；库用户只依赖 `lib/w_tools_figma.dart` 的导出。

## 库 API

`lib/w_tools_figma.dart` 是稳定导出的边界；`lib/src/cli/` 是 CLI 内部实现，不承诺稳定。

| 导出 | 用途 |
| --- | --- |
| `FigmaClient` / `HttpFigmaClient` | REST 客户端；`HttpFigmaClient(token: ...)` 走 `X-Figma-Token` |
| `CacheStore` / `UsageEntry` | 缓存、用量、预算文件读写 |
| `FetchCommand` / `FetchResult` | `file` / `nodes` / `images` 取数 |
| `InitCommand` / `UrlCommand` / `UsageCommand` / `DiffCommand` | 对应 CLI 命令 |
| `FigmaSpecRenderer` / `TokenCollector` / `TokenRenderer` | 规格与 token 渲染 |
| `SpecDiff` / `FigmaUrlTarget` / `findFigmaNode` / `pyFixed` | diff / URL / 节点工具 |

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

装最新版（pub.dev 上的当前版本）；要锁版本时再手写 `^x.y.z` 约束。

```bash
dart pub add dev:w_tools_figma
```

等价于：

```yaml
dev_dependencies:
  w_tools_figma: ^0.13.1
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

生成（**都不在项目仓库里**）：

```text
~/.config/w_tools/figma-token              # 填 figd_ 个人令牌（权限 600）
~/.cache/w_tools/figma/<项目标识>/          # 节点 / 图片 缓存
~/.cache/w_tools/figma/_usage.log          # 本月调用次数（按账号，跨项目共用）
~/.cache/w_tools/figma/_budget.json        # 额度上限
```

老项目的 `<项目>/.figma-cache/`、`<项目>/.figma-token` 会在下次运行时**自动迁移**
到上述位置（迁移后旧文件删除）。

迁移每个项目只做一次（标记 `<项目缓存目录>/_migrated-v1`）。把老项目整目录拷进一个**已经迁移过**
的项目不会重跑；确实要重迁时删掉该标记即可。

token 从 Figma：

```text
Settings → Security → Personal access tokens
```

只读权限即可。token 可以：

```text
1. CI / agent：export FIGMA_TOKEN=figd_xxx
2. 本地：写入 ~/.config/w_tools/figma-token
```

环境变量优先于文件。POSIX 上 `init` 会把 token 文件权限设为 600。

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
dart run w_tools_figma:figma fetch nodes <fileKey> 0:1 --depth=2   # 大页面只拉 2 层
```

`spec` / `tokens` 只读缓存，不先 fetch 会失败。

### 5. 读规格 / 汇总 token

```bash
dart run w_tools_figma:figma spec 1862:9222
dart run w_tools_figma:figma spec 1862:9222 --json
dart run w_tools_figma:figma spec 1862:9222,1862:9226
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
| `init` | token 模板 / 缓存目录 / 预算文件（老项目迁移时补 `.gitignore`） | 0 |
| `frames` | 列出缓存里的 FRAME，找 nodeId | 0 |
| `fetch file` | 拉文件结构，`--depth` | 1 次 Tier 1 |
| `fetch nodes` | 拉节点树，批量 ids 只算 1 次；`--depth=<n>` 限制层数（默认不限） | 1 次 Tier 1 |
| `fetch images` | 拿图片下载地址，不下载文件 | 1 次 Tier 1 |
| `get` | 下载图片 URL 到本地文件 | 0 |
| `me` | 校验 token | 0 |
| `spec` | 节点 → Markdown / JSON | 0（读缓存） |
| `tokens` | 颜色 / 文字 / 圆角 / 间距汇总 | 0（读缓存） |
| `url` | Figma 链接 → fileKey + nodeId | 0 |
| `diff` | 对比旧缓存与最新节点；`--if-stale` 可 0 次 | 1 次 Tier 1；`--if-stale` 未变 0 |
| `usage` | 本月调用次数 / 最近记录 | 0 |
| `budget` | 查看 / 设置月度预算 | 0 |
| `cache` | 查看 / 清理本机缓存；`clean --all` 必须 `--yes` | 0 |
| `help` | 显示命令帮助 | 0 |
| `version` | 显示版本 | 0 |

`fetch` / `diff` 在额度用尽时默认拒绝（退出码 3），加 `--ignore-budget` 继续。

参数边界：

- `tokens --out=<path>` 与 `--json` 互斥；`--map=<yaml>` 用于语义名映射；
- `spec --node-only` 只返回结构化 `node`（不生成 markdown）；`--node-depth=<n>` 只限制 `node` 的子节点深度；
- `cache clean --all` 必须同时给 `--yes`；`--all` 清所有项目缓存，但不会动账号级 `_usage.log` / `_budget.json`；
- `fetch nodes --depth=<n>` 限制层数（默认不限，深页面缓存会很大）；
- `diff --if-stale` 先比版本：没变直接退出（0 次 Tier 1），变了才拉。

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

旧版本 `file-<key>-s<depth>.json` 缓存不会再命中，升级后可清理一次缓存目录。

缓存目录（`~/.cache/w_tools/figma/<项目标识>/`）：

```text
file-<key>-d<depth>.json
nodes-<key>-<ids>.json
images-<key>-<ids>-s<scale>.json
_meta-<key>.json
```

账号级（`~/.cache/w_tools/figma/`，跨项目共用）：

```text
_usage.log      # TSV：时间 \t 类型 \t 缓存文件名
_budget.json    # {"limit": 20}（代码只读 limit；budget --set 会保留其它字段）
```

> `cache stats` 的文件数 / 字节数包含 `_nodes-index.json`（节点与 FRAME 的索引）和
> `_migrated-v1`（迁移标记）；两者都可以删（索引会重建），`cache clean` 会一并清掉。

预算规则：本月已用超过 `limit` 的 80% 时打警告；达到上限后 `fetch` / `diff` 默认拒绝（退出码 3），
`--ignore-budget` 放行；缓存命中与 `spec` / `tokens`（纯本地）不触发检查。
遇到 429 只按 `Retry-After` 提示，不自动重试（View 座位重试会继续烧额度）。

## 典型工作流

```bash
# 首次
dart run w_tools_figma:figma init
dart run w_tools_figma:figma fetch nodes <fileKey> 1862:9222
dart run w_tools_figma:figma fetch nodes <fileKey> 0:1 --depth=2   # 大页面只拉 2 层

# 看规格
dart run w_tools_figma:figma spec 1862:9222

# 汇总设计 token
dart run w_tools_figma:figma tokens 1862:9222 --out=docs/design-tokens.md

# 设计稿改版后
dart run w_tools_figma:figma diff <fileKey> 1862:9222

# 额度
dart run w_tools_figma:figma usage
dart run w_tools_figma:figma budget --set=15
dart run w_tools_figma:figma cache stats            # 缓存位置 / 文件数 / 大小
dart run w_tools_figma:figma cache clean --all --yes  # 清理所有项目缓存（保留用量；--all 必须 --yes）

# 图片地址下载 / token 校验
dart run w_tools_figma:figma get '<signed-url>' assets/demo.png
dart run w_tools_figma:figma me
```

## 输出

`--json` 输出带 `schema` 字段（`w_tools_figma.<命令>/1`）；文件清单、字段与"什么时候 bump"的策略见
[`schema/README.md`](schema/README.md)。`tokens --json` 同时给结构化数组
（`colors` / `texts` / `radii` / `spacings`）与 `markdown`，脚本不用解析人读文本。
`source` 是第一个命中的缓存文件（兼容字段）；多缓存汇总时看 `sources`。

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
