# Changelog

## 3.3.0

### Added
- `WApp.themeMode`（`ValueListenable<ThemeMode>`）与 `WApp.setThemeMode(...)`：运行时切主题模式，
  只重建 `GetMaterialApp`，不重置路由 / 不重建 `appWrapper`。
- `WApp.dispose()`：移除语言 / 系统语言 / 主题监听并 dispose `language`；幂等，dispose 后
  `init` / `run` / `buildRoot` / `setThemeMode` 抛 `StateError`。
- 跟随系统语言：`WLocaleConfig(followSystem: true)` 时启动与系统语言变化都同步到 `WLanguage`，
  用户显式切语言后停止跟随。

### Changed
- 语言以 `WLanguage` 为唯一真源：首帧后移除 GetX 自带的系统语言观察者（它会把 `Get.locale`
  设成不按 `supportedLocales` 解析的 `deviceLocale`，还会整树 reassemble）。
- 依赖下界 `w_tools_app: ^4.2.0`。

### Fixed
- `buildRoot()` 在未初始化 `WidgetsBinding` 的纯单测里抛可执行的 `StateError`
  （不再只给 Framework 的断言文本）。
- 跟随系统解析改用 `WLocaleConfig.supportedLanguages`（`WAppOptions.supportedLocales`
  只覆盖 Flutter 列表），`en` / `en_US` 形态不一致时不再出现「语言不同步」；
  `supportedLocales` 校验失败时给出形态提示。
- `init()` 在非关键插件失败后无法重试（`_initialized` 已置位，重复调用直接返回）：现在按
  上一轮插件结果判断，只重试失败的插件，已成功的插件不重复执行。
- `WAppStartupReport.pluginRuns` 只保留最近一轮 `init` 的记录：此前重试会累积历史失败，
  成功重试后 `failures` 仍显示旧失败。

## 3.2.0

### Added
- `WApp.buildRoot()`：构建应用根（不调用 `runApp`、不要求 `init`），widget 测试复用运行时装配（`appWrapper` / `builder` / scope / 系统栏兜底）。
- `WAppOptions.startupLog` / `WApp.startupReport` / `WAppStartupReport`：逐插件耗时、失败、首帧与启动摘要日志。
- `WApp` 首帧后调用插件 `onFirstFrame()`，并为 `systemUiOverlayStyle` 加根级兜底 `AnnotatedRegion`。

### Changed
- `WAppTheme.systemUiOverlayStyle` 从一次性设置改为**全局兜底**：页面自己的 `WScaffold` / `WAppBar` 标注优先，页面未标注时回落到它（修复从浅色状态栏页面返回后不恢复）。
- 插件失败 / 超时错误为 `WAppPluginInitException`（从 `w_tools_app` re-export）。

## 3.1.0

### Changed
- `w_tools_app` 下界从 `>=3.2.0 <5.0.0` 收紧到 `^4.0.0`：3.0.0 起页面作用域与行为按
  app 4.0.0 设计，不再对 3.2.0 的旧 runner / 语言码解析行为作兼容承诺。
- 清理 3.0.0 里为 app 3.2.0 deprecation 留下的内部 `deprecated_member_use` ignore 注释。
- 文档：`app_getx` 3.0.0 / app 4.0.0 的现状与迁移入口。

## 3.0.0

### Added
- `WAppScope` / `WApp.of(context)` / `WApp.maybeOf(context)`：在应用树内读取当前 `WApp`，
  页面不再需要保存全局 `app`；`WApp.run()` 会自动插入 scope。
- re-export `WLanguageScope`，页面可用 `WLanguageScope.of(context)` 读取语言。

### Breaking
- 删除 `WAppOptions.locale` / `WAppOptions.fallbackLocale`，以及 `WApp.start` / `WApp.run`
  上的 `locale` / `fallbackLocale` 参数：语言选择统一走 `WAppOptions.localeConfig`
  （`WLanguage`）；GetX 的 `fallbackLocale` 从 `WLocaleConfig.fallbackLanguage` 派生。
- 删除 `WApp.addPlugin` / `WApp.addPlugins` / `WApp.removePlugin` / `WApp.clearPlugins`：
  插件只在 `WAppOptions.plugins` 声明。
- 删除 `WAppPlugin.builderWrapper` / `WAppPlugin.wrapApp`：用
  `WAppOptions.builder` / `appWrapper` 包裹；`WApp` 不再叠加插件包裹钩子。
- 删除 `WAppPluginRunner.addPlugin` / `addPlugins` / `removePlugin` / `clearPlugins`
  （随 `w_tools_app` 4.0 的 re-export 面变化）。
- 删除 `WLanguage.listenLanguageChange` / `WLanguage.bindLocaleUpdater` /
  `WLanguage.new` / `WLocaleConfig.copyWith` / `WAppTheme.copyWith`。
- `WAppOptions.new` / `WAppOptions.copyWith` 的签名移除 locale / fallbackLocale 参数。
- `WAppTheme.new` 的 `systemUiOverlayStyle` 默认值改为 `null`。

### Changed
- `WAppOptions.supportedLocales` 仍可显式覆盖，默认从 `localeConfig` 派生；当前语言
  不在列表内时 `WApp.run()` 抛 `StateError`。空列表在构造时抛 `ArgumentError`。
