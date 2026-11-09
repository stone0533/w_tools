- **启动 / 插件**（`explain WApp`）：`WApp.options(WAppOptions(...)).start()`；插件 `WAppPlugin` + `dependsOn`，
  非 GetX 用 `WAppPluginRunner`；语言 `WLanguage` / `WLocaleConfig`；路由栈 `WRouteStack`（`app.routeStack`）；
  外观 `WAppTheme`；底部面板 `WBottomSheet`。
  插件里注册服务用 `registerService(() => Svc().init())`；`Future<void> onInit() => Get.putAsync(...)`
  会把泛型推成 `void`，实例注册到 `void` 下，`Get.find` 找不到且 analyzer 不报。
