# Core 模块文档

## 概述

Core 模块（`w_tools_core` 子包）是整个 `w_tools` 工具库的**零业务依赖基础层**，只依赖 Dart SDK 和 Flutter SDK 的 `foundation` / `services` 等基础包，不依赖任何第三方业务包（如 Dio、GetX 等）。

模块提供通用的加解密、哈希、日志、平台判断、正则匹配、本地存储、Token 管理、防抖节流、表单验证等工具类。

### 与 w_tools_ui 的职责划分

| 模块 | 职责 | 依赖 |
|------|------|------|
| **Core** | 纯 Dart/Flutter 基础工具，不涉及 UI 组件 | 仅基础 SDK |
| **UI** | Flutter Widget 组件（Toast、Dialog、Loading 等）、BuildContext 扩展 | Flutter Widgets |

## 快速判断
- 存储 / Token → `WStorage` / `WToken`（读取前先 `init`，明文存储）
- 业务校验 → `WValidator`
- 纯正则 → `WRegExp`
- 日志 → `WLogger`
- 防抖 / 节流 → `WDebounce` / `WThrottle`（`WUx` 的同名方法已弃用）
- 可运行示例：[packages/core/example](../../packages/core/example/README.md)

- 强制规则：根 [`AGENTS.md`](../../AGENTS.md)

---

## 模块结构

```
core/
├── w_tools_core.dart        # barrel 导出
└── src/
    ├── extensions/
    │   └── map.dart         # WMapExtension
    └── utils/
        ├── countdown.dart   # WCountdown
        ├── encrypt.dart     # WEncrypt
        ├── hash.dart        # WHash
        ├── logger.dart      # WLogger + 顶层函数 logT/logD/logI/logW/logE/logF
        ├── platform.dart    # WPlatform, WPlatformType
        ├── reg_exp.dart     # WRegExp
        ├── storage.dart     # WStorage
        ├── token.dart       # WToken
        ├── ux.dart          # WUx, WDebounce, WThrottle, WCancellableAction
        └── validator.dart   # WValidator
```

---

## 1. WToken - token 键名

### 功能说明

集中管理 token / refresh token / 过期时间的存储键名；资源路径直接用完整路径（ui 12.0 删除了 `WAssets.imagePath`）。

### 配置字段

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `tokenKey` | String | `'access_token'` | Token 存储键名 |
| `refreshTokenKey` | String | `'refresh_token'` | 刷新 Token 存储键名 |
| `tokenExpiryKey` | String | `'token_expiry'` | Token 过期时间存储键名 |

### 使用示例

```dart
void main() {
  WToken.tokenKey = 'auth_token';
  WToken.refreshTokenKey = 'auth_refresh_token';
  WToken.tokenExpiryKey = 'auth_token_expiry';
}
```

---

## 2. WCountdown - 倒计时

### 功能说明

提供秒级精度的倒计时器，支持暂停/恢复。

### 字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `isRunning` | bool | 是否正在运行 |
| `isPaused` | bool | 是否暂停 |
| `remainingSeconds` | int | 剩余秒数 |
| `totalSeconds` | int | 总秒数 |

### 构造与方法

| 成员 | 类型 | 说明 |
|------|------|------|
| `WCountdown({callback, onComplete})` | 构造函数 | `callback` 每秒触发，`onComplete` 结束触发；`remaining` 是 `ValueListenable<int>`；`dispose()` 后不可复用 |
| `start(second)` | void | 开始倒计时 |
| `pause()` | void | 暂停 |
| `resume()` | void | 恢复 |
| `stop()` | void | 停止 |
| `dispose()` | void | 释放资源（停止并清空监听） |
| `formatRemaining({type})` | String | 默认纯 `SS`；传 `WCountdownRemainingType.minutesSeconds` 得 `MM:SS` |

### 使用示例

```dart
final countdown = WCountdown(
  callback: (remaining) {
    print('剩余 $remaining 秒');
    print('格式化: ${countdown.formatRemaining()}'); // 默认 SS（秒）
  },
  onComplete: () => print('倒计时结束'),
);

countdown.start(second: 60);  // 60 秒倒计时
// countdown.pause();
// countdown.resume();
// countdown.dispose();
```

---

## 3. WEncrypt - 加解密

### 功能说明

提供 Base64 编解码、随机密钥/IV 生成、AES 对称加解密。AES 输出格式为 `Base64(IV):Base64(密文)`，解密密文时自动从冒号分隔符提取 IV。

