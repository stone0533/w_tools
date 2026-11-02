- **Startup**: use `WApp.start()` as the entry point, not a hand-written runApp/init sequence;
  declare plugin order with `WAppPlugin.dependsOn`. `builderWrapper` lives inside MaterialApp;
  `wrapApp` is outside and has no Theme/MediaQuery. `WRouteObserver` is appended automatically.
- **Bottom sheet**: use `WBottomSheet`.
