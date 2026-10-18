# w_tools_app

[![pub package](https://img.shields.io/pub/v/w_tools_app.svg)](https://pub.dev/packages/w_tools_app)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

`w_tools_app` 是 w_tools 的应用启动层，提供 `WApp` 启动器、插件依赖编排、GetX 路由与语言切换、底部弹窗与路由观察者。

> **注意：本包强依赖 GetX。** 使用 `WApp` 即意味着你的项目需要使用 GetX。

## 特性

- **一站式启动**：`WApp.start()` = `init()` + `run()`
- **插件体系**：`WAppPlugin` 支持 `dependsOn` 分层初始化（同层并行、跨层串行）
- **路由工具**：`WRoute` / `WRouteObserver` 记录与操作 GetX 路由
- **语言切换**：`WLanguage` 统一管理当前语言与支持语言
- **底部弹窗**：`WBottomSheet.show()`
- **全局配置**：`WAppConfig`

## 安装

```yaml
dependencies:
  w_tools_app: ^1.0.0
```

> 本包最低要求 Flutter 3.27.0。

## 快速开始

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:w_tools_app/w_tools_app.dart';

Future<void> main() async {
  final app = WApp()
    ..title = 'Demo'
    ..initialRoute = '/'
    ..getPages = [
      GetPage(name: '/', page: () => const HomePage()),
    ];

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

final app = WApp()..addPlugin(AnalyticsPlugin());
```

## 主要 API

| 能力 | 入口 |
|---|---|
| 应用启动 | `WApp` / `WApp.start()` |
| 插件契约 | `WAppPlugin` / `WAppPlugin.dependsOn` |
| 配置 | `WAppConfig` |
| 路由 | `WRoute` / `WRouteObserver` |
| 语言 | `WLanguage` |
| 底部弹窗 | `WBottomSheet` |

## License

MIT
