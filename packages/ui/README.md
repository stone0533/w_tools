# w_tools_ui

[![pub package](https://img.shields.io/pub/v/w_tools_ui.svg)](https://pub.dev/packages/w_tools_ui)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

`w_tools_ui` 是 w_tools 的 UI 组件层，提供通用组件、布局、导航、扩展与屏幕适配工具。

> 文档分工：本文负责**安装 / 快速开始 / 常用配方**；模块边界、设计取舍与反例见
> [`docs/modules/ui_module.md`](https://github.com/stone0533/w_tools/blob/main/docs/modules/ui_module.md)。

## 特性

- **通用组件**：`WText` / `WImage` / `WButton` / `WBadge` 等
- **布局组件**：`WScaffold` / `WAppBar` / `WListView` / `WStep`
- **导航组件**：`WNavBar` / `WNavController`（顶部 tab 直接用 Material `TabBar`）
- **扩展方法**：颜色、字符串、数字、Widget、BoxDecoration 等
- **屏幕适配**：`WScreen`、间距与尺寸工具

## 安装

```yaml
dependencies:
  w_tools_ui: ^12.0.0
```

> 本包最低要求 Flutter 3.38.0。

## 依赖与平台

- 直接第三方依赖只有 `cached_network_image`（约束 `^3.3.1`）。
- 它会传递带入 `flutter_cache_manager`、`path_provider`、`sqflite`、`octo_image`、
  `rxdart`、`uuid` 等；移动 / 桌面用 `path_provider` + `sqflite` 做磁盘缓存，
  Web 走 `cached_network_image_web`。
- `asset` / `file` / `base64` / `provider` 来源不经过网络缓存，但依赖仍在 pub 层，
  不能靠“只用 asset 图”裁掉插件注册。
- 已有 `ImageProvider` 用 `WImageSource.provider` 接管加载。是否拆分缓存依赖见
  [ADR-0008](https://github.com/stone0533/w_tools/blob/main/docs/adr/0008-ui-image-cache-dependency.md)。

## 快速开始

```dart
import 'package:w_tools_ui/w_tools_ui.dart';

class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WScaffold.basic(
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

空 data（`''` / 纯空白）表示「没有配图」，**不是加载失败**：走 `placeholderBuilder`，
不会触发 `errorWidgetBuilder`，也不会回调 `onLoadStatusChanged(failed)`。

`WImageSlots` 只有两个槽：`placeholderBuilder`（空 / 加载中 / 等待重试）与
`errorWidgetBuilder`（收到 `onRetry`）。需要「错误文案 + 重试按钮」时在 error builder 里
返回 `WImageErrorView`：

```dart
WImage.source(
  source: WImageSource.network(url),
  slots: WImageSlots(
    errorWidgetBuilder: (context, data, error, retry) =>
        WImageErrorView(error: error, onRetry: retry),
  ),
)
```

内置 loading / retry / 图片错误文案按当前 `Locale` 取中文或英文；
`WButton.loadingLabel` / `WImageErrorView.retryLabel` 传非空字符串可覆盖。

`WImageError.message` 是固定中文诊断文案（日志 / `toString()`）；UI 里用
`error.localizedMessage(context)` 跟随当前 `Locale`。

> `WImage` 不会自动给尺寸：没有 `width` / `height` / `aspectRatio` 时，必须由父级
> （`SizedBox` / `Expanded` / `AspectRatio`）约束；否则在 `Row` / `Column` / `ListView`
> 里加载前占位是 0 尺寸，表现为空白（debug 下会打印提示）。
>
> 注意 `width + BoxFit.fitWidth` **不会确定高度**；仍要补 `height`、`aspectRatio` 或让父级
> 在高度轴有界。`aspectRatio` 不能和固定 `width` / `height` 同时设置：固定宽度 + 比例时用
> 父级 `AspectRatio`，或只给 `aspectRatio`。debug 提示会带脱敏 source，并按 source + 轴去重。

### 入口选择

| 场景 | 入口 |
|---|---|
| 已知网络 / 资源 / 文件 / Base64 | `WImageSource.network/asset/file/base64` |
| 任意 `ImageProvider` / 内存字节 | `WImageSource.provider` / `ImageProvider` + `MemoryImage` |
| 需要加载行为 | `options: WImageLoadOptions(...)` |
| 需要单图占位 / 错误 / 重试 UI | `slots: WImageSlots(...)` |
| 没有配图 / 空 data | `slots: WImageSlots(placeholderBuilder: ...)` |
| 需要视觉样式 | `style: WImageStyle(...)` |
| 需要 App 级默认占位/错误/进度 | `WImageTheme(slots: WImageSlots(...))` |
| 需要预加载 | `await WImageSource.resolve(...)` + `precacheImage` |
| 需要手动重试 | `errorWidgetBuilder` 的 `onRetry` |

`WImageSource.asset(name)` 接收**完整资源路径**（如 `assets/images/logo.png`）；
12.0 删除了全局前缀 `WAssets.imagePath` 与 `prefix` 参数。

### 常用配方

```dart
WImage.source(
  source: WImageSource.network(url),
  style: const WImageStyle(
    width: 40,
    height: 40,
    borderRadius: BorderRadius.all(Radius.circular(20)),
  ),
)
WImage.source(
  source: WImageSource.network(url),
  style: const WImageStyle(width: 80, height: 80),
  options: const WImageLoadOptions(memCacheWidth: 240, memCacheHeight: 240),
)
WImage.source(
  source: WImageSource.network(url),
  slots: WImageSlots(
    errorWidgetBuilder: (context, data, error, retry) =>
        WImageErrorView(error: error, onRetry: retry),
  ),
)
WImage.source(source: WImageSource.asset('assets/images/logo.png'))
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

手动重试 / 状态监听：

```dart
WImage.source(
  source: WImageSource.network(url),
  onLoadStatusChanged: (status) => debugPrint('$status'),
  onProgress: (progress) => debugPrint('${progress.fraction}'),
  slots: WImageSlots(
    errorWidgetBuilder: (context, data, error, retry) =>
        WImageErrorView(error: error, onRetry: retry),
  ),
);
```

留白不在 `WImageStyle` 里：需要 padding / margin 时在外层包 `Padding` / `Container`
（12.0 删除了 `WImageStyle.margin/padding`，`width/height` 语义与 Flutter 一致）。

`WImageStyle` 只保留一个预设与两条链式糖：

```dart
WImageStyle.cover(aspectRatio: 16 / 9, radius: 12)

const WImageStyle().square(40).rounded(20)
WImageStyle.cover().square(40) // 设置 width/height 时自动清空 aspectRatio
```

头像 / 缩略图直接用 `width` + `height` + 可选 `borderRadius`，不必再记预设名；
`WImageStyle.avatar` / `WImageStyle.thumbnail` 已在 12.0 删除（它们只是这两行的预设）。

### 宽度铺满 + 高度上限

宽度铺满、高度不超过 `maxHeight`，超出部分按 `alignment` 保留上 / 中 / 下。不需要新 API：
`ConstrainedBox` + `fitWidth` 就够了。

```dart
ConstrainedBox(
  constraints: const BoxConstraints(maxHeight: 240),
  child: WImage.source(
    source: WImageSource.network(url),
    style: const WImageStyle(
      width: double.infinity, // 必须：宽度要是紧约束，否则夹高时会被缩窄
      fit: BoxFit.fitWidth,
      alignment: Alignment.center, // topCenter 保上 / center 保中 / bottomCenter 保下
    ),
  ),
)
```

- 按宽度算出的高度 ≤ `maxHeight` 时，与普通 `fitWidth` 完全一致；
- 超过时盒子固定在 `maxHeight`，`fitWidth` 会裁源图，`alignment` 的 y 分量决定保留哪一段
  （x 分量不起作用，宽度总是铺满）；
- 不要再给 `style.height`：固定高度会让上面的第一种情况也变成固定盒子；
- 宽度约束不紧时（例如放在 `Column` 里），图片会按原图宽度走，甚至被 `maxHeight` 缩窄，
  所以显式写 `width: double.infinity` 或让父级给紧宽度；宽度无界时（`Row` / 水平列表）
  先给有界宽度，否则铺不满；
- 加载前占位高度是 0，解码后才会展开；要避免跳动，优先在能拿到宽高时用
  `aspectRatio` + `cover` 在数据层夹比例，或先放一个已知高度的占位。

可运行示例见 [`example/lib/recipes_page.dart`](example/lib/recipes_page.dart)。

完整的网络、资源、Base64、进度、重试、主题与预加载示例见
[`example/`](example/README.md)。

> 12.0 迁移见 [`docs/migrations/ui-12.0.md`](https://github.com/stone0533/w_tools/blob/main/docs/migrations/ui-12.0.md)；
> 10.0 迁移见 [`docs/migrations/ui-10.0.md`](https://github.com/stone0533/w_tools/blob/main/docs/migrations/ui-10.0.md)；
> 9.0 迁移见 [`docs/migrations/ui-9.0.md`](https://github.com/stone0533/w_tools/blob/main/docs/migrations/ui-9.0.md)；
> 8.0 迁移见 [`docs/migrations/ui-8.0.md`](https://github.com/stone0533/w_tools/blob/main/docs/migrations/ui-8.0.md)；
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
WText.rich(
  textSpan: TextSpan(
    text: '¥128',
    children: [TextSpan(text: ' 起', style: TextStyle(fontSize: 12))],
  ),
  variant: WTextVariant.price,
);
```

11 个 variant：`display/headline/title/price/body/bodyStrong/number/caption/label/button/badge`。
品牌样式在主题构建处装一次：

```dart
final base = ThemeData(colorScheme: scheme, useMaterial3: true);
theme: base.withWTextStyles(WTextStyles.fromTextTheme(base.textTheme)),
```

`WTextConfig` 已移除；局部只覆盖需要的字段（`style/color/maxLines/overflow/textScaler`）。

图标 + 文字一行：

```dart
WIconText(icon: Icons.star, text: '收藏');
WIconText(icon: Icons.location_on, text: '上海市', variant: WTextVariant.caption);
WIconText.custom(icon: SvgPicture.asset('assets/star.svg'), text: '收藏'); // 任意 Widget
```

不要用 `Row + Icon + Text` 手拼；中文行盒会让图标看起来偏高。需要按品牌字体微调时传
`iconOffset`，间距用 `gap`。

## 按钮与点击

```dart
WButton(label: '保存', onTap: save);
WButton(variant: WButtonVariant.outlined, label: '取消', onTap: cancel);
WButton(variant: WButtonVariant.danger, label: '删除', onTap: remove);
WButton(label: '提交', loading: true, onTap: submit);
WButton(icon: Icons.add, label: '新增', size: WButtonSize.small, onTap: add);
WButton(icon: Icons.favorite, semanticLabel: '收藏', tooltip: '收藏', isSelected: true, onTap: toggle);
WPressable(onTap: openDetail, child: card); // 任意 child，无 button 语义
```

`WButton` 渲染 Material `FilledButton` / `OutlinedButton` / `TextButton`，视觉走
`ButtonStyle`；全站换色装 `WButtonTheme`，单按钮传 `style: ButtonStyle(...)`。
任意 child / 卡片点击用 `WPressable`；需要键盘、最小点击区域或 button 语义时用 `WButton`。
图标按钮用 `tooltip`；toggle 按钮用 `isSelected`（进入 `Semantics.selected`）；
纯图标按钮必须给 `semanticLabel`。

## 页面骨架与布局

```dart
WScaffold.basic(
  title: '首页',
  actions: [IconButton(onPressed: ..., icon: const Icon(Icons.search))],
  floatingActionButton: FloatingActionButton(onPressed: ..., child: const Icon(Icons.add)),
  drawer: Drawer(...),        // drawer / endDrawer / bottomSheet / footer 均透传
  bottomSheet: ...,
  body: ...,
);

// 自定义顶栏：WAppBar 或其他 PreferredSizeWidget（Material AppBar / SliverAppBar）
WScaffold(appBar: WAppBar(title: '详情'), body: ...);

// 底栏不是 WNavBar 时：WScaffold(bottomNavigationBarSafeArea: true, ...)

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
WBadge.count(count: 120, maxCount: 99, child: const Icon(Icons.notifications));
WBadge.dot(child: const Icon(Icons.notifications));
WBadge(offset: const Offset(4, -4), badgeContent: const Text('3'), child: const Icon(Icons.notifications));
WBadge(semanticLabel: '3 条未读', badgeContent: const Text('3'), child: const Icon(Icons.notifications));
WClipRRect 已删除；圆角裁剪直接用 Flutter 原生 `ClipRRect`：
ClipRRect(borderRadius: BorderRadius.circular(12), child: image);
WActionRow(children: [WButton(...), WButton(...)]);
```

## 状态与反馈

```dart
WGradientCircularProgressIndicator(radius: 24, value: 0.6, colors: const [Colors.indigo, Colors.lightBlue]);
WGradientCircularProgressIndicator(radius: 24, indeterminate: true, colors: const [Colors.indigo, Colors.lightBlue]);
WKeepAliveWrapper(child: item);
WNotificationListener<ScrollNotification>(
  onNotificationPercentage: (p) { ... },
  child: list,
)
```

## 导航

```dart
class _NavDemoState extends State<NavDemo> {
  late final _controller = WNavController(length: 3);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WNavBar(
      controller: _controller,
      decoration: const BoxDecoration(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      onBeforeTap: (index) async => true, // 返回 false 阻止切换
      itemBuilder: (context, index, selected) => Text('Tab $index'),
    );
  }
}
```

`WNavController` 只维护 `currentIndex`，不需要 `vsync`；由调用方 `dispose`。
`WNavBar` 默认 `safeArea: true`，会避开底部 home indicator；已在外层包 `SafeArea` 时传
`safeArea: false`。切换前拦截用 `onBeforeTap`（`FutureOr<bool>`）。
默认 item 可传 `destinations: [WNavDestination(...)]`；完全自定义用 `itemBuilder`。
外层装饰 / 内边距直接传 `decoration` / `padding`（12.0 删除了 `WNavBarStyle`）。

顶部 tab：

```dart
DefaultTabController(
  length: 2,
  child: Column(
    children: [
      TabBar(
        labelColor: Colors.indigo,
        indicatorAnimation: TabIndicatorAnimation.elastic,
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

顶部 tab 直接用 Material `TabBar`（12.0 删除了 `WTabBar` / `WTabBarStyle`），
`labelColor` / `indicatorColor` / `indicatorPadding` / `textScaler` / `indicatorAnimation`
等参数原样传给 `TabBar`，全站样式放 `TabBarTheme`。要关闭灰色按压块 + ripple，
设置 `overlayColor: WidgetStatePropertyAll(Colors.transparent)` +
`splashFactory: NoSplash.splashFactory`。

## 扩展方法

> `WSizeBox` / `WPadding` / `WRow` / `WColumn` 已在 5.0 删除，直接用 Flutter 原生组件；
> `heightBox` / `widthBox` / `squareBox` / `horizontalPadding` / `verticalPadding` /
> `borderRadius` 已在 12.0 删除，直接用 `SizedBox` / `EdgeInsets` / `BorderRadius`；
> `allPadding` 用于需要 `EdgeInsets` 值的场景。

```dart
const SizedBox(height: 16);
16.allPadding;                // EdgeInsets.all(16)
'#FF5733'.toColor();          // AARRGGBB
'#FF573380'.toCssColor();     // CSS / Figma 的 RRGGBBAA
// 数字格式化（toThousandsSeparated / toCurrency / toPercent）在 w_tools_core 的
// WNumFormatExtension（ui 12.0 移出）。
card.withStartPadding(8).withEndPadding(4); // 跟随 Directionality
2.borderSideOf(context);      // 跟随 ColorScheme.outline（borderSide 已弃用）

const BoxDecoration()
    .withBackground(color: Colors.white)   // color / gradient 二选一
    .circle();                             // 圆形并清空 borderRadius
```

扩展方法随 `package:w_tools_ui/w_tools_ui.dart` 一起导入。

## 工具

```dart
final screen = WScreen.of(context);
screen.w(16);
screen.h(24);
screen.sp(14);

// 资源路径直接传完整路径（12.0 删除了 WAssets.imagePath）
WImageSource.asset('assets/images/logo.png');
```

`WScreen` 无 `WScreenScope` 时返回原始值；需要 `ScreenUtil` 时在 App 根节点注入
`WScreenScope`：

```dart
WScreenScope(
  widthScaler: (v) => ScreenUtil().setWidth(v),
  heightScaler: (v) => ScreenUtil().setHeight(v),
  fontScaler: (v) => ScreenUtil().setSp(v),
  child: app,
);
```

10.0 起静态 `WScreen.w/h/sp` 与 `WScreen.delegate*` 已删除；
统一用 `WScreenScope` + `WScreen.of(context)`。


## 主要 API

| 能力 | 入口 |
|---|---|
| 文本 / 图片 | `WText` / `WImage` |
| 按钮 / 点击 | `WButton` / `WPressable` |
| 徽标 / 横向操作 | `WBadge` / `WActionRow` / `WSelectableRow` |
| 裁剪 | Flutter 原生 `ClipRRect`（`WClipRRect` 已删除） |
| 加载指示 | `WGradientCircularProgressIndicator` |
| 列表保活 | `WKeepAliveWrapper` |
| 滚动通知 | `WNotificationListener` |
| 布局 | `WScaffold` / `WAppBar` / `WListView` |
| 导航 | `WNavBar` / `WNavController` |
| 屏幕工具 | `WScreen` / `WScreenScope` |
| 资源 | `WImageSource.asset`（完整路径） |
| 扩展 | `WColorExtension` / `WImageStyleExtension` / `WStringExtension` / `WNumLayoutExtension` / `WWidgetExtension` / `WBoxDecorationExtension` |

完整构造参数与成员见 [pub.dev API 文档](https://pub.dev/documentation/w_tools_ui/latest/)
或 `packages/ui/lib` 源码；模块边界与设计取舍见 [`docs/modules/ui_module.md`](https://github.com/stone0533/w_tools/blob/main/docs/modules/ui_module.md)。

## License

MIT
