- **启动**：入口用 `WApp.start()`，不要手写 runApp + 初始化顺序；插件需要顺序时用
  `WAppPlugin.dependsOn`。`builderWrapper` 在 MaterialApp 内，`wrapApp` 在外且没有
  Theme / MediaQuery；`WRouteObserver` 已由 WApp 自动追加，不要重复添加。
- **底部面板**：用 `WBottomSheet`。
