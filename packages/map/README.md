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
  w_tools_map: ^1.1.0
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
| 配置 | `WMapConfig` / `onItemSelected` / `onItemClosed` / `onMapTap` |
| 业务侧控制地图 | `WMapController`（目前提供 `closeSelection`） |
| 多地图共享数据 | `WMapZone.addDataUpdatedListener` / `removeDataUpdatedListener` |

## 模型不实现 WMapItem（推荐用于生成模型）

`json_serializable` 生成的模型不方便手改，可以直接用 `WMapItemMapper`：

```dart
final zone = WMapZone<MapListResultDataMaps>(
  maps: maps,
  mapper: WMapItemMapper<MapListResultDataMaps>(
    // MarkerId 必须稳定
    id: (m) => m.map_id ?? m.name ?? '',
    name: (m) => m.name,
    // record，不用 import google_maps_flutter
    position: (m) => (
      latitude: double.tryParse(m.latitude ?? '') ?? 0,
      longitude: double.tryParse(m.longitude ?? '') ?? 0,
    ),
  ),
);
```

不传 `mapper` 时，`T` 必须 `implements WMapItem`（原来的用法不变）。

## 用资产做 Marker 图标

```dart
WMapZone<Shop>(
  maps: shops,
  iconAsset: 'assets/images/map_address_icon.png',
  imagePixelRatio: 2.5,
);
```

包内部 `rootBundle.load` + 缓存，同一路径只解码一次；资产缺失时自动降级为默认图标。
这样业务层不需要 `BitmapDescriptor`，也不需要 `google_maps_flutter`。

## 每个条目不同图标

```dart
final zone = WMapZone<Shop>(
  maps: shops,
  iconBuilder: (shop) => shop.isFlagship
      ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
      : BitmapDescriptor.defaultMarker,
);
```

> Google Maps 对图片图标有缓存，`BitmapDescriptor.fromAssetImage` 的结果请复用同一实例，
> 不要每次构建都重新创建。

## 地图内边距（避免 marker 被卡片挡住）

```dart
WMap<Shop>(
  zone: zone,
  config: const WMapConfig<Shop>(
    // 底部选中卡片 140 高
    padding: EdgeInsets.only(bottom: 140, top: 60),
  ),
);
```

`padding` 改变的是"可视区域中心"，选中动画会按调整后的中心计算。

## 关闭选中 / 点击地图空白

```dart
final mapController = WMapController<Shop>();

WMap<Shop>(
  controller: mapController,
  zone: zone,
  config: WMapConfig<Shop>(
    onItemSelected: (item) => setState(() => selected = item),
    onItemClosed: (_) => setState(() => selected = null),
    // 点地图空白处，常用于"点空白关闭选中"
    onMapTap: (position) {
      if (selected != null) mapController.closeSelection(selected!);
    },
  ),
);
```

> `closeSelection` 必须通过 `WMapController` 调用：它定义在组件内部状态里，
> 之前外部拿不到实例，导致 `onItemClosed` 无法触发。

## 数据异步加载

`initialCameraPosition` 只在首帧使用。若首次渲染时 `maps` 为空，
拿到数据后调用 `zone.update(maps)`，包内会自动把相机移到新的 `cameraPosition`：

```dart
// 先渲染空地图
final zone = WMapZone<Shop>(maps: const []);
// 接口回来
zone.update(shops);
```

多个 `WMap` 共享同一个 zone 时，用 `addDataUpdatedListener` 注册，而不是旧的
`onDataUpdated` 字段（后者会被后注册的回调覆盖，已标记 deprecated）。

## 示例

完整可运行示例见 [`example/`](example/)，包含：3 个门店 Marker、点击选中 / 关闭、
相机动画、底部卡片的内边距处理。

```bash
cd example
flutter pub get
flutter run   # 需先按 google_maps_flutter 文档配置 API Key
```

## License

MIT