### 方法列表

| 方法 | 签名 | 说明 |
|------|------|------|
| `base64Encode(input)` | String | Base64 编码 |
| `base64Decode(input)` | String | Base64 解码 |
| `generateKey({length=32})` | String | 生成随机密钥（Base64） |
| `generateIv({length=16})` | String | 生成随机 IV（Base64） |
| `aesEncrypt(data, {keyStr, ivStr})` | String | AES 加密，返回 `"IV:密文"` |
| `aesDecrypt(data, {keyStr})` | String | AES 解密，输入格式 `"IV:密文"` |

### 使用示例

```dart
// 生成密钥
final key = WEncrypt.generateKey(); // 默认 32 字节
final iv = WEncrypt.generateIv();   // 默认 16 字节

// 加密（IV 未传时自动随机生成）
final encrypted = WEncrypt.aesEncrypt('hello world', keyStr: key);
print(encrypted); // 形如 "dGhpcyBpcyBp...:VABhG..."

// 解密
final decrypted = WEncrypt.aesDecrypt(encrypted, keyStr: key);
print(decrypted); // "hello world"
```

---

## 4. WHash - 哈希工具

### 功能说明

提供常用哈希算法和密码哈希/验证工具。

### 方法列表

| 方法 | 签名 | 说明 |
|------|------|------|
| `md5(string)` | String | MD5 哈希 |
| `bytesMd5(List<int>)` | String | 字节数组 MD5 |
| `sha1(input)` | String | SHA-1 |
| `sha256(input)` | String | SHA-256 |
| `sha512(input)` | String | SHA-512 |
| `hmacSha256(data, key)` | String | HMAC-SHA256 |

### 使用示例

```dart
// 普通哈希
final digest = WHash.md5('hello');
final sha = WHash.sha256('hello');
final hmac = WHash.hmacSha256('data', 'secret_key');
```

---

## 5. WLogger - 日志工具

### 功能说明

分级日志输出，支持性能计时。底层使用自定义 PrettyPrinter（`methodCount=0, errorMethodCount=5, lineLength=50, 彩色输出`）。

### 核心方法

| 方法 | 说明 |
|------|------|
| `setLevel(Level)` | 设置日志级别 |
| `turnOff()` | 关闭日志输出 |
| `t/d/i/w/e/f(message, {time, error, stackTrace, tag})` | Trace/Debug/Info/Warning/Error/Fatal 日志 |
| `startPerformanceTimer(key)` | 开始性能计时 |
| `stopPerformanceTimer(key, {message})` | 停止并返回/输出耗时（毫秒） |
| `cancelPerformanceTimer(key)` | 取消计时 |
| `getActivePerformanceTimers()` | 获取活跃计时器名称 |
| `measureSync(key, fn, {message})` | 同步函数计时（自动 start+stop） |

> 没有顶层 `logT/logD/...` 函数；统一用 `WLogger.t/d/i/w/e/f`。

### 使用示例

```dart
// 设置级别
WLogger.setLevel(Level.verbose);
// WLogger.turnOff();  // 生产环境关闭

// 常规日志
WLogger.i('应用启动', tag: 'APP');
WLogger.w('配置项缺失', tag: 'CONFIG');
WLogger.e('网络请求失败', error: exception, tag: 'API');

// 性能计时
WLogger.startPerformanceTimer('heavy_op');
await heavyOperation();
WLogger.stopPerformanceTimer('heavy_op'); // 输出耗时并返回毫秒

// 同步快捷计时
final result = WLogger.measureSync('sync_op', () {
  return doSomethingSync();
});
```

---

## 6. WPlatform - 平台判断

### 功能说明

基于 `dart:io` 和 `kIsWeb` 封装的平台类型判断。

### 类型定义

`WPlatformType` 枚举：`android` / `ios` / `web` / `linux` / `macos` / `windows` / `fuchsia`

### 属性列表

| 属性 | 类型 | 说明 |
|------|------|------|
| `platformType` | WPlatformType | 当前平台类型 |
| `isMobile` / `isDesktop` / `isWeb` | bool | 平台大类判断 |
| `isAndroid` / `isIOS` / `isLinux` / `isMacOS` / `isWindows` | bool | 具体平台判断 |


### 使用示例

```dart
// 属性判断
if (WPlatform.isWeb) {
  print('运行在浏览器');
}
```

---

## 7. WRegExp - 正则工具

### 功能说明

