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
- 防抖 / 节流 → `WUx`
- 可运行示例：[packages/core/example](../../packages/core/example/README.md)

- 强制规则：根 [`AGENTS.md`](../../AGENTS.md)

---

## 模块结构

```
core/
├── w_tools_core.dart        # barrel 导出
└── src/
    ├── config.dart          # WConfig 弃用代理（键名已迁到 WToken）
    ├── extensions/
    │   └── map.dart         # WMapExtension
    └── utils/
        ├── countdown.dart   # WCountdown
        ├── encrypt.dart     # WEncrypt
        ├── hash.dart        # WHash
        ├── logger.dart      # WLogger + 顶层函数 logT/logD/logI/logW/logE/logF
        ├── platform.dart    # WPlatform, WPlatformType
        ├── reg_exp.dart     # WRegExp（WRegExpPattern / WRegExpPreset 已弃用）
        ├── storage.dart     # WStorage
        ├── token.dart       # WToken
        ├── ux.dart          # WUx, WCancellableAction
        └── validator.dart   # WValidator
```

---

## 1. WToken 键名 / WConfig（弃用）

### 功能说明

集中管理模块内通用的键名和路径常量。所有字段为可修改的静态变量，建议在应用启动时一次性配置。

> ⚠️ `assetImagePath` 已废弃且**不再产生任何效果**（从未被读取）。资源前缀的唯一开关是
> `w_tools_ui` 的 `WAssets.imagePath`；根聚合包导出的是 `core.WConfig`，仅 token 键名有效。

### 配置字段

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `assetImagePath` | String | `'assets/images/'` | **已废弃**，无效；请用 `WAssets.imagePath` |
| `tokenKey` | String | — | Token 存储键名 |
| `refreshTokenKey` | String | — | 刷新 Token 存储键名 |
| `tokenExpiryKey` | String | — | Token 过期时间存储键名 |

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
| `WCountdown({callback, onComplete})` | 构造函数 | `callback` 每秒触发，`onComplete` 结束触发 |
| `start(second)` | void | 开始倒计时 |
| `pause()` | void | 暂停 |
| `resume()` | void | 恢复 |
| `stop()` | void | 停止 |
| `dispose()` | void | 释放资源（停止并清空监听） |
| `formatRemaining({type})` | String | `MM:SS`（默认）或纯 `SS` 格式 |

### 使用示例

```dart
final countdown = WCountdown(
  callback: (remaining) {
    print('剩余 $remaining 秒');
    print('格式化: ${countdown.formatRemaining()}'); // MM:SS
  },
  onComplete: () => print('倒计时结束'),
);

countdown.start(60);  // 60 秒倒计时
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
| `hashPassword(password, {salt})` | String | **已弃用（3.0 移除）**：密码哈希应在服务端用 bcrypt/argon2 |
| `verifyPassword(password, hash)` | bool | 密码验证 |

### 使用示例

```dart
// 普通哈希
final digest = WHash.md5('hello');
final sha = WHash.sha256('hello');
final hmac = WHash.hmacSha256('data', 'secret_key');

// 密码安全存储
final stored = WHash.hashPassword('my_password'); // "sha256$Ab12...$xxx"
final ok = WHash.verifyPassword('my_password', stored); // true
final bad = WHash.verifyPassword('wrong_password', stored); // false
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
| `startPerformance(name)` | 开始性能计时 |
| `stopPerformance(name)` | 停止并输出计时 |
| `cancelPerformance(name)` | 取消计时 |
| `getActivePerformanceTimers()` | 获取活跃计时器名称 |
| `measureSync(name, fn)` | 同步函数计时（自动 start+stop） |

### 顶层便捷函数

| 函数 | 对应级别 |
|------|----------|
| `logT / logD / logI / logW / logE / logF` | Trace → Fatal |

### 使用示例

