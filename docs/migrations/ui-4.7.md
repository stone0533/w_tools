> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

# ui 4.7 迁移：组件 Config 改为可选

| 组件 | 旧 | 新 |
| --- | --- | --- |
| `WClipRRect` | `config:` 必填 | 可省略（默认 `WClipRRectConfig()`，圆角 0） |
| `WBadge` | `config:` 必填 | 可省略（默认显示徽章） |
| `WTabBar` | `config:` 必填 | 可省略（默认无自定义样式） |
| `WNavBar` | `config:` 必填 | 可省略（默认 `const WNavBarConfig()`） |

只传 `child` / `tabs` / `badgeContent` 即可使用；需要样式时再传 `config`。
`WClipRRectConfig` / `WBadgeConfig` / `WTabBarConfig` 仍是可变配置（setter / 链式），
后续版本会像其它组件一样收敛为不可变值对象。
