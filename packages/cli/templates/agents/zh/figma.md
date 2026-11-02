## Figma → Flutter（可选）

需要从设计稿取规格 / token 时使用 `w_tools_figma`：

```bash
dart pub add dev:w_tools_figma:{{figmaConstraint}}
dart run w_tools_figma:figma init
export FIGMA_TOKEN=figd_xxx
# 或把 token 写入 .figma-token

dart run w_tools_figma:figma url '<figma-url>' --json
dart run w_tools_figma:figma frames
dart run w_tools_figma:figma fetch nodes <fileKey> <nodeId>
dart run w_tools_figma:figma spec <nodeId> --json --node-depth=2
dart run w_tools_figma:figma tokens <nodeId> --map=figma_tokens.yaml
dart run w_tools_figma:figma diff <fileKey> <nodeId> --if-stale
```

- `spec` / `tokens` 只读缓存；缓存缺失才 `fetch`。
- 不要默认 `--refresh`；确认要更新才加。
- `spec --json` 的 `node` 是结构化节点，`markdown` 只用于人读。
- 写页面时先查现有组件：

```bash
dart run w_tools_cli:list <关键词>
dart run w_tools_cli:explain <组件名>
```

- 不要凭记忆造 `W*` 组件名；实现后跑 `dart run w_tools_cli:doctor`。
