- **Startup**: use `WApp.options(WAppOptions(...)).start()` as the entry point, not a hand-written
  runApp/init sequence; declare plugin order with `WAppPlugin.dependsOn`. `builderWrapper` lives
  inside MaterialApp; `wrapApp` is outside and has no Theme/MediaQuery. `WRouteObserver` is
  appended automatically.
- **Bottom sheet**: use `WBottomSheet`.
- **Global theme / defaults**: compose theme widgets with `WAppOptions.appWrapper`; do not make
  `w_tools_app_getx` depend on other subpackages.

- **Localization**: use `WLocaleConfig` for supported languages
  (`WAppOptions.localeConfig`); switch at runtime with `WLanguage().changeLanguage(...)` and
  listen to `languageStream`; do not mutate `WAppConfig.currentLanguage` and expect a notify.
- **Route stack**: `WRouteStack` / `WRouteObserver` are maintained by WApp; use
  `WRouteStack.defaultStack.popUntilRoute(...)` or `app.routeStack`.
- **Bottom sheet**: use `WBottomSheet.show(...)`, not `showModalBottomSheet`.
- **Plugin order**: declare `WAppPlugin.dependsOn` for dependent plugins; never rely on
  registration order.
