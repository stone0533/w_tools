# w_tools_ui

[![pub package](https://img.shields.io/pub/v/w_tools_ui.svg)](https://pub.dev/packages/w_tools_ui)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

`w_tools_ui` 是 w_tools 的 UI 组件层，提供通用组件、布局、导航、扩展与屏幕适配工具。

## 特性

- **通用组件**：`WText` / `WImage` / `WButton` / `WBadge` 等
- **布局组件**：`WScaffold` / `WAppBar` / `WListView` / `WStep`
- **导航组件**：`WNavBar` / `WNavController` / `WTabBar`
- **扩展方法**：颜色、字符串、数字、Row / Column、TextStyle、Widget、BoxDecoration 等
- **屏幕适配**：`WScreen`、间距与尺寸工具

## 安装

```yaml
dependencies:
  w_tools_ui: ^4.7.0
```

> 本包最低要求 Flutter 3.27.0。

## 快速开始

```dart
import 'package:w_tools_ui/w_tools_ui.dart';

class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WScaffold(
      body: Column(
        children: const [
          WAppBar(title: 'Demo'),
          Expanded(
            child: WText(
              text: 'Hello w_tools_ui',
              variant: WTextVariant.body,
            ),
          ),
        ],
      ),
    );
  }
}
```

## WImage 快速示例

```dart
import 'package:w_tools_ui/w_tools_ui.dart';

WImage.network(
  'https://example.com/cover.jpg',
  style: const WImageStyle(
    aspectRatio: 16 / 9,
    fit: BoxFit.cover,
    borderRadius: BorderRadius.all(Radius.circular(12)),
  ),
  config: const WImageLoadConfig(memCacheWidth: 800),
);
```

四种来源：`WImage.network` / `WImage.asset` / `WImage.file` / `WImage.base64`，
需要确定性时用命名构造；动态字符串用 `WImageSource.parse`。

### 入口选择

| 场景 | 入口 |
|---|---|
| 已知网络 / 资源 / 文件 / Base64 | `WImage.network/asset/file/base64` |
| 任意 `ImageProvider` | `WImage.provider` / `WImage.memory` |
| 动态字符串，需要自动判定 | `WImageSource.parse` + `WImage.source` |
| 需要加载配置 | `config: WImageLoadConfig(...)` |
| 需要视觉样式 | `style: WImageStyle(...)` |

`WImage.asset(name)` 默认 **不**拼 `WAssets.imagePath`；
需要自动拼前缀时用 `WImage.asset(name, prefix: true)`。

### 常用配方

```dart
WImage(data: url, style: WImageStyle.avatar(40))              // 圆形头像
WImage(
  data: url,
  style: WImageStyle.thumbnail(80),
  config: const WImageLoadConfig(memCacheWidth: 240, memCacheHeight: 240),
)                                                              // 缩略图
WImage(data: url, style: WImageStyle.cover(aspectRatio: 16 / 9)) // 封面图
WImage.asset('logo.png', prefix: true)       // 自动拼 WAssets.imagePath
WImage.memory(bytes)                         // Uint8List
WImage.provider(myProvider)                  // 任意 ImageProvider
WImage.network(url, config: const WImageLoadConfig(showRetryButton: true)) // 内置重试
```

`WImageStyle` 也提供预设与链式糖：

```dart
WImageStyle.avatar(40)
WImageStyle.thumbnail(80)
WImageStyle.cover(aspectRatio: 16 / 9, radius: 12)

const WImageStyle().square(40).rounded(20)
```

完整的网络、资源、Base64、进度、重试、主题与预加载示例见
[`example/`](example/README.md)。

## 1.x → 2.0 迁移

| 1.x | 2.0 |
|---|---|
| `WImage(url, config: WImageConfig()..width = 100)` | `WImage.network(url, style: const WImageStyle(width: 100))` |
| `WImageConfig`（可变 + 链式） | `WImageStyle`（不可变 + `copyWith`） |
| `WImageConfigBuild` | `WImage.source` / `WImage.network/asset/file/base64` |
| `toImage(config:)` | `toImage(style:)` |
| `onLoadProgress` | `onProgress` |
| `progressIndicatorBuilder` | `progressBuilder` |
| `cacheEnabled` / `fitCenter` / `size` | 已删除 |
| `WImageGlobalConfig` 默认占位符 | `WImageTheme` |
| `WImageGlobalConfig` 缓存预算 | `WImageCachePolicy` |

## 导航

```dart
class _NavDemoState extends State<NavDemo> {
  late final _controller = WNavController(length: 3, vsync: this);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WNavBar(
      config: const WNavBarConfig(),
      controller: _controller,
      itemBuilder: (context, index, selected) => Text('Tab $index'),
    );
  }
}
```

`WNavController` 需要页面 State 提供 `vsync`，并由调用方 `dispose`。

顶部 tab：

```dart
DefaultTabController(
  length: 2,
  child: Column(
    children: [
      WTabBar(
        config: WTabBarConfig(),
        tabs: const [Text('全部'), Text('已完成')],
      ),
      const Expanded(
        child: TabBarView(
          children: [Text('全部内容'), Text('已完成内容')],
        ),
      ),
    ],
  ),
)
```

`WTabBar` 不自带 controller，需要 `DefaultTabController` 或显式 `TabController`。

## 扩展方法

> 新代码中 `SizedBox` / `Padding` 优先 `WSizeBox` / `WPadding`；`heightBox` / `widthBox` /
> `squareBox` 与 `WSizeBox` 等价，仅保留兼容。`allPadding` 用于需要 `EdgeInsets` 值的场景。

```dart
WSizeBox.height(16);          // SizedBox(height: 16)
16.allPadding;                // EdgeInsets.all(16)
1234.toThousandsSeparated;    // 1,234
1234.56.toCurrency(symbol: '¥'); // ¥1,234.56
0.125.toPercent;              // 12.5%
'#FF5733'.toColor();

const BoxDecoration()
    .withColor(Colors.white)
    .withBorderRadius(BorderRadius.circular(8));
```

扩展方法随 `package:w_tools_ui/w_tools_ui.dart` 一起导入。

## 工具

```dart
WScreen.w(16);
WScreen.h(24);
WScreen.sp(14);

WAssets.imagePath = 'assets/icons/';
'logo.png'.assetImagePath;
```

`WScreen` 无 delegate 时返回原始值；需要 `ScreenUtil` 时注入 delegate。


## 主要 API

| 能力 | 入口 |
|---|---|
| 文本 / 图片 | `WText` / `WImage` |
| 按钮 / 徽标 | `WButton` / `WBadge` / `WActionRow` / `WSelectableRow` |
| 裁剪 | `WClipRRect` |
| 加载指示 | `WGradientCircularProgressIndicator` |
| 列表保活 | `WKeepAliveWrapper` |
| 滚动通知 | `WNotificationListenerBuilder` |
| 布局 | `WScaffold` / `WAppBar` / `WListView` |
| 导航 | `WNavBar` / `WNavController` / `WTabBar` |
| 屏幕工具 | `WScreen` |
| 资源 | `WAssets` |
| 扩展 | `WHexColor` / `WStringExtension` / `WNumExtension` / `WWidgetExtension` / `WBoxDecorationExtension` |

## License

MIT
