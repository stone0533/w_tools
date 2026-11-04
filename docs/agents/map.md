# map 使用规则（给人和 AI）

## 什么时候用

Google Maps 展示、marker 选中 / 关闭、自定义 marker 图标。

## 最小用法

```dart
// zone / controller 必须建在 State 字段或页面级单例，不要每次 build new
final zone = WMapZone<Store>(
    maps: stores,
    initialCamera: const CameraPosition(target: LatLng(31.2, 121.5), zoom: 11),
    mapper: WMapItemMapper<Store>(
      id: (s) => s.id,
      name: (s) => s.name,
      position: (s) => (latitude: s.lat, longitude: s.lng),
    ),
);

WMap<Store>(
  zone: zone,
  config: WMapConfig<Store>(
    onItemSelected: (s) {},
    onItemClosed: (s) {},
  ),
);
```

> `WMap` / `WMapZone` / Google 类型由 `package:w_tools_map_google/w_tools_map_google.dart` 提供；数据模型用 `package:w_tools_map/w_tools_map.dart`；
> 使用其它 google_maps 类型时再直接依赖 google_maps_flutter。
> `initialCamera` 只在**没有可渲染条目**时生效；有数据时默认取首个条目 + `defaultZoom`。
> `update()` 会重建 marker 但不会抢走当前相机（选中后下拉刷新不会跳回第一个）。

## 不要用

- 直接 `GoogleMap`（用 `WMap`）；
- `hashCode` 生成 `markerId`（必须稳定）；
- 手动往 `zone.markers` 塞自定义 Marker（`update()` 会清掉，用 `iconBuilder` / `iconAsset`）。

## 常见坑

- Android / iOS 都要配 Google Maps API Key；
- `json_serializable` 模型不要改生成代码，用 `WMapItemMapper` 取字段；
- 业务 UI 选中 / 关闭统一走 `WMapController.select` / `closeSelection`；`closeSelection` 会隐藏 InfoWindow。
- 直接构造 `WMap(config:, zone:)`；`WMapConfig.build()` 已在 5.0 删除。

完整说明：[map_module.md](../modules/map_module.md) · 示例：`packages/map_google/example`
