# w_tools_figma JSON schema

`--json` 输出的 v1 契约：

| 文件 | schema |
| --- | --- |
| `fetch.v1.json` | `w_tools_figma.fetch/1` |
| `specs.v1.json` | `w_tools_figma.specs/1` |
| `spec.v1.json` | `w_tools_figma.spec/1` |
| `tokens.v1.json` | `w_tools_figma.tokens/1` |
| `diff.v1.json` | `w_tools_figma.diff/1` |
| `usage.v1.json` | `w_tools_figma.usage/1` |
| `budget.v1.json` | `w_tools_figma.budget/1` |

策略与 `w_tools_cli` 的 context schema 一致：

```text
新增字段不 bump
删除 / 重命名 / 改变类型 / 改变语义才 bump
消费方应忽略未知字段
```

`test/schema_test.dart` 使用 `json_schema` 校验代表性输出。
