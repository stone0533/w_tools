# Changelog

## 1.0.0

首次发布。

- 新增 `WApp` 启动器：`init()` / `run()` / `start()`，`start()` 为一站式入口
- 新增 `WAppPlugin` 插件契约：支持 `dependsOn` 分层初始化（同层并行、跨层串行）
- 新增 `WAppConfig`：统一配置标题、初始路由、主题、语言与系统栏样式
- 新增 `WRoute` / `WRouteObserver`：GetX 路由记录、移除与观察
- 新增 `WLanguage`：语言切换与监听
- 新增 `WBottomSheet.show()`：独立底部弹窗工具
