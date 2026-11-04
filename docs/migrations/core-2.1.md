> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

# core 2.1 迁移：token 键名改用 `WToken`

| 旧 | 新 | 说明 |
| --- | --- | --- |
| `WConfig.tokenKey` | `WToken.tokenKey` | 默认值仍为 `token`；旧字段是弃用代理，3.0 移除 |
| `WConfig.refreshTokenKey` | `WToken.refreshTokenKey` | 默认 `refresh_token` |
| `WConfig.tokenExpiryKey` | `WToken.tokenExpiryKey` | 默认 `token_expiry` |
| `WConfig.assetImagePath` | `WAssets.imagePath`（w_tools_ui） | 该字段自 2.0 起无任何效果，仅为源码兼容保留 |

`WConfig` 的键名字段与 `WToken` 双向同步（setter 代理），迁移期间混用不会丢配置。
