# w_tools_ui

[![pub package](https://img.shields.io/pub/v/w_tools_ui.svg)](https://pub.dev/packages/w_tools_ui)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

`w_tools_ui` 是 w_tools 的 UI 组件层，提供通用组件、布局、导航、扩展与屏幕适配工具。

> 文档分工：本文负责**安装 / 快速开始 / 常用配方**；模块边界、设计取舍与反例见
> [`docs/modules/ui_module.md`](../../docs/modules/ui_module.md)。

## 特性

- **通用组件**：`WText` / `WImage` / `WButton` / `WBadge` 等
- **布局组件**：`WScaffold` / `WAppBar` / `WListView` / `WStep`
- **导航组件**：`WNavBar` / `WNavController` / `WTabBar`
- **扩展方法**：颜色、字符串、数字、TextStyle、Widget、BoxDecoration 等
- **屏幕适配**：`WScreen`、间距与尺寸工具

## 安装

```yaml
dependencies:
  w_tools_ui: ^7.0.0
```

> 本包最低要求 Flutter 3.38.0。

## 快速开始

```dart
import 'package:w_tools_ui/w_tools_ui.dart';

class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WScaffold(
      title: 'Demo',
      body: const Center(
        child: WText(
          text: 'Hello w_tools_ui',
          variant: WTextVariant.body,
        ),
      ),
    );
  }
}
```

## WImage 快速示例

```dart
import 'package:w_tools_ui/w_tools_ui.dart';

WImage.source(
  source: WImageSource.network('https://example.com/cover.jpg'),
  style: const WImageStyle(
    aspectRatio: 16 / 9,
    fit: BoxFit.cover,
    borderRadius: BorderRadius.all(Radius.circular(12)),
  ),
  options: const WImageLoadOptions(memCacheWidth: 800),
);
```

所有来源统一走 `WImage.source` + `WImageSource`。

> `WImage` 不会自动给尺寸：没有 `width` / `height` / `aspectRatio` 时，必须由父级
> （`SizedBox` / `Expanded` / `AspectRatio`）约束；否则在 `Row` / `Column` / `ListView`
> 里加载前占位是 0 尺寸，表现为空白（debug 下会打印提示）。

### 入口选择

| 场景 | 入口 |
|---|---|
| 已知网络 / 资源 / 文件 / Base64 | `WImageSource.network/asset/file/base64` |
| 任意 `ImageProvider` / 内存字节 | `WImageSource.provider` / `ImageProvider` + `MemoryImage` |
| 动态字符串，需要自动判定 | `WImageSource.parse` + `WImage.source` |
| 需要加载行为 | `options: WImageLoadOptions(...)` |
| 需要单图占位/错误/进度/重试 UI | `slots: WImageSlots(...)` |
| 需要视觉样式 | `style: WImageStyle(...)` |
| 需要 App 级默认占位/错误/进度 | `WImageTheme(slots: WImageSlots(...))` |
| 需要预加载 | `await WImageSource.resolve(...)` + `precacheImage` |
| 需要手动重试/状态 | `controller: WImageController()` |

`WImageSource.asset(name)` 默认 **不**拼 `WAssets.imagePath`；
需要自动拼前缀时用 `WImageSource.asset(name, prefix: true)`。

### 常用配方

```dart
WImage.source(source: WImageSource.parse(url), style: WImageStyle.avatar(40))
WImage.source(
  source: WImageSource.parse(url),
  style: WImageStyle.thumbnail(80),
  options: const WImageLoadOptions(memCacheWidth: 240, memCacheHeight: 240),
)
WImage.source(
  source: WImageSource.network(url),
  slots: const WImageSlots(showRetryButton: true),
)
WImage.source(source: WImageSource.asset('logo.png', prefix: true))
WImage.source(source: WImageSource.provider(MemoryImage(bytes)))
```

App 级默认占位只装一次：

```dart
WImageTheme(
  slots: WImageSlots(
    placeholderBuilder: (context, data) => const Center(child: CircularProgressIndicator()),
    errorWidgetBuilder: (context, data, error) => const Icon(Icons.broken_image),
  ),
  child: app,
)
```

预加载要与 WImage 使用同一套尺寸规则：

```dart
final provider = await WImageSource.network(url).resolve(memCacheWidth: 240);
await precacheImage(provider, context);
```

手动重试/状态监听：

```dart
final controller = WImageController();
WImage.source(
  source: WImageSource.network(url),
  controller: controller,
  slots: const WImageSlots(showRetryButton: true),
);
controller.state.addListener(() => debugPrint('${controller.state.value.status}'));
// controller.dispose();
```

`WImageStyle.width/height` 只约束图片内容；`padding` / `margin` 会加在总尺寸上
（`width: 10` + `padding: 5` → 总尺寸 20），这一点与 `Container` 不同。

`WImageStyle` 也提供预设与链式糖：

```dart
WImageStyle.avatar(40)
WImageStyle.thumbnail(80)
WImageStyle.cover(aspectRatio: 16 / 9, radius: 12)

const WImageStyle().square(40).rounded(20)
```

完整的网络、资源、Base64、进度、重试、主题与预加载示例见
[`example/`](example/README.md)。

> 7.0 迁移见 [`docs/migrations/ui-7.0.md`](https://github.com/stone0533/w_tools/blob/main/docs/migrations/ui-7.0.md)；
> 历史迁移见 [`docs/migrations/`](https://github.com/stone0533/w_tools/blob/main/docs/migrations/README.md)。

## 文本

```dart
WText(text: '标题', variant: WTextVariant.title);
WText(text: '正文', variant: WTextVariant.body, maxLines: 2, overflow: TextOverflow.ellipsis);
WText(
  text: '价格',
  variant: WTextVariant.price,
  style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
);
```

11 个 variant：`display/headline/title/price/body/bodyStrong/number/caption/label/button/badge`。
品牌样式在主题构建处装一次：

```dart
final base = ThemeData(colorScheme: scheme, useMaterial3: true);
theme: base.withWTextStyles(WTextStyles.fromTextTheme(base.textTheme)),
```

`WTextConfig` 已移除；局部只覆盖需要的字段（`style/color/maxLines/overflow/textScaler`）。

## 按钮与点击

```dart
WButton(label: '保存', onTap: save);
WButton(label: '提交', loading: true, enabled: false, onTap: submit);
WButton(icon: Icons.add, label: '新增', style: WButtonStyles.of(context).primary, onTap: add);
WPressable(onTap: openDetail, child: card); // 任意 child，无 button 语义
```

任意 child / 卡片点击用 `WPressable`；需要键盘、最小点击区域或 button 语义时用 `WButton`。

## 页面骨架与布局

```dart
WScaffold(
  title: '首页',
  actions: [IconButton(onPressed: ..., icon: const Icon(Icons.search))],
  floatingActionButton: FloatingActionButton(onPressed: ..., child: const Icon(Icons.add)),
  body: ...,
);

// 自定义顶栏：WAppBar 或其他 PreferredSizeWidget（Material AppBar / SliverAppBar）
WScaffold(appBar: WAppBar(title: '详情'), body: ...);

WStep(labels: const ['下单', '付款', '完成'], current: 2);
```

列表：

```dart
WListView(sliver: WListViewSliver.list(itemCount: n, itemBuilder: ...));
WListView(sliver: WListViewSliver.separated(itemCount: n, itemBuilder: ..., separatorBuilder: ...));
WListView(sliver: WListViewSliver.grid(itemCount: n, gridDelegate: ..., itemBuilder: ...));
WListView(sliver: WListViewSliver.overlap(itemCount: n, itemExtent: 80, overlap: 24, itemBuilder: ...));
```

角标 / 裁剪 / 横向操作：

```dart
WBadge(badgeContent: const Text('3'), child: const Icon(Icons.notifications));
WClipRRect(borderRadius: BorderRadius.circular(12), child: image);
WActionRow(children: [WButton(...), WButton(...)]);
```

## 状态与反馈

```dart
WGradientCircularProgressIndicator(radius: 24, value: 0.6, colors: const [Colors.indigo, Colors.lightBlue]);
WKeepAliveWrapper(child: item);
WNotificationListenerBuilder<ScrollNotification>(child: list)
  .onNotificationPercentage((p) { ... })
  .build()
```

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
      style: const WNavBarStyle(),
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
        style: const WTabBarStyle(),
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

> `WSizeBox` / `WPadding` / `WRow` / `WColumn` 已在 5.0 删除，直接用 Flutter 原生组件；
> `heightBox` / `widthBox` / `squareBox` 仍保留，是 `SizedBox` 的简写；
> `allPadding` 用于需要 `EdgeInsets` 值的场景。

```dart
const SizedBox(height: 16);
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

`WScreen` 无 delegate 时返回原始值；需要 `ScreenUtil` 时注入 delegate：

```dart
WScreen.delegateWidth = (v) => ScreenUtil().setWidth(v);
WScreen.delegateHeight = (v) => ScreenUtil().setHeight(v);
WScreen.delegateFont = (v) => ScreenUtil().setSp(v);
```


## 主要 API

| 能力 | 入口 |
|---|---|
| 文本 / 图片 | `WText` / `WImage` |
| 按钮 / 点击 | `WButton` / `WPressable` |
| 徽标 / 横向操作 | `WBadge` / `WActionRow` / `WSelectableRow` |
| 裁剪 | `WClipRRect` |
| 加载指示 | `WGradientCircularProgressIndicator` |
| 列表保活 | `WKeepAliveWrapper` |
| 滚动通知 | `WNotificationListenerBuilder` |
| 布局 | `WScaffold` / `WAppBar` / `WListView` |
| 导航 | `WNavBar` / `WNavController` / `WTabBar` |
| 屏幕工具 | `WScreen` |
| 资源 | `WAssets` |
| 扩展 | `WColorExtension` / `WImageStyleExtension` / `WStringExtension` / `WNumExtension` / `WWidgetExtension` / `WBoxDecorationExtension` |

完整构造参数与成员见 [pub.dev API 文档](https://pub.dev/documentation/w_tools_ui/latest/)
或 `packages/ui/lib` 源码；模块边界与设计取舍见 [`docs/modules/ui_module.md`](https://github.com/stone0533/w_tools/blob/main/docs/modules/ui_module.md)。

## License

MIT
