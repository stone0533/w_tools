> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

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

## 配置类改为不可变

| 旧 | 新 |
| --- | --- |
| `WTabBarConfig()..labelStyle = ...` / `divider(...)` / `indicatorWithHeightAndColor(...)` | `const WTabBarConfig(...)` / `copyWith(...)` |
| `WBadgeConfig().positionTopRight(...)` / `hideBadge()` / `badgeStyle(...)` | `WBadgeConfig.topRight(...)` / `const WBadgeConfig(showBadge: false)` / `copyWith(...)` |
| `WClipRRectConfig()..borderRadiusAll(12)` | `WClipRRectConfig.all(12)` |
