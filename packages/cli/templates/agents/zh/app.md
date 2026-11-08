- **启动**：入口用 `WApp.options(WAppOptions(...)).start()`，不要手写 runApp + 初始化顺序；
  必须提供 `home`，或 `initialRoute` + `getPages`。插件需要顺序时用 `WAppPlugin.dependsOn`。
  `builderWrapper` 在 MaterialApp 内，`wrapApp` 在外且没有 Theme / MediaQuery；
  `WRouteObserver` 已由 WApp 自动追加，不要重复添加。
- **插件**：实现 `WAppPlugin`，`onInit` 参与分层初始化；有顺序要求必须显式声明 `dependsOn`。
- **多语言**：支持语言 / 首次语言 / 回退语言用 `WLocaleConfig`（`WAppOptions.localeConfig`）；
  运行期用 `app.language`（`WLanguage`）的 `changeLanguage(...)`，监听 `languageChanges` 或 `languageListenable`；
  不要自己保存第二份 currentLanguage。
- **路由栈**：用 `app.routeStack`；`WRouteStack` / `WRouteObserver` 由 WApp 维护，
  没有全局 `defaultStack`。操作栈用 `app.routeStack.popUntilRoute(...)`。
- **底部面板**：用 `WBottomSheet.show(...)`，不要直接用 `showModalBottomSheet`。
- **应用外观**：`theme` / `darkTheme` / `themeMode` / `systemUiOverlayStyle` 用 `WAppTheme`，
  通过 `WAppOptions.theme` 传入。
- **全局主题 / 默认视图**：用 `WAppOptions.appWrapper` 组合对应包的主题 Widget；
  需要 Theme / MediaQuery 的插件用 `builderWrapper`；不要为此让 app 依赖其它子包。
