# ui 5.0 迁移

| 旧 | 新 |
| --- | --- |
| `WRowButtons` / `WRowButtonsController` | `WActionRow` / `WSelectableRow` |
| `WImage.avatar/thumbnail/cover/assetImage` | `WImage(...)` + `WImageStyle.avatar/thumbnail/...` |
| `WImageCachePolicy` | 直接配置 `PaintingBinding.instance.imageCache` |
| `WImageConfig` | `WImageLoadConfig` |
| `WImageDefaults` | `WImageDefaultsScope` |
| `WImageXxxError` 子类 | `WImageError.kind` |
| `WRow` / `WColumn` / `WPadding` / `WSizeBox` | 原生 `Row` / `Column` / `Padding` / `SizedBox` |
| `WButtonStyles.primary/secondary/text/danger` | `WButtonStyles.of(context).{primary,...}` |