```dart
// 设置级别
WLogger.setLevel(Level.verbose);
// WLogger.turnOff();  // 生产环境关闭

// 常规日志
WLogger.i('应用启动', tag: 'APP');
WLogger.w('配置项缺失', tag: 'CONFIG');
logE('网络请求失败', error: exception, tag: 'API');

// 性能计时
WLogger.startPerformance('heavy_op');
await heavyOperation();
WLogger.stopPerformance('heavy_op'); // 自动输出耗时

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

### 方法列表

| 方法 | 签名 | 说明 |
|------|------|------|
| `getPlatformValue<T>` | `({android, ios, web, desktop, fallback}) → T` | 按平台返回对应值 |
| `runForPlatform` | `({android, ios, web, desktop, fallback}) → void` | 按平台执行对应回调 |

### 使用示例

```dart
// 属性判断
if (WPlatform.isWeb) {
  print('运行在浏览器');
}

// 值分发
final fontSize = WPlatform.getPlatformValue<double>(
  android: 14,
  ios: 15,
  web: 16,
  desktop: 14,
  fallback: 14,
);

// 行为分发
WPlatform.runForPlatform(
  android: () => print('Android 特定逻辑'),
  ios: () => print('iOS 特定逻辑'),
  web: () => print('Web 特定逻辑'),
  desktop: () => print('桌面端逻辑'),
  fallback: () => print('兜底逻辑'),
);
```

---

## 7. WRegExp - 正则工具

### 功能说明

提供预置的正则模式常量、预编译实例、以及身份证/手机号/银行卡等业务数据的提取与格式化。

### WRegExpPattern（静态常量字符串，已弃用）

> 2.2 起用 `WRegExp`（预编译 RegExp）；本类 3.0 移除，字符串形式的规则请自行维护。

| 分类 | 模式 | 说明 |
|------|------|------|
| 身份 | `password` | 密码（≥8位+大小写数字） |
| 身份 | `email` | 邮箱 |
| 身份 | `phone` | 大陆手机号 |
| 身份 | `idCard` | 18 位身份证号 |
| 身份 | `chineseName` | 2-20 汉字 |
| 网络 | `url` | URL |
| 网络 | `ipv4` | IPv4 地址 |
| 网络 | `mac` | MAC 地址 |
| 数字 | `number` | 数字 |
| 数字 | `integer` | 整数 |
| 数字 | `positive` | 正数 |
| 数字 | `positiveInteger` | 正整数 |
| 数字 | `decimal` | 小数 |
| 数字 | `positiveDecimal` | 正小数 |
| 其他 | `date` | 日期 |
| 其他 | `bankCard` | 银行卡号 |
| 其他 | `postalCode` | 邮政编码 |

### WRegExpPreset（按分类的 Map，已弃用）

> 2.2 起用 `WRegExp`；本类 3.0 移除。

| 分类键 | 包含模式 |
|--------|----------|
| `personal` | password / email / phone / idCard / chineseName |
| `network` | url / ipv4 / mac |
| `number` | number / integer / positive / positiveInteger / decimal / positiveDecimal |
| `misc` | date / bankCard / postalCode |

### WRegExp（预编译实例 + 便捷方法）

预编译的 `RegExp` 实例（如 `WRegExp.email`、`WRegExp.phone`）以及以下方法：

| 方法 | 说明 |
|------|------|
| `firstXxxMatch(input)` | 返回第一个匹配的字符串（如 `firstEmailMatch`、`firstPhoneMatch`） |
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
final phone = WRegExp.firstPhoneMatch('联系我 13812345678 或 13987654321');
print(phone); // "13812345678"（第一个匹配）

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
| `getObject<T>(key, fromJson)` | `setObject(key, value)` | JSON 对象 |

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

// 对象存取（JSON 编解码）
await WStorage.setObject('profile', user);
final user = WStorage.getObject<User>('profile', User.fromJson);

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
// 启动时先 init WStorage + 配置 WConfig
await WStorage.init();
WConfig.tokenKey = 'auth_token';
WConfig.refreshTokenKey = 'auth_refresh_token';
WConfig.tokenExpiryKey = 'auth_token_expiry';

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
| `debounce` | `(function, {duration=300})` | `WCancellableAction` | 防抖 |
| `throttle` | `(function, {duration=300})` | `WCancellableAction` | 节流 |
| `delay` | `(function, {duration=0})` | `Future<void>` | 延迟执行 |
| `nextFrame` | `(function)` | void | 下一帧执行 |
| `smoothScrollTo` | `(controller, offset, {...})` | `Future<void>` | 平滑滚动到指定位置 |
| `smoothScrollToTop` | `(controller, {...})` | `Future<void>` | 滚到顶部 |
| `smoothScrollToBottom` | `(controller, {...})` | `Future<void>` | 滚到底部 |

### WCancellableAction

| 方法 | 说明 |
|------|------|
| `call()` | 执行原始函数 |
| `cancel()` | 取消挂起的执行 |

### 使用示例

```dart
// 搜索框防抖
final search = WUx.instance.debounce((keyword) {
  api.search(keyword);
}, duration: const Duration(milliseconds: 300));

