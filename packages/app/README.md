# w_tools_app

[![pub package](https://img.shields.io/pub/v/w_tools_app.svg)](https://pub.dev/packages/w_tools_app)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

`w_tools_app` 是 w_tools 的应用启动层，提供 `WApp` 启动器、插件依赖编排、GetX 路由与语言切换、底部弹窗与路由观察者。

> **注意：本包强依赖 GetX。** 使用 `WApp` 即意味着你的项目需要使用 GetX。

## 特性

- **一站式启动**：`WApp.start()` = `init()` + `run()`
- **插件体系**：`WAppPlugin` 支持 `dependsOn` 分层初始化（同层并行、跨层串行）
- **路由工具**：`WRouteStack` / `WRouteObserver` 记录与操作 GetX 路由
- **语言切换**：`WLanguage` 统一管理当前语言与支持语言
- **底部弹窗**：`WBottomSheet.show()`
- **全局配置**：`WAppConfig`

## 安装

```yaml
dependencies:
  w_tools_app: ^2.0.0
```

> 本包最低要求 Flutter 3.38.0。

## 快速开始

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:w_tools_app/w_tools_app.dart';

Future<void> main() async {
  final app = WApp.options(
    WAppOptions(
      title: 'Demo',
      initialRoute: '/',
      getPages: [GetPage(name: '/', page: () => const HomePage())],
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

final app = WApp.options(const WAppOptions(title: 'Demo'))..addPlugin(AnalyticsPlugin());
```

## 生命周期

```text
init()   可重复 / 并发调用；只执行一次插件 onInit
start()  = init() + run()，只调用一次
run()    通常由 start 调用；重复调用会再次 runApp
```

初始化失败时 `isInitialized` 保持 false；再次调用 `init()` 会重新执行插件 `onInit`。

## 语言与路由

```dart
WAppConfig.supportedLanguages = {
  'zh_CN': '简体中文',
  'en_US': 'English',
};

WLanguage().changeLanguage('zh_CN');
WLanguage().languageStream.listen((code) {
  // 更新 UI
});
```

```dart
// WApp 运行后，WRouteObserver 会维护 WRouteStack.defaultStack
WRouteStack.defaultStack.popUntilRoute('/home');
```

## 主要 API

| 能力 | 入口 |
|---|---|
| 应用启动 | `WApp` / `WApp.start()` |
| 插件契约 | `WAppPlugin` / `WAppPlugin.dependsOn` |
| 配置 | `WAppConfig` |
| 路由 | `WRouteStack` / `WRouteObserver` |
| 语言 | `WLanguage` |
| 底部弹窗 | `WBottomSheet` |

## 完整示例

见 [`example/`](example/)：WApp 启动、插件依赖、GetX 路由、语言切换与底部弹窗。

## License

MIT
