# w_tools_map

[![pub package](https://img.shields.io/pub/v/w_tools_map.svg)](https://pub.dev/packages/w_tools_map)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

`w_tools_map` 是 w_tools 的地图组件层，基于 `google_maps_flutter` 提供通用地图视图与数据区域管理。

## 特性

- `WMapItem`：业务数据模型只需实现 id / 名称 / 经纬度
- `WMapZone`：持有控制器、Marker 集合与数据列表，支持跨组件共享
- `WMapConfig`：配置选中 / 关闭时的缩放与纬度偏移、事件回调
- 选中与关闭时自动平滑移动相机并打开 Marker InfoWindow
- 不内置业务 UI，列表、卡片等由业务方自行构建

## 安装

```yaml
dependencies:
  w_tools_map: ^1.0.0
```

请按 `google_maps_flutter` 文档配置 Android / iOS 的 Google Maps API Key。

> 本包最低要求 Flutter 3.27.0。

## 快速开始

```dart
import 'package:flutter/material.dart';
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

class MapPage extends StatelessWidget {
  MapPage({super.key});

  final zone = WMapZone<Shop>(
    maps: [Shop(id: '1', name: '门店 A', latitude: 31.23, longitude: 121.47)],
  );

  @override
  Widget build(BuildContext context) {
    return WMap<Shop>(
      config: const WMapConfig<Shop>(),
      zone: zone,
    );
  }
}
```

## 主要 API

| 能力 | 入口 |
|---|---|
| 数据模型 | `WMapItem` |
| 地图区域 | `WMapZone` / `initMap` / `update` |
| 地图组件 | `WMap` |
| 配置 | `WMapConfig` / `onItemSelected` / `onItemClosed` |

## License

MIT
