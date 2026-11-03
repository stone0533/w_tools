# form 3.1 迁移：图标集合

| 旧 | 新 | 说明 |
| --- | --- | --- |
| `WFormDefaults.xxxIcon` 全局静态 | `WForm(icons: WFormIcons(...))` / `WFormTheme(icons:)` | `WFormDefaults` 弃用（4.0 移除） |
| 8 个 `xxxIcon` 参数 | `WFormIcons` + `copyWith` | 单字段 `xxxIcon` 仍优先 |

优先级：单字段图标 > `WFormIcons` > `WFormDefaults`（兜底） > 包内默认。
