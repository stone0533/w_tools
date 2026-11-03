# ui 4.1 迁移：图片加载实现与缓存预算

| 旧 | 新 | 说明 |
| --- | --- | --- |
| `WImageLoader` / `WImageLoadSnapshot`（公共导出） | 无（内部实现） | 4.1 起不再从 barrel 导出；需要自定义加载请提 issue，不要依赖内部状态机 |
| `WImageCachePolicy.configure(...)` | `PaintingBinding.instance.imageCache..maximumSize = ... ..maximumSizeBytes = ...` | 5.0 移除；避免再维护一层全局静态状态 |
| `WImageCachePolicy.reset()` | 直接恢复 `ImageCache` 默认值（1000 / 100MB） | 同上 |

`WImageConfig`（不可变加载配置）、`WImageStyle`、`WImageSource`、`WImageError`、`WImageDefaultsScope`
保持不变。