提供预置的正则模式常量、预编译实例、以及身份证/手机号/银行卡等业务数据的提取与格式化。

### WRegExp（预编译实例 + 便捷方法）

预编译的 `RegExp` 实例（如 `WRegExp.email`、`WRegExp.phone`）以及以下方法：

| 方法 | 说明 |
|------|------|
| `firstXxxMatch(input)` | 返回 `Match?`（如 `firstEmailMatch`；等价于 `WRegExp.email.firstMatch(input)`） |
| `extractBirthdayFromIdCard(idCard)` | 从身份证号提取出生日期 |
| `extractGenderFromIdCard(idCard)` | 从身份证号提取性别 |
| `maskPhone(phone)` | 手机号脱敏：`XXX****XXXX` |
| `maskBankCard(card)` | 银行卡脱敏 |
| `formatPhone(phone)` | 格式化：`XXX-XXXX-XXXX` |
| `formatDate(dateStr)` | 日期格式化 |

### 使用示例

```dart
// 预编译匹配
final isPhone = WRegExp.phone.hasMatch('13812345678'); // true
final phone = WRegExp.firstPhoneMatch('13812345678')?.group(0);
print(phone); // "13812345678"（模式是整串锚定）

// 身份证提取
final birthday = WRegExp.extractBirthdayFromIdCard('110101199001011234');
final gender = WRegExp.extractGenderFromIdCard('110101199001011234');

// 脱敏与格式化
final masked = WRegExp.maskPhone('13812345678');   // "138****5678"
final formatted = WRegExp.formatPhone('13812345678'); // "138-1234-5678"
```

---

## 8. WStorage - 本地存储

### 功能说明

基于 `shared_preferences` 的封装，提供类型安全的读写、JSON 对象存取，以及幂等初始化（`synchronized` 锁保护）。

### 初始化

| 成员 | 类型 | 说明 |
|------|------|------|
| `init()` | `Future<void>` | 幂等初始化，内部使用锁保护 |
| `isInitialized` | bool (getter) | 是否已初始化 |
| `prefs` | SharedPreferences (getter) | 底层实例，未 init 时抛 `StateError` |

### 数据读写

| 读方法 | 写方法 | 类型 |
|--------|--------|------|
| `getString(key)` | `setString(key, value)` | String |
| `getInt(key)` | `setInt(key, value)` | int |
| `getBool(key)` | `setBool(key, value)` | bool |
| `getDouble(key)` | `setDouble(key, value)` | double |
| `getStringList(key)` | `setStringList(key, value)` | `List<String>` |
| `getObject<T>(key, {defaultValue})` | `setObject(key, value)` | JSON 可解码类型（`Map<String, dynamic>` / `List<dynamic>`） |

### 其他方法

| 方法 | 说明 |
|------|------|
| `remove(key)` | 删除指定键 |
| `clear()` | 清空全部 |
| `containsKey(key)` | 判断键是否存在 |
| `allKeys()` | 获取所有键名 |

### 注意事项

- **写方法自动 ensureInitialized**，读方法未 init 时抛 `StateError`。
- 建议在应用启动时显式调用 `WStorage.init()`，避免首次写入时的隐式延迟。

### 使用示例

```dart
// 应用启动时一次性初始化
await WStorage.init();

// 基本类型
await WStorage.setString('username', 'zhangsan');
final name = WStorage.getString('username');

// 对象存取（JSON 编解码；自定义模型请自己 fromJson）
await WStorage.setObject('profile', {'name': '张三'});
final profile = WStorage.getObject<Map<String, dynamic>>('profile');

// 查询与清理
final keys = WStorage.allKeys();
await WStorage.remove('username');
await WStorage.clear();
```

---

## 9. WToken - Token 管理

### 功能说明

基于 `WStorage` 的 Token 便捷管理。键名由 `WToken` 持有（默认 `token` / `refresh_token` / `token_expiry`），无需硬编码。

### 保存方法

| 方法 | 说明 |
|------|------|
| `saveToken(token, [expiry])` | 保存访问 Token（可选过期时间） |
| `saveRefreshToken(refreshToken)` | 保存刷新 Token |
| `saveTokens(token, refreshToken, [expiry])` | 一次性保存两者 |

### 读取方法

| 方法 | 返回 | 说明 |
|------|------|------|
| `getToken()` | `String?` | 获取访问 Token |
| `getRefreshToken()` | `String?` | 获取刷新 Token |
| `getTokenExpiry()` | `DateTime?` | 获取过期时间 |

