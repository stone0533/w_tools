# Flutter W Tools

[![CI](https://github.com/stone0533/w_tools/actions/workflows/ci.yml/badge.svg)](https://github.com/stone0533/w_tools/actions/workflows/ci.yml)

一个按子包拆分、以子包配置（`WToken` / `WAssets` / `WAppConfig` 等）驱动的 Flutter 工具库，提供了多种实用工具和组件，帮助开发者快速构建高质量的 Flutter 应用。

## 特性

- **组件库**：提供丰富的 UI 组件，涵盖通用组件、输入组件、布局组件和导航组件
- **工具类**：包含加密、验证、日志、存储、网络请求等多种实用工具
- **扩展功能**：提供颜色、字符串、数字、容器等多种扩展方法
- **配置在子包**：`WToken`（键名）/ `WAssets`（资源前缀）/ `WAppConfig`（语言）等配置各归其包（`WConfig` 已在 3.0 删除）
- **响应式设计**：支持屏幕适配，自动适应不同设备尺寸

## 文档

| 文档 | 内容 |
|------|------|
| [docs/modules/README.md](https://github.com/stone0533/w_tools/blob/main/docs/modules/README.md) | 模块文档索引、依赖矩阵、SDK 速查 |
| [docs/modules/components.md](https://github.com/stone0533/w_tools/blob/main/docs/modules/components.md) | 组件目录（先查这里），含「不要用在哪」 |
| [docs/conventions.md](https://github.com/stone0533/w_tools/blob/main/docs/conventions.md) | 接入约定：包 / 暂存层 / 业务层判定与 doctor 规则 |
| [docs/ai-contract.md](https://github.com/stone0533/w_tools/blob/main/docs/ai-contract.md) | AI 使用契约：catalog / explain / AGENTS 的更新与完整性检查 |
| [docs/ai-maintainer-prompts.md](https://github.com/stone0533/w_tools/blob/main/docs/ai-maintainer-prompts.md) | 维护者 AI 提示词：按场景复制 |
| [scripts/README.md](https://github.com/stone0533/w_tools/blob/main/scripts/README.md) | scripts 运行手册：何时跑哪个检查 / 发布脚本 |
| [docs/documentation-map.md](https://github.com/stone0533/w_tools/blob/main/docs/documentation-map.md) | 文档定位与 AI 整理规则 |
| [CONTRIBUTING.md](CONTRIBUTING.md) | 新增/修改组件的硬性要求 |
| [docs/releasing.md](https://github.com/stone0533/w_tools/blob/main/docs/releasing.md) | 发版流程与发布脚本 |
| [docs/adr/](https://github.com/stone0533/w_tools/tree/main/docs/adr) | 架构决策（版本策略、依赖子包） |
| [packages/cli/README.md](https://github.com/stone0533/w_tools/blob/main/packages/cli/README.md) | `init` / `doctor` CLI |

> `docs/modules/` 面向使用者，`docs/` 顶层面向维护者/agent；`docs/` 不随 pub 发布
>（已在根 `.pubignore` 排除）。

## 安装

> ℹ️ **版本说明**：具体版本以各包 `pubspec.yaml` 与 pub.dev 页面为准；仓库 `main` 可能领先于
> pub.dev 已发布版本。根包 `w_tools` 自 2.0.0 起是**聚合包**，依赖 6 个基础子包，只 re-export
> 子包能力；聚合示例以根 `pubspec.yaml` 为准，其它安装示例以对应子包的 `pubspec.yaml` 为准。
> 安装命令用 `pub add`（装 pub.dev 上已发布的最新版），**安装命令里不写死版本号**——否则仓库一领先，
> 文档里的 `^x.y.z` 就会变成装不到的版本。配置片段里仍写 caret 约束时，下界必须等于当前版本
> （由 `scripts/check_package_docs.py` 校验）。
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

### 两条接入路径（先选一条）

| 路径 | 适用 | 入口 |
|---|---|---|
| **A. 只依赖子包** | 生产项目（推荐；doctor R1 要求） | `import 'package:w_tools_ui/w_tools_ui.dart';` 等 |
| **B. 聚合包** | 快速体验 / 旧项目兼容 | `import 'package:w_tools/w_tools.dart';` |

#### A. 只依赖用到的子包（推荐）

根包只保留 core/async/ui/form/api/toast；`app` / `map` / `qr` 一律按需直接依赖对应子包：

```bash
flutter pub add w_tools_core w_tools_async w_tools_ui w_tools_form
# 需要再加 w_tools_app_getx / api / toast / qr / map / map_google
```

> 依赖放子包，但业务代码不要直接 import 子包：统一 import CLI 生成的
> `lib/app/w/toolkit.dart` 聚合入口（见 [`docs/conventions.md`](https://github.com/stone0533/w_tools/blob/main/docs/conventions.md) §5）。

模板与理由：[`packages/cli/templates/`](https://github.com/stone0533/w_tools/tree/main/packages/cli/templates)、[`docs/conventions.md`](https://github.com/stone0533/w_tools/blob/main/docs/conventions.md)、
[ADR-0002](https://github.com/stone0533/w_tools/blob/main/docs/adr/0002-consumers-depend-on-subpackages.md)。

更省事的做法是用 CLI 生成（聚合入口、暂存层 README、`AGENTS.md` 片段一次装好）。
CLI 在独立的纯 Dart 包里，不需要先引入聚合包：

```bash
dart pub add dev:w_tools_cli
```

```bash
dart run w_tools_cli:w_tools init      # 生成到当前项目
dart run w_tools_cli:w_tools doctor    # 之后随时检查是否守约定
```

#### B. 聚合包入口（快速体验 / 旧项目兼容）

如果你明确选择聚合包，统一使用：

```dart
import 'package:w_tools/w_tools.dart';
```

根包不再提供旧 `WConfig` 兼容层（`WConfig` 已在 core 3.0 删除）。

配置走子包入口：

```dart
import 'package:flutter/material.dart';
import 'package:w_tools/w_tools.dart';

WToken.tokenKey = 'auth_token';         // core：token 键名
WAssets.imagePath = 'assets/images/';   // ui：资源前缀

// form：图标按页面作用域配置（WFormIcons 没有全局静态赋值）
WFormTheme(
  icons: WFormIcons.defaults.copyWith(clear: const Icon(Icons.clear)),
  child: form,
);
```


### 从 pub.dev 安装

各子包可独立安装，可只引入需要的包；根包 `w_tools` 也作为聚合包提供。
**当前可安装版本以 pub.dev 页面为准**；仓库 `main` 可能领先于已发布版本，安装前先确认。

> 环境：Dart `^3.10.0`、Flutter `>=3.38.0`。

```bash
flutter pub add w_tools_core w_tools_ui   # 只引子包
```

或一键引入聚合包（会带上全部 6 个基础子包及其依赖）：

```bash
flutter pub add w_tools
```

> ⚠️ `pub add` 装的是 pub.dev 上当前发布的最新版本；想锁定版本时以 pub.dev 页面为准。
> 需要仓库 `main` 上尚未发布的改动时，用上面的 path / git 依赖方式。
>
> ⚠️ 聚合包只用于快速体验 / 旧项目兼容。按接入约定（doctor R1），生产项目应直接依赖子包；
> 用了聚合包再跑 `doctor` 会报 R1。

然后运行：

```bash
flutter pub get
```

### 依赖与子包说明（选依赖前请先读）

`w_tools` 是**聚合包**，直接依赖以下 6 个基础子包，方便一键引入：

| 子包 | 职责 |
|---|---|
| `w_tools_core` | 工具类、扩展方法、全局配置 |
| `w_tools_async` | 异步执行、状态、Controller 与异步视图 |
| `w_tools_ui` | UI 组件（`WText` / `WImage` / `WButton` / `WScaffold` / `WAppBar` / `WListView` / `WNavBar` 等） |
| `w_tools_form` | 表单组件（`WFormTextField` / `WFormDropdown` / `WFormCheckbox` / `WFormBorder` 等） |
| `w_tools_api` | 网络请求（`DioRegistry` / `BaseOptions` / 各类拦截器 / `BaseRepository`） |
| `w_tools_toast` | 轻量提示（`WToast`） |

## 快速开始

根包只包含基础能力。应用启动器 `WApp` 需要单独依赖：

```yaml
dependencies:
  w_tools_app_getx: ^1.0.1
```

```dart
import 'package:w_tools_app_getx/w_tools_app_getx.dart';
```

完整用法见 [`packages/app_getx/README.md`](https://github.com/stone0533/w_tools/blob/main/packages/app_getx/README.md)。

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
- **RowButtons** (`WActionRow` / `WSelectableRow`): 行按钮组件
- **Text** (`WText`): 增强的文本组件
- **TextStyle** (`WTextStyleExtension`): `TextStyle` 的 `bold` / `withColor` / `withSize` 扩展

#### 输入组件
- **FormButton** (`WFormButton`): 表单字段值选择按钮（`WButton` 负责普通点击）
- **FormCheckbox** (`WFormCheckbox`): 单个复选框字段组件
- **FormBuilder** (`WFormScope`): 表单构建器组件
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
- **弹窗工具** (`WFormPopup.show`): 提供从触发控件下方弹出的自定义路由
- **语言工具** (`WLanguage`): 提供语言管理和切换功能
- **Toast 工具** (`WToast`): 提供轻量级消息提示功能
- **异步工具** (`WAsync` / `WAsyncState` / `WAsyncView`): 提供执行、四态状态、Controller 与异步视图
- **平台工具** (`WPlatform`): 提供平台检测和适配功能，支持移动、桌面和 Web 平台的判断，以及平台特定操作的执行
- **正则工具** (`WRegExp`): 提供常用正则表达式
- **路由工具** (`WRouteStack` / `WRouteStack.defaultStack`): 路由栈记录与回退

### 📚 扩展功能

#### 扩展方法
- **颜色扩展** (`WColorExtension`): 十六进制颜色解析 / 生成（`fromHex` / `toHex`）
- **字符串扩展** (`WStringExtension`): 提供字符串格式化、验证、转换等功能
- **数字扩展** (`WNumExtension`): 提供数字格式化、范围检查等功能
- **容器扩展** (`WWidgetExtension`): 提供容器装饰、布局调整等功能
- **映射扩展** (`WMapExtension`): 提供映射操作、转换等功能
- **全局键扩展** (`WGlobalKeyExtension`): GlobalKey 查找 / 定位
- **文本样式扩展** (`WTextStyleExtension`): `bold` / `withColor` / `withSize`
- **布局糖**（`WRow` / `WColumn` / `WSizeBox` / `WPadding`）已弃用（5.0 移除），直接用 Flutter `Row` / `Column` / `SizedBox` / `EdgeInsets`

## 使用示例

### 使用组件

```dart
import 'package:flutter/material.dart';
import 'package:w_tools/w_tools.dart';

class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WScaffold(
      title: '示例页面',
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            WButton(label: '点击我', onTap: () {}),
            const WText(text: '这是一个文本组件'),
          ],
        ),
      ),
    );
  }
}
```

### 使用表单组件

```dart
import 'package:w_tools/w_tools.dart';

// 直接把字段放进 WForm（不要从 Config.build / *Core 开始）
WForm(
  controller: WFormController(),
  child: WFormMultiDropdown(
    name: 'multi_select',
    label: '多选',
    items: {'option1': '选项1', 'option2': '选项2', 'option3': '选项3'},
    initialValue: {'option1'},   // Set<String>
    onChanged: (value) => debugPrint('选中的值: $value'),
  ),
);
```

### 使用工具类

```dart
import 'package:w_tools/w_tools.dart';

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

## 完整示例

根包最小聚合示例见 [`example/`](example/)：一个 `WForm` 表单，验证 `package:w_tools/w_tools.dart` 的实际用法。

## 许可证

MIT License