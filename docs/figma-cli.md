# `w_tools_figma` CLI 契约（v0.1）

- 状态：**v0.1 已实现**（契约仍可微调；以当前 CLI 行为为准）
- 定位：**只读**的 Figma 取数 / 规格导出工具，与 `w_tools` 的 UI 约定无关
- 包名：`w_tools_figma`（与 `w_tools_*` 命名一致）；入口 `dart run w_tools_figma:figma <command>`
- 技术栈：**Dart**（Flutter 项目必有 Dart 运行时；跨平台；可测试；不依赖 Python）
- 为什么独立成包：
  1. `w_tools_cli` 的职责是「接入约定 + doctor」，塞入 Figma 会变成大杂烩；
  2. 消费方可能只要其中一个；
  3. 独立包可以独立发版，不牵连 UI 包版本。
- 为什么只读：token 权限最小化，避免误改设计稿。

---

## 1. 命令总览

| 命令 | 作用 | Figma Tier | 额度消耗 |
| --- | --- | --- | --- |
| `init` | 建令牌模板（用户配置目录）、建项目缓存目录与账号级额度文件——**已实现**（0.8.0 起不在项目里建文件） | — | 0 |
| `fetch file` | 拉文件结构（`depth` 可控）——**v0.1 已实现** | 1 | 1 次（缓存命中 0） |
| `fetch nodes` | 拉节点树（**批量 ids 只算 1 次**）——**v0.1 已实现** | 1 | 1 次 |
| `fetch images` | 拿渲图下载地址（批量）——**v0.1 已实现** | 1 | 1 次 |
| `get <url> <outfile>` | 下载图片地址到本地——**v0.1 已实现** | 0 | 0 |
| `me` | 校验 token——**v0.1 已实现** | 0 | 0 |
| `spec <node-id>` | 节点树 → 完整规格（Markdown 或 JSON）——**v0.1 已实现** | 0（读缓存） | 0 |
| `tokens` | 汇总颜色 / 文字样式 / 间距 → `design-tokens.md`——**v0.1 已实现** | 0（读缓存） | 0 |
| `url <figma-url>` | 从 Figma 链接解析 `fileKey` + `nodeId`——**v0.1 已实现** | 0 | 0 |
| `diff <node-id>` | 对比「上次缓存」与「当前线上」，列出改动的属性——**v0.1 已实现** | 1 | 1 次 |
| `cache` | `cache stats|clean [--all --yes]`：查看/清理机器缓存（不影响用量记录；`--all` 必须 `--yes`） | — | 0 |
| `usage` | 本月调用次数 / 剩余估算——**v0.1 已实现**（座位类型需额外 `me` 调用，暂未做） | 0（本地日志） | 0 |
| `budget` | 查看 / 设置月度预算——**v0.1 已实现** | 0 | 0 |

> 缓存命中时不读 token、不发请求；只有缓存未命中、`--refresh` 或
> `--check-stale` 时才需要 token。JSON 输出里的 `tierCalls` 表示本次真实请求次数。

---

## 2. 全局约定

### 2.1 全局参数

| 参数 | 说明 |
| --- | --- |
| `--root=<dir>` | 项目根（默认当前目录）；token / 缓存都相对它解析 |
| `--json` | 机器可读输出（schema 文件见 [`packages/figma/schema/`](../packages/figma/schema/)） |
| `--refresh` | `fetch` 删除对应缓存并强制重拉（**唯一会绕过缓存的开关**） |
| `--no-log` | 本次不写用量日志（调试用） |
| `--file=<path>` | `spec` / `tokens` 指定缓存节点树 JSON；不是 fileKey |

### 2.2 文件布局

```
<root>/
  ~/.config/w_tools/figma-token          # figd_ 个人令牌，600（不在仓库里）
  ~/.cache/w_tools/figma/<项目标识>/      # 节点 / 图片缓存
  ~/.cache/w_tools/figma/_usage.log      # 额度（账号级，跨项目共用）
    file-<fileKey>-d<depth>.json
    nodes-<fileKey>-<idslug>.json
    images-<fileKey>-<idslug>-s<scale>.json
    _usage.log                 # TSV：时间 \t 类型 \t 缓存文件名
    _budget.json               # {"month":"2026-11","limit":20,"used":1}
```

### 2.3 退出码

| 码 | 含义 |
| --- | --- |
| 0 | 成功 |
| 1 | 一般错误（解析失败、节点不存在等） |
| 2 | 参数错误 |
| 3 | 额度受限（HTTP 429）——输出 `Retry-After` 与建议 |
| 4 | 缺少 / 非法 token |
| 5 | 网络错误 / 超时 |

### 2.4 额度与缓存规则

