> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

# form 4.0 迁移

| 旧 | 新 |
| --- | --- |
| `WFormDefaults.*` 全局静态图标 | `WFormIcons.defaults.*` / `WFormTheme.icons` / `WForm.icons` |
| `WFormBorderConfig.builder()` / `WFormBorderConfigBuilder` | 直接 `WFormBorderConfig(...)` / `copyWith(...)` |
| `Row(...).withFormBorder(...)` | `WFormFieldShell(name: ..., child: Row(...))` |
