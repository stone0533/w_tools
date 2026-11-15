- **Startup / plugins** (`explain WApp`): `WApp.options(WAppOptions(...)).start()`; plugins implement
  `WAppPlugin` and declare `dependsOn`; `WAppPluginRunner` for non-GetX shells; language via
  `WLanguage` / `WLocaleConfig` (pages use `WLanguageScope.of(context)`); route stack via `WRouteStack`
  (pages use `WApp.of(context).routeStack`); appearance via `WAppTheme`; bottom sheets via `WBottomSheet`.
  Register services with `registerService(() => Svc().init())`; `Future<void> onInit() => Get.putAsync(...)`
  infers the generic as `void`, the instance lands under `void`, and `Get.find` misses it without an analyzer error.
