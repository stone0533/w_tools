# Flutter W Tools

一个基于 Config 开发的功能丰富的 Flutter 工具库，提供了多种实用工具和组件，帮助开发者快速构建高质量的 Flutter 应用。

## 特性

- **组件库**：提供丰富的 UI 组件，涵盖通用组件、输入组件、布局组件和导航组件
- **工具类**：包含加密、验证、日志、存储、网络请求等多种实用工具
- **扩展功能**：提供颜色、字符串、数字、容器等多种扩展方法
- **配置驱动**：采用配置驱动的设计模式，便于定制和扩展
- **响应式设计**：支持屏幕适配，自动适应不同设备尺寸

## 安装

### 从 pub.dev 安装

在 `pubspec.yaml` 文件中添加依赖：

```yaml
dependencies:
  w_tools: ^1.0.5
```

然后运行：

```bash
flutter pub get
```

## 快速开始

### 初始化应用

通过创建 WApp 实例并配置相关参数来初始化应用：

```dart
import 'package:flutter/material.dart';
import 'package:w_tools/w.dart';

void main() async {
  // 创建 WApp 实例
  final app = WApp();
  
  // 设置应用配置
  app.designWidth = 375; // 设计稿宽度
  app.title = 'Flutter App';
  app.initialRoute = '/';
  app.getPages = [
    GetPage(name: '/', page: () => HomePage()),
  ];
  app.orientations = [DeviceOrientation.portraitUp];
  app.envFileName = '.env';
  app.turnOffLog = false;
  
  // 初始化应用
  await app.init();
  
  // 运行应用
  app.run();
}
```

## 核心功能

### 🎯 组件库

#### 通用组件
- **Badge** (`WBadge`): 徽章组件
- **Button** (`WButton`): 多种样式的按钮组件，支持透明度、缩放、震动等点击效果
- **Clip** (`WClip`): 裁剪组件
- **GradientCircularProgressIndicator** (`WGradientCircularProgressIndicator`): 渐变圆形进度指示器
- **Image** (`WImage`): 增强的图片组件
- **KeepAliveWrapper** (`WKeepAliveWrapper`): 保持组件状态的包装器
- **NetworkImageWithRetry** (`WNetworkImageWithRetry`): 带重试机制的网络图片
- **NotificationListener** (`WNotificationListener`): 通知监听器
- **QRCodeScanner** (`WQRCodeScanner`): 二维码扫描组件
- **RowButtons** (`WRowButtons`): 行按钮组件
- **Text** (`WText`): 增强的文本组件
- **TextStyle** (`WTextStyle`): 文本样式工具
- **RichText** (`WRichText`): 富文本组件，支持复杂文本渲染

#### 输入组件
- **FormButton** (`WFormButton`): 表单按钮组件
- **FormCheckbox** (`WFormCheckbox`): 单个复选框字段组件
- **FormBuilder** (`WFormBuilder`): 表单构建器组件
- **FormDropdown** (`WFormDropdown`): 表单下拉选择组件，支持自定义样式和选项
- **FormMultiDropdown** (`WFormMultiDropdown`): 表单多选下拉框组件，支持多项选择和自定义样式配置
- **FormRadioGroup** (`WFormRadioGroup`): 表单单选按钮组组件
- **FormTextField** (`WFormTextField`): 表单单行文本输入组件
- **DatePicker** (`FormBuilderDatePicker`): 表单日期选择器组件

#### 布局组件
- **AppBar** (`WAppBar`): 自定义应用栏组件
- **Container** (`WContainer`): 增强的容器组件，支持多种装饰和变换
- **ListView** (`WListView`): 增强的列表视图组件，支持下拉刷新和上拉加载
- **Scaffold** (`WScaffold`): 增强的脚手架组件
- **Step** (`WStep`): 步骤指示器组件

#### 导航组件
- **NavBar** (`WNavBar`): 可自定义的底部导航栏组件，支持自定义导航项、点击回调和缓存机制
- **TabBar** (`WTabBar`): 增强的标签栏组件，支持自定义样式、指示器和分割线
- **NavController** (`WNavController`): 导航控制器，用于管理导航栏的状态和动画

### 🔌 API 相关
- **Dio 工具** (`WDioUtil`): 基于 Dio 的网络请求工具
- **HTTP 配置** (`WHttpConfig`): HTTP 请求配置
- **拦截器**: 缓存、Cookie、错误处理、日志、令牌等拦截器
- **仓库** (`BaseRepository`): 基础仓库类

### 🔧 工具类

