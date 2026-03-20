# Flutter W Tools

一个基于Config开发的功能丰富的 Flutter 工具库，提供了多种实用工具和组件，帮助开发者快速构建高质量的 Flutter 应用。

## 特性

### 🔧 工具类
- **加密工具** (`WSecret`): 提供 AES 加密/解密、哈希函数、安全随机密钥生成等功能
- **验证工具** (`WValidator`): 提供邮箱、手机号、密码强度等多种验证功能
- **日志工具** (`WLogger`): 提供不同级别的日志记录功能
- **倒计时工具** (`WCountdown`): 提供倒计时功能
- **性能监控** (`WPerformance`): 提供性能监控和数据收集功能
- **用户体验** (`WUX`): 提供防抖、节流、平滑滚动等用户体验优化功能
- **错误处理** (`WErrorHandler`): 提供统一的错误处理机制
- **配置管理** (`WEnv`): 提供环境变量配置管理功能

### 🎨 主题系统
- **主题管理** (`WThemeManager`): 支持亮色主题、暗色主题和跟随系统主题
- **主题配置** (`WThemeConfig`): 提供自定义主题配置功能

### 🌍 国际化
- **多语言支持** (`WTranslations`): 支持中文和英文两种语言
- **语言切换**: 支持动态切换语言

### 📱 平台适配
- **平台检测** (`WPlatform`): 支持检测不同平台（Android、iOS、Web、Linux、macOS、Windows）
- **平台特定代码**: 支持执行平台特定的代码

### 🧩 插件系统
- **插件接口** (`WPlugin`): 定义插件接口
- **插件管理** (`WPluginManager`): 管理插件的生命周期

### 📦 API 管理
- **网络请求** (`WRequest`): 基于 Dio 的网络请求封装
- **拦截器**: 提供缓存、Cookie、错误处理、日志、Token 等拦截器
- **响应处理**: 统一的响应格式和错误处理

### 🎯 组件库
- **按钮** (`WButton`): 多种样式的按钮组件
- **输入框** (`WTextField`): 功能丰富的文本输入组件
- **表单** (`WForm`): 表单构建和验证
- **布局** (`WLayout`): 常用布局组件
- **通用组件**: 徽章、图片、文本、QR 码扫描等

## 安装

### 从 pub.dev 安装

在 `pubspec.yaml` 文件中添加依赖：

```yaml
dependencies:
  flutter_w_tools: ^1.0.0
```

### 从本地安装

在 `pubspec.yaml` 文件中添加依赖：

```yaml
dependencies:
  flutter_w_tools:
    path: /path/to/flutter_w_tools
```

然后运行：

```bash
flutter pub get
```

## 快速开始

### 初始化应用

```dart
import 'package:w_tools_tools/flutter_w_tools.dart';

void main() async {
  // 初始化应用
  await WApp.init(
    orientations: [DeviceOrientation.portraitUp],
    envFileName: '.env',
    turnOffLog: false,
  );
  
  // 运行应用
  WApp.run(
    375, // 设计稿宽度
    title: 'Flutter App',
    initialRoute: '/',
    getPages: [
      GetPage(name: '/', page: () => HomePage()),
    ],
  );
}
```

## 使用示例

### 加密工具

```dart
import 'package:w_tools_tools/flutter_w_tools.dart';

// 生成安全的随机密钥
final key = WSecret.generateSecureKey();

// 加密数据
final plainText = 'Hello, World!';
final encrypted = WSecret.encryptAES(plainText, keyStr: key);

// 解密数据
final decrypted = WSecret.decryptAES(encrypted, keyStr: key);
print(decrypted); // 输出: Hello, World!

// 密码哈希
final password = 'Password123';
final hash = WSecret.hashPassword(password);
print(hash);

// 验证密码
final isValid = WSecret.verifyPassword(password, hash);
print(isValid); // 输出: true
```

### 验证工具

```dart
import 'package:w_tools_tools/flutter_w_tools.dart';

// 验证邮箱
final email = 'test@example.com';
final isEmailValid = WValidator.isValidEmail(email);
print(isEmailValid); // 输出: true

// 验证手机号
final phone = '13800138000';
final isPhoneValid = WValidator.isValidPhone(phone);
print(isPhoneValid); // 输出: true

// 验证密码强度
final password = 'Password123';
final isPasswordValid = WValidator.isValidPassword(password);
print(isPasswordValid); // 输出: true

// 防止 SQL 注入
final input = "' OR 1=1; --";
final sanitized = WValidator.preventSqlInjection(input);
print(sanitized);

// 防止 XSS 攻击
final xssInput = '<script>alert("XSS")</script>';
final sanitizedXss = WValidator.preventXss(xssInput);
print(sanitizedXss);
```

