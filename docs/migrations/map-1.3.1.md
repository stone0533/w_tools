# map 1.3.1 修复：Marker 复用 / 控制器清理

- `WMapZone.update()` / `initMap()` 现在按 id 缓存 Marker：条目未变化时复用同一 `Marker`
  实例，减少 Google Maps 重建闪烁；条目内容（name / 坐标 / 图标 / 实例）变化时重建对应 Marker。
- `WMap` 销毁时若 `zone.googleMapController` 仍是自己创建的那个，会置空，避免悬空引用。
- `WMapController.closeSelection` 在相机动画结束后会先判 `mounted` 再回调 `onItemClosed`。
