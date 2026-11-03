# map 2.0 迁移

`WMapZone.onDataUpdated` 已删除（多个 WMap 共享 zone 时会互相覆盖）：

```dart
zone.addDataUpdatedListener(onUpdated);
// 不再需要时：zone.removeDataUpdatedListener(onUpdated);
```
