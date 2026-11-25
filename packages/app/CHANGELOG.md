# Changelog

## 4.1.0

### Added
- `WAppPlugin.onFirstFrame()`：首帧后逐插件调用，失败隔离；适合移除原生闪屏 / 首帧后预热。
- `WAppPlugin.timeout` / `WAppPlugin.critical`：单插件初始化超时与关键性；非关键插件失败记录后继续启动。
- `WAppPluginRun` / `WAppPluginInitException`：插件耗时记录与带插件名的失败异常；`WAppPluginRunner.runs` / `totalDuration` / `firstFrame()`。

### Changed
- 关键插件 `onInit` 失败 / 超时现在抛 `WAppPluginInitException`（`cause` 保留原异常），不再直接透传插件异常；重试语义不变。
- 生命周期文档区分 App 级（`customTasks` / `onLazyInit`）与插件级（`onInit` / `onFirstFrame`）。

## 4.0.1

### Changed
- README 的 `w_tools_app_getx` 示例版本更新到 `^3.1.0`。docs-only，无代码 / API 变化。

## 4.0.0

### Added
- `WLanguageScope`：把 `WLanguage` 注入子树；`WLanguageScope.of(context)` 读取实例，
  语言切换时依赖者自动重建。`WApp.run()` 会自动插入。

### Breaking
- 删除 `WAppPlugin.builderWrapper` / `WAppPlugin.wrapApp`：渲染包裹统一用
  `WAppOptions.builder` / `WAppOptions.appWrapper`，插件只负责生命周期与
  `navigatorObservers`。
- 删除 `WAppPluginRunner.addPlugin` / `WAppPluginRunner.addPlugins` /
  `WAppPluginRunner.removePlugin` / `WAppPluginRunner.clearPlugins`：插件列表在构造时确定。
- 删除 `WLanguage.listenLanguageChange`：改用 `languageChanges.listen(...)`。
- 删除 `WLanguage.bindLocaleUpdater`：GetX 启动器改为监听 `languageListenable`。
- 删除 `WLanguage.new`：改用 `WLanguage.fromConfig(WLocaleConfig?)`；不再接受空
  `supportedLanguages`（与 `WLocaleConfig` 对齐）。
- 删除 `WLocaleConfig.copyWith` / `WAppTheme.copyWith`：配置对象在启动时构造一次。
- `WAppTheme.new` 的 `systemUiOverlayStyle` 默认值改为 `null`：不再默认设置透明状态栏 +
  黑色导航栏，需要时显式传入。

### Changed
- `WAppPluginRunner` 同层插件改为按注册顺序**串行**执行；某个 `onInit` 抛错会立即
  中断本次 init，重试时已成功的插件不重复执行、从失败点继续。
- `WLanguage.localeFromCode` 只接受 `lang` / `lang_COUNTRY` / `lang_Script_COUNTRY`，
  非法语言码抛 `ArgumentError`；`WLocaleConfig` 构造时同样校验语言码。
- `WAppPlugin` 的文档收口：runner 只执行 `dependsOn` / `onInit`，
  `navigatorObservers` 只由 `WApp` 消费；`onInit` 的 GetX 服务注册提示改指向
  `registerService<T>`。

## 3.1.1

### Changed
- `WAppPlugin.onInit` 的 dartdoc 补充：箭头写法 `Future<void> onInit() => Get.putAsync(...)`
  会把实例注册到 `void` 下（`S` 被推断成 `void`），改用
  `w_tools_app_getx` 的 `registerService<T>(...)` 或块体 + 显式泛型。

## 3.1.0

### Added
- `WAppPluginRunner`：GetX-free 的插件注册表与 `dependsOn` 分层初始化器。
- `WLanguage` / `WLocaleConfig`：语言状态与语言配置（GetX-free）。
- `WAppTheme`：应用外观（亮/暗主题、主题模式、系统栏）。

### Changed
- `WAppTheme.systemUiOverlayStyle` 恢复 1.x 默认：透明状态栏 + 黑色导航栏；
  显式传 `null` 可关闭。
- 文档：修正 `WAppPlugin` 生命周期顺序与契约层引用；补 `wrapApp` 保留 child 的测试。

## 3.0.0

### Breaking
- `w_tools_app` 拆为契约核心：只保留 `WAppPlugin`。
- `WApp` / `WAppOptions` / 路由 / 语言 / 底部弹窗移到 `w_tools_app_getx`。

## 2.1.0

### Added
- `WAppOptions.applyOrientations`：默认 `false`，启动时不再擅自设置屏幕方向；
  需要固定方向时显式传 `applyOrientations: true` 和 `orientations`。

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
