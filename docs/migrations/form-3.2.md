> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

# form 3.2 迁移：Config.build 与 *Core 内部化

| 旧 | 新 | 说明 |
| --- | --- | --- |
| `WFormTextFieldConfig().build(...)` 等 5 个 `build()` | 直接字段 `WFormTextField` 等 | 已标 `@internal` 并从公共导出 hide |
| `WFormTextFieldCore` 等 7 个 `*Core` | 直接字段；底层封装用组件本身 | 同上 |

消费方使用这些符号会在 `analyze` 报 `invalid_use_of_internal_member` / 找不到符号；
4.0 物理移出。需要特殊布局时用直接字段的 `config` 参数。
