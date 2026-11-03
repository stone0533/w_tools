# Changelog

## 2.4.0

### Changed
- `WStorage.setObject` 统一 `jsonEncode`（含 `String`），与 `getObject` 的 `jsonDecode` 对称。
- `WThrottle` 回调抛异常时，窗口结束后仍会解锁，不再永久卡死。
- `WCountdown.dispose()` 后不可再 `start`（抛 `StateError`）；`isRunning` / `isPaused` 改为只读 getter，
  并实现 `ValueListenable<int>`（`value` / `addListener` / `removeListener`）。

### Deprecated（3.0 移除）
- `WPlatform.getPlatformValue` / `runForPlatform`：改用 `platformType` / `isX` 组合判断。

## 2.3.0

### Added
- `WDebounce` / `WThrottle`：`Duration` 参数、`isPending` / `isThrottled`、`cancel()`。
- `WCountdown.remaining`：`ValueListenable<int>`，每秒通知；`dispose()` 后再次 `start` 会重建。

### Deprecated（3.0 移除）
- `WUx.debounce` / `WUx.throttle`：改用 `WDebounce` / `WThrottle`。

## 2.2.0

### Changed
- `WValidator` 的格式校验全部改走 `WRegExp`（邮箱 / 手机号 / 用户名 / 密码 / IPv4 / 身份证 / 银行卡），
  正则字符串集中到包内唯一来源；`WRegExp` 新增 `username`。

### Deprecated（3.0 移除）
- `WRegExpPattern` / `WRegExpPreset`：用 `WRegExp`；字符串形式请自行维护。
- `WValidator.escapeSql` / `stripHtml`：不能替代参数化查询与 HTML 转义。
- `WHash.hashPassword` / `verifyPassword`：密码哈希应在服务端用 bcrypt / argon2。

## 2.1.0

### Changed
- token 键名移入 `WToken`（`tokenKey` / `refreshTokenKey` / `tokenExpiryKey`），成为唯一真源；
  `WConfig` 的同名字段改为弃用代理（3.0 移除），行为不变。

## 2.0.0

### Breaking
- 异步能力整体迁移到 `w_tools_async`：`WAsync` / `WAsyncConfig` /
  `WCancelToken` / `WAsyncState` / `WAsyncController` / 异步视图不再由 core 导出。
  迁移：`import 'package:w_tools_async/w_tools_async.dart';`。

### Fixed
- `WUx.debounce` / `throttle` / `delay` 对负数 duration 抛出 `ArgumentError`。
- `WEncrypt.generateKey` / `generateIv` 校验 AES 合法长度。
- `WValidator.isValidUrl` 要求 host 非空，拒绝 `https://` / `https://?q=1`。
- `WHash.verifyPassword` 使用常量时间比较，降低时序侧信道。

### Docs
- `WStorage` / `WToken` 明确 SharedPreferences 为明文存储，高敏感数据应使用 Keychain / Keystore。
- `WUx` 说明 duration 必须为非负毫秒数。
- `WEncrypt` 明确 AES-CBC 只提供机密性，不提供完整性 / 认证。
- `WMapExtension.sortedByKeys` 说明混合 Comparable 键需显式传 compare。

## 1.0.1

### Deprecated
- `WConfig.assetImagePath`：该字段从未被读取，资源前缀的实际开关是 `w_tools_ui` 的
  `WAssets.imagePath`（聚合包的 `WConfig.assetImagePath` 已改为代理它）。
  字段仅为源码兼容保留，将在下个大版本移除。

## 1.0.0

首次发布。

- 密码规则：`WRegExpPattern.password` 与 `WValidator.isValidPassword` 统一为
  「≥8 位，且同时包含小写字母、大写字母与数字（允许符号）」；
  `WValidator.passwordPattern` 是该规则的唯一来源（1.0.0 首发即为此规则）。
- 新增 `WAsync` / `WAsyncConfig` / `WCancelToken`：支持重试、超时、并发控制、协作式取消与加载状态合并
- `WAsync.wait` / `WAsync.any` 在等待期间响应取消；`runWithRetry` 支持 `retryIf` 过滤重试异常
- 新增 `WValidator`：邮箱、手机号、身份证、银行卡 Luhn、真实日期、时间、数值等校验
- 新增 `WRegExp` / `WRegExpPattern` / `WRegExpPreset`：正则模式、匹配、提取、掩码与格式化
- 新增 `WEncrypt` / `WHash`：AES-CBC（安全随机 IV）、Base64、MD5、SHA、HMAC 与加盐密码哈希
- 新增 `WStorage` / `WToken`：基于 SharedPreferences 的本地存储与 Token 管理
- 新增 `WLogger`：分级日志、标签、性能计时与级别切换
- 新增 `WCountdown`、`WPlatform`、`WUx`、`WMapExtension` 等常用工具
- 提供 `WConfig` 全局配置（资源路径与 Token 存储键名）
