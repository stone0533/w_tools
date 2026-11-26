# w_tools_app

`w_tools_app` 是 w_tools 的 **GetX-free 应用内核**，提供：

- `WAppPlugin`：插件契约（`name` / `dependsOn` / `onInit` / `onFirstFrame` /
  `timeout` / `critical` / `navigatorObservers`）；
- `WAppPluginRunner`：插件注册表、`dependsOn` 分层串行初始化、首帧钩子与运行记录；
- `WAppPluginRun` / `WAppPluginInitException`：插件耗时与带插件名的失败异常；
- `WLanguage` / `WLanguageScope` / `WLocaleConfig`：语言状态、树内注入与语言配置；
- `WAppTheme`：应用外观（亮/暗主题、主题模式、系统栏）。

```dart
class SplashPlugin extends WAppPlugin {
  @override
  String get name => 'native-splash';

  @override
  Future<void> onInit() async {
    FlutterNativeSplash.preserve(widgetsBinding: WidgetsBinding.instance);
  }

  @override
  Future<void> onFirstFrame() async {
    // 首帧后移除原生闪屏；不再依赖某个页面先被打开
    FlutterNativeSplash.remove();
  }
}

final runner = WAppPluginRunner([SplashPlugin()]);
await runner.init();
runner.firstFrame(); // 非 GetX 壳：首帧后自行调用
```

`WAppPluginRunner` 执行 `dependsOn` / `onInit` / `onFirstFrame`；所有 `onFirstFrame`
回调结束后会补排一帧（`onFirstFrame` 运行在 post-frame 阶段，直接调
`allowFirstFrame()` 不会自己排帧）。插件上的 `navigatorObservers` 由 GetX 启动器
`WApp` 消费。同层插件按注册顺序串行执行，
失败后重试会跳过已成功的插件；非关键插件失败不阻塞启动，再次 `init()` 只重试它。

插件失败默认会抛 `WAppPluginInitException`（带 `pluginName` 与原始 `cause`）。
可以用 `timeout` 限制单个插件的初始化时间（默认不限制），用 `critical: false`
让非关键插件失败时只记录、继续启动。

```dart
class AnalyticsPlugin extends WAppPlugin {
  @override
  String get name => 'analytics';

  @override
  Duration get timeout => const Duration(seconds: 10);

  @override
  bool get critical => false; // 埋点失败不影响启动

  @override
  Future<void> onInit() => Analytics.init();
}
```

需要完整的 `WApp` 启动器、GetX 路由与底部弹窗时，依赖：

```yaml
dependencies:
  w_tools_app_getx: ^3.2.0
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

需要“跟随系统”时用 `WLocaleConfig(followSystem: true)`（与 `initialLanguage` 互斥）：
启动语言由系统解析，应用壳把系统语言变化通过
`changeLanguage(code, userSelected: false)` 写回，用户显式切换后停止跟随；
系统语言不在支持列表内时回退 `fallbackLanguage`。

测试 teardown 直接 `language.dispose()`（释放变化流与监听）；dispose 后
`changeLanguage` 抛 `StateError`。

页面里用 `WLanguageScope.of(context)` 读取当前语言；语言切换时依赖者自动重建：

```dart
final language = WLanguageScope.of(context);
language.changeLanguage('en_US');
```

## 历史迁移

升级前先看 [`docs/migrations/`](https://github.com/stone0533/w_tools/blob/main/docs/migrations/README.md)：
每个包的 breaking 变更都有「旧 → 新」对照，不只是变更清单。
