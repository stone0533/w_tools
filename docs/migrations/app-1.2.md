> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

# app 1.2 迁移：`WAppOptions` / `WLocaleConfig` / `WRouteStack`

| 旧 | 新 | 说明 |
| --- | --- | --- |
| `WApp()..title = ...` 等可变字段 | `WApp.options(WAppOptions(...))` | 字段 2.0 移除；`start()` 参数仍可覆盖 options |
| `WAppConfig.supportedLanguages = {...}` 在 main 里 | `WLocaleConfig(supportedLanguages: ...)` 放进 `WAppOptions` | 当前语言真源仍是 `WLanguage`；当前语言不在支持列表时回退 `defaultLanguage` |
| 静态 `WRoute.popUntilRoute(...)` 等 | `WRouteStack.defaultStack.popUntilRoute(...)`；持有 `WApp` 时用 `app.routeStack` | 静态 `WRoute` 2.0 移除 |
| `WRouteObserver()` | `WRouteObserver(stack: app.routeStack)` | 无参时仍写默认栈，兼容旧代码 |

优先级：`start()` / 显式参数 > `WAppOptions` > 已弃用字段 > 默认值。
