# app 3.0 迁移

## 拆分

```text
w_tools_app        # WAppPlugin 契约（GetX 无关）
w_tools_app_getx   # WApp / GetX 路由 / 语言 / 底部弹窗
```

迁移：

```dart
// before
import 'package:w_tools_app/w_tools_app.dart';

// after（使用 WApp）
import 'package:w_tools_app_getx/w_tools_app_getx.dart';
```

只用插件接口时继续 import `package:w_tools_app/w_tools_app.dart`。
