## Figma → Flutter (optional)

Use `w_tools_figma` when you need specs or design tokens from Figma:

```bash
dart pub add dev:w_tools_figma:^0.1.0
dart run w_tools_figma:figma init
export FIGMA_TOKEN=figd_xxx
# or put the token in .figma-token

dart run w_tools_figma:figma url '<figma-url>'
dart run w_tools_figma:figma fetch nodes <fileKey> <nodeId>
dart run w_tools_figma:figma spec <nodeId> --json
dart run w_tools_figma:figma tokens <nodeId>
```

- `spec` / `tokens` read the cache; only `fetch` when the cache is missing.
- Do not use `--refresh` by default; use it only when you intend to update.
- In `spec --json`, `node` is structured; `markdown` is for humans.
- Reuse existing components before writing new ones:

```bash
dart run w_tools_cli:list <keyword>
dart run w_tools_cli:explain <Component>
```

{{figmaComponentRules}}
- Do not invent `W*` component names; run `dart run w_tools_cli:doctor` after implementation.