- 语言切换改为监听 `app.language.languageListenable`，不再通过回调槽注入。
- `appWrapper` 位于 `GetMaterialApp` 外；`builder` 位于 `GetMaterialApp` 内，二者不再
  与插件钩子混排。

## 2.1.1

### Fixed
- `example` 的 `w_tools_app` path override 移到 `example/pubspec_overrides.yaml`；
  发布物里的示例可独立 `pub get`。

## 2.1.0

### Added
- `registerService<T extends GetxService>(factory, {tag, permanent})`：在
  `WAppPlugin.onInit` 里注册服务。返回 `Future<void>`，`T` 只由 factory 推断，
  避免 `Future<void> onInit() => Get.putAsync(...)` 把实例注册到 `void` 下、
  `Get.find<T>()` 找不到的坑（连箭头写法也安全）。

## 2.0.0

### Breaking
- 删除 `WAppConfig`：语言状态改为每个 `WApp` 实例持有的 `app.language`（`WLanguage`）。
- `WLocaleConfig.defaultLanguage` 删除，改为 `initialLanguage` / `fallbackLanguage`；
  `WLocaleConfig.new` 改为校验支持列表，且不再提供 `const` 构造。
- `WLanguage` 不再使用全局单例：`WLanguage.new` 改为实例构造；删除
  `WLanguage.languageStream`（改用 `languageChanges` / `languageListenable`）与
  `WLanguage.syncFromConfig`；`WLanguage.changeLanguage` 返回 `bool`。
- `WRouteStack.defaultStack` 删除：每个 `WApp` 有自己的 `app.routeStack`；
  `WRouteStack.routes` 改为 `UnmodifiableListView`；
  `WRouteStack.removeRouteIfExists` / `WRouteStack.removeRoutesAfter` / `WRouteStack.popUntilRoute` 返回 `bool` / `int` / `bool`。
- `WLanguage._internal` 私有构造删除（`WLanguage.new` 改为实例构造）。
- `WRouteObserver.new` 必须传 `stack:`；默认不记录 `PopupRoute`（可 `recordPopups: true`）。
- `WAppOptions.applyOrientations` 改为 `shouldApplyOrientations`；
  `WAppOptions.theme` 类型改为 `WAppTheme?`，删除 `WAppOptions.darkTheme` / `WAppOptions.themeMode` /
  `WAppOptions.systemUiOverlayStyle`。
- `WAppOptions.new` / `WAppOptions.copyWith` 改为非 const，新增 `home` 等字段；
  `WAppOptions` 现在做不可变拷贝并实现 `==` / `hashCode`。
- `WApp.routeStack` 改为 `final`；自定义栈通过 `WAppOptions.routeStack` 注入。

### Added
- `WLanguage` / `WLocaleConfig` / `WAppTheme` 的声明移到 `w_tools_app`；本包继续
  re-export，import 路径不变。依赖下界抬到 `w_tools_app: ^3.1.0`。
- `WAppOptions`：`home`、`routes`、`navigatorKey`、`supportedLocales`、
  `localizationsDelegates`、`routeStack`、`unknownRoute`、`shouldApplyOrientations`；
  `WAppOptions` 的 `==` / `hashCode`。
- `WAppTheme`：亮/暗主题、主题模式与系统 UI 样式；`==` / `hashCode` / `copyWith`。
- `WLanguage`：`languageChanges`、`languageListenable`、`hasExplicitSelection`。
- `WRouteObserver`：`stack`、`recordPopups`。
- `WApp`：`language`；`WLocaleConfig` 的 `==` / `hashCode` / `copyWith`。

### Changed
- 恢复 1.x 默认透明状态栏：`WAppTheme.systemUiOverlayStyle` 默认非 null；
  未传 `theme` 时使用默认 `WAppTheme`，显式 `null` 关闭。
- `WAppOptions` 构造时校验 `home` 或 `initialRoute` + `getPages`；`start` 覆盖仍可用，
  但基础配置必须有效。
- `WApp.run` 从 `WLocaleConfig` 派生 `supportedLocales`，并默认使用
  `GlobalMaterialLocalizations.delegates`。
- 插件在 `init` 后不可增删；`start` / `run` 只能调用一次。
- `WRouteObserver` 按栈去重；`PopupRoute` 默认不进入路由栈。
- `WLanguage.changeLanguage` 改为更新 `Get.locale` + `Get.rootController.update()`，
  不再触发 GetX 的全树 `performReassemble`。
- `WLanguage` 不再暴露 `RxString`；直接依赖 `Obx` 读 `currentLanguage` 的代码改用
  `languageListenable` / `languageChanges`。

### Fixed
- `WLocaleConfig.initialLanguage` 现在真正作为首次启动语言生效。
- `WLanguage` 的 `initialLanguage` / `fallbackLanguage` 会校验是否在支持列表内。
- 示例“移除当前路由后返回”不再多 pop 一次首页。

## 1.0.1

### Fixed
- README：修正 `WApp.start()` 为 `app.start()`；补 `WLocaleConfig`、`WBottomSheet.show`
  与 `appWrapper` / `builderWrapper` 说明。

## 1.0.0

### Added
- 从 `w_tools_app` 拆出 GetX 启动层：WApp、WAppOptions、GetX 路由、语言、底部弹窗、路由观察者。
