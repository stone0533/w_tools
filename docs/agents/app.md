# app 使用规则（给人和 AI）

## 什么时候用

应用启动（初始化顺序、插件、路由、主题、多语言）、底部弹窗。

`WAppPlugin` / `WAppPluginRunner` / `WLanguage` / `WLanguageScope` / `WLocaleConfig` /
`WAppTheme` 在 `w_tools_app`；`WApp` / `WAppScope` / `WAppOptions` / 路由 / 底部弹窗在
`w_tools_app_getx`。

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

插件按 `dependsOn` 分层、同层按注册顺序**串行**执行；关键插件（默认）的 `onInit`
抛错 / 超时会抛 `WAppPluginInitException`（带插件名），重试时已成功的插件不重复执行。
插件列表只在 `WAppOptions.plugins` 声明，没有 `addPlugin` / `removePlugin`。

首帧后要做的事（移除原生闪屏、预热）写插件的 `onFirstFrame()`，不要塞进某个页面：

```dart
class SplashPlugin with WAppPlugin {
  @override
  String get name => 'native-splash';
  @override
  Future<void> onInit() async => FlutterNativeSplash.preserve(
    widgetsBinding: WidgetsBinding.instance,
  );
  @override
  Future<void> onFirstFrame() async => FlutterNativeSplash.remove();
}
```

单插件可设 `Duration? get timeout`（默认不限制）与 `bool get critical`（默认 true；
false 时失败只记录、继续启动）。

多语言：

```dart
final app = WApp.options(
  WAppOptions(
    title: 'Demo',
    home: const HomePage(),
    localeConfig: WLocaleConfig(
      supportedLanguages: {'zh_CN': '简体中文', 'en_US': 'English'},
      initialLanguage: 'zh_CN',   // 启动语言
      fallbackLanguage: 'en_US',  // GetX 翻译缺失时的回退
    ),
  ),
);
await app.start();

// 运行期切换
app.language.changeLanguage('en_US');
// UI 监听：app.language.languageListenable（ValueListenable）或 languageChanges（Stream）
```

语言只有 `localeConfig` 一个入口，`WAppOptions.locale` / `fallbackLocale` 已删除。
`WAppOptions.supportedLocales` 只用于显式覆盖 Flutter 本地化列表；当前语言不在列表内时
`run()` 抛 `StateError`。语言不持久化：要恢复上次选择，在 `start()` 之前调用
`app.language.changeLanguage(saved)`。

页面里用 `WLanguageScope.of(context)` 读取语言（切换时自动重建），用
`WApp.of(context)` 读取应用实例；不要保存全局 `app`。

`WAppScope` / `WLanguageScope` 由 `WApp.run()` 自动插入；测试里可以手动包一层：

```dart
await tester.pumpWidget(WAppScope(app: app, child: const MyPage()));
```

`WAppOptions.copyWith(...)` 可复用配置；`start()` 只覆盖 `initialRoute / getPages / builder /
navigatorObservers / defaultTransition / theme / translations`，
`title`、`home`、`orientations`、`shouldApplyOrientations`、`appWrapper`、`localeConfig`、
`plugins` 等只能放 `WAppOptions`；外观（theme / darkTheme / themeMode / systemUiOverlayStyle）
统一放 `WAppTheme`；默认不干预系统栏，需要时显式传 `systemUiOverlayStyle`。

## WAsyncExecutor（项目 composition root）

如果项目使用默认 async loading / toast，用专用插件创建并注册执行器：

```dart
class AsyncExecutorPlugin with WAppPlugin {
  @override
  String get name => 'async-executor';

  @override
  Future<void> onInit() async {
    Get.put(
      WAsyncExecutor(
        WAsyncHooks(
          onStart: AppLoading.show,
          onError: AppToast.error,
          onFinally: AppLoading.hide,
        ),
      ),
    );
  }
}
```

在 `WAppOptions.plugins` 注册；`onInit` 在 `runApp` 前执行。业务用
`Get.find<WAsyncExecutor>().run(...)`，全局默认 hooks 已删除。

## 包裹应用（不需要插件）

```dart
final app = WApp.options(
  WAppOptions(
    title: 'Demo',
    home: const HomePage(),
    // MaterialApp 外：没有 Theme / MediaQuery
    appWrapper: (child) => WAsyncTheme(
      child: WToastTheme(style: WToastStyle.defaults, child: child),
    ),
    // MaterialApp 内：有 Theme / Localizations / MediaQuery
    builder: (context, child) => Theme(
      data: Theme.of(context).copyWith(extensions: [buildAppTextStyles()]),
      child: child ?? const SizedBox.shrink(),
    ),
  ),
);
await app.start();
```

插件已删除 `builderWrapper` / `wrapApp`；需要 Theme 的全局中间件放 `builder`。
`appWrapper` 在 `GetMaterialApp` 外，`builder` 在 `GetMaterialApp` 内。

## 不要用

- 手写 `runApp` + 自己的初始化顺序（用 `app.start()`）；
- 重复添加 `WRouteObserver`（`WApp` 已自动追加）；
- 在 `appWrapper` 里读 Theme / MediaQuery（它在 MaterialApp 外）；
- 给 `WAppOptions` 传 `locale` / `fallbackLocale`（3.0 已删除；用 `localeConfig`）；
- 保存全局 `app` 变量；页面用 `WApp.of(context)` / `WLanguageScope.of(context)` 读取；
- 自己保存 `WLanguage` 实例；用 `WLanguageScope.of(context)`；
- 使用已删除的 `WRouteStack.defaultStack`；改用 `WApp.of(context).routeStack`。

## 常见坑

- `start()` / `run()` 只能调一次（重复调用抛 `StateError`）；
- 插件同层串行，有顺序要求仍要写 `dependsOn`，不要依赖注册顺序的偶然性；
- 多语言用 `app.language.changeLanguage(...)`，监听 `app.language.languageChanges`；
  不要保存第二份 current；
- `WLanguage` 的 `languageChanges` 是只读流，`languageListenable` 是只读 `ValueListenable`；
- 语言码只接受 `lang` / `lang_COUNTRY` / `lang_Script_COUNTRY`（如 `en` / `en_US` / `zh_Hant_TW`）。

## 语言与路由栈

```dart
final app = WApp.of(context);
final language = WLanguageScope.of(context);

language.changeLanguage('zh_CN');
language.languageChanges.listen((code) { ... });

app.routeStack.popUntilRoute('/home');
app.routeStack.routes;

final result = await WBottomSheet.show<String>(const MySheetContent());
```

示例页：`example/lib/pages` 覆盖插件顺序、语言切换、路由栈与底部弹窗。

完整说明：[app_module.md](../modules/app_module.md) · 示例：`packages/app_getx/example`
