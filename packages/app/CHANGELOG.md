## 2.1.0

### Added
- `WAppOptions.applyOrientations`：默认 `false`，启动时不再擅自设置屏幕方向；
  需要固定方向时显式传 `applyOrientations: true` 和 `orientations`。

# Changelog

## 2.0.0

### Breaking
- 删除 `WApp` 的可变配置字段（`title` / `initialRoute` / `getPages` / `theme` / `translations` /
  `locale` / `fallbackLocale` / `builder` / `navigatorObservers` / `defaultTransition` /
  `systemUiOverlayStyle` / `orientations` / `appWrapper`）：改用 `WApp.options(WAppOptions(...))`。
- 删除静态 `WRoute`：改用 `WApp.routeStack` / `WRouteStack`。
- `WApp` 不再有无参构造函数。

## 1.2.0

### Added
- `WAppOptions`（不可变）+ `WApp.options(...)`；`start()` 参数 > options > 字段 > 默认值。
- `WLocaleConfig`：支持语言列表 + 当前语言不支持时的回退默认值。
- `WRouteStack` + `WApp.routeStack`；`WRouteObserver(stack:)` 可写入指定实例。

### Deprecated（2.0 移除）
- `WApp` 的可变配置字段（`title` / `initialRoute` / `getPages` / `theme` / `locale` /
  `fallbackLocale` / `builder` / `navigatorObservers` / `defaultTransition` /
  `systemUiOverlayStyle` / `orientations` / `appWrapper`）。
- 静态 `WRoute`：改用 `WApp.routeStack` / `WRouteStack`。

## 1.1.0

### Added
- `WBottomSheet.show` 透传 `backgroundColor` / `barrierColor` / `isDismissible` / `enableDrag` /
  `shape` / `clipBehavior` / `ignoreSafeArea` / `elevation` / `isScrollControlled`。

### Fixed
- `WRoute.popUntilRoute` 用路由自身 `settings.name` 判断，避免名不一致时一路弹空。
- `WApp.run()` 移除 `title ?? ''` 死分支。

## 1.0.1

### Fixed
- `WApp.init()` 并发调用时共享同一次初始化，避免插件 `onInit` 被执行两次；补充并发测试。
- 文档明确 `start()` / `run()` 只应调用一次，以及初始化失败重试会重新执行插件。

## 1.0.0

首次发布。

- 新增 `WApp` 启动器：`init()` / `run()` / `start()`，`start()` 为一站式入口
- 新增 `WAppPlugin` 插件契约：支持 `dependsOn` 分层初始化（同层并行、跨层串行）
- 新增 `WAppConfig`：统一配置标题、初始路由、主题、语言与系统栏样式
- 新增 `WRoute` / `WRouteObserver`：GetX 路由记录、移除与观察
- 新增 `WLanguage`：语言切换与监听
- 新增 `WBottomSheet.show()`：独立底部弹窗工具
