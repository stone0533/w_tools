> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

# core 3.0 迁移

| 旧 | 新 |
| --- | --- |
| `WConfig.tokenKey` / `refreshTokenKey` / `tokenExpiryKey` | `WToken.*`（`WConfig` 已删除；`assetImagePath` 从未生效） |
| `WRegExpPattern` / `WRegExpPreset` | `WRegExp` 的预编译实例（`WRegExp.email` 等） |
| `WUx().debounce` / `WUx().throttle` | `WDebounce` / `WThrottle` |
| `WHash.hashPassword` / `verifyPassword` | 服务端 bcrypt / Argon2；本包只保留通用哈希 |
| `WPlatform.getPlatformValue` / `runForPlatform` | `WPlatform.platformType` / `isAndroid` 等组合判断 |
| `WValidator.escapeSql` / `stripHtml` | 参数化查询 / 输出侧 HTML 转义，不要用正则清洗 |