#### 工具类列表
- **加密工具** (`WSecret`): 提供 AES 加密/解密、多种哈希函数（MD5、SHA1、SHA256、SHA512、HMAC-SHA256）、安全随机密钥生成、Base64 编码/解码、密码哈希（PBKDF2）等功能
- **验证工具** (`WValidator`): 提供邮箱、手机号、密码强度、用户名、URL、IP地址、身份证号码、银行卡号、日期时间等多种验证功能，以及防止 SQL 注入和 XSS 攻击的功能
- **日志工具** (`WLogger`): 提供不同级别的日志记录功能
- **倒计时工具** (`WCountdown`): 提供倒计时功能
- **性能监控** (`WPerformance`): 提供性能监控和数据收集功能
- **用户体验** (`WUX`): 提供防抖、节流、平滑滚动等用户体验优化功能
- **配置管理** (`WEnv`): 提供环境变量配置管理功能
- **存储工具** (`WStorage`): 提供本地存储功能
- **弹窗工具** (`WPopup`): 提供弹窗管理功能
- **语言工具** (`WLanguage`): 提供语言管理和切换功能
- **选择器工具** (`WPicker`): 提供选择器功能
- **Toast 工具** (`WToast`): 提供轻量级消息提示功能
- **Future 工具** (`WFuture`): 提供 Future 相关的工具方法
- **平台工具** (`WPlatform`): 提供平台检测和适配功能，支持移动、桌面和 Web 平台的判断，以及平台特定操作的执行
- **正则工具** (`WRegExp`): 提供常用正则表达式
- **GetX 扩展** (`WGet`): 提供 GetX 框架的扩展功能，包括路由管理和弹窗显示

### 📚 扩展功能

#### 扩展方法
- **颜色扩展** (`Color`): 提供颜色转换、十六进制字符串生成等功能
- **字符串扩展** (`String`): 提供字符串格式化、验证、转换等功能
- **数字扩展** (`num`): 提供数字格式化、范围检查等功能
- **容器扩展** (`Widget`): 提供容器装饰、布局调整等功能
- **映射扩展** (`Map`): 提供映射操作、转换等功能
- **行扩展** (`Row`): 提供行布局的便捷操作
- **列扩展** (`Column`): 提供列布局的便捷操作
- **图片扩展** (`Image`): 提供图片加载、处理等功能
- **全局键扩展** (`GlobalKey`): 提供全局键的便捷操作
- **尺寸框扩展** (`SizedBox`): 提供尺寸框的便捷创建
- **内边距扩展** (`Padding`): 提供内边距的便捷添加
- **文本样式扩展** (`TextStyle`): 提供从 WTextConfig 创建 TextStyle 的方法
- **行高样式扩展** (`StrutStyle`): 提供从 WTextConfig 创建 StrutStyle 的方法

## 使用示例

### 使用组件

```dart
import 'package:flutter/material.dart';
import 'package:w_tools/w.dart';

class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WScaffold(
      appBar: WAppBar(
        config: WAppBarConfig(),
        title: '示例页面',
      ),
      body: Center(
        child: Column(
          children: [
            WButton(
              onPressed: () {},
              child: Text('点击我'),
            ),
            WText('这是一个文本组件'),
          ],
        ),
      ),
    );
  }
}
```

### 使用表单组件

```dart
import 'package:w_tools/w.dart';

// 使用多选下拉框
final multiDropdownConfig = WFormMultiDropdownConfig()
  ..height = 50
  ..width = 200
  ..itemStyle = TextStyle(fontSize: 16)
  ..itemCheckedStyle = TextStyle(fontSize: 16, color: Colors.blue)
  ..itemDisabledStyle = TextStyle(fontSize: 16, color: Colors.grey);

WFormMultiDropdown<String> multiDropdown = multiDropdownConfig.build(
  name: 'multi_select',
  items: {'option1': '选项1', 'option2': '选项2', 'option3': '选项3'},
  initialValue: 'option1',
  onChanged: (value) {
    print('选中的值: $value');
  },
);
```

### 使用工具类

```dart
import 'package:w_tools/w.dart';

// 加密解密
String encrypted = WSecret.encryptAES('hello', 'mykey');
String decrypted = WSecret.decryptAES(encrypted, 'mykey');

// 验证
bool isValid = WValidator.isEmail('test@example.com');

// 存储
await WStorage.setString('key', 'value');
String value = await WStorage.getString('key');

// 响应式设计
Container(
  width: 100.w, // 根据设计稿宽度按比例缩放
  height: 50.h, // 根据设计稿高度按比例缩放
  child: Text('响应式布局'),
)
```

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个库。

## 许可证

MIT License