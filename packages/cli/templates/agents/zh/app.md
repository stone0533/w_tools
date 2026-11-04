- **启动**：入口用 `WApp.options(WAppOptions(...)).start()`，不要手写 runApp + 初始化顺序；
  插件需要顺序时用 `WAppPlugin.dependsOn`。`builderWrapper` 在 MaterialApp 内，`wrapApp`
  在外且没有 Theme / MediaQuery；`WRouteObserver` 已由 WApp 自动追加，不要重复添加。
- **底部面板**：用 `WBottomSheet`。
- **全局主题 / 默认视图**：用 `WAppOptions.appWrapper` 组合对应包的主题 Widget（见该包文档）；
  不要为此让 app 依赖其它子包。
