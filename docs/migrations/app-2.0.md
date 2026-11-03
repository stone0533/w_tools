# app 2.0 迁移

| 旧 | 新 |
| --- | --- |
| `WApp()` + 可变字段（`..title =` 等） | `WApp.options(WAppOptions(...))` |
| 静态 `WRoute.*` | `WApp.routeStack.*` / `WRouteStack.defaultStack.*` |

`WApp.options` 的配置项与旧字段一一对应；`start()` 仍可覆盖 `initialRoute` / `getPages` /
`theme` / `translations` / `locale` / `fallbackLocale` / `builder` / `navigatorObservers` /
`defaultTransition` 这 9 个参数。`title`、`orientations`、`systemUiOverlayStyle`、`appWrapper`、
`localeConfig`、`plugins` 只能放在 `WAppOptions` 里。
