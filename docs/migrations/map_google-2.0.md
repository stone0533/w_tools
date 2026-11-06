# map_google 2.0 迁移：`WMapConfig` → `WMapOptions`

`w_tools_map_google 2.0.0` 只做命名收敛，字段和行为不变。

| 旧 | 新 |
|---|---|
| `WMapConfig<T>` | `WMapOptions<T>` |
| `config: WMapConfig<Shop>(...)` | `config: WMapOptions<Shop>(...)` |

```dart
// 2.0
WMap<Shop>(
  zone: zone,
  config: const WMapOptions<Shop>(
    selectZoom: 12,
    onItemSelected: ...,
  ),
)
```

旧的 `WMapConfig.build()` 已在 5.0 删除；这次不再提供兼容别名。