1. **缓存优先**：命中即返回，不算 Tier 1，不写日志；
2. **批量**：`nodes` / `images` 一次可传多个 id，只算 1 次；
3. **自动过期检测**：`fetch --check-stale` 用 `GET /v1/files/:key/meta`（Tier 3，不占 20 次/月）
   读 `version`；与 `_meta-<fileKey>.json` 里记录的版本不同 → 标记 `stale`，**只提示不自动重拉**
   （避免误耗额度），`--refresh` 才真正重拉。第一次检查只建立版本基线；不开 `--check-stale`
   时不发任何额外请求；
4. **预算**：`_budget.json` 记录本月已用；超过 `limit` 的 80% 时打印警告；
5. 429 时按 `Retry-After` 提示，**不自动重试**（View 座位重试会继续烧额度）。

---

## 3. 命令契约

### 3.1 `init`

```bash
dart run w_tools_figma:figma init [--force]
```

- 无 `~/.config/w_tools/figma-token` 时创建模板（注释说明 `figd_` 必须走 `X-Figma-Token`）；
- 建 `~/.cache/w_tools/figma/<项目标识>/` 与账号级 `_budget.json`；
- 老项目的 `.figma-cache/`、`.figma-token` 首次运行时自动迁移：
  缓存搬进项目缓存目录、`_usage.log` 并入账号级、真 token 覆盖新位置的模板；
- 新项目**不再**往 `.gitignore` 写条目（新路径都在仓库外）；老项目仍有旧文件时才补；
- 已存在且未传 `--force` → 不动文件，只报告状态。

### 3.2 `frames`

```bash
dart run w_tools_figma:figma frames [--file=<path>] [--json] [--all] [--name=<s>] [--page=<s>] [--verbose]
```

从本地 `nodes-*.json` 列出 FRAME：`page / id / name / width×height / children / cacheFile`，不访问 Figma。默认只列顶层 FRAME；`--all` 包含嵌套；人类输出包含 page 列。

### 3.3 `fetch`

```bash
dart run w_tools_figma:figma fetch file   <fileKey> [--depth=3]
dart run w_tools_figma:figma fetch nodes  <fileKey> <id1,id2,...>
dart run w_tools_figma:figma fetch images <fileKey> <id1,id2,...> [--scale=2]
```

`--check-stale` 用 Tier 3 的 `file/meta` 判断缓存是否过期；缓存命中时仍需要 token
（因为会访问 `/meta`），只提示不自动重拉。

JSON 输出：

```json
{ "schema": "w_tools_figma.fetch/1", "cacheFile": "nodes-abcd-1862-9222.json",
  "fromCache": false, "tierCalls": 1, "stale": false,
  "cachedVersion": null, "latestVersion": null }
```

### 3.4 `spec`（**核心命令**）

```bash
dart run w_tools_figma:figma spec <nodeId[,nodeId...]> [--file=<path>] [--root=<dir>] [--json] [--node-only] [--node-depth=<n>]
```

从缓存解析单个节点，输出**全部属性**（这是现有 `figma_spec.py` 的 Dart 重写）：

| 字段 | 说明 |
| --- | --- |
| `size` | 宽 / 高 |
| `fills` | 纯色 / 渐变 / 图片填充 |
| `strokes` | 颜色、宽度、**`dash`（虚线）**、`align`（INSIDE / OUTSIDE） |
| `radius` | 四角圆角（分别给出） |
| `effects` | 阴影（offset / blur / spread / color） |
| `text` | 字符、字体、字号、字重、行高、**`align`**、颜色、**`runs`（富文本分段色）** |
| `visible` | 层可见性（设计稿里隐藏的层不算） |
| `children` | 递归子树 |
| `layout` | auto-layout 间距 / padding / 对齐 |

`--json` 同时输出原始节点和 Markdown：

```json
{ "schema": "w_tools_figma.spec/1", "source": "test/fixtures/nodes-frame.json",
  "nodeId": "1862:9222", "markdown": "# 基本資料  (1862:9222)...",
  "node": { "id": "1862:9222", "type": "FRAME", "children": [] } }
```

`node` 是原始 Figma 节点（结构化），`markdown` 是人读表格。
多节点时 JSON schema 为 `w_tools_figma.specs/1`，`items` 是数组；Markdown 输出多张表。
`--node-depth=<n>` 只限制 `node` 的子节点深度；`--node-only` 不返回 `markdown`。Markdown 默认仍输出完整规格。

默认（不带 `--json`）输出 **Markdown 表格**，字段与上表一致，便于贴进 PR / 设计稿核对单。

### 3.5 `tokens`

```bash
dart run w_tools_figma:figma tokens <nodeId,nodeId,...> [--out=docs/design-tokens.md] [--map=figma_tokens.yaml]
```

