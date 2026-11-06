# w_tools_map

[![pub package](https://img.shields.io/pub/v/w_tools_map.svg)](https://pub.dev/packages/w_tools_map)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

`w_tools_map` 是 w_tools 的**地图接口层**，只包含平台无关的模型：

- `WMapItem`：业务模型实现 id / 名称 / 经纬度；
- `WMapItemMapper<T>`：为 `json_serializable` 等生成模型提供字段映射。

它**不依赖** `google_maps_flutter`，也不包含 `WMap` 组件。

Google Maps 实现：

```text
w_tools_map_google → WMap / WMapZone / WMapConfig / Google 类型
```

## 安装

只使用模型：

```yaml
dependencies:
  w_tools_map: ^3.0.0
```

需要地图组件时：

```yaml
dependencies:
  w_tools_map: ^3.0.0
  w_tools_map_google: ^1.0.0
```

## 使用模型

```dart
import 'package:w_tools_map/w_tools_map.dart';

class Shop implements WMapItem {
  Shop({this.id, this.name, this.latitude, this.longitude});

  @override
  final String? id;

  @override
  final String? name;

  @override
  final double? latitude;

  @override
  final double? longitude;
}
```

生成模型不实现 `WMapItem` 时：

```dart
final mapper = WMapItemMapper<ShopDto>(
  id: (m) => m.id,
  name: (m) => m.name,
  position: (m) => (latitude: m.lat, longitude: m.lng),
);
```

## 完整地图

见 [`w_tools_map_google`](../map_google/README.md) 与 [`map_google/example`](../map_google/example/)。

## 历史迁移

升级前先看 [`docs/migrations/`](https://github.com/stone0533/w_tools/blob/main/docs/migrations/README.md)：
每个包的 breaking 变更都有「旧 → 新」对照，不只是变更清单。

## License

MIT
