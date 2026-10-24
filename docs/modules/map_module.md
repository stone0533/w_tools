# Map 模块文档

## 概述

Map 模块（`w_tools_map` 子包）基于 `google_maps_flutter` 封装，提供通用地图组件 `WMap`。组件职责仅限：渲染地图与 Marker、管理相机动画（选中/关闭时的平滑移动）、暴露 `GoogleMapController` 供外部控制。

**不内置任何业务 UI**（列表面板、选中浮起、空状态等）。业务方通过 `WMapConfig.onItemSelected` / `WMapConfig.onItemClosed` 接收事件后自行构建业务 UI。

依赖：`google_maps_flutter`。

## 模块结构

```
map/
└── src/map.dart        # WMap / WMapConfig / WMapZone / WMapItem
```

---

## 1. WMapItem - 条目抽象基类

### 功能说明

业务数据模型实现此接口，提供地图渲染所需的必需字段。其他业务字段（营业时间、地址、标签等）由子类自行持有。

### 抽象字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | `String?` | 唯一标识，用于生成 `MarkerId` 及选中态一致性校验 |
| `name` | `String?` | 名称，用于 Marker 的 `InfoWindow` 标题 |
| `latitude` | `double?` | 纬度 |
| `longitude` | `double?` | 经度 |

### 使用示例

```dart
class StoreItem implements WMapItem {
  final String? mapZoneId;
  final String? name;
  final double? latitude;
  final double? longitude;
  final String? business;
  final String? address;

  const StoreItem({
    this.mapZoneId,
    this.name,
    this.latitude,
    this.longitude,
    this.business,
    this.address,
  });

  @override
  String? get id => mapZoneId;
  @override
  String? get name => this.name;
  @override
  double? get latitude => this.latitude;
  @override
  double? get longitude => this.longitude;
}
```

---

## 2. WMapZone - 地图区域类

### 功能说明

持有 `GoogleMapController`、`markers` 集合、地图数据列表 `maps`，支持外部复用、跨组件共享控制器状态及通过 `update` 刷新数据。

泛型 `T` 约束为 `WMapItem`。

### 核心字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `googleMapController` | `GoogleMapController?` | Google 地图控制器（由 `WMap` 在 onMapCreated 时写入） |
| `zoneId` | `String?` | 区域 ID |
| `name` | `String?` | 区域名称 |
| `markers` | `Set<Marker>` | Marker 集合 |
| `maps` | `List<T>?` | 地图数据列表 |
| `cameraPosition` | `CameraPosition?` | 初始相机位置（`maps` 为空时为 null） |
| `icon` | `BitmapDescriptor?` | Marker 图标（为 null 时使用默认图标） |
| `defaultZoom` | `double` | 默认缩放级别，默认 `11` |
| `onDataUpdated` | `void Function()?` | 数据更新回调（由 `WMap` 内部注册，用于刷新选中态一致性） |

### 核心方法

| 方法 | 说明 |
|------|------|
| `WMapZone({...})` | 构造函数，自动调用 `initMap()` |
| `initMap()` | 依据 `maps` 生成 `markers`，首个条目作为初始相机位置（`maps` 为空时 `cameraPosition = null`） |
| `update(maps)` | 更新数据并重新初始化 |
| `addMarkerTapListener(listener)` | 注册 Marker 点击回调（支持多个 `WMap` 共享同一 zone） |
| `removeMarkerTapListener(listener)` | 移除 Marker 点击回调 |

### 使用示例

```dart
final zone = WMapZone<StoreItem>(
  zoneId: 'zone_1',
  name: '香港',
  maps: storeList,
  icon: customIcon,
);

// 数据刷新
zone.update(newStoreList);
```

---

## 3. WMap - 地图组件

### 功能说明

基于 `GoogleMap` 封装的通用地图组件。交互行为：

