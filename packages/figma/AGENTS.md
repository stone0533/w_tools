# Figma → Flutter 页面（消费方可复制）

把本段复制到消费方项目的 `AGENTS.md`，按需改包路径。

## 工具

`w_tools_figma`（独立 CLI 包，0.4.0 已发布；0.5.0 待发布）：

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
- 节点很大时，先对子节点执行 `spec`，不要把整页 `node` 全塞进上下文。
- 不知道 nodeId 时先跑 `frames`；`tokens --map` 可把颜色映射到项目语义名。
- 组件优先用项目 toolkit；先跑：

```bash
dart run w_tools_cli:list <关键词>
dart run w_tools_cli:explain <组件名>
```

- 不要凭记忆造 `W*` 组件名。
- 按 [`docs/agents/ui.md`](https://github.com/stone0533/w_tools/blob/main/docs/agents/ui.md)：
  - 页面骨架用 `AppScaffold`
  - 文本用 `WText` + `WTextStyles`
  - 图片用 `WImage.asset` / `WImage.network`，禁止裸 `Image.asset`
  - 表单用 `WForm` + `WTextField` 等直接字段
  - 间距用 `WSizeBox` / `WPadding`
- `tokens` 只给设计 token，不会自动生成页面代码；组件映射必须结合项目 toolkit。

## 0.4.0 能力

当前安装的稳定版是 0.4.0；以下命令可直接使用：

```bash
figma frames --all
figma frames --name=会员 --page=我的
figma frames --verbose
figma spec 1862:9222,1862:9226 --json
figma spec 1862:9222 --json --no-markdown
```

多画板 JSON schema 是 `w_tools_figma.specs/1`；`frames` 默认只列顶层画板。

## 规则

- 先读缓存，`spec` / `tokens` 不联网。
- 不要默认 `--refresh`；会消耗 Tier 1。
- `--check-stale` 只提示，不重拉；需要更新时再 `--refresh`。
- token 走 `FIGMA_TOKEN` 环境变量或 `.figma-token`；不要提交、不要打印。
- 实现后跑 `dart run w_tools_cli:doctor` 和项目测试。
