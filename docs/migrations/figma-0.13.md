# figma 0.13.0 迁移

0.12.0 宣布弃用、0.13.0 删除的三个入口。删的都是"源码兼容别名 / 转发方法 / 同义 flag"，
JSON 契约与其它命令行为没有变化。

## 删除清单

| 删除 | 改用 | 备注 |
|---|---|---|
| `UsageSummary`（含 `.new` 与各 getter） | `UsageResult` | 同一类型改名，成员与语义不变 |
| `FigmaSpecRenderer.renderMarkdown(node, targetId)` | `FigmaSpecRenderer.renderMarkdownFromRoot(root, targetId)` | 旧方法只是转发 |
| `spec --no-markdown` | `spec --node-only` | 只影响 `--json`，语义一致 |

## 需要改的地方

```dart
// before
final UsageSummary summary = UsageCommand(store).run();

// after
final UsageResult summary = UsageCommand(store).run();
```

```bash
# before
dart run w_tools_figma:figma spec 1:2 --json --no-markdown

# after
dart run w_tools_figma:figma spec 1:2 --json --node-only
```

## 不需要改的地方

- `tokens --json` 的 `colors` / `texts` / `radii` / `spacings`、`url` / `me` 的 `schema` 字段：0.12.0 起就有。
- `spec --json` 的 `node` / `markdown` 结构、退出码、缓存路径：均未变。
