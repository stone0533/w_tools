# Flutter W Tools

[![CI](https://github.com/stone0533/w_tools/actions/workflows/ci.yml/badge.svg)](https://github.com/stone0533/w_tools/actions/workflows/ci.yml)

一个基于 Config 开发的功能丰富的 Flutter 工具库，提供了多种实用工具和组件，帮助开发者快速构建高质量的 Flutter 应用。

## 特性

- **组件库**：提供丰富的 UI 组件，涵盖通用组件、输入组件、布局组件和导航组件
- **工具类**：包含加密、验证、日志、存储、网络请求等多种实用工具
- **扩展功能**：提供颜色、字符串、数字、容器等多种扩展方法
- **配置驱动**：采用配置驱动的设计模式，便于定制和扩展
- **响应式设计**：支持屏幕适配，自动适应不同设备尺寸

## 文档

| 文档 | 内容 |
|------|------|
| [docs/modules/README.md](docs/modules/README.md) | 模块文档索引、依赖矩阵、SDK 速查 |
| [docs/modules/components.md](docs/modules/components.md) | 组件目录（先查这里），含「不要用在哪」 |
| [docs/conventions.md](docs/conventions.md) | 接入约定：包 / 暂存层 / 业务层判定与 doctor 规则 |
| [CONTRIBUTING.md](CONTRIBUTING.md) | 新增/修改组件的硬性要求 |
| [docs/releasing.md](docs/releasing.md) | 发版流程与发布脚本 |
| [docs/adr/](docs/adr/) | 架构决策（版本策略、依赖子包） |
| [packages/cli/README.md](packages/cli/README.md) | `init` / `doctor` CLI |

> `docs/modules/` 面向使用者，`docs/` 顶层面向维护者/agent；`docs/` 不随 pub 发布会
>（已在根 `.pubignore` 排除）。

## 安装

> ℹ️ **发布状态**：8 个 Flutter 子包与聚合包 `w_tools` 已发布到 pub.dev；
> `w_tools_cli` 是独立的纯 Dart 工具包，发布状态见 pub.dev。
> 根包 `w_tools` 自 2.0.0 起是**聚合包**，依赖 8 个 Flutter 子包，只 re-export 子包能力；
> 各包按其当前主版本约束（见根 `pubspec.yaml`，本文不硬编码版本号）。
> 只想要部分能力时，建议直接引入对应子包，避免把 GetX / 地图 / 扫码等依赖一并带入。

### 本地开发 / 跨仓库接入

**本地 / 同仓库开发 —— path 依赖：**

```yaml
dependencies:
  w_tools:
    path: ../github_w_tools
```

**跨仓库使用 —— Git 依赖**（需锁定 `ref`；Git 依赖不支持版本号解析）：

```yaml
dependencies:
  w_tools:
    git:
      url: https://github.com/stone0533/w_tools
      ref: main
```

> 只想用某个子包时同理：把 `path` 指向仓库内的 `packages/ui`、`packages/core` 等。

### 推荐：只依赖用到的子包（不要依赖聚合包）

聚合包会把 `w_tools_map` 的 `google_maps_flutter` 原生 SDK 一起拖进构建。
不用地图的项目请直接依赖子包，并在项目里放一个聚合入口：

```yaml
dependencies:
  w_tools_core: ^1.0.0
  w_tools_ui: ^2.0.0
  w_tools_form: ^1.0.0
  # 需要再加 w_tools_app / api / toast / qr / map
```

模板与理由：[`packages/cli/templates/`](packages/cli/templates/)、[`docs/conventions.md`](docs/conventions.md)、
[ADR-0002](docs/adr/0002-consumers-depend-on-subpackages.md)。

更省事的做法是用 CLI 生成（聚合入口、暂存层 README、`AGENTS.md` 片段一次装好）。
CLI 在独立的纯 Dart 包里，不需要先引入聚合包：

```yaml
dev_dependencies:
  w_tools_cli: ^1.1.0
```

```bash
dart run w_tools_cli:init      # 生成到当前项目
dart run w_tools_cli:doctor    # 之后随时检查是否守约定
```

### 从 pub.dev 安装

各子包独立发布，可只引入需要的包；根包 `w_tools` 也作为聚合包发布。

```yaml
dependencies:
  w_tools_core: ^1.0.0   # 只引子包
  w_tools_ui: ^2.0.0
```

或一键引入聚合包（会带上全部 8 个 Flutter 子包及其依赖）：

```yaml
dependencies:
  w_tools: ^2.0.0
```

然后运行：

```bash
flutter pub get
```

### 依赖与子包说明（选依赖前请先读）

`w_tools` 是**聚合包**，直接依赖以下 8 个 Flutter 子包，方便一键引入：

| 子包 | 职责 |
|---|---|
| `w_tools_core` | 工具类、扩展方法、全局配置 |
| `w_tools_ui` | UI 组件（`WText` / `WImage` / `WButton` / `WScaffold` / `WAppBar` / `WListView` / `WNavBar` 等） |
| `w_tools_form` | 表单组件（`WFormTextField` / `WFormDropdown` / `WFormCheckbox` / `WFormBorder` 等） |
| `w_tools_api` | 网络请求（`DioRegistry` / `BaseOptions` / 各类拦截器 / `BaseRepository`） |
| `w_tools_toast` | 轻量提示（`WToast`） |
| `w_tools_qr` | 二维码扫描（`WQrView`） |
| `w_tools_map` | 地图相关 |
| **`w_tools_app`** | 应用启动器（`WApp`）、插件契约（`WAppPlugin`）、路由观察者、`WRoute` |

> ⚠️ **`w_tools_app` 强依赖 GetX，且不可替换。**
>
> - `WApp.run()` 内部构建的根组件就是 `GetMaterialApp`
> - `run()` / `start()` 的 `initialRoute` / `getPages` / `translations` / `locale` / `defaultTransition` 参数均为 GetX 类型
> - `WRoute` 基于 GetX（`WRouteObserver` 本身不依赖 GetX，但与 `WRoute` 配套使用）
>
> **换句话说：使用启动器 = 你的项目必须使用 GetX。**

因此请按需选择引入方式（下例为**发布后**的版本约束写法；发布前请改用上面的 path / git 写法）：

**① 只用组件 / 工具，且不想引入 GetX** —— 按需导入子包，不要用根包 `w_tools`：

```yaml
dependencies:
  w_tools_ui: ^2.0.0     # 只用 UI 组件
  w_tools_core: ^1.0.0   # 只用工具类与扩展
```

```dart
import 'package:w_tools_ui/w_tools_ui.dart';
import 'package:w_tools_core/w_tools_core.dart';
```

**② 要用 `WApp` 启动器，或想一键使用聚合能力** —— 导入根包，并接受 GetX 作为依赖：

```yaml
dependencies:
  w_tools: ^2.0.0
```

```dart
import 'package:w_tools/w.dart';
```

> **版本策略**：8 个 Flutter 子包与 `w_tools_cli` 各自独立发版，互不跟随（具体版本以
> 各包 `pubspec.yaml` 与 pub.dev 为准，不在本文硬编码）；根包按聚合层版本独立发布，
> 其依赖约束为各子包 `^1.x`。发版流程与自动校验见 `docs/releasing.md`。

## 快速开始

### 初始化应用

使用**一站式入口 `start()`**（等价于 `init()` + `run()`），它保证 `runApp` 之前的所有准备
（系统设置、插件初始化）都已完成：

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:w_tools/w.dart';

void main() async {
  final app = WApp()..title = 'Flutter App';

  // 可选：声明式注入第三方能力（自定义插件见下方「生命周期与插件」）
  // app.addPlugins([MyAppPlugin()]);

  // 可选：在最外层包裹 app（例如 ScreenUtilInit、MediaQuery 覆盖、全局手势）
  // 注意 w_tools 不内置 ScreenUtil，需要时请自行引入 flutter_screenutil：
  // app.appWrapper = (child) => ScreenUtilInit(
  //       designSize: const Size(375, 0),
  //       child: child,
  //     );

  // 一站式启动：内部先 init()（系统设置 + 插件 onInit），再 run()
  await app.start(
    initialRoute: '/',
    getPages: [GetPage(name: '/', page: () => HomePage())],
  );
}
```

> `start()` 的等价写法是 `await app.init(); app.run();`。
> 但请注意 **`run()` 之前必须先 `init()`**，否则会抛 `StateError` ——
> 插件初始化（`.env` 加载、业务服务、原生闪屏保留等）都在 `init()` 里完成，
> 遗漏会导致难以定位的启动时序问题（数据未加载、首屏拿不到实例、闪屏异常等）。

### 生命周期与插件

启动阶段的执行顺序：

```text
WidgetsFlutterBinding.ensureInitialized()
→ 系统设置（状态栏、屏幕方向）
→ 插件 onInit（按 dependsOn 分层：同层并行、跨层串行）
→ 首帧后 onLazyInit 回调
→ runApp(appWrapper(插件 wrapApp 链 → GetMaterialApp))
```

自定义插件：

```dart
class MyAppPlugin extends WAppPlugin {
  @override
  String get name => 'my-plugin';

  /// 声明依赖：本插件会在名为 'env' 的插件之后初始化
  @override
  List<String> get dependsOn => const ['env'];

  /// 初始化阶段（ensureInitialized 之后、runApp 之前）
  @override
  Future<void> onInit() async {
    await MyService.init();
  }

  /// 包裹 GetMaterialApp 的 builder（如 BotToastInit）
  @override
  TransitionBuilder? get builderWrapper => null;

  /// 包裹整个 app（如 ScreenUtilInit、全局手势）
  @override
  Widget wrapApp(Widget child) => child;

  /// 追加路由观察者
  @override
  List<NavigatorObserver> get navigatorObservers => [];
}
```

> **插件间有依赖时请用 `dependsOn` 声明，不要依赖 `addPlugins` 的注册顺序** ——
> 同一层的插件是**并行**执行的，注册顺序不产生任何顺序保证。
> 依赖了未注册的插件名或存在循环依赖时，`init()` 会抛出 `StateError` 并指出问题插件。

## 核心功能

### 🎯 组件库

#### 通用组件
- **Badge** (`WBadge`): 徽章组件
- **Button** (`WButton`): 多种样式的按钮组件，支持透明度、缩放、震动等点击效果
- **Clip** (`WClipRRect`): 圆角裁剪组件
- **GradientCircularProgressIndicator** (`WGradientCircularProgressIndicator`): 渐变圆形进度指示器
- **Image** (`WImage`): 增强的图片组件（网络图支持自动重试与 `WImageController` 手动重试）
- **KeepAliveWrapper** (`WKeepAliveWrapper`): 保持组件状态的包装器
- **NotificationListener** (`WNotificationListenerBuilder`): 通知监听器构建器
- **QrView** (`WQrView`): 二维码扫描组件（来自 `w_tools_qr` 子包）
- **RowButtons** (`WRowButtons`): 行按钮组件
- **Text** (`WText`): 增强的文本组件
- **TextStyle** (`WTextStyleExtension`): 由 `WTextConfig` 创建 `TextStyle` 的扩展
- **RichText** (`WRichText`): 富文本组件，支持复杂文本渲染

#### 输入组件
- **FormButton** (`WFormButton`): 表单按钮组件
- **FormCheckbox** (`WFormCheckbox`): 单个复选框字段组件
- **FormBuilder** (`WFormBuilder`): 表单构建器组件
- **FormDropdown** (`WFormDropdown`): 表单下拉选择组件，支持自定义样式和选项
- **FormMultiDropdown** (`WFormMultiDropdown`): 表单多选下拉框组件，支持多项选择和自定义样式配置
- **FormRadioGroup** (`WFormRadioGroup`): 表单单选按钮组组件
- **FormTextField** (`WFormTextField`): 表单单行文本输入组件
- **DatePicker** (`WFormDatePicker`): 表单日期选择器组件

#### 布局组件
- **AppBar** (`WAppBar`): 自定义应用栏组件
- **ListView** (`WListView`): 增强的列表视图组件，支持普通/分隔线/网格布局、头尾组件、子项重叠与空列表占位
- **Scaffold** (`WScaffold`): 增强的脚手架组件
- **Step** (`WStep`): 步骤指示器组件

#### 导航组件
- **NavBar** (`WNavBar`): 可自定义的底部导航栏组件，支持自定义导航项、点击回调和缓存机制
- **TabBar** (`WTabBar`): 增强的标签栏组件，支持自定义样式、指示器和分割线
- **NavController** (`WNavController`): 导航控制器，用于管理导航栏的状态和动画

### 🔌 API 相关
- **Dio 工具** (`DioRegistry`): 基于 Dio 的网络请求工具，按 `baseUrl` 缓存实例
- **Dio 基础配置** (`WApiConfig.baseOptions`): 全局默认 `BaseOptions`
- **拦截器**: 日志 (`WLogInterceptor`)、令牌 (`WTokenInterceptor`)
- **仓库** (`BaseRepository`): 基础仓库类

### 🔧 工具类

#### 工具类列表
- **加密工具** (`WEncrypt`): 提供 AES 加密/解密、安全随机密钥与 IV 生成、Base64 编码/解码
- **哈希工具** (`WHash`): 提供 MD5、SHA1、SHA256、SHA512、HMAC-SHA256 与加盐密码哈希
- **验证工具** (`WValidator`): 提供邮箱、手机号、密码强度、用户名、URL、IP地址、身份证号码、银行卡号、日期时间等验证功能，以及基础的 SQL 注入 / XSS 字符清洗（不能替代参数化查询与输出转义）
- **日志工具** (`WLogger`): 提供不同级别的日志记录功能
- **倒计时工具** (`WCountdown`): 提供倒计时功能
- **用户体验** (`WUx`): 提供防抖、节流、平滑滚动等用户体验优化功能
- **存储工具** (`WStorage`): 提供本地存储功能
- **弹窗工具** (`WFormPopup.show` / `WFormPopupRoute`): 提供从触发控件下方弹出的自定义路由
- **语言工具** (`WLanguage`): 提供语言管理和切换功能
- **Toast 工具** (`WToast`): 提供轻量级消息提示功能
- **异步工具** (`WAsync`): 提供单个/批量 Future 的加载、重试、超时、并发控制与错误处理
- **平台工具** (`WPlatform`): 提供平台检测和适配功能，支持移动、桌面和 Web 平台的判断，以及平台特定操作的执行
- **正则工具** (`WRegExp`): 提供常用正则表达式
- **路由工具** (`WRoute`): 基于 GetX 的路由栈管理（记录、按名称移除/回退）

### 📚 扩展功能

#### 扩展方法
- **颜色扩展** (`HexColor`): 提供颜色转换、十六进制字符串生成等功能
- **字符串扩展** (`WStringExtension`): 提供字符串格式化、验证、转换等功能
- **数字扩展** (`WNumExtension`): 提供数字格式化、范围检查等功能
- **容器扩展** (`WWidgetExtension`): 提供容器装饰、布局调整等功能
- **映射扩展** (`WMapExtension`): 提供映射操作、转换等功能
- **行扩展** (`WRow` / `WRowExtension`): 提供行布局的便捷操作
- **列扩展** (`WColumn` / `WColumnExtension`): 提供列布局的便捷操作
- **图片扩展** (`WImageExtension`): 提供图片加载、处理等功能
- **全局键扩展** (`WGlobalKeyExtension`): 提供全局键的便捷操作
- **尺寸框扩展** (`WSizeBox`): 提供尺寸框的便捷创建
- **内边距扩展** (`WPadding`): 提供内边距的便捷添加
- **文本样式扩展** (`WTextStyleExtension`): 提供从 WTextConfig 创建 TextStyle 的方法
- **行高样式扩展** (`WStrutStyleExtension`): 提供从 WTextConfig 创建 StrutStyle 的方法

## 使用示例

### 使用组件

```dart
import 'package:flutter/material.dart';
import 'package:w_tools/w.dart';

class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WScaffold(
      body: Column(
        children: [
          WAppBar(title: '示例页面'),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  WButton(
                    onTap: () {},
                    child: WText(text: '点击我'),
                  ),
                  WText(text: '这是一个文本组件'),
                ],
              ),
            ),
          ),
        ],
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

WFormMultiDropdown multiDropdown = multiDropdownConfig.build(
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

// 加密解密（keyStr 须为 Base64 编码的密钥）
final key = WEncrypt.generateKey();
String encrypted = WEncrypt.aesEncrypt('hello', keyStr: key);
String decrypted = WEncrypt.aesDecrypt(encrypted, keyStr: key);

// 验证
bool isValid = WValidator.isValidEmail('test@example.com');

// 存储（读取前需先调用 WStorage.init()，未初始化会抛出 StateError）
await WStorage.setString('key', 'value');
String? value = WStorage.getString('key');

// 响应式设计：WScreen 默认返回原始数值，
// 需适配时注入委托（也可对接 flutter_screenutil 的 setWidth/setHeight/setSp）
WScreen.delegateWidth = (v) => v * WScreen.screenWidth / 375;
WScreen.delegateHeight = (v) => v * WScreen.screenHeight / 667;

Container(
  width: WScreen.w(100), // 宽度按设计稿缩放
  height: WScreen.h(50), // 高度按设计稿缩放
  child: const Text('响应式布局'),
)
```

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个库。

## 许可证

MIT License