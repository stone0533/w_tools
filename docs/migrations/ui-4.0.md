# ui 4.0 迁移：按钮默认样式跟随主题

| 旧 | 新 | 说明 |
| --- | --- | --- |
| `WButton` 不传 `style` 时用写死的 `#3949AB` / `#D32F2F` | `WButtonStyles.of(context).primary`（`ColorScheme.primary` / `onPrimary`） | 默认视觉变化；依赖旧默认色的页面显式传 `WButtonStyle` |
| `WButtonStyles.primary` / `secondary` / `text` / `danger` | `WButtonStyles.of(context)` 的四组样式 | 静态预设 5.0 移除 |

`WButtonStyles.of(context)` 按 `ThemeData` 缓存，主题切换会重新解析。
