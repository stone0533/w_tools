# w_tools_app_getx

[![pub package](https://img.shields.io/pub/v/w_tools_app_getx.svg)](https://pub.dev/packages/w_tools_app_getx)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

`w_tools_app_getx` 是 w_tools 的 GetX 应用启动层，提供 `WApp` 启动器、插件依赖编排、GetX 路由与语言切换、底部弹窗与路由观察者。

> **注意：本包强依赖 GetX。** 使用 `WApp` 即意味着你的项目需要使用 GetX。

## 特性

- **一站式启动**：`app.start()` = `init()` + `run()`；入口是 `WApp.options(...)`
- **插件体系**：`WAppPlugin` 支持 `dependsOn` 分层初始化、`onFirstFrame` 首帧钩子、
  单插件 `timeout` / `critical`
- **启动可观测**：`app.startupReport`（逐插件耗时 / 失败 / 首帧）+ `startupLog`
- **系统栏兜底**：`WAppTheme.systemUiOverlayStyle` 是全局 fallback，页面标注优先
- **实例级状态**：`app.language` / `app.routeStack`，没有全局单例
- **语言切换**：`WLanguage` + `WLocaleConfig`（来自 `w_tools_app`）
- **路由工具**：`WRouteStack` / `WRouteObserver` 记录与操作 GetX 路由
- **测试宿主**：`app.buildRoot()` 复用运行时装配，widget 测试不用手搭外壳
- **底部弹窗**：`WBottomSheet.show()`

## 安装

```yaml
dependencies:
  w_tools_app_getx: ^3.2.0
```

> 本包最低要求 Flutter 3.38.0。

## 快速开始

```dart
import 'package:flutter/material.dart';
import 'package:w_tools_app_getx/w_tools_app_getx.dart';

Future<void> main() async {
  final app = WApp.options(
    WAppOptions(
      title: 'Demo',
      home: const HomePage(), // 或 initialRoute + getPages
    ),
  );

  await app.start();
}
```

自定义插件：

```dart
class AnalyticsPlugin with WAppPlugin {
  @override
  String get name => 'analytics';

  @override
  Future<void> onInit() async {
    // 初始化统计 SDK
  }
}

final app = WApp.options(
  WAppOptions(
    title: 'Demo',
    home: const HomePage(),
    plugins: [AnalyticsPlugin()],
  ),
);
await app.start();
```

插件负责初始化（以及可选的 `navigatorObservers`）；需要包裹整个应用时用
`WAppOptions.appWrapper`，需要在 MaterialApp 内部插入 Theme / MediaQuery 时用
`WAppOptions.builder`。

### 首帧钩子 / 超时 / 关键性

`onFirstFrame` 在首帧绘制后由 `WApp` 逐个插件调用，适合移除原生闪屏、首帧后预热；
单个插件抛错只记录，不影响启动。`timeout` 默认不限制（建议对网络 / 原生通道插件
显式设置），`critical: false` 的插件失败时继续启动：

```dart
class SplashPlugin extends WAppPlugin {
  @override
  String get name => 'native-splash';

  @override
  Future<void> onInit() async => FlutterNativeSplash.preserve(
    widgetsBinding: WidgetsBinding.instance,
  );

  @override
  Future<void> onFirstFrame() async => FlutterNativeSplash.remove();
}

class AnalyticsPlugin extends WAppPlugin {
  @override
  String get name => 'analytics';

  @override
  Duration get timeout => const Duration(seconds: 10);

  @override
  bool get critical => false;

  @override
  Future<void> onInit() => Analytics.init();
}
```

### 启动观测

```dart
await app.start();

final report = app.startupReport;
report?.pluginRuns;          // 逐插件耗时 / 成功失败（WAppPluginRun）
report?.failures;            // 失败插件
report?.initDuration;        // init 总耗时
report?.firstFrameDuration;  // 首帧耗时（首帧后填入）

// 日志默认在 debug 打开；profile / CI 可显式打开，debug 下可静音
WAppOptions(title: 'Demo', home: const HomePage(), startupLog: true);
```

日志格式固定：`[WApp] plugin env 120ms ok`、`[WApp] started in 480ms（...）`、
`[WApp] first frame 60ms`。插件失败抛 `WAppPluginInitException`（带 `pluginName`）；
`start()` 失败后可以再次调用重试（已成功的插件不重复执行）。

### 系统栏兜底

`WAppTheme.systemUiOverlayStyle` 现在是**全局兜底**：页面自己的
`WScaffold.systemStatusBarStyle` / `WAppBarStyle.systemOverlayStyle` 优先；
页面没有标注时回落到这里。从浅色状态栏页面返回后会恢复，不会停留在浅色。

### widget 测试宿主

`app.buildRoot()` 用与运行时一致的装配（`GetMaterialApp` → `appWrapper` →
`WAppScope` / `WLanguageScope` → 系统栏兜底）构建根，不要求 `init()`，
测试只写业务：

```dart
// test/support/pump_app.dart（示例）
Future<void> pumpWApp(WidgetTester tester, Widget child) async {
  final app = WApp.options(appOptions.copyWith(home: child));
  await tester.pumpWidget(app.buildRoot());
  await tester.pump();
}
```

其中 `appOptions` 是项目里构造 `WAppOptions` 的同一个函数（含 `appWrapper` /
`builder` / `theme`），测试不会再漏 `ScreenUtilInit` / `WFormTheme`。
`setUp` 里建议 `Get.testMode = true; Get.reset();`。

### 在插件里注册服务

`onInit` 返回 `Future<void>`：直接用箭头写 `Get.putAsync(...)` 会让泛型 `S` 被推成
`void`，实例注册到 `void` 下，`Get.find<T>()` 找不到（服务其实在跑，analyzer 也不报）。
用 `registerService<T>` —— `T` 只由 factory 推断，箭头写法也安全：

```dart
class PbePlugin with WAppPlugin {
  @override
  String get name => 'pbe';

  @override
  Future<void> onInit() => registerService(() => PbeService().init());
}

// 之后：Get.find<PbeService>()
```

不想用 helper 就写块体 + 显式泛型：`await Get.putAsync<PbeService>(() => PbeService().init());`。

## 生命周期

```text
init()   可重复 / 并发调用；只执行一次插件 onInit
start()  = init() + run()，只调用一次
run()    通常由 start 调用；只能调用一次
```

初始化失败时 `isInitialized` 保持 false；再次调用 `init()` 会从失败点继续：已经成功的
插件不会重复执行，`customTasks` 会重新执行。插件列表在 `WAppOptions.plugins` 声明，
`init` 之后不再允许修改。

> `w_tools_app 3.2.0` 的 deprecated 入口已在 4.0.0 删除；本包 3.0.0 起迁移到
> `WApp.of` / `WLanguageScope`，3.1.0 把依赖下界收到 `w_tools_app ^4.0.0`。

## 语言

语言只通过 `WLocaleConfig` 声明：

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

app.language.changeLanguage('en_US');
app.language.languageChanges.listen((code) {
  // 更新 UI
});
```

`WAppOptions.supportedLocales` 只用于显式覆盖 Flutter 本地化列表，默认从
`localeConfig` 派生；当前语言不在列表内时 `run()` 抛 `StateError`。语言不会持久化，
要恢复上次选择，在 `start()` 之前调用 `app.language.changeLanguage(saved)`。

页面里用 `WLanguageScope.of(context)` 读取语言，用 `WApp.of(context)` 读取应用实例：

```dart
final language = WLanguageScope.of(context);
final app = WApp.of(context);
app.routeStack.routes;
```

## 包裹顺序

```text
WAppOptions.appWrapper（MaterialApp 外，没有 Theme / MediaQuery）
  → GetMaterialApp
    → WAppOptions.builder（MaterialApp 内，可用 Theme / MediaQuery）
      → 页面
```

插件不再提供 `builderWrapper` / `wrapApp`；需要 Theme 的全局中间件放 `builder`。

## 路由

```dart
// 页面里：WApp 自动维护 routeStack，不需要手动添加 WRouteObserver
final app = WApp.of(context);
app.routeStack.popUntilRoute('/home');
app.routeStack.routes;

final result = await WBottomSheet.show<String>(const MySheetContent());
```

完整示例见 [`example/`](example/) 的插件顺序、语言、路由栈与底部弹窗页面。

## 主要 API

| 能力 | 入口 |
|---|---|
| 应用启动 | `WApp` / `app.start()` |
| 插件契约 | `WAppPlugin` / `WAppPlugin.dependsOn` |
| 应用配置 | `WAppOptions` / `WLocaleConfig` |
| 页面内访问 | `WApp.of(context)` / `WLanguageScope.of(context)` |
| 应用外观 | `WAppTheme`（来自 `w_tools_app`） |
| 语言 | `app.language`（`WLanguage`，来自 `w_tools_app`） |
| 路由 | `app.routeStack` / `WRouteObserver` |
| 底部弹窗 | `WBottomSheet` |

## 完整示例

见 [`example/`](example/)：WApp 启动、插件依赖、GetX 路由、语言切换与底部弹窗。

## 历史迁移

从 2.x 升级先看 [`docs/migrations/app_getx-3.0.md`](https://github.com/stone0533/w_tools/blob/main/docs/migrations/app_getx-3.0.md)：
语言只留 `localeConfig`、插件只在 options 声明、包裹回到字段版。

## License

MIT
