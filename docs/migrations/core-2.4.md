> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

# core 2.4 迁移：存储 / 节流 / 倒计时 / 平台判断

| 旧 | 新 | 说明 |
| --- | --- | --- |
| `WStorage.setObject(key, 'a')` + `getString` | `setObject` 现在统一 JSON 编码，`getString` 得到 `"a"` | 与 `getObject` 对称；纯字符串请直接用 `setString` / `getString` |
| `WThrottle` 回调抛异常后永久锁死 | 窗口结束后自动解锁，异常照常抛出 | 行为修复 |
| `WCountdown.dispose()` 后可复用 | 不再可复用（`start` 抛 `StateError`） | 需要继续使用请创建新实例 |
| `WPlatform.getPlatformValue` / `runForPlatform` | `WPlatform.platformType` / `isAndroid` / `isIOS` / `isWeb` / `isDesktop` | 3.0 移除多参 API |
