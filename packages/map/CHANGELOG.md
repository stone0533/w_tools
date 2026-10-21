# Changelog

## 1.1.0

### Added
- `WMapZone.iconAsset` + `imagePixelRatio`：直接给资产路径，包内部 `rootBundle` 加载并缓存
  （同一路径只解码一次），业务层不必 import google_maps_flutter、也不会重复创建 BitmapDescriptor。
  优先级：`iconBuilder` > `icon` > `iconAsset` > 默认图标。
- `WMapItemMapper.position` 改为返回 record `({double latitude, double longitude})`，
  业务层不接触 `LatLng`。
- `WMap` 收到数据更新时 `setState`，保证异步图标加载完成后地图会重绘。
- `WMapConfig.padding`：透传 `GoogleMap.padding`，底部有选中卡片/顶部有筛选栏时
  把可视中心抬起来，避免 marker 被遮住。
- `WMapZone.iconBuilder`：按条目决定 Marker 图标（优先于 `icon`），
  用于"旗舰店/普通店/暂停营业"这类差异化图标。
- `WMapItemMapper<T>` + `WMapZone(mapper: ...)`：业务模型**不必实现 `WMapItem`**。
  json_serializable 生成的模型用这种方式接入，避免手改生成类。
  `WMapZone` / `WMap` / `WMapConfig` / `WMapController` 的泛型约束也随之放宽为 `T`。
- `WMapController`：业务侧可通过 `mapController.closeSelection(item)` 关闭选中。
  之前 `closeSelection` 定义在私有的 `_WMapState` 里，`WMapConfig.onItemClosed` 永远无法触发。
- `WMapConfig.onMapTap`：点地图空白处（非 Marker）的回调，常用于"点空白关闭选中"。
- `WMapZone.addDataUpdatedListener` / `removeDataUpdatedListener`：
  支持多个 `WMap` 共享同一 zone（原来的单值 `onDataUpdated` 会被后注册的覆盖）。
- 数据异步到达时自动补一次相机移动：`initialCameraPosition` 只在首帧使用，
  之前 maps 为空后补数据，地图会一直停在默认位置。

### Changed
- MarkerId 兜底规则从 `hashCode` 改为经纬度（`'22.3_114.2'`），对象重建后仍然稳定。
- `showMarkerInfoWindow` 改为等待 `animateCamera` 完成后再调用，
  避免相机动画把刚打开的 InfoWindow 覆盖掉。

### Deprecated
- `WMapZone.onDataUpdated`：改用 `addDataUpdatedListener` / `removeDataUpdatedListener`。

### Packaging
- `example/` 改为独立包（去掉 `resolution: workspace`）：从 pub.dev 下载本包后
  `cd example && flutter pub get` 可以直接跑起来，不再依赖仓库根的 workspace。
- 新增本包自己的 `.pubignore`，显式排除 `test/`、构建产物与示例的 lock 文件。

## 1.0.0

首次发布。

- 新增 `WMapItem`：业务数据模型契约（id / 名称 / 经纬度）
- 新增 `WMapZone`：持有一组地图数据、Marker 集合与控制器，支持 `update` 刷新
- 新增 `WMap`：基于 Google Maps 渲染地图与 Marker，并管理相机动画
- 新增 `WMapConfig`：选中 / 关闭缩放、纬度偏移与事件回调
