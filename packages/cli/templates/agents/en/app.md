- **Startup**: use `WApp.options(WAppOptions(...)).start()` as the entry point, not a hand-written
  runApp/init sequence; provide `home`, or `initialRoute` + `getPages`. Declare plugin order with
  `WAppPlugin.dependsOn`. `builderWrapper` lives inside MaterialApp; `wrapApp` is outside and has no
  Theme/MediaQuery. `WRouteObserver` is appended automatically.
- **Plugins**: implement `WAppPlugin`; `onInit` participates in layered initialization. Declare
  `dependsOn` when order matters.
- **Localization**: use `WLocaleConfig` (`WAppOptions.localeConfig`) for supported / initial /
  fallback languages. Switch at runtime with `app.language` (`WLanguage`).`changeLanguage(...)` and listen to
  `languageChanges` or `languageListenable`; do not keep a second writable currentLanguage.
- **Route stack**: use `app.routeStack`; `WRouteStack` / `WRouteObserver` are maintained by WApp and
  there is no global `defaultStack`. Use `app.routeStack.popUntilRoute(...)`.
- **Bottom sheet**: use `WBottomSheet.show(...)`, not `showModalBottomSheet`.
- **Global theme / defaults**: compose theme widgets with `WAppOptions.appWrapper`; plugins that need
  Theme/MediaQuery use `builderWrapper`; do not make the app package depend on other subpackages.
