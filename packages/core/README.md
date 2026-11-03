# w_tools_core

[![pub package](https://img.shields.io/pub/v/w_tools_core.svg)](https://pub.dev/packages/w_tools_core)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

`w_tools_core` 是 w_tools 的基础工具层，提供扩展方法、校验、正则、加密、存储、日志、倒计时、平台判断与全局配置。  
不依赖任何业务框架，可单独引入到任意 Flutter 项目。异步能力请使用 `w_tools_async`。

## 特性

- **数据校验**：邮箱、手机号、身份证、银行卡（Luhn）、真实日期、数值等
- **正则工具**：`WRegExpPattern` / `WRegExpPreset` / `WRegExp` 分层使用
- **加密与哈希**：AES-CBC、Base64、MD5、SHA 系列、HMAC-SHA256
- **本地存储**：基于 `shared_preferences` 的 `WStorage` 与 `WToken`
- **日志与性能**：`WLogger` 支持级别切换、标签、性能计时
- **其他工具**：倒计时、平台判断、防抖/节流、Map 扩展与全局配置

## 安全说明

- `WStorage` / `WToken` 使用 SharedPreferences，是**明文存储**，不是安全存储。
- 高敏感 token、密码、密钥请使用 `flutter_secure_storage` 等 Keychain / Keystore 方案。
- `WEncrypt` 的 AES-CBC 只提供机密性，不提供完整性 / 认证；需要防篡改时使用 AES-GCM。

## 安装

```yaml
dependencies:
  w_tools_core: ^2.4.0
```

```bash
flutter pub get
```

> 本包最低要求 Flutter 3.27.0。

## 快速开始

```dart
import 'package:w_tools_core/w_tools_core.dart';

Future<void> example() async {
  await WStorage.init();
  await WStorage.setString('token', 'abc');

  WLogger.i('result: $length');
  WLogger.d('email valid: ${WValidator.isValidEmail('dev@example.com')}');
}
```

## 主要 API

| 能力 | 入口 |
|---|---|
| 全局配置 | `WConfig` |
| 校验 | `WValidator` |
| 正则 | `WRegExp` / `WRegExpPattern` / `WRegExpPreset` |
| 加密 / 哈希 | `WEncrypt` / `WHash` |
| 存储 / Token | `WStorage` / `WToken` |
| 日志 | `WLogger` / `WLogger.t` / `d` / `i` / `w` / `e` / `f` |
| 倒计时 | `WCountdown` |
| 平台判断 | `WPlatform` / `WPlatformType` |
| 交互工具 | `WUx` / `WCancellableAction` |
| Map 扩展 | `WMapExtension.sortedByKeys` / `merge` |

## 行为说明

- `WStorage` 的读取方法在未初始化时抛出 `StateError`，避免把「未初始化」误判为「没有数据」。
- `WToken` 直接读写 `WStorage`，不维护额外静态缓存。
- `WEncrypt.aesEncrypt` 未显式传入 IV 时使用安全随机 IV。

## 交互工具示例

```dart
final debouncedSearch = WUx().debounce(
  () => loadResults(),
  duration: 300,
);

// 页面 dispose 时取消
debouncedSearch.cancel();
```

## 完整示例

见 [`example/`](example/)：校验、哈希、AES、存储、防抖、倒计时与平台判断。

## License

MIT
