> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

# app_getx 3.0 迁移

`w_tools_app_getx 3.0.0` 跟随 `w_tools_app 4.0.0` 收口：语言只留 `localeConfig`
一个入口，插件只负责初始化，包裹统一走 `WAppOptions`。

## 语言配置

`WAppOptions.locale` / `WAppOptions.fallbackLocale` 与 `WApp.start` / `WApp.run` 上的
`locale` / `fallbackLocale` 参数已删除。用 `WLocaleConfig` 声明支持列表、启动语言和
回退语言：

```dart
// before
WAppOptions(
  title: 'Demo',
  home: const HomePage(),
  locale: const Locale('zh', 'CN'),
  fallbackLocale: const Locale('en', 'US'),
  supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
);

// after
WAppOptions(
  title: 'Demo',
  home: const HomePage(),
  localeConfig: WLocaleConfig(
    supportedLanguages: {'zh_CN': '简体中文', 'en_US': 'English'},
    initialLanguage: 'zh_CN',
    fallbackLanguage: 'en_US',
  ),
);
```

- GetX 的 `fallbackLocale` 从 `WLocaleConfig.fallbackLanguage` 派生；
- `WAppOptions.supportedLocales` 仍可显式覆盖 Flutter 本地化列表，默认从
  `localeConfig` 派生；当前语言不在列表内时 `run()` 抛 `StateError`；
- 运行期切换仍用 `app.language.changeLanguage(...)`；恢复上次选择在 `start()` 之前调用
  同一个方法。

## 插件

| 旧 | 新 |
| --- | --- |
| `WApp.addPlugin` / `addPlugins` / `removePlugin` / `clearPlugins` | 只在 `WAppOptions.plugins` 声明 |
| `WAppPlugin.builderWrapper` | `WAppOptions.builder` |
| `WAppPlugin.wrapApp` | `WAppOptions.appWrapper` |
| `WAppPluginRunner.addPlugin` / `addPlugins` / `removePlugin` / `clearPlugins` | `WAppPluginRunner(plugins)` |

插件按 `dependsOn` 分层、同层按注册顺序串行；某个 `onInit` 抛错会中断本次 `init`，
重试时已成功的插件不重复执行。

## 页面内访问

`WApp.run()` 会自动插入 `WAppScope` 与 `WLanguageScope`；页面不再保存全局 `app`：

```dart
// before
late WApp app;
app.routeStack.popUntilRoute('/');

// after
final app = WApp.of(context);
app.routeStack.popUntilRoute('/');
```

- `WApp.of(context)` / `WApp.maybeOf(context)` 读取当前 `WApp`；
- `WLanguageScope.of(context)` 读取语言并跟随切换重建；
- 测试可手动包 `WAppScope(app: app, child: page)`。

## 外观

- `WAppTheme.systemUiOverlayStyle` 默认改为 `null`，需要时显式传入；
- `WAppTheme.copyWith` / `WLocaleConfig.copyWith` 删除，直接构造新实例。

## 语言 API 变化（来自 `w_tools_app` 4.0）

- `WLanguage.listenLanguageChange` 删除：用 `app.language.languageChanges.listen(...)`；
- `WLanguage.bindLocaleUpdater` 删除：`WApp` 已自动监听；
- `WLanguage.new` 删除：用 `WLanguage.fromConfig(WLocaleConfig?)`；
- `WLanguage.localeFromCode` 只接受三种语言码形态。