### 清除方法

| 方法 | 说明 |
|------|------|
| `clearToken()` | 仅清除访问 Token |
| `clearRefreshToken()` | 仅清除刷新 Token |
| `clearAllTokens()` | 清除全部 |

### 状态判断

| 方法 | 返回 | 说明 |
|------|------|------|
| `isTokenExpired()` | bool | 是否已过期（无过期时间视为永不过期） |
| `isTokenValid()` | bool | 有值且未过期 |
| `hasRefreshToken()` | bool | 是否存在刷新 Token |
| `updateTokenExpiry(DateTime)` | void | 更新过期时间 |

### 使用示例

```dart
// 启动时先 init WStorage + 配置 token 键名
await WStorage.init();
WToken.tokenKey = 'auth_token';
WToken.refreshTokenKey = 'auth_refresh_token';
WToken.tokenExpiryKey = 'auth_token_expiry';

// 登录成功后保存
final expiresAt = DateTime.now().add(const Duration(hours: 2));
await WToken.saveTokens('access_xxx', 'refresh_yyy', expiresAt);

// 请求拦截器里判断
if (WToken.isTokenValid()) {
  final token = WToken.getToken();
  // 附加到请求头
} else if (WToken.hasRefreshToken()) {
  // 走刷新流程
}

// 登出
await WToken.clearAllTokens();
```

---

## 10. WUx - UX 辅助（单例）

> 防抖 / 节流用 `WDebounce` / `WThrottle`（支持 `isPending` / `isThrottled`、`Duration` 参数）。

### 功能说明

防抖、节流、延迟、下一帧、滚动动画等高频交互辅助。

### 常量

| 常量 | 值 | 说明 |
|------|----|------|
| `defaultDuration` | 300ms | 默认交互时长 |
| `fastDuration` | 150ms | 快速时长 |
| `slowDuration` | 500ms | 慢速时长 |
| `defaultCurve` | Curves.easeOut | 默认动画曲线 |

### 核心方法

| 方法 | 签名 | 返回 | 说明 |
|------|------|------|------|
| `delay` | `(function, {duration=0})` | `Future<void>` | 延迟执行 |
| `nextFrame` | `(function)` | void | 下一帧执行 |
| `smoothScrollTo` | `(controller, offset, {...})` | `Future<void>` | 平滑滚动到指定位置 |
| `smoothScrollToTop` | `(controller, {...})` | `Future<void>` | 滚到顶部 |
| `smoothScrollToBottom` | `(controller, {...})` | `Future<void>` | 滚到底部 |

### 使用示例

```dart
// 防抖 / 节流用独立类
final search = WDebounce(() {
  api.search(keywordController.text);
}, duration: const Duration(milliseconds: 300));
search();
search(); // 只执行最后一次

final onTap = WThrottle(() => submitForm(), duration: const Duration(seconds: 1));
onTap();
```

> `WUx` 仍提供 `delay` / `nextFrame` / `smoothScrollTo*`（实例方法：`WUx().xxx`），没有 `WUx.instance`。

---

## 11. WValidator - 数据校验

### 功能说明

集合了格式校验、密码强度、身份证合法性等业务校验。

### 格式校验

| 方法 | 说明 |
|------|------|
| `isValidEmail(input)` | 邮箱格式 |
| `isValidPhone(input)` | 大陆手机号 |
| `isValidPassword(input)` | ≥8 位 + 大写 + 小写 + 数字 |
| `isValidUsername(input)` | 3-20 位字母/数字/下划线 |
| `isValidUrl(input)` | URL |
| `isValidIpv4(input)` | IPv4 |
| `isValidIdCard(input)` | 18 位身份证号（校验真实出生日期，不校验末位校验码） |
| `isValidBankCard(input)` | 16-19 位 + Luhn 校验 |
| `isValidChineseName(input)` | 2-20 汉字 |
| `isValidPostalCode(input)` | 6 位邮编 |
| `isValidMacAddress(input)` | MAC 地址 |
| `isValidDate(input)` | 真实日期 |
| `isValidTime(input)` | 时间 |
| `isValidDateTime(input)` | 日期时间 |

### 数字与长度