- 点击 Marker → 选中该条目 + 地图居中（纬度上移 `selectLatOffset` 以露出底部内容）+ 打开 InfoWindow
- 选中/关闭时通过 `WMapConfig` 回调通知业务方，由业务方构建 UI
- 数据更新后若选中条目已不在 `maps` 中，自动清除选中态

### 构造参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `config` | `WMapConfig<T>` | 组件配置 |
| `zone` | `WMapZone<T>` | 地图区域 |

### 公开方法

| 方法 | 说明 |
|------|------|
| `closeSelection(item)` | 关闭选中（由业务方调用）：清除选中 + 复位相机到 `closeZoom` + 触发 `onItemClosed` |

### 使用示例

```dart
WMap<StoreItem>(
  config: mapConfig,
  zone: zone,
);
```

---

## 4. WMapConfig - 配置类

### 功能说明

配置 `WMap` 的相机行为与事件回调，不包含任何 UI 样式配置。泛型 `<T extends WMapItem>` 保证回调类型安全。

### 配置字段

| 字段 | 默认值 | 说明 |
|------|--------|------|
| `selectZoom` | `12` | 选中条目时的缩放级别 |
| `closeZoom` | `11` | 关闭选中条目时的缩放级别 |
| `selectLatOffset` | `0.0` | 选中条目时的纬度偏移（向上偏移；0 表示 Marker 居中） |
| `onItemSelected` | `null` | 选中条目回调 `ValueChanged<T>?` |
| `onItemClosed` | `null` | 关闭选中条目回调 `ValueChanged<T>?` |

### 构建方法

| 方法 | 说明 |
|------|------|
| `build({required WMapZone<T> zone})` | 构建 `WMap` 组件 |

### 使用示例

```dart
final mapConfig = WMapConfig<StoreItem>(
  selectZoom: 12,
  closeZoom: 11,
  selectLatOffset: 0.03,
  onItemSelected: (item) => print('选中: ${item.name}'),
  onItemClosed: (item) => print('关闭: ${item.name}'),
);
```

---

## 完整使用示例

```dart
import 'package:w_tools/w_tools.dart';

/// 1. 业务数据模型（见 WMapItem 示例）

/// 2. 构建配置
final mapConfig = WMapConfig<StoreItem>(
  onItemSelected: (item) {
    // 业务方自行展示列表面板 / 选中浮起等 UI
  },
  onItemClosed: (item) {
    // 关闭业务 UI
  },
);

/// 3. 构建区域
final zone = WMapZone<StoreItem>(
  zoneId: 'zone_1',
  name: '香港',
  maps: stores,
);

/// 4. 使用组件
WMap<StoreItem>(config: mapConfig, zone: zone);
```

---

## 交互流程

```
点击地图 Marker
        │
        ▼
  选中该条目（_selected = item）
        │
        ▼
  地图居中（lat - selectLatOffset, zoom = selectZoom）+ 打开 InfoWindow
        │
        ▼
  触发 onItemSelected，业务方构建 UI

业务方调用 closeSelection(item)
        │
        ▼
  清除选中 + 复位相机（原纬度, zoom = closeZoom）+ 触发 onItemClosed
```

---

## 注意事项

- `WMapZone` 可在外部创建并复用；调用 `update(maps)` 可刷新数据并重建 markers。
- `WMap` 在 `initState` 注册 `zone` 的 Marker 点击回调，在 `dispose` 时移除。
- 选中态一致性：数据更新后若选中条目不在当前 `maps` 列表，会自动清除选中。
- Marker 图标默认使用 `BitmapDescriptor.defaultMarker`；`icon` 为 null 时生效。
- `latitude`/`longitude` 为 `double?`，为 null 时兜底为 `0.0`。

---

## 相关文档

- [w_tools_ui — WListView / WScaffold](ui_module.md)：地图页面的布局容器通常来自 ui 子包。
- [w_tools_core — WPlatform](core_module.md)：地图功能依赖原生平台（Android / iOS），Web / 桌面端不支持。

---

相关文档：[模块索引](README.md) · [组件目录](components.md) · [接入约定](../conventions.md)
