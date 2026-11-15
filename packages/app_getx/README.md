# w_tools_app_getx

[![pub package](https://img.shields.io/pub/v/w_tools_app_getx.svg)](https://pub.dev/packages/w_tools_app_getx)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

`w_tools_app_getx` 是 w_tools 的 GetX 应用启动层，提供 `WApp` 启动器、插件依赖编排、GetX 路由与语言切换、底部弹窗与路由观察者。

> **注意：本包强依赖 GetX。** 使用 `WApp` 即意味着你的项目需要使用 GetX。

## 特性

- **一站式启动**：`app.start()` = `init()` + `run()`；入口是 `WApp.options(...)`
- **插件体系**：`WAppPlugin` 支持 `dependsOn` 分层初始化（同层按注册顺序串行）
- **实例级状态**：`app.language` / `app.routeStack`，没有全局单例
- **语言切换**：`WLanguage` + `WLocaleConfig`（来自 `w_tools_app`）
- **路由工具**：`WRouteStack` / `WRouteObserver` 记录与操作 GetX 路由
- **底部弹窗**：`WBottomSheet.show()`

## 安装

```yaml
dependencies:
  w_tools_app_getx: ^3.0.0
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
