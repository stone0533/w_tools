# app 使用规则（给人和 AI）

## 什么时候用

应用启动（初始化顺序、插件、路由、主题、多语言）、底部弹窗。

## 最小用法

```dart
void main() {
  WApp.options(
    WAppOptions(
      title: 'Demo',
      initialRoute: '/',
      getPages: [GetPage(name: '/', page: () => const HomePage())],
      theme: ThemeData(useMaterial3: true),
    ),
  ).start();   // = init() + run()，只调用一次
}
```

插件：

```dart
class AnalyticsPlugin with WAppPlugin {
  @override
  String get name => 'analytics';
  @override
  Future<void> onInit() async { ... }
}
WApp.options(
  WAppOptions(title: 'Demo', plugins: [AnalyticsPlugin()]),
).start();
```

多语言：

```dart
WApp.options(
  WAppOptions(
    title: 'Demo',
    localeConfig: const WLocaleConfig(
      supportedLanguages: {'zh_CN': '简体中文', 'en_US': 'English'},
      defaultLanguage: 'zh_CN',   // 当前语言不在列表时回退
    ),
  ),
).start();
```

`WAppOptions.copyWith(...)` 可复用配置；`start()` 只覆盖 `initialRoute / getPages / builder /
navigatorObservers / defaultTransition / theme / translations / locale / fallbackLocale`，
`title`、`orientations`、`systemUiOverlayStyle`、`appWrapper` 等只能放 `WAppOptions`。

## 组合全局主题（不需要插件）

```dart
WApp.options(
  WAppOptions(
    title: 'Demo',
    appWrapper: (child) => WAsyncTheme(
      child: WToastTheme(style: WToastStyle.defaults, child: child),
    ),
  ),
).start();
```

`appWrapper` 在 MaterialApp 外、插件 `wrapApp` 之内；需要 Theme 的东西放 `builderWrapper`。

## 不要用

- 用可变字段（`app.title = ...` 已在 2.0 删除）；统一 `WAppOptions`；
- 手写 `runApp` + 自己的初始化顺序（用 `WApp.start()`）；
- 重复添加 `WRouteObserver`（`WApp` 已自动追加）；
- 在 `wrapApp` 里读 Theme / MediaQuery（它在 MaterialApp 外）。

## 常见坑

- `start()` 只能调一次（重复调用会再次 `runApp`）；
- 需要 Theme 的插件生命周期用 `builderWrapper`，不是 `wrapApp`；
- 多语言用 `WLanguage().changeLanguage(...)` 监听变化，不要直接写 `WAppConfig.currentLanguage`。

完整说明：[app_module.md](../modules/app_module.md) · 示例：`packages/app/example`
