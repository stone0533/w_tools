# map 3.0 迁移

## 拆分

```text
w_tools_map          # 平台无关模型 / WMapItemMapper
w_tools_map_google   # WMap / WMapZone / Google 类型
```

迁移：

```dart
import 'package:w_tools_map/w_tools_map.dart';
import 'package:w_tools_map_google/w_tools_map_google.dart';
```

旧 `package:w_tools_map/w_tools_map.dart` 不再提供 `WMap` / `WMapZone`。
