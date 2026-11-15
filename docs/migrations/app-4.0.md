> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

# app 4.0 迁移

`w_tools_app 4.0.0` 做减法：插件只保留生命周期，渲染包裹回到 `WAppOptions` 的两个字段；
语言与外观配置不再提供 `copyWith`。

## 插件钩子

插件不再能包裹应用 Widget：

| 旧 | 新 |
| --- | --- |
| `WAppPlugin.builderWrapper` | `WAppOptions.builder` |
| `WAppPlugin.wrapApp` | `WAppOptions.appWrapper` |

```dart
// before
class ThemePlugin with WAppPlugin {
  @override
  String get name => 'theme';

  @override
  TransitionBuilder get builderWrapper => (context, child) {
    return Theme(data: ..., child: child ?? const SizedBox.shrink());
  };
}

// after
WAppOptions(
  builder: (context, child) {
    return Theme(data: ..., child: child ?? const SizedBox.shrink());
  },
);
```

插件仍保留 `name` / `dependsOn` / `onInit` / `navigatorObservers`；`navigatorObservers`
只由 `WApp` 消费。

## 插件注册

| 旧 | 新 |
| --- | --- |
| `WAppPluginRunner.addPlugin` / `addPlugins` / `removePlugin` / `clearPlugins` | 构造 `WAppPluginRunner(plugins)` 时传完整列表 |

`init()` 之后不再允许增删插件；需要在启动前决定插件列表的，先组装列表再构造 runner。

## 插件执行顺序

- 同层插件从“并行”改为“按注册顺序串行”；
- 某个 `onInit` 抛错会立即中断本次 `init`，同层后续插件不再执行；
- 失败后重试会跳过已成功的插件，从失败点继续。

## 语言

`WLanguage` 只保留 `fromConfig` 构造：

```dart
// before
final language = WLanguage(
  supportedLanguages: {'zh_CN': '简体中文'},
  currentLanguage: 'zh_CN',
  initialLanguage: 'zh_CN',
  fallbackLanguage: 'en_US',
);

// after
final language = WLanguage.fromConfig(
  WLocaleConfig(
    supportedLanguages: {'zh_CN': '简体中文', 'en_US': 'English'},
    initialLanguage: 'zh_CN',
    fallbackLanguage: 'en_US',
  ),
);
```

- `WLanguage.listenLanguageChange` 删除：用 `language.languageChanges.listen(...)`。
- `WLanguage.bindLocaleUpdater` 删除：GetX 启动器自己监听 `languageListenable`。
- `supportedLanguages` 不能为空，且语言码只接受 `lang` / `lang_COUNTRY` /
  `lang_Script_COUNTRY`；`en_US_POSIX` 这类字符串会抛 `ArgumentError`。

## 页面内访问

`WApp.run()` 会自动插入 `WLanguageScope`（`w_tools_app`）与 `WAppScope`
（`w_tools_app_getx`）。页面不再需要保存全局 `WLanguage` / `app`：

```dart
// before
late WLanguage language;
language = app.language;

// after
final language = WLanguageScope.of(context);
language.changeLanguage('en_US');
```

- `WLanguageScope.of(context)` 读取语言，并在切换时重建依赖者；
- `WApp.of(context)` 读取应用实例（路由栈等）；
- 两者都有 `maybeOf`；`of` 找不到 scope 时抛 `FlutterError`；
- 测试可手动包 `WLanguageScope` / `WAppScope`，不必启动完整应用。

## 外观

- `WAppTheme.copyWith` / `WLocaleConfig.copyWith` 删除：直接构造新实例。
- `WAppTheme.systemUiOverlayStyle` 默认改为 `null`：不再默认设置透明状态栏 + 黑色导航栏。
  需要固定系统栏时显式传入：

```dart
WAppTheme(
  systemUiOverlayStyle: const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.black,
  ),
);
```
