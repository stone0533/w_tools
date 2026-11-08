> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

# app_getx 2.0 迁移

从 `w_tools_app_getx 1.x` 升级到 `2.0.0`。2.0 的重点是去掉全局语言状态、
让每个 `WApp` 拥有自己的语言与路由栈，并补齐 `WAppOptions` 的路由/主题/本地化字段。

| 旧 | 新 |
| --- | --- |
| `WAppConfig.supportedLanguages = {...}` | `WLocaleConfig(supportedLanguages: {...})` 放进 `WAppOptions` |
| `WAppConfig.currentLanguage` | `app.language.currentLanguage` / `app.language.changeLanguage(...)` |
| `WLanguage()` 全局单例 | `app.language` |
| `WLanguage().languageStream` | `app.language.languageChanges` 或 `languageListenable` |
| `WLanguage().syncFromConfig()` | 删除；`WLocaleConfig` 在 `WApp` 构造时应用 |
| `WLocaleConfig(defaultLanguage: 'zh_CN')` | `WLocaleConfig(initialLanguage: 'zh_CN', fallbackLanguage: 'en_US')` |
| `WRouteStack.defaultStack` | `app.routeStack`（或 `WAppOptions.routeStack` 注入） |
| `WRouteObserver()` | `WRouteObserver(stack: app.routeStack)` |
| `WAppOptions(applyOrientations: true)` | `WAppOptions(shouldApplyOrientations: true)` |
| `WAppOptions(...)` 的 `const` 用法 | 去掉 `const`（内部做不可变拷贝） |
| `WApp.routeStack = ...` | `WAppOptions(routeStack: ...)`（`WApp.routeStack` 为 final） |

## 升级步骤

1. 把 `WAppConfig` 的读写迁到 `WLocaleConfig` + `app.language`；
2. 把 `WRouteStack.defaultStack` 改为 `app.routeStack`，需要隔离时通过
   `WAppOptions.routeStack` 注入；
3. 把 `defaultLanguage` 改为 `initialLanguage` / `fallbackLanguage`，
   两者都必须在 `supportedLanguages` 中；
4. 去掉 `WAppOptions` 的 `const`；`applyOrientations` 改为 `shouldApplyOrientations`；
5. 如果项目需要中文 Material 控件，确认 `WAppOptions.localizationsDelegates` 或使用默认的
   `GlobalMaterialLocalizations.delegates`；
6. 运行 `flutter analyze` 与 `flutter test`，按编译错误清理旧 API。

## 为什么

- 全局 `WAppConfig` + `WLanguage` 单例让多 `WApp` / 测试互相污染；
- `defaultLanguage` 只在“当前语言不受支持”时生效，和“首次启动语言”语义冲突；
- `WRouteStack.defaultStack` 让路由栈无法按应用隔离；
- `WAppOptions` 缺少 `home` / `darkTheme` / `supportedLocales` 等常用入口。
