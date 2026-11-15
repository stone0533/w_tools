# context JSON schema

`context.v1.json` 是 `dart run w_tools_cli:w_tools context --format=json` 的 v1 结构契约。

规则：

- 新增字段不 bump `schemaVersion`；
- 消费方必须忽略未知字段；
- 删除 / 重命名 / 改类型 / 改语义才 bump；
- 严格校验器必须允许 `additionalProperties`。

当前版本：`schema = w_tools.context`，`schemaVersion = 1`。

`test/schema_test.dart` 会用 `json_schema` 校验真实 `ProjectSnapshot.toJson()` 输出。

## 不是稳定契约的字段

`commands` 是提示映射：key 会随命令收敛变化（例如 `feedbackSearch`），消费方按值执行并忽略
未知 / 缺失 key；增删 key 不 bump `schemaVersion`。需要稳定命令清单时以 `w_tools --help` 为准。

`capabilities` 的 `summary` 是给人 / AI 读的摘要（来源 `catalog/capabilities.yaml`），会随
catalog 更新；消费方不要按具体字符串做程序分支，只依赖 `package` / `summary` 两个字段。
