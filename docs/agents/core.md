# core 使用规则（给人和 AI）

## 什么时候用

存储 / token、校验与正则、日志、防抖节流、倒计时、加解密。

## 最小用法

```dart
await WStorage.init();                    // 读之前必须 init（未初始化会抛 StateError）
await WStorage.setString('k', 'v');
await WToken.saveToken(token, expiry);    // 键名由 WToken 持有
WValidator.isValidEmail(email);           // 业务语义校验
WRegExp.email.hasMatch(text);             // 纯正则匹配
WLogger.i('message', tag: 'tag');         // 不要 print（tag 是命名参数）

final debounce = WDebounce(() => search(), duration: const Duration(milliseconds: 300));
debounce();                               // 页面 dispose 时 debounce.cancel()
```

## 不要用

- `WConfig`（3.0 已删除，用 `WToken`）；
- `WUx().debounce/throttle`（3.0 已删除，用 `WDebounce` / `WThrottle`）；
- `WRegExpPattern` / `WRegExpPreset` / `escapeSql` / `stripHtml` / `WHash.hashPassword`（3.0 已删除）；
- `WStorage` 存密码 / 密钥（明文存储，不是 Keychain）。

## 常见坑

- 读方法不会自动初始化：先 `await WStorage.init()`；
- `WEncrypt` 的 AES-CBC 不提供完整性，需要防篡改用 AES-GCM；
- 全局静态字段（如 `WToken.tokenKey`）在测试间会串，测试里改完要还原。

完整说明：[core_module.md](../modules/core_module.md) · 示例：`packages/core/example`
