# Figma example

离线示例：不联网、不需要 token、不消耗额度。

## 运行

```bash
cd packages/figma
./example/run_demo.sh
```

示例使用合成 fixture：

```text
example/fixtures/nodes-demo.json
  FRAME 375×812
    TEXT 欢迎回来
    RECTANGLE Primary Button
    TEXT 说明
```

## 输出

```text
frames              FRAME 列表
spec 1:2            Markdown 规格表
spec 1:2 --json     node + markdown
tokens 1:2          颜色 / 文字 / 圆角 / 间距
```

## AI 使用顺序

1. `spec --json` 读 `node` 的结构和尺寸
2. `tokens` 读颜色、字号、间距
3. 用 `w_tools_cli:list` / `explain` 查项目组件
4. 按 `docs/agents/ui.md` 映射到 `WText` / `WImage` / `WButton` / `AppScaffold`
5. 实现后跑 `w_tools_cli:doctor`

示例页面映射见 [`flutter/demo_page.md`](flutter/demo_page.md)。

## 不包含

```text
真实 token
真实设计稿缓存
fetch / diff（需要网络和额度）
完整 Flutter App
```

`fetch` / `diff` 用真实 token 时，按 [`../README.md`](../README.md) 的步骤操作。