search('flutter');
search('dart'); // 上一个被取消，只执行最后一次

// 按钮节流
final onTap = WUx.instance.throttle(() {
  submitForm();
}, duration: const Duration(seconds: 1));

// 延迟 + 取消
final delayed = WUx.instance.delay(() {
  print('3 秒后执行');
}, duration: const Duration(seconds: 3));
// delayed.cancel(); // 需要时取消

// 滚动
await WUx.instance.smoothScrollToTop(scrollController);
```

---

## 11. WValidator - 表单验证与安全清洗

### 功能说明

集合了格式校验、密码强度、身份证合法性、以及基础的 SQL/HTML 清洗工具。

### 格式校验

| 方法 | 说明 |
|------|------|
| `isEmail(input)` | 邮箱格式 |
| `isPhone(input)` | 大陆手机号 |
| `isValidPassword(input)` | ≥8 位 + 大写 + 小写 + 数字 |
| `isValidUsername(input)` | 3-20 位字母/数字/下划线 |
| `isValidUrl(input)` | URL |
| `isValidIPv4(input)` | IPv4 |
| `isValidIdCard(input)` | 18 位身份证号（带真实日期校验） |
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

### 安全清洗

| 方法 | 说明 |
|------|------|
| `escapeSql(input)` | **已弃用（3.0 移除）**：基础 SQL 特殊字符替换，不能替代参数化查询 |
| `stripHtml(input)` | **已弃用（3.0 移除）**：移除标签，不能替代 HTML 转义 |

### 注意事项

`escapeSql` 仅作**基础字符替换**，不替代参数化查询。涉及数据库操作请使用预编译语句。

### 使用示例

```dart
// 表单校验
if (!WValidator.isValidPassword(pwd)) {
  return '密码需要 ≥8 位，包含大小写和数字';
}
if (!WValidator.isValidIdCard(idCard)) {
  return '身份证号不合法';
}

// 安全清洗
final safeSql = WValidator.escapeSql(userInput);
final cleanHtml = WValidator.stripHtml(dirtyHtml);

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

## 完整配置示例

### 示例 1：启动期一次性配置

```dart
import 'package:w_tools_core/w_tools_core.dart';

Future<void> initializeApp() async {
  // 1. 静态配置（资源前缀请用 w_tools_ui 的 WAssets.imagePath）
  WConfig.tokenKey = 'app_auth_token';
  WConfig.refreshTokenKey = 'app_refresh_token';
  WConfig.tokenExpiryKey = 'app_token_expiry';

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

### 3. WValidator 安全方法仅基础清洗

`escapeSql` 和 `stripHtml` 是**基础防护**，不替代：

- SQL：必须使用参数化查询 / ORM 预编译；
- HTML：生产环境请使用专业包（如 `vader` / `html_whitelist`）做严格白名单过滤。

### 4. WConfig 是全局可变单例

`WConfig` 的字段在运行时可被重新赋值。如果你的应用存在多入口或测试场景，请注意隔离：测试前先重置配置。

---

相关文档：[模块索引](README.md) · [组件目录](components.md) · [接入约定](../conventions.md)
