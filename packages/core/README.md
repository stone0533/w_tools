# w_tools_core

[![pub package](https://img.shields.io/pub/v/w_tools_core.svg)](https://pub.dev/packages/w_tools_core)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

`w_tools_core` 是 w_tools 的基础工具层，提供扩展方法、校验、正则、加密、存储、日志、倒计时、平台判断与全局配置。  
不依赖任何业务框架，可单独引入到任意 Flutter 项目。异步能力请使用 `w_tools_async`。

## 特性

- **数据校验**：邮箱、手机号、身份证、银行卡（Luhn）、真实日期、数值等
- **正则工具**：`WRegExp`（预编译正则 + 提取方法）
- **加密与哈希**：AES-CBC、Base64、MD5、SHA 系列、HMAC-SHA256
- **本地存储**：基于 `shared_preferences` 的 `WStorage` 与 `WToken`
- **日志与性能**：`WLogger` 支持级别切换、标签、性能计时
- **其他工具**：倒计时、平台判断、防抖/节流、Map 扩展

## 安全说明

- `WStorage` / `WToken` 使用 SharedPreferences，是**明文存储**，不是安全存储。
- 高敏感 token、密码、密钥请使用 `flutter_secure_storage` 等 Keychain / Keystore 方案。
- `WEncrypt` 的 AES-CBC 只提供机密性，不提供完整性 / 认证；需要防篡改时使用 AES-GCM。

## 安装

```yaml
dependencies:
  w_tools_core: ^3.2.0
```

```bash
flutter pub get
```

> 本包最低要求 Flutter 3.38.0。

## 快速开始

```dart
import 'package:w_tools_core/w_tools_core.dart';

Future<void> example() async {
  await WStorage.init();
  await WStorage.setString('token', 'abc');

  WLogger.i('saved: ${WStorage.getString('token')}');
  WLogger.d('email valid: ${WValidator.isValidEmail('dev@example.com')}');
  WLogger.d('amount: ${1234.5.toCurrency(symbol: '¥')}');
}
```

## 主要 API

| 能力 | 入口 |
|---|---|
| 配置 | `WToken`（token 键名）；`WConfig` 已在 3.0 删除（资源路径直接用完整路径） |
| 校验 | `WValidator` |
| 正则 | `WRegExp` |
| 加密 / 哈希 | `WEncrypt` / `WHash` |
| 存储 / Token | `WStorage` / `WToken` |
| 日志 | `WLogger` / `WLogger.t` / `d` / `i` / `w` / `e` / `f` |
| 倒计时 | `WCountdown` |
| 平台判断 | `WPlatform` / `WPlatformType` |
| 交互工具 | `WDebounce` / `WThrottle`；`WUx` 的同名方法已在 3.0 删除 |
| Map 扩展 | `WMapExtension.sortedByKeys` / `merge` |
| 数字格式化 | `WNumFormatExtension`：`toThousandsSeparated` / `toCurrency` / `toPercent` / `toPercentWithFixed` / `toPadLeft` |

## 行为说明

- `WStorage` 的读取方法在未初始化时抛出 `StateError`，避免把「未初始化」误判为「没有数据」。
- `WToken` 直接读写 `WStorage`，不维护额外静态缓存。
- `WEncrypt.aesEncrypt` 未显式传入 IV 时使用安全随机 IV。

## 交互工具示例

```dart
final debouncedSearch = WDebounce(
  loadResults,
  duration: const Duration(milliseconds: 300),
);

// 页面 dispose 时取消
debouncedSearch.cancel();
```

## 完整示例

见 [`example/`](example/)：校验、哈希、AES、存储、防抖、倒计时与平台判断。

## 历史迁移

升级前先看 [`docs/migrations/`](https://github.com/stone0533/w_tools/blob/main/docs/migrations/README.md)：
每个包的 breaking 变更都有「旧 → 新」对照，不只是变更清单。

## License

MIT