### 主题系统

```dart
import 'package:w_tools_tools/flutter_w_tools.dart';

// 获取当前主题
final theme = WThemeManager().currentTheme;

// 切换主题模式
await WThemeManager().setThemeMode(WThemeMode.dark);

// 自定义主题
final customLightTheme = WThemeConfig(
  primaryColor: Colors.blue,
  secondaryColor: Colors.green,
  backgroundColor: Colors.white,
  // ... 其他颜色配置
);
await WThemeManager().setLightTheme(customLightTheme);

// 监听主题变更
WThemeManager().addListener((theme) {
  // 主题变更时的回调
  print('Theme changed');
});
```

### 国际化

```dart
import 'package:w_tools_tools/flutter_w_tools.dart';
import 'package:get/get.dart';

// 在 GetMaterialApp 中配置
GetMaterialApp(
  translations: WTranslations(),
  locale: WLocale.defaultLocale,
  fallbackLocale: WLocale.fallbackLocale,
  // ... 其他配置
);

// 使用国际化字符串
Text('hello'.tr); // 输出: 你好 (中文) 或 Hello (英文)

// 切换语言
Get.updateLocale(Locale('en', 'US'));
```

### 性能监控

```dart
import 'package:w_tools_tools/flutter_w_tools.dart';

// 监控函数执行时间
final duration = await WPerformance().monitor('network_request', () async {
  // 模拟网络请求
  await Future.delayed(Duration(seconds: 1));
  return 'success';
});
print('Network request took $duration ms');

// 手动监控
final id = WPerformance().start('heavy_task');
// 执行耗时操作
await Future.delayed(Duration(milliseconds: 500));
final taskDuration = WPerformance().end('heavy_task', id);
print('Heavy task took $taskDuration ms');
```

### 用户体验优化

```dart
import 'package:w_tools_tools/flutter_w_tools.dart';

// 防抖
final debouncedFunction = WUX().debounce(() {
  // 执行搜索操作
  print('Searching...');
}, duration: 500);

// 调用防抖函数
debouncedFunction();
debouncedFunction(); // 只会执行一次

// 节流
final throttledFunction = WUX().throttle(() {
  // 执行滚动操作
  print('Scrolling...');
}, duration: 100);

// 调用节流函数
throttledFunction();
throttledFunction(); // 在 100ms 内只会执行一次

// 平滑滚动
final scrollController = ScrollController();
await WUX().smoothScrollToTop(scrollController);
```

### 平台适配

```dart
import 'package:w_tools_tools/flutter_w_tools.dart';

// 检测平台
if (WPlatform.isMobile) {
  // 移动平台特定代码
} else if (WPlatform.isDesktop) {
  // 桌面平台特定代码
} else if (WPlatform.isWeb) {
  // Web 平台特定代码
}

// 获取平台特定的值
final platformValue = WPlatform.getPlatformValue(
  android: 'Android',
  ios: 'iOS',
  web: 'Web',
  desktop: 'Desktop',
  fallback: 'Unknown',
);
print(platformValue);

// 执行平台特定的操作
WPlatform.executePlatformAction(
  android: () => print('Android specific action'),
  ios: () => print('iOS specific action'),
  web: () => print('Web specific action'),
  desktop: () => print('Desktop specific action'),
  fallback: () => print('Unknown platform action'),
);
```

### 插件系统

```dart
import 'package:w_tools_tools/flutter_w_tools.dart';

// 创建插件
class MyPlugin implements WPlugin {
  @override
  String get name => 'my_plugin';
  
  @override
  String get version => '1.0.0';
  
  @override
  Future<void> initialize() async {
    print('Initializing MyPlugin');
    // 初始化插件
  }
  
  @override
  Future<void> dispose() async {
    print('Disposing MyPlugin');
    // 销毁插件
  }
}

// 注册插件
WPluginManager().registerPlugin(MyPlugin());

// 初始化所有插件
await WPluginManager().initializeAll();

// 获取插件
final myPlugin = WPluginManager().getPlugin<MyPlugin>('my_plugin');

// 销毁所有插件
await WPluginManager().disposeAll();
```

### 网络请求

```dart
import 'package:w_tools_tools/flutter_w_tools.dart';

// 发送 GET 请求
final response = await WRequest.get('/api/users');
print(response.data);

// 发送 POST 请求
final postResponse = await WRequest.post('/api/users', data: {
  'name': 'John Doe',
  'email': 'john@example.com',
});
print(postResponse.data);

// 发送带参数的请求
final paramsResponse = await WRequest.get('/api/users', params: {
  'page': 1,
  'limit': 10,
});
print(paramsResponse.data);
```

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个库。

## 许可证

MIT License