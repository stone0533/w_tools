# Changelog

## 1.0.0

首次发布。

- 新增 `WMapItem`：业务数据模型契约（id / 名称 / 经纬度）
- 新增 `WMapZone`：持有一组地图数据、Marker 集合与控制器，支持 `update` 刷新
- 新增 `WMap`：基于 Google Maps 渲染地图与 Marker，并管理相机动画
- 新增 `WMapConfig`：选中 / 关闭缩放、纬度偏移与事件回调