- 汇总所选节点的「纯色 / 字体组合 / 圆角 / 间距」；
- 生成与项目现有 `design-tokens.md` 同结构的 Markdown（颜色表 / 文字表 / 组件尺寸表）；
- 设计稿里出现但项目还没有的值，落在「待确认」小节；
- **0 额度**（只读缓存）。

### 3.6 `get` / `me`

```bash
dart run w_tools_figma:figma get '<signed-image-url>' assets/demo.png
dart run w_tools_figma:figma me [--json]
```

`get` 只下载 `fetch images` 返回的签名 URL，不访问 Figma API，不消耗额度。
`me` 调 `/v1/me` 校验 token，不消耗 Tier 1。

### 3.7 `url`

```bash
dart run w_tools_figma:figma url 'https://www.figma.com/design/<key>/...?node-id=1862-9222'
dart run w_tools_figma:figma url '<link>' --json
# → fileKey=<key>  nodeId=1862:9222
```

`--json` 输出 `{"fileKey":"...","nodeId":"..."}`。

### 3.8 `diff`

```bash
dart run w_tools_figma:figma diff <fileKey> <nodeId> [--root=<dir>] [--if-stale]
```

- 拉最新节点（**消耗 1 次**），与旧缓存逐属性比较；
- `--if-stale` 先用 Tier 3 的 `/meta` 比较版本；没变直接退出（0 次 Tier 1），变了才拉；
- 输出「改了什么」：`fill #F8F8F5 → #FFFFFF`、`text.size 14 → 16`、`added: DROP_SHADOW` 等；
- 这正是「设计稿改版后，agent 不知道改了什么」的解法。

### 3.9 `usage` / `budget`

```bash
dart run w_tools_figma:figma usage          # 本月次数 + 最近记录
dart run w_tools_figma:figma budget --set=20 # 设置月度预算（解决「只能等 429」）
```

`usage --json`：

```json
{ "schema": "w_tools_figma.usage/1", "month": "2026-11", "used": 1,
  "limit": 20, "seat": "view", "last": [{"at": "...", "kind": "nodes", "cache": "..."}] }
```

---

## 4. 安全

- token 优先读 `FIGMA_TOKEN` 环境变量，其次读 `~/.config/w_tools/figma-token`；只接受 `figd_` 开头的个人令牌；**任何输出（日志 / 报错）都不打印**；
- 0.8.0 起令牌 / 缓存都在用户目录，不再写 `.gitignore`；
- 只调用 `GET` 接口（不写 Figma）。

---

## 5. 测试策略

| 层 | 方式 |
| --- | --- |
| 网络 | 抽象 `FigmaClient` 接口，测试注入 fake（不联网、不耗额度） |
| spec / tokens / diff | 用**真实缓存**做 fixture（脱敏后放 `test/fixtures/`），golden 对比输出 |
| 迁移验证 | 用现有 `figma_spec.py` 的输出做 golden，Dart 版逐字节一致才算通过 |
| 额度逻辑 | 单测 `_budget.json` / 日志 / stale 判定 |

---

## 6. 实施计划

| 阶段 | 内容 | 额度 |
| --- | --- | --- |
| 1 | ✅ **`init` / `fetch` / `usage` / `url` 已实现**（FakeClient 测试覆盖缓存 / 额度 / 幂等） | 0 |
| 2 | ✅ **`spec` 已实现**（`packages/figma`，Dart 重写 `figma_spec.py`，golden 逐字节一致） | 0（读缓存） |
| 3 | ✅ **`tokens` / `diff` / `budget` / meta 自动失效 已实现** | 0（缓存 fixture） |
| 4 | 消费方迁移：项目脚本改成薄 wrapper，文档指向 CLI | 0 |

---

## 7. 与现有资产的关系

| 现有 | 去向 |
| --- | --- |
| 各项目 `scripts/figma_api.sh` | 改成 wrapper：`exec dart run w_tools_figma:figma "$@"`（或直接删，文档指向 CLI） |
| `scripts/figma_spec.py`（198 行） | Dart 重写为 `spec` 命令；golden 对比通过后删除 |
| `docs/design-tokens.md`（各项目） | 由 `tokens` 命令生成骨架，项目填语义名 |
| `design-fidelity.md` 的额度经验 | 收敛成本文档 §2.4，各项目文档只保留指针 |

---

## 8. 待定

1. 发布方式：pub 发布 / git 依赖 / 仅 monorepo 内 path；
2. `tokens` 的语义名映射是否需要项目侧配置（`figma_tokens.yaml`）；
3. `spec` 的 Markdown 版式是否需要可定制（模板引擎 or 固定）。
