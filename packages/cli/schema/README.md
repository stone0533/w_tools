# context JSON schema

`context.v1.json` 是 `dart run w_tools_cli:w_tools context --format=json` 的 v1 结构契约。

规则：

- 新增字段不 bump `schemaVersion`；
- 消费方必须忽略未知字段；
- 删除 / 重命名 / 改类型 / 改语义才 bump；
- 严格校验器必须允许 `additionalProperties`。

当前版本：`schema = w_tools.context`，`schemaVersion = 1`。

`test/schema_test.dart` 会用 `json_schema` 校验真实 `ProjectSnapshot.toJson()` 输出。
