# map 使用规则（给人和 AI）

## 什么时候用

Google Maps 展示、marker 选中 / 关闭、自定义 marker 图标。

## 最小用法

```dart
WMap<Store>(
  zone: WMapZone<Store>(
    maps: stores,
    initialCamera: const CameraPosition(target: LatLng(31.2, 121.5), zoom: 11),
    mapper: WMapItemMapper<Store>(
      id: (s) => s.id,
      name: (s) => s.name,
      position: (s) => (latitude: s.lat, longitude: s.lng),
    ),
  ),
  config: WMapConfig<Store>(onItemSelected: (s) => ..., onItemClosed: ...),
);
```

> `LatLng` / `CameraPosition` 需要 `import 'package:google_maps_flutter/google_maps_flutter.dart';`

## 不要用

- 直接 `GoogleMap`（用 `WMap`）；
- `hashCode` 生成 `markerId`（必须稳定）；
- 手动往 `zone.markers` 塞自定义 Marker（`update()` 会清掉，用 `iconBuilder` / `iconAsset`）。

## 常见坑

- Android / iOS 都要配 Google Maps API Key；
- `json_serializable` 模型不要改生成代码，用 `WMapItemMapper` 取字段；
- 业务 UI 选中 / 关闭统一走 `WMapController.select` / `closeSelection`。

完整说明：[map_module.md](../modules/map_module.md) · 示例：`packages/map/example`
