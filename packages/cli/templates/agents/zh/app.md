- **启动**：入口用 `WApp.options(WAppOptions(...)).start()`，不要手写 runApp + 初始化顺序；
  插件需要顺序时用 `WAppPlugin.dependsOn`。`builderWrapper` 在 MaterialApp 内，`wrapApp`
  在外且没有 Theme / MediaQuery；`WRouteObserver` 已由 WApp 自动追加，不要重复添加。
- **底部面板**：用 `WBottomSheet`。
- **全局主题 / 默认视图**：用 `WAppOptions.appWrapper` 组合对应包的主题 Widget（见该包文档）；
  不要为此让 app 依赖其它子包。

- **多语言**：支持语言列表用 `WLocaleConfig`（`WAppOptions.localeConfig`）；运行期切换用
  `WLanguage().changeLanguage(...)`，监听 `languageStream`；不要直接改
  `WAppConfig.currentLanguage` 后期待通知。
- **路由栈**：`WRouteStack` / `WRouteObserver` 由 WApp 自动维护；操作栈用
  `WRouteStack.defaultStack.popUntilRoute(...)` 或 `app.routeStack`。
- **底部面板**：用 `WBottomSheet.show(...)`，不要直接用 `showModalBottomSheet`。
- **插件顺序**：有依赖的插件必须声明 `WAppPlugin.dependsOn`，不要依赖注册顺序。
