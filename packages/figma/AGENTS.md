# Figma → Flutter 页面（消费方可复制）

把本段复制到消费方项目的 `AGENTS.md`，按需改包路径。

## 工具

`w_tools_figma`（独立 CLI 包）：

```bash
dart run w_tools_figma:figma <command>
```

需要设计稿事实时先看：

```text
packages/figma/README.md       # 安装 / token / 命令
packages/figma/schema/         # --json 输出契约
```

## Figma → Flutter 页面流程

```bash
# 1. 从 Figma 链接拿 fileKey / nodeId
dart run w_tools_figma:figma url '<figma-url>' --json
dart run w_tools_figma:figma frames

# 2. 缓存不存在时取节点（1 次 Tier 1；缓存命中 0）
dart run w_tools_figma:figma fetch nodes <fileKey> <nodeId>

# 3. 读取规格
dart run w_tools_figma:figma spec <nodeId> --json --node-depth=2
dart run w_tools_figma:figma spec <nodeId> --json --node-only

# 4. 需要设计 token 时
dart run w_tools_figma:figma tokens <nodeId> --out=docs/design-tokens.md
dart run w_tools_figma:figma tokens <nodeId> --map=figma_tokens.yaml

# 5. 设计稿改版后
dart run w_tools_figma:figma diff <fileKey> <nodeId> --if-stale

# 6. 图片地址下载
dart run w_tools_figma:figma get '<signed-url>' assets/demo.png
```

## 写页面时

- `spec --json` 的 `node` 用于读结构、尺寸、颜色、文字、间距；`markdown` 只用于人读。
- `tokens --json` 的 `colors` / `texts` / `radii` / `spacings` 是结构化 token（每项带 `count`，
  颜色 / 文字还带 `samples`）；要 token 就读数组，不要解析 `markdown`。
- `url --json` / `me --json` 也带 `schema`（`w_tools_figma.url/1` / `w_tools_figma.me/1`），
  按 `schema` 分派；契约见 `packages/figma/schema/README.md`。
- 节点很大时，先对子节点执行 `spec`，不要把整页 `node` 全塞进上下文。
- 不知道 nodeId 时先跑 `frames`；`tokens --map` 可把颜色映射到项目语义名。
- `spec` / `tokens` 默认扫描所有缓存，自动选包含目标 nodeId 的文件；失败时按提示加 `--file=`。
- 组件优先用项目 toolkit；先跑：

```bash
dart run w_tools_cli:w_tools list <关键词>
dart run w_tools_cli:w_tools explain <组件名>
```

- 不要凭记忆造 `W*` 组件名。
- 按 [`docs/agents/ui.md`](https://github.com/stone0533/w_tools/blob/main/docs/agents/ui.md)：
  - 页面骨架用 `AppScaffold`（`init` 生成）；仓库内页面用 `WScaffold` + `WAppBar`
  - 文本用 `WText` + `WTextStyles`
  - 图片用 `WImage.source(source: WImageSource.asset(...))` / `WImageSource.network(...)`，禁止裸 `Image.asset`
  - 表单用 `WForm` + `WFormTextField` 等直接字段
  - 间距用原生 `SizedBox` / `Padding`（`WSizeBox` / `WPadding` 5.0 已删除），适配值用 `WScreen.w/h`
- `tokens` 只给设计 token，不会自动生成页面代码；组件映射必须结合项目 toolkit。

## 常用命令

当前稳定版见 pub.dev；下面这些命令可直接用：

```bash
dart run w_tools_figma:figma frames --all
dart run w_tools_figma:figma frames --name=会员 --page=我的
dart run w_tools_figma:figma frames --verbose
dart run w_tools_figma:figma spec 1862:9222,1862:9226 --json
dart run w_tools_figma:figma spec 1862:9222 --json --node-only
```

多节点 JSON schema 是 `w_tools_figma.specs/1`；`frames` 默认只列顶层画板。

## 规则

- 先读缓存，`spec` / `tokens` 不联网。
- 不要默认 `--refresh`；会消耗 Tier 1。
- `--check-stale` 只提示，不重拉；需要更新时再 `--refresh`。
- token 走 `FIGMA_TOKEN` 环境变量或 `~/.config/w_tools/figma-token`（旧 `.figma-token` 首次运行会自动迁移）；不要提交、不要打印。
- 实现后跑 `dart run w_tools_cli:w_tools doctor` 和项目测试。
