> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

# form 3.0 迁移：默认边框与主题

| 旧 | 新 | 说明 |
| --- | --- | --- |
| `WForm` 不传 `borderConfig` 时无边框、message / 校验错误不可见 | 默认 `WFormBorderConfig.fromTheme(Theme.of(context))` | 字段有主题边框，错误默认显示 |
| 想保持「无外观」 | 显式传 `const WFormBorderConfig()` | 无边框、不渲染 message |
| 嵌套时祖先 `WFormTheme(borderConfig:)` 覆盖显式参数 | 显式参数 > 祖先作用域 | 里层配置优先 |
| `WFormBorderConfig` 无 `==`、hint/error 只能传 builder | 实现 `==`/`hashCode`；新增 `hintStyle`/`errorStyle` | 内置工厂不再创建闭包 |
