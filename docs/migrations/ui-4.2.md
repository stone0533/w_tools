# ui 4.2 迁移：图片加载配置与错误分类

| 旧 | 新 | 说明 |
| --- | --- | --- |
| `WImageConfig` | `WImageLoadConfig` | 类更名，字段不变；旧名保留为弃用 typedef（5.0 移除） |
| `WImageError` 子类（`WImageEmptyError` 等 7 个） | `WImageError.kind`（`WImageErrorKind`） | 子类已弃用（5.0 移除）；用 `switch (error.kind)` 分支 |

`WImageLoadConfig` 仍是不可变值对象：`copyWith` 传 `null` 可清空 builder 字段；
视觉样式仍由 `WImageStyle` 负责。
