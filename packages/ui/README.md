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
  w_tools_ui: ^2.1.0
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
    memCacheWidth: 800,
    borderRadius: BorderRadius.all(Radius.circular(12)),
  ),
)
```

四种来源：`WImage.network` / `WImage.asset` / `WImage.file` / `WImage.base64`，
需要确定性时用命名构造；动态字符串用 `WImageSource.parse`。

### 常用配方

```dart
WImage.avatar(url, size: 40)                 // 圆形头像
WImage.thumbnail(url, width: 80)             // 缩略图 + 解码尺寸上限
WImage.cover(url, aspectRatio: 16 / 9)       // 封面图
WImage.assetImage('logo.png')                // 自动拼 WAssets.imagePath
WImage.memory(bytes)                         // Uint8List
WImage.provider(myProvider)                  // 任意 ImageProvider
WImage.network(url, style: const WImageStyle(showRetryButton: true)) // 内置重试
```

`WImageStyle` 也提供预设与链式糖：

```dart
WImageStyle.avatar(40)
WImageStyle.thumbnail(80, cacheSize: 240)
WImageStyle.cover(aspectRatio: 16 / 9, radius: 12)

const WImageStyle().square(40).rounded(20).decodeSize(120)
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

```dart
16.heightBox;                 // SizedBox(height: 16)
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

## 主要 API

| 能力 | 入口 |
|---|---|
| 文本 / 图片 | `WText` / `WImage` |
| 按钮 / 徽标 | `WButton` / `WBadge` / `WRowButtons` |
| 布局 | `WScaffold` / `WAppBar` / `WListView` |
| 导航 | `WNavBar` / `WNavController` / `WTabBar` |
| 屏幕工具 | `WScreen` / `WSizeBox` / `WPadding` |
| 扩展 | `HexColor` / `WStringExtension` / `WNumExtension` / `WWidgetExtension` / `WBoxDecorationExtension` |

## License

MIT
