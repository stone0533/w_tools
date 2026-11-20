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
| `FetchCommand` / `FetchResult` | `nodes` / `imageUrls` 取数 |
| `DiffCommand` / `DiffResult` | `diff` 命令 |
| `FigmaSpecRenderer` / `TokenCollector` / `TokenRenderer` | 规格与 token 渲染 |
| `SpecDiff` / `findFigmaNode` / `pyFixed` | diff / 节点工具 |

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
  w_tools_figma: ^1.1.0
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
同 id 有多份缓存时取最新一份；最新是 `--depth` 裁剪缓存时会在 stderr 提示子节点可能缺失。需要完整树时用 `--file=` 指定完整缓存。

### 5. 读规格 / 汇总 token

```bash
dart run w_tools_figma:figma spec 1862:9222
dart run w_tools_figma:figma spec 1862:9222 --json
dart run w_tools_figma:figma spec 1862:9222,1862:9226
dart run w_tools_figma:figma spec 1862:9222 --json --node-depth=2
dart run w_tools_figma:figma spec 1862:9222 --with-id
dart run w_tools_figma:figma spec 1862:9222 --with-layout

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
| `init` | token 模板 / 缓存目录 / 预算文件 | 0 |
| `frames` | 列出缓存里的 FRAME，找 nodeId | 0 |
| `fetch nodes` | 拉节点树，批量 ids 只算 1 次；`--depth=<n>` 限制层数（默认不限） | 1 次 Tier 1 |
| `fetch images` | 拿图片下载地址（不缓存，直接输出 `id<TAB>url`；签名会过期） | 1 次 Tier 1 |
| `get` | 下载图片 URL 到本地文件 | 0 |
| `me` | 校验 token | 0 |
| `spec` | 节点 → Markdown / JSON | 0（读缓存） |
| `tokens` | 颜色 / 文字 / 圆角 / 间距汇总 | 0（读缓存） |
| `url` | Figma 链接 → fileKey + nodeId | 0 |
| `diff` | 对比旧缓存与最新节点；`--if-stale` 可 0 次 | 1 次 Tier 1；`--if-stale` 未变 0 |
| `usage` | 本月调用次数 / 最近记录；`--set=<n>` 设置月度预算 | 0 |
| `cache` | 查看 / 清理本机缓存；`clean` 必须 `--yes` | 0 |
| `help` | 显示命令帮助 | 0 |
| `version` | 显示版本 | 0 |

`fetch` / `diff` 不再做本地额度拦截；额度由 Figma 服务端限制，遇到 429 返回退出码 3。

参数边界：

- `tokens --out=<path>` 与 `--json` 互斥；`--map=<yaml>` 用于语义名映射，`--json` 的 `colors[].name` 也会带上映射；
- `spec --node-only` 只与 `--json` 一起使用；只返回结构化 `node`（不生成 markdown）；`--node-depth=<n>` 只限制 `node` 的子节点深度；
- `spec --skip-name-prefix=<s>` 跳过名称以该前缀开头的节点（逗号分隔）；`--with-id` 让 markdown 表格加 nodeId 列，`--with-layout` 让 markdown 表格加布局列（layoutMode / itemSpacing / padding），默认都不加；
- `tokens --skip-markdown` 只与 `--json` 一起用，不渲染 markdown；
- `cache clean` 必须给 `--yes`（无论是否 `--all`）；`--all` 清所有项目缓存，拒绝提示统计所有项目，但不会动账号级 `_usage.log` / `_budget.json`；
- `cache stats --files` 列出每个文件并按 `legacy`（旧 `file-*`）/ `nodes` / `index` 分类，`indexed` 表示 `_nodes-index.json` 是否引用该文件；`cache clean --legacy --yes` 只删旧 `file-*`，`cache clean --file=<path> --yes` 只删点名文件；`nodes-<key>-0-1.json` 是有效的整页缓存，不是自动可回收的 orphan；
- `fetch nodes --depth=<n>` 限制层数（默认不限，深页面缓存会很大）；`--root` 默认向上找最近的 `pubspec.yaml` / `.git`；
- `frames --all` 可配合 `--depth=<n>`（0 = 顶层，隐含 `--all`）和 `--limit=<n>` 收窄；`--name` / `--page` 会搜索全部 FRAME（含嵌套）；大文件优先过滤；
- `fetch images` 不缓存：每次调用都重新请求，直接输出 `id<TAB>url`；`--depth` / `--refresh` / `--check-stale` 不适用；
- `fetch nodes` 不接受 `--scale`；缓存损坏默认报错（`--refresh` 才覆盖），部分缺失会写入 `missingNodeIds`；
- `diff` 首次运行输出「已建立基线（无旧缓存，未做比较）」，JSON 带 `firstBaseline`；
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
--refresh         → 跳过缓存读取并重拉；成功后才覆盖，失败保留旧缓存
--check-stale     → 调 Tier 3 的 /meta，只提示不自动重拉
```

