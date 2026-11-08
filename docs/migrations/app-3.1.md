> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

# app 3.1 迁移

`w_tools_app 3.1.0` 把 GetX-free 的应用内核类型从 `w_tools_app_getx` 上移：

| 旧位置 | 新位置 |
| --- | --- |
| `package:w_tools_app_getx/...` 中的 `WLanguage` / `WLocaleConfig` / `WAppTheme` | `package:w_tools_app/w_tools_app.dart` |
| 插件分层初始化（`WApp` 内部） | `WAppPluginRunner` |

`w_tools_app_getx` 仍 re-export 这些类型，已有 import 不需要改。

```dart
// 只使用内核能力时：
import 'package:w_tools_app/w_tools_app.dart';

final runner = WAppPluginRunner([EnvPlugin()]);
await runner.init();
```
