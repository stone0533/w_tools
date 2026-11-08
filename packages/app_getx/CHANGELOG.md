# Changelog

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
