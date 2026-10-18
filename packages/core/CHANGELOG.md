# Changelog

## Unreleased

- **行为变更（breaking）**：`WRegExpPattern.password` 与 `WValidator.isValidPassword` 统一为「≥8 位，且同时包含小写字母、大写字母与数字（允许符号）」。此前两个公开入口各写一套规则：`WRegExpPattern.password` 接受纯字母/纯数字组合并拒绝符号，`WValidator.isValidPassword` 强制大小写并允许符号。
- `WValidator` 新增 `passwordPattern` 常量，作为密码规则的唯一真相；`WRegExpPattern.password` 直接引用它。
- 新增回归测试 `test/core/password_rule_test.dart`，锁住「两个公开入口对同一输入给出相同结果」。

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
