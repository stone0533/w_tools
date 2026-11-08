# w_tools_app

`w_tools_app` 是 w_tools 的 **GetX-free 应用内核**，提供：

- `WAppPlugin`：插件契约；
- `WAppPluginRunner`：插件注册表、`dependsOn` 分层初始化；
- `WLanguage` / `WLocaleConfig`：语言状态与语言配置；
- `WAppTheme`：应用外观（亮/暗主题、主题模式、系统栏）。

```dart
class AppServicePlugin extends WAppPlugin {
  @override
  String get name => 'app-service';

  @override
  Future<void> onInit() async {
    // 初始化
  }
}

final runner = WAppPluginRunner([AppServicePlugin()]);
await runner.init();
```

需要完整的 `WApp` 启动器、GetX 路由与底部弹窗时，依赖：

```yaml
dependencies:
  w_tools_app_getx: ^2.0.0
```

`w_tools_app_getx` 会 re-export 本包的 `WAppPlugin` / `WAppPluginRunner` /
`WLanguage` / `WLocaleConfig` / `WAppTheme`，import 路径不变。

## 历史迁移

升级前先看 [`docs/migrations/`](https://github.com/stone0533/w_tools/blob/main/docs/migrations/README.md)：
每个包的 breaking 变更都有「旧 → 新」对照，不只是变更清单。
