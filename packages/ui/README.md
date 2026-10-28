# w_tools_ui

[![pub package](https://img.shields.io/pub/v/w_tools_ui.svg)](https://pub.dev/packages/w_tools_ui)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

`w_tools_ui` 是 w_tools 的 UI 组件层，提供通用组件、布局、导航、扩展与屏幕适配工具。

## 特性

- **通用组件**：`WText` / `WImage` / `WButton` / `WBadge` 等
- **布局组件**：`WScaffold` / `WAppBar` / `WContainer` / `WListView` / `WStep`
- **导航组件**：`WNavBar` / `WNavController` / `WTabBar`
- **扩展方法**：颜色、字符串、数字、Row / Column、TextStyle、Widget 等
- **屏幕适配**：`WScreen`、间距与尺寸工具

## 安装

```yaml
dependencies:
  w_tools_ui: ^2.0.0
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
          Expanded(child: WText(text: 'Hello w_tools_ui')),
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

完整的网络、资源、Base64、进度、重试、主题与预加载示例见
[`example/`](example/README.md)。

## 主要 API

| 能力 | 入口 |
|---|---|
| 文本 / 图片 | `WText` / `WImage` |
| 按钮 / 徽标 | `WButton` / `WBadge` / `WRowButtons` |
| 布局 | `WScaffold` / `WAppBar` / `WContainer` / `WListView` |
| 导航 | `WNavBar` / `WNavController` / `WTabBar` |
| 屏幕工具 | `WScreen` / `WSizeBox` / `WPadding` |
| 扩展 | `ColorExtension` / `StringExtension` / `NumExtension` / `WidgetExtension` 等 |

## License

MIT
