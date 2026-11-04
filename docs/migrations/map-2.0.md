> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

# map 2.0 迁移

`WMapZone.onDataUpdated` 已删除（多个 WMap 共享 zone 时会互相覆盖）：

```dart
zone.addDataUpdatedListener(onUpdated);
// 不再需要时：zone.removeDataUpdatedListener(onUpdated);
```

## 其他删除

| 旧 | 新 |
| --- | --- |
| `WMapConfig.build(zone:)` | 直接 `WMap(config:, zone:)` |
| `WMapZone.zoneId` / `name` | 由业务层自己持有（地图只关心条目与相机） |