| 方法 | 说明 |
|------|------|
| `isNumeric(input)` | 数字 |
| `isInteger(input)` | 整数 |
| `isPositive(input)` | 正数 |
| `isNonNegative(input)` | 非负 |
| `isValidPositiveInteger(input)` | 正整数 |
| `isValidDecimal(input)` | 小数 |
| `isValidPositiveDecimal(input)` | 正小数 |
| `isNotBlank(input)` | 非空且不全为空白 |
| `isLengthValid(input, min, max)` | 长度区间校验 |

### 使用示例

```dart
// 表单校验
if (!WValidator.isValidPassword(pwd)) {
  return '密码需要 ≥8 位，包含大小写和数字';
}
if (!WValidator.isValidIdCard(idCard)) {
  return '身份证号不合法';
}

// 链式校验
final ok = WValidator.isNotBlank(name) && WValidator.isLengthValid(name, 3, 20);
```

---

## 12. WMapExtension - Map 扩展

### 功能说明

为 `Map` 提供按键排序和原地合并能力。

### 扩展方法

| 方法 | 说明 |
|------|------|
| `sortedByKeys([compare])` | 返回按键排序的新 Map |
| `merge(other, {overwrite=true})` | 原地合并，返回自身 |

### 使用示例

```dart
final map = {'banana': 2, 'apple': 1, 'cherry': 3};

// 按键排序
final sorted = map.sortedByKeys(); // {'apple': 1, 'banana': 2, 'cherry': 3}
final desc = map.sortedByKeys((a, b) => b.compareTo(a)); // 降序

// 合并
final base = {'a': 1, 'b': 2};
base.merge({'b': 99, 'c': 3}); // base => {'a': 1, 'b': 99, 'c': 3}
base.merge({'b': 0}, overwrite: false); // 不覆盖已有值
```

---

## 13. WNumFormatExtension - 数字格式化

从 `w_tools_ui` 12.0 迁入；与 UI 无关，需要 locale 感知时直接用 `intl`。

```dart
1234.toThousandsSeparated;        // 1,234
1234.5.toCurrency(symbol: '¥');   // ¥1,234.5
0.125.toPercent;                  // 12.5%
42.toPadLeft(5);                  // 00042
```

`toCurrency` 的 `thousandSeparator` / `decimalSeparator` 是纯字符串替换，不做 locale 推断；
科学计数法会先展开为普通十进制，`NaN` / `Infinity` 原样返回。

## 完整配置示例

### 示例 1：启动期一次性配置

```dart
import 'package:w_tools_core/w_tools_core.dart';

Future<void> initializeApp() async {
  // 1. 静态配置（资源路径直接传完整路径，ui 12.0 删除了 WAssets.imagePath）
  WToken.tokenKey = 'app_auth_token';
  WToken.refreshTokenKey = 'app_refresh_token';
  WToken.tokenExpiryKey = 'app_token_expiry';

  // 2. 存储初始化（幂等）
  await WStorage.init();

  // 3. 日志级别（生产可关闭）
  WLogger.setLevel(Level.info);
  // WLogger.turnOff();
}
```

### 示例 2：WStorage + WToken 完整认证流程

```dart
// 登录
Future<void> login(String username, String password) async {
  final response = await authApi.login(username, password);
  final expiresAt = DateTime.now().add(const Duration(hours: 2));
  await WToken.saveTokens(
    response.accessToken,
    response.refreshToken,
    expiresAt,
  );
}

// 请求前判断
Future<void> ensureValidToken() async {
  if (WToken.isTokenValid()) return;

  if (WToken.hasRefreshToken()) {
    final newToken = await authApi.refresh(WToken.getRefreshToken()!);
    await WToken.saveToken(newToken.accessToken, newToken.expiresAt);
    return;
  }

  await WToken.clearAllTokens();
  // 跳登录
}

// 登出
Future<void> logout() async {
  await WToken.clearAllTokens();
  await WStorage.clear();
}
```

---

## 注意事项

### 1. WStorage 读取前需 init

直接调用 `WStorage.getString('key')` 而未先 `await WStorage.init()` 会抛 `StateError`。建议在 `main()` 里一次性初始化。

### 2. WEncrypt 的 Key/IV 须 Base64

`WEncrypt.aesEncrypt` / `aesDecrypt` 传入的 `keyStr` 和 `ivStr` **必须是 Base64 编码字符串**。直接传明文会导致解密失败。使用 `WEncrypt.generateKey()` 和 `WEncrypt.generateIv()` 生成的就是符合要求的 Base64 格式。

---

相关文档：[模块索引](README.md) · [组件目录](components.md) · [接入约定](../conventions.md)