`fetch nodes` / `fetch images` 的 ids 会去重并按字符串排序，因此
`2:3,1:2` 与 `1:2,2:3` 命中同一份缓存，不会因顺序多打一次 Tier 1。

`fetch images` **不写缓存**：Figma 返回的是会过期的签名 URL，缓存下来只会拿到失效链接；
每次调用都直接输出 `id<TAB>url`（`--json` 用 `w_tools_figma.images/1`）。

`fetch nodes --check-stale` 即使用缓存也需要 token，因为会访问 `/meta`。
第一次 `--check-stale` 只建立版本基线；之后线上版本变化才会报 stale。
`--refresh` / `--check-stale` 只适用于 `fetch nodes`；`fetch images` 会直接拒绝。

旧版本按 `file-<key>-s<depth>.json` 存过的文件缓存不会再被读取，升级后可清理一次缓存目录。

缓存目录（`~/.cache/w_tools/figma/<项目标识>/`）：

```text
nodes-<key>-<ids>.json
_meta-<key>.json
```

账号级（`~/.cache/w_tools/figma/`，跨项目共用）：

```text
_usage.log      # TSV：时间 \t 类型 \t 缓存文件名
_budget.json    # {"limit": 20}（代码只读 limit；usage --set 会保留其它字段）
```

> `cache stats` 的文件数 / 字节数包含 `_nodes-index.json`（node id + FRAME 摘要索引）；
> 它可以删（会重建），`cache clean` 会一并清掉；`cache clean --legacy` 只删旧 `file-*`，不碰 `nodes-*`。

预算规则：`_budget.json` 的 `limit` 只用于 `usage` 的提示（已用超过 80% 时打警告），
不再拦截请求；真正的额度限制由 Figma 服务端返回 429（退出码 3）。
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
dart run w_tools_figma:figma usage --set=15
dart run w_tools_figma:figma cache stats            # 缓存位置 / 文件数 / 大小
dart run w_tools_figma:figma cache stats --files    # 逐文件明细（legacy / nodes / index）
dart run w_tools_figma:figma cache clean --yes        # 清理当前项目缓存（保留用量）
dart run w_tools_figma:figma cache clean --legacy --yes  # 只清旧 file-* 缓存
dart run w_tools_figma:figma cache clean --file=nodes-...json --yes  # 只删点名缓存
dart run w_tools_figma:figma cache clean --all --yes  # 清理所有项目缓存（保留用量）

# 图片地址下载 / token 校验
dart run w_tools_figma:figma get '<signed-url>' assets/demo.png
dart run w_tools_figma:figma me
```

## 输出

`--json` 输出带 `schema` 字段（`w_tools_figma.<命令>/1`）；文件清单、字段与"什么时候 bump"的策略见
[`schema/README.md`](schema/README.md)。`tokens --json` 同时给结构化数组
（`colors` / `texts` / `radii` / `spacings`）与 `markdown`，脚本不用解析人读文本。
`tokens --json --skip-markdown` 可以只取结构化数组；多缓存汇总时看 `sources`。
`fetch --json` 的 `missingNodeIds` 会列出 Figma 返回 null 的节点 id。

`spec --json` 固定返回 `items`（单个节点也是数组）：

```json
{"schema":"w_tools_figma.specs/1","items":[{"source":"...","nodeId":"...","markdown":"...","node":{...}}]}
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
fetch images 直接输出下载地址，不缓存（签名 URL 会过期）
tokens 只统计 SOLID 颜色
spec --json 固定为 specs/1（items）；node 可用 --node-depth 控制深度；markdown 仍完整
diff 只对比指定节点，不对比整个文件
usage 不含座位类型
```
