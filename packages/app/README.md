# w_tools_app

`w_tools_app` 是 w_tools 的 **GetX-free 应用内核**，提供：

- `WAppPlugin`：插件契约（`name` / `dependsOn` / `onInit` / `navigatorObservers`）；
- `WAppPluginRunner`：插件注册表、`dependsOn` 分层串行初始化；
- `WLanguage` / `WLanguageScope` / `WLocaleConfig`：语言状态、树内注入与语言配置；
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

`WAppPluginRunner` 只执行 `dependsOn` / `onInit`；插件上的 `navigatorObservers`
由 GetX 启动器 `WApp` 消费。同层插件按注册顺序串行执行，失败后重试会跳过已成功的插件。

需要完整的 `WApp` 启动器、GetX 路由与底部弹窗时，依赖：

```yaml
dependencies:
  w_tools_app_getx: ^3.1.0
```

语言与外观类型也可以直接引用：

```dart
final language = WLanguage.fromConfig(
  WLocaleConfig(
    supportedLanguages: const {'zh_CN': '简体中文', 'en_US': 'English'},
    initialLanguage: 'zh_CN',
    fallbackLanguage: 'en_US',
  ),
);
language.changeLanguage('en_US');
```

`WLanguage` 不持久化选择；恢复上次语言时，在 `start()` 之前调用
`changeLanguage(saved)`（不在支持列表内会返回 `false`）。

页面里用 `WLanguageScope.of(context)` 读取当前语言；语言切换时依赖者自动重建：

```dart
final language = WLanguageScope.of(context);
language.changeLanguage('en_US');
```

## 历史迁移

升级前先看 [`docs/migrations/`](https://github.com/stone0533/w_tools/blob/main/docs/migrations/README.md)：
每个包的 breaking 变更都有「旧 → 新」对照，不只是变更清单。
