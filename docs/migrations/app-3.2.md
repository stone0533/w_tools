> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

# app 3.2 迁移

`w_tools_app 3.2.0` 只做弃用与一个新增能力，**不删除 API、不改变默认行为**。

## 新增：WLanguageScope

页面不再需要保存全局语言实例：

```dart
final language = WLanguageScope.of(context);
language.changeLanguage('en_US');
```

`WLanguageScope` 是 `InheritedNotifier<ValueListenable<String>>`；语言切换时依赖者重建。
`WApp` 在 3.2.0 还不会自动插入 scope，需要手动包在 `appWrapper` 或测试里。

## 弃用（4.0.0 删除）

| 旧 | 新 |
| --- | --- |
| `WAppPlugin.builderWrapper` | `WAppOptions.builder` |
| `WAppPlugin.wrapApp` | `WAppOptions.appWrapper` |
| `WAppPluginRunner.addPlugin` / `addPlugins` / `removePlugin` / `clearPlugins` | `WAppPluginRunner(plugins)` |
| `WLanguage` 5 参构造 | `WLanguage.fromConfig` |
| `WLanguage.listenLanguageChange` | `languageChanges.listen` |
| `WLanguage.bindLocaleUpdater` | `languageListenable` |
| `WLocaleConfig.copyWith` / `WAppTheme.copyWith` | 直接构造 |

这些入口在 3.2.0 仍然可用，只带 `@Deprecated` 注解；4.0.0 删除。

## 修复

`WAppPluginRunner.init` 失败后重试会跳过已成功的插件，避免重复执行 `onInit` 副作用。
