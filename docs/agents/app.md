# app 使用规则（给人和 AI）

## 什么时候用

应用启动（初始化顺序、插件、路由、主题、多语言）、底部弹窗。

## 最小用法

```dart
Future<void> main() async {
  final app = WApp.options(
    WAppOptions(
      title: 'Demo',
      home: const HomePage(),   // 或 initialRoute: '/', getPages: [...]
      theme: WAppTheme(light: ThemeData(useMaterial3: true)),
    ),
  );
  await app.start();          // = init() + run()，只调用一次
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

class ServicePlugin with WAppPlugin {
  @override
  String get name => 'service';
  @override
  List<String> get dependsOn => const ['analytics'];
  @override
  Future<void> onInit() async { ... }
}

final app = WApp.options(
  WAppOptions(
    title: 'Demo',
    home: const HomePage(),
    plugins: [AnalyticsPlugin(), ServicePlugin()],
  ),
);
await app.start();
```

多语言：

```dart
final app = WApp.options(
  WAppOptions(
    title: 'Demo',
    home: const HomePage(),
    localeConfig: WLocaleConfig(
      supportedLanguages: {'zh_CN': '简体中文', 'en_US': 'English'},
      initialLanguage: 'zh_CN',   // 首次启动语言
      fallbackLanguage: 'en_US',  // 当前语言不受支持时回退
    ),
  ),
);
await app.start();

// 运行期切换
app.language.changeLanguage('en_US');
```

`WAppOptions.copyWith(...)` 可复用配置；`start()` 只覆盖 `initialRoute / getPages / builder /
navigatorObservers / defaultTransition / theme / translations / locale / fallbackLocale`，
`title`、`home`、`orientations`、`shouldApplyOrientations`、`appWrapper`、`localeConfig`、
`plugins` 等只能放 `WAppOptions`；外观（theme / darkTheme / themeMode / systemUiOverlayStyle）
统一放 `WAppTheme`。

## 组合全局主题（不需要插件）

```dart
final app = WApp.options(
  WAppOptions(
    title: 'Demo',
    home: const HomePage(),
    appWrapper: (child) => WAsyncTheme(
      child: WToastTheme(style: WToastStyle.defaults, child: child),
    ),
  ),
);
await app.start();
```

`appWrapper` 在 MaterialApp 外、插件 `wrapApp` 之内；需要 Theme 的东西放 `builderWrapper`。

## 不要用

- 手写 `runApp` + 自己的初始化顺序（用 `app.start()`）；
- 重复添加 `WRouteObserver`（`WApp` 已自动追加）；
- 在 `wrapApp` 里读 Theme / MediaQuery（它在 MaterialApp 外）；
- 自己保存 `WLanguage` 实例 / 用已删除的 `WRouteStack.defaultStack`；改用 `app.language` / `app.routeStack`。

## 常见坑

- `start()` / `run()` 只能调一次（重复调用抛 `StateError`）；
- 需要 Theme 的插件生命周期用 `builderWrapper`，不是 `wrapApp`；
- 多语言用 `app.language.changeLanguage(...)`，监听 `app.language.languageChanges`；
  不要保存第二份 current；
- `WLanguage` 的 `languageChanges` 是只读流，`languageListenable` 是只读 `ValueListenable`。

## 语言与路由栈

```dart
app.language.changeLanguage('zh_CN');
app.language.languageChanges.listen((code) { ... });

app.routeStack.popUntilRoute('/home');
app.routeStack.routes;

final result = await WBottomSheet.show<String>(const MySheetContent());
```

示例页：`example/lib/pages` 覆盖插件顺序、语言切换、路由栈与底部弹窗。

完整说明：[app_module.md](../modules/app_module.md) · 示例：`packages/app_getx/example`
