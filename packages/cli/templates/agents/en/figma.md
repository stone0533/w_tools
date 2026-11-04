## Figma → Flutter (optional)

Use `w_tools_figma` when you need specs or design tokens from Figma:

```bash
{{figmaInstall}}
dart run w_tools_figma:figma init
export FIGMA_TOKEN=figd_xxx
# or put the token in ~/.config/w_tools/figma-token (outside the project since 0.8.0)

dart run w_tools_figma:figma url '<figma-url>' --json
dart run w_tools_figma:figma frames
dart run w_tools_figma:figma frames --name=<substring> --page=<page>
dart run w_tools_figma:figma fetch nodes <fileKey> <nodeId>
dart run w_tools_figma:figma spec <nodeId> --json --node-depth=2
dart run w_tools_figma:figma spec <id1>,<id2> --json
dart run w_tools_figma:figma spec <nodeId> --json --node-only
dart run w_tools_figma:figma tokens <nodeId> --map=figma_tokens.yaml
dart run w_tools_figma:figma diff <fileKey> <nodeId> --if-stale
```

- `spec` / `tokens` read the cache and auto-select the cache containing the target nodeId; only `fetch` when the cache is missing.
- Do not use `--refresh` by default; use it only when you intend to update.
- In `spec --json`, `node` is structured; `markdown` is for humans.
- Reuse existing components before writing new ones:

```bash
dart run w_tools_cli:w_tools list <keyword>
dart run w_tools_cli:w_tools explain <Component>
```

- Do not invent `W*` component names; run `dart run w_tools_cli:w_tools doctor` after implementation.
