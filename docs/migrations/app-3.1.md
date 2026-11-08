> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

# app 3.1 迁移

`w_tools_app 3.1.0` 新增 GetX-free 应用内核类型：

| 类型 | 说明 |
| --- | --- |
| `WAppPluginRunner` | 插件注册表与 `dependsOn` 分层初始化 |
| `WLanguage` / `WLocaleConfig` | 语言状态与语言配置 |
| `WAppTheme` | 亮/暗主题、主题模式、系统栏 |

这些类型直接从 `package:w_tools_app/w_tools_app.dart` 引用。
`w_tools_app_getx` 的 GetX 启动层会在后续版本复用它们。
