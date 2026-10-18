# Changelog

## 1.0.0

首次发布。

- 新增 `WAsync` / `WAsyncConfig` / `WCancelToken`：支持重试、超时、并发控制、协作式取消与加载状态合并
- `WAsync.wait` / `WAsync.any` 在等待期间响应取消；`runWithRetry` 支持 `retryIf` 过滤重试异常
- 新增 `WValidator`：邮箱、手机号、身份证、银行卡 Luhn、真实日期、时间、数值等校验
- 新增 `WRegExp` / `WRegExpPattern` / `WRegExpPreset`：正则模式、匹配、提取、掩码与格式化
- 新增 `WEncrypt` / `WHash`：AES-CBC（安全随机 IV）、Base64、MD5、SHA、HMAC 与加盐密码哈希
- 新增 `WStorage` / `WToken`：基于 SharedPreferences 的本地存储与 Token 管理
- 新增 `WLogger`：分级日志、标签、性能计时与级别切换
- 新增 `WCountdown`、`WPlatform`、`WUx`、`WMapExtension` 等常用工具
- 提供 `WConfig` 全局配置（资源路径与 Token 存储键名）
