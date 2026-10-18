# w_tools_core

[![pub package](https://img.shields.io/pub/v/w_tools_core.svg)](https://pub.dev/packages/w_tools_core)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

`w_tools_core` 是 w_tools 的基础工具层，提供扩展方法、异步任务、校验、正则、加密、存储、日志、倒计时、平台判断与全局配置。  
不依赖任何业务框架，可单独引入到任意 Flutter 项目。

## 特性

- **异步任务**：`WAsync` 统一处理重试、超时、并发控制、取消与加载状态
- **数据校验**：邮箱、手机号、身份证、银行卡（Luhn）、真实日期、数值等
- **正则工具**：`WRegExpPattern` / `WRegExpPreset` / `WRegExp` 分层使用
- **加密与哈希**：AES-CBC、Base64、MD5、SHA 系列、HMAC-SHA256
- **本地存储**：基于 `shared_preferences` 的 `WStorage` 与 `WToken`
- **日志与性能**：`WLogger` 支持级别切换、标签、性能计时
- **其他工具**：倒计时、平台判断、防抖/节流、Map 扩展与全局配置

## 安装

```yaml
dependencies:
  w_tools_core: ^1.0.0
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

  final length = await WAsync.run<List<String>, int>(
    () async => ['a', 'b'],
    onSuccess: (list) => list.length,
  );

  WLogger.i('result: $length');
  WLogger.d('email valid: ${WValidator.isValidEmail('dev@example.com')}');
}
```

## 主要 API

| 能力 | 入口 |
|---|---|
| 全局配置 | `WConfig` |
| 异步任务 | `WAsync` / `WAsyncConfig` / `WCancelToken` |
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

- `WAsync` 将 `Exception` 视为业务异常（通过 `onError` 上报并返回 `null`），
  将 `Error`（如 `TypeError` / `StateError`）原样向上抛出。
- `WStorage` 的读取方法在未初始化时抛出 `StateError`，避免把「未初始化」误判为「没有数据」。
- `WToken` 直接读写 `WStorage`，不维护额外静态缓存。
- `WEncrypt.aesEncrypt` 未显式传入 IV 时使用安全随机 IV。

## License

MIT
