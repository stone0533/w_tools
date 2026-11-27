# w_tools_map_google

`w_tools_map` 的 Google Maps 实现，提供 `WMap` / `WMapZone` / `WMapOptions`。

```bash
flutter pub add w_tools_map w_tools_map_google
```

```dart
import 'package:w_tools_map/w_tools_map.dart';
import 'package:w_tools_map_google/w_tools_map_google.dart';
```

## 最小用法

```dart
final zone = WMapZone<Shop>(
  maps: shops,
  mapper: WMapItemMapper<Shop>(
    id: (s) => s.id,
    name: (s) => s.name,
    position: (s) => (latitude: s.lat, longitude: s.lng),
  ),
);

WMap<Shop>(
  zone: zone,
  config: WMapOptions<Shop>(
    onItemSelected: (shop) {},
    onItemClosed: (shop) {},
  ),
);
```

`zone` / `WMapOptions` 建在 State 字段或页面级单例，不要每次 build 新建；
从业务侧关闭选中用 `WMapController.closeSelection(item)`。完整示例见 [`example/`](example/)。

需要 Google Maps API Key；Android/iOS 原生配置见 `example/`。

## 历史迁移

升级前先看 [`docs/migrations/`](https://github.com/stone0533/w_tools/blob/main/docs/migrations/README.md)：
每个包的 breaking 变更都有「旧 → 新」对照，不只是变更清单。
