# ui 4.3 迁移：图片预设构造与默认作用域

| 旧 | 新 | 说明 |
| --- | --- | --- |
| `WImage.avatar(data, size: 40)` | `WImage(data, style: WImageStyle.avatar(40))` | 构造器 5.0 移除 |
| `WImage.thumbnail(data, width: 80, cacheSize: 240)` | `WImage(data, style: WImageStyle.thumbnail(80), config: WImageLoadConfig(memCacheWidth: 240, memCacheHeight: 240))` | 构造器 5.0 移除 |
| `WImage.cover(data, aspectRatio: 2)` | `WImage(data, style: WImageStyle.cover(aspectRatio: 2))` | 构造器 5.0 移除 |
| `WImage.assetImage(name)` | `WImage.source(source: WImageSource.asset(name, prefix: true))` | 构造器 5.0 移除 |
| `WImageDefaultsScope(defaults: WImageDefaults(...))` | `WImageDefaultsScope(defaults: WImageLoadConfig(...))` | `errorBuilder` → `errorWidgetBuilder`；`WImageDefaults` 5.0 移除 |
