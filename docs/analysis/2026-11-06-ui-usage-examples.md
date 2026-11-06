# w_tools_ui 使用示例与选型分析（7.0.0）

> 生成日期：2026-11-06 · 基于工作区当前源码（`packages/ui`，未发布改动）
> 范围：`w_tools_ui` 全部公开组件 + 扩展 + 工具；不含 form / async / toast 等其它子包。
> 文中代码块用同一份骨架在 `packages/ui/example` 下通过 `dart analyze` 校验，构造参数与
> 当前源码一致；完整可运行场景见 [`packages/ui/example`](../../packages/ui/example/README.md)。

---

## 1. 结论速览

`w_tools_ui` 的设计可以概括成三句话：

1. **文字走语义**：`WText(variant:)` + 主题里装一次 `WTextStyles`，不在调用点写整段 `TextStyle`。
2. **样式走值对象**：`WImageStyle` / `WButtonStyle` / `WButtonSize` / `WStepStyle` / `WAppBarStyle` 都是
   `const` 不可变对象，用 `copyWith` / 预设工厂派生，不散落参数。
3. **图片三分**：视觉（`WImageStyle`）、加载行为（`WImageLoadOptions`）、占位/错误/进度（`WImageSlots`）
   各管一段，互不越界。

| 需求 | 入口 | 不要用 |
| --- | --- | --- |
| 普通业务按钮 | `WButton` | `ElevatedButton` / 自绘 Container |
| 任意 child / 整卡片点击 | `WPressable` | `GestureDetector`（无按压反馈）/ `WButton`（语义不对） |
| 表单里的值选择 | `WFormButton`（form 包） | `WButton` 手写 |
| 文本 | `WText(variant:)` | 裸 `Text(style: ...)` |
| 图片 | `WImage.source` + `WImageSource` | `Image.network` / `Image.asset` |
| 页面骨架 | `WScaffold` + `WAppBar` | 手拼 `Scaffold`（消费方项目用 CLI 生成的 AppScaffold） |
| 列表 | `WListView` / `WListViewSliver` | 手写 `CustomScrollView` + sliver（除非要组合别的 sliver） |
| 底部 tab | `WNavBar` + `WNavController` | `BottomNavigationBar` |
| 顶部 tab | `WTabBar`（需 `TabController`） | `WTabBar` 单独用（不自带 controller） |
| 步骤条 | `WStep` / `WStepFlow` | 手拼 Row + 圆圈 |
| 角标 | `WBadge` | 绝对定位 Container |
| 屏幕 / 字体适配 | `WScreen` | 到处 `MediaQuery` 手算 |
| 资源前缀 | `WAssets.imagePath` / `'x.png'.assetImagePath` | 硬编码 `assets/...` |

---

## 2. 包边界与导出面

- 依赖只有 `flutter`、`badges`（角标）、`cached_network_image`（网络图缓存）；**不依赖任何其它
  w_tools 子包**，可以单独引入。
- 最低 Flutter 3.38 / Dart SDK ^3.10。
- 单一入口：

```dart
import 'package:w_tools_ui/w_tools_ui.dart';
```

导出面分四层：

| 层 | 内容 | 文件 |
| --- | --- | --- |
| 组件 | 文本 / 图片 / 按钮 / 徽标 / 裁剪 / 列表 / 导航 / 步骤 / 进度 / 保活 / 通知 | `lib/src/components/` |
| 扩展 | 数字、字符串、颜色、TextStyle、Widget、BoxDecoration、GlobalKey | `lib/src/extensions/` |
| 预设 | `WGradients` / `WShadows` | `lib/src/styles/` |
| 工具 | `WScreen` / `WAssets` | `lib/src/utils/` |

> `WSizeBox` / `WPadding` / `WRow` / `WColumn` 在 5.0 已删除，间距直接用原生 `SizedBox`。

---

## 3. 全局装配：只做一次的三件事

### 3.1 装 `WTextStyles`（否则只有兜底排版）

```dart
import 'package:flutter/material.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: Colors.indigo);
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  // 一次装好：既写 ThemeData.textTheme（给 Material 组件），
  // 又注册 ThemeExtension（给 WText 的 price / number / badge）。
  return base.withWTextStyles(WTextStyles.fromTextTheme(base.textTheme));
}

// 有品牌字号的场景，自己造 WTextStyles（11 个角色都是 required）：
final brandStyles = WTextStyles(
  display: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700),
  headline: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
  title: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
  body: const TextStyle(fontSize: 15, height: 1.5),
  bodyStrong: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
  caption: const TextStyle(fontSize: 12, color: Color(0xFF8A8A8A)),
  label: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
  button: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
  price: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
  number: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
  badge: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
);
```

为什么两步都要：form / toast / async 只读 `Theme.of(context).textTheme`，`WText` 的
`price` / `number` / `badge` 读 `WTextStyles` 扩展；`withWTextStyles` 一次写两处。

### 3.2 装 App 级图片兜底（可选）

```dart
WImageTheme(
  slots: WImageSlots(
    placeholderBuilder: (context, data) =>
        const Center(child: CircularProgressIndicator()),
    errorWidgetBuilder: (context, data, error) => const Icon(Icons.broken_image),
  ),
  child: app,
)
```

`WImageTheme` 只继承 **slots**，不会改单图的 `WImageStyle` / `WImageLoadOptions`。

### 3.3 配资源前缀与屏幕适配

```dart
// 启动时一次；末尾 `/` 会自动补齐，空字符串表示不加前缀。
WAssets.imagePath = 'assets/images/';

// 需要 flutter_screenutil 的等比缩放时，在 build 期注入 delegate。
ScreenUtilInit(
  designSize: const Size(375, 667),
  builder: (context, child) {
    WScreen.delegateWidth = (v) => ScreenUtil().setWidth(v);
    WScreen.delegateHeight = (v) => ScreenUtil().setHeight(v);
    WScreen.delegateFont = (v) => ScreenUtil().setSp(v);
    return child!;
  },
)
```

`WScreen` 无 delegate 时是恒等函数（返回原值），所以不装也能跑。

---

## 4. 文本：`WText`

### 4.1 11 个语义角色

| variant | 用途 | 兜底槽位 |
| --- | --- | --- |
| `display` | 超大展示文字 | `displayLarge` |
| `headline` | 页面主标题 | `headlineMedium` |
| `title` | 区块标题 | `titleLarge` |
| `price` | 价格 | `headlineSmall` |
| `body` | 正文 | `bodyLarge` + `bodyMedium` |
| `bodyStrong` | 强调正文 | `titleMedium` |
| `number` | 数字 / 指标 | 不投影（兜底 `bodyLarge`） |
| `caption` | 辅助说明 | `bodySmall` |
| `label` | 标签 | `labelMedium` |
| `button` | 按钮文字 | `labelLarge` |
| `badge` | 角标 | `labelSmall` |

### 4.2 常用写法

```dart
// import 'dart:ui' show FontFeature;
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const WText(text: '账户余额', variant: WTextVariant.title),
    const WText(
      text: '最近 30 天的收支明细，按时间倒序排列',
      variant: WTextVariant.body,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    ),
    const WText(
      text: '¥128.00',
      variant: WTextVariant.price,
      // 一次性覆盖只写需要改的字段：价格用等宽数字防跳动。
      style: TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
    ),
    const WText(text: '已售 1,234', variant: WTextVariant.caption),
    const WText(text: '新品', variant: WTextVariant.badge, color: Colors.white),
    WText(
      text: '保存失败',
      variant: WTextVariant.body,
      color: Theme.of(context).colorScheme.error,
    ),
    const WText(
      text: '订单金额 ¥128.00',
      variant: WTextVariant.body,
      // 视觉文案与读屏文案不一致时单独提供，读屏更自然。
      semanticsLabel: '订单金额 128 元',
    ),
  ],
)
```

### 4.3 规则与反例

- 先查 variant，`price` / `number` / `badge` 已覆盖价格、指标、角标常见场景。
- `style` 合法但只写差异字段；**颜色用 `color:` 或主题**，不要 `style: TextStyle(color: ...)`。
- 消费方不能新增 `WTextVariant`；跨页重复样式先做本地 helper/常量。
- 反例：`WText(text: '标题', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: ...))`
  —— 绕过了主题、暗色模式和 ScreenUtil 字号。
- `variant` 为 null 且不传 `style` 时，`WText` 直接继承 `DefaultTextStyle`（不会强加 body 样式）。

---

## 5. 图片：`WImage` + `WImageSource`

### 5.1 心智模型

```text
WImageSource      图片来源：network / asset / file / base64 / provider / parse
WImageStyle       视觉：尺寸 / fit / 圆角 / 边框 / 阴影 / 比例 / 语义
WImageLoadOptions 行为：解码尺寸 / 自动重试 / gapless
WImageSlots       单图占位 / 错误 / 进度 / 重试按钮
WImageTheme       App 级 slots 兜底
WImageController  手动重试 + 状态监听
```

四者不会互相覆盖（唯一例外见 §5.5 的重试视图规则）。

### 5.2 六种来源

```dart
// 网络（可带请求头与缓存 key；换图但 URL 不变时用 cacheKey 破缓存）
WImage.source(
  source: WImageSource.network(
    'https://example.com/a.png',
    headers: const {'Authorization': 'Bearer token'},
    cacheKey: 'a-v2',
  ),
  style: const WImageStyle(width: 80, height: 80),
);

// 资源（默认不拼 WAssets.imagePath；prefix: true 才拼）
WImage.source(source: WImageSource.asset('logo.png', prefix: true));

// 本地文件（Web 不支持，resolve 会抛 UnsupportedError）
WImage.source(source: WImageSource.file('/data/user/0/app/files/a.png'));

// Base64（可带 data: 前缀，前缀会自动剥离）
WImage.source(
  source: WImageSource.base64('data:image/png;base64,AAAA'),
  style: const WImageStyle(width: 64, height: 64),
);

// 任意 ImageProvider（已有 provider、内存图走这里）
WImage.source(
  source: WImageSource.provider(MemoryImage(bytes)),
  style: WImageStyle.avatar(40),
);

// 动态字符串：自动判定
// http(s):// 或 // → network；file: → file；data: → base64；其它 → asset
WImage.source(source: WImageSource.parse(urlFromApi));
```

### 5.3 视觉：`WImageStyle`

```dart
// 预设：头像（方形 + 全圆角）
WImageStyle.avatar(40)
// 预设：列表缩略图（正方形视觉占位）
WImageStyle.thumbnail(80)
// 预设：封面（固定比例 + 可选圆角）
WImageStyle.cover(aspectRatio: 16 / 9, radius: 12)
// 链式糖
const WImageStyle().square(40).rounded(20)

// 完整写法
const WImageStyle(
  aspectRatio: 16 / 9,
  fit: BoxFit.cover,
  borderRadius: BorderRadius.all(Radius.circular(12)),
  border: Border.fromBorderSide(BorderSide(color: Color(0x11000000))),
  boxShadow: WShadows.card,
);
```

两条硬约束（debug assert）：

- `aspectRatio` **不能**与 `width` / `height` 同时设置；
- `width` / `height` 只约束图片内容，`padding` / `margin` **会加在总尺寸上**
  （`width: 10` + `padding: 5` → 总宽 20），与 `Container` 的盒模型不同。

尺寸兜底：没有 `width` / `height` / `aspectRatio` 时必须由父级约束
（`SizedBox` / `Expanded` / `AspectRatio`），否则在 `Row` / `Column` / `ListView` 里加载前是
0 尺寸，表现为空白（debug 会打印提示）。

### 5.4 加载行为：`WImageLoadOptions`

```dart
WImage.source(
  source: WImageSource.network(url),
  style: WImageStyle.thumbnail(80),
  options: const WImageLoadOptions(
    memCacheWidth: 240,   // 解码尺寸上限（物理像素），列表里必配
    memCacheHeight: 240,
    retryCount: 2,        // 仅网络自动重试次数
    retryDelay: 1000,     // 重试基础间隔（毫秒）
    gaplessPlayback: true,
  ),
);
```

### 5.5 占位 / 错误 / 进度：`WImageSlots`

```dart
WImage.source(
  source: WImageSource.network(url),
  style: const WImageStyle(width: 120, height: 120),
  slots: WImageSlots(
    placeholderBuilder: (context, data) => const Center(child: CircularProgressIndicator()),
    progressBuilder: (context, data, progress) =>
        LinearProgressIndicator(value: progress.fraction), // 总大小未知时 fraction 为 null
    errorWidgetBuilder: (context, data, error) => Center(
      child: Text(error.message), // 按 error.kind 分支更稳
    ),
    // 内置「错误 + 重试」视图；只对 network / provider / file 给按钮
    showRetryButton: true,
    retryLabel: '重新加载',
  ),
);
```

优先级：单图 slots 的非空字段 > `WImageTheme` > 内置兜底。

注意：`showRetryButton: true` 时**不再继承主题的 error builder**——否则主题自定义错误 UI 会盖掉
内置重试视图。需要「主题错误样式 + 重试」就自己在 `errorWidgetBuilder` 里放按钮调
`controller.retry()`。

### 5.6 手动重试与状态监听

```dart
class RetryableImage extends StatefulWidget {
  const RetryableImage({super.key, required this.url});
  final String url;

  @override
  State<RetryableImage> createState() => _RetryableImageState();
}

class _RetryableImageState extends State<RetryableImage> {
  final _controller = WImageController();

  @override
  void dispose() {
    _controller.dispose(); // 一个 controller 只能绑一张图
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<WImageLoadSnapshot>(
      valueListenable: _controller.state,
      builder: (context, snapshot, _) => Column(
        children: [
          WImage.source(
            source: WImageSource.network(widget.url),
            controller: _controller,
            slots: const WImageSlots(showRetryButton: true),
            onLoadStatusChanged: (status) => debugPrint('status: $status'),
            onProgress: (progress) => debugPrint('fraction: ${progress.fraction}'),
          ),
          if (snapshot.status == WImageLoadStatus.failed)
            TextButton(
              onPressed: _controller.retry,
              child: Text('立即重试（第 ${snapshot.attempt} 次）'),
            ),
        ],
      ),
    );
  }
}
```

### 5.7 预加载

```dart
// 与 WImage 使用同一套尺寸规则；尺寸不一致会导致二次解码。
final provider = await WImageSource.network(url).resolve(
  memCacheWidth: 240,
  memCacheHeight: 240,
);
await precacheImage(provider, context);
```

### 5.8 错误分类

```dart
// WImageErrorKind: empty / network / asset / decode / provider / file / unsupported
if (error.kind == WImageErrorKind.network) {
  // 可引导用户检查网络
}
```

不要用字符串比较错误信息；`WImageError` 不要自己构造来 mock 失败，用真实 `WImageSource` 触发。

---

## 6. 按钮：`WButton` 与 `WPressable`

### 6.1 样式分层

| 层 | 类型 | 管什么 |
| --- | --- | --- |
| 视觉 | `WButtonStyle` | 颜色 / 渐变 / 边框 / 圆角 / 阴影 / 内边距 / 动效 / 语义 |
| 预设 | `WButtonStyles.of(context)` | `primary` / `secondary` / `text` / `danger`，按 `ColorScheme` 派生 |
| 尺寸 | `WButtonSize` | `small` / `medium` / `large`，或自定义值对象 |
| 动效 | `WButtonMotion` | opacity / scale / none |
| 语义 | `WButtonSemantics` | 朗读 label / hint / loadingLabel |
| 内容 | `content` / `contentBuilder` | 复杂排版，`contentBuilder` 能拿到已应用 size 的最终样式 |

`WButton` **不含 width**：宽度由父布局（`Expanded` / `SizedBox` / `Row`）决定。

### 6.2 常用按钮

```dart
final buttons = WButtonStyles.of(context);

Column(
  children: [
    // 默认就是 primary
    WButton(label: '保存', onTap: () {}),
    // loading 期间自动不可点，无需自己再传 enabled: false
    WButton(label: '提交中', loading: true, onTap: () {}),
    // 预设四态
    WButton(label: '取消', style: buttons.secondary, onTap: () {}),
    WButton(label: '删除', style: buttons.danger, onTap: () {}),
    WButton(label: '更多', style: buttons.text, onTap: () {}),
    // 图标 + 文字 / 纯图标（纯图标必须给语义标签）
    WButton(icon: Icons.add, label: '新增', onTap: () {}),
    WButton(icon: Icons.search, semanticLabel: '搜索', onTap: () {}),
    // 尺寸
    WButton(label: '小按钮', size: WButtonSize.small, onTap: () {}),
    // 长按
    WButton(icon: Icons.mic, semanticLabel: '按住说话', onLongPress: () {}),
    // 自定义加载占位
    WButton(
      label: '导出',
      loading: true,
      loadingBuilder: (context) => const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      onTap: () {},
    ),
  ],
)
```

### 6.3 复杂内容：`contentBuilder`

```dart
WButton(
  contentBuilder: (context, style) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.shopping_cart, size: style.iconSize, color: style.foregroundColor),
      const SizedBox(width: 8),
      Text('去结算', style: style.textStyle),
      const SizedBox(width: 8),
      Text('¥128.00', style: style.textStyle),
    ],
  ),
  onTap: () {},
)
```

`WButtonResolvedStyle` 是对当前 `WidgetState` 生效的最终样式，**不要缓存跨帧使用**。

### 6.4 项目级按钮注册表（推荐）

单页 Demo 用 `WButtonStyles.of(context)` 够；业务项目建议像示例工程一样集中一层，
页面只传 `style`，品牌调整只改一处：

```dart
// lib/ui/app_buttons.dart
abstract final class AppButtons {
  static WButtonStyle primary(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return WButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.pressed)) {
          return scheme.primary.withValues(alpha: 0.82);
        }
        return scheme.primary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.38);
        }
        return scheme.onPrimary;
      }),
      borderRadius: BorderRadius.circular(8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      disabledOpacity: 1,
    );
  }

  static WButtonStyle secondary(BuildContext context) =>
      WButtonStyle.outlined(foregroundColor: Theme.of(context).colorScheme.primary);

  static WButtonStyle danger(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return WButtonStyle.filled(
      backgroundColor: scheme.error,
      foregroundColor: scheme.onError,
      borderRadius: BorderRadius.circular(8),
    );
  }
}

// 页面
WButton(label: '保存', style: AppButtons.primary(context), onTap: save);
```

### 6.5 任意 child 点击：`WPressable`

```dart
WPressable(
  onTap: () => openDetail(item),
  effect: WPressEffect.scale, // opacity（默认）/ scale / none
  child: Card(child: ListTile(title: Text(item.title))),
)
```

| 用 `WButton` | 用 `WPressable` |
| --- | --- |
| 需要按钮语义 / 键盘焦点 / 48×48 最小点击区 | 整卡片 / 整行 / 任意布局 |
| 有 label 或 icon | 内容完全自定义 |
| loading / disabled 状态 | 只做按压反馈 |

需要 button 语义时不要用 `WPressable`；`WPressable` 不做 loading，也不做无障碍按钮角色。

---

## 7. 页面骨架：`WScaffold` / `WAppBar`

### 7.1 两种模式（二选一）

```dart
// 模式 A：便捷参数，内部自动构建 WAppBar
WScaffold(
  title: '首页',
  actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.search))],
  floatingActionButton: FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add)),
  body: const Center(child: WText(text: 'Hello')),
);

// 模式 B：显式 appBar（推荐用于需要自定义样式的页面）
WScaffold(
  appBar: WAppBar(
    title: '详情',
    actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.share))],
    style: const WAppBarStyle(
      gradient: LinearGradient(colors: [Colors.indigo, Colors.blue]),
      foregroundColor: Colors.white,
      height: 52,
    ),
  ),
  body: const SizedBox.shrink(),
);
```

两条 assert：

- 传了 `appBar` 就不能再传 `title` / `titleWidget` / `leading` / `actions` / `onBack` /
  `appBarStyle` / `appBarBottom`；
- 把 `WAppBar` 作为 `appBar` 传时必须 `includeStatusBar: true`（默认就是），否则状态栏背景会断。

### 7.2 常用槽位

```dart
WScaffold(
  titleWidget: Row(children: const [Icon(Icons.lock), SizedBox(width: 6), Text('安全中心')]),
  leading: IconButton(onPressed: () {}, icon: const Icon(Icons.menu)),
  onBack: () {},                       // 自定义返回；不传走默认 Navigator.maybePop
  appBarBottom: const TabBar(tabs: [Tab(text: '全部'), Tab(text: '已完成')]),
  body: content,
  bottomNavigationBar: navBar,
  backgroundColor: const Color(0xFFF7F8FA),
  systemStatusBarStyle: SystemUiOverlayStyle.dark,
  underlayWidget: const DecoratedBox(decoration: BoxDecoration(gradient: ...)),
);
```

- `underlayWidget` 会与 body 叠在 `Stack` 里（底层装饰、上层内容）。
- 安全区：`includeTopSafeArea` 默认 `false`（有 appBar 时由 Scaffold 处理）；`includeBottomSafeArea`
  默认 `true`，但传了 `bottomNavigationBar` 时不再补底部 padding。
- `title` 与 `titleWidget` 互斥。

### 7.3 `WAppBarStyle`

```dart
const WAppBarStyle(
  backgroundColor: Colors.white,   // 与 gradient 只能选一个（assert）
  foregroundColor: Colors.black87,
  titleStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
  height: 48,                     // 不含状态栏
  titleSpacing: 0,
  systemOverlayStyle: SystemUiOverlayStyle.dark,
)
```

`WAppBar.preferredSize` 只算 toolbar + bottom，不含状态栏（Scaffold 会补 top padding）。

---

## 8. 列表：`WListView` / `WListViewSliver`

### 8.1 四种构造

```dart
// 普通列表（可带 header / footer / 空态）
WListView(
  controller: scrollController,
  sliver: WListViewSliver.list(
    itemCount: items.length,
    itemBuilder: (context, index) => ListTile(title: Text(items[index].title)),
    padding: const EdgeInsets.all(16),
    header: const Padding(padding: EdgeInsets.all(16), child: WText(text: '最近')),
    empty: const Center(child: WText(text: '暂无数据')),
    emptyFill: true,   // 空态撑满视口；与 shrinkWrap: true 互斥
    keepAlive: true,   // 列表项保活
  ),
);

// 分割线
WListView(
  sliver: WListViewSliver.separated(
    itemCount: 10,
    itemBuilder: (context, index) => ListTile(title: Text('$index')),
    separatorBuilder: (context, index) => const Divider(height: 1),
  ),
);

// 网格
WListView(
  sliver: WListViewSliver.grid(
    itemCount: 6,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
    ),
    itemBuilder: (context, index) => Card(child: Center(child: Text('$index'))),
  ),
);

// 叠压（朋友圈式九宫格 / 头像堆叠），只支持垂直、非 reverse
WListView(
  sliver: WListViewSliver.overlap(
    itemCount: 8,
    itemExtent: 80,
    overlap: 24,
    itemBuilder: (context, index) => Card(child: Center(child: Text('$index'))),
  ),
);
```

### 8.2 嵌入已有滚动容器

```dart
CustomScrollView(
  slivers: [
    const SliverAppBar(title: Text('相册')),
    WListViewSliver.grid(...),
    const SliverToBoxAdapter(child: SizedBox(height: 24)),
  ],
)
```

`WListViewSliver` 只是 sliver 内容描述：**不要**放进非 sliver 子树；要独立滚动再用 `WListView`。

### 8.3 坑

- `shrinkWrap: true` + `emptyFill: true` 会 assert；
- `overlap` 只支持垂直非 reverse；
- `itemCount` 为 0 时 `empty` 才会出现，`emptyFill` 决定是否撑满；
- header / footer 不参与 `empty` 判断。

---

## 9. 导航：`WNavBar` 与 `WTabBar`

### 9.1 底部 tab（controller 由页面持有）

```dart
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with SingleTickerProviderStateMixin {
  late final _nav = WNavController(length: 3, vsync: this);

  @override
  void dispose() {
    _nav.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WScaffold(
      // 页面内容要跟着 controller 重建；WNavBar 只重建自己。
      body: ListenableBuilder(
        listenable: _nav,
        builder: (context, _) => IndexedStack(
          index: _nav.currentIndex,
          children: const [HomePage(), OrdersPage(), ProfilePage()],
        ),
      ),
      bottomNavigationBar: WNavBar(
        controller: _nav,
        // 返回 false 可阻止切换（如未登录时拦截「我的」）
        onItemTap: (index) async {
          if (index == 2 && !isLoggedIn) {
            await showLoginSheet(context);
            return false;
          }
          return true;
        },
        itemBuilder: (context, index, selected) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? _icons[index] : _outlinedIcons[index]),
            WText(
              text: _labels[index],
              variant: WTextVariant.caption,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
```

要点：`WNavController` 需要 `vsync`，由页面 `dispose`；`WNavBar` 只加/移除监听，不释放 controller；
`onItemTap` 异步回调乱序时以最后一次为准。

`WNavBarStyle` / `WNavBarConfig` 只控制外层装饰与 padding；选中态和切换动画归 controller。

### 9.2 顶部 tab

```dart
DefaultTabController(
  length: 2,
  child: Column(
    children: [
      WTabBar(
        tabs: const [Text('全部'), Text('已完成')],
        style: const WTabBarStyle(
          isScrollable: true,
          indicatorColor: Colors.indigo,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
        ),
        onTap: (index) {},
      ),
      const Expanded(
        child: TabBarView(children: [Text('全部内容'), Text('已完成内容')]),
      ),
    ],
  ),
)
```

`WTabBar` 不自带 controller：用 `DefaultTabController` 或显式传 `TabController`。
`WTabBarStyle` 与旧 `WTabBarConfig` 字段一一对应，新代码用 `style`。

---

## 10. 步骤：`WStep` / `WStepFlow`

```dart
// 最简
const WStep(current: 2, labels: ['下单', '付款', '完成']);

// 复用流程（labels 在构造时冻结）
final flow = WStepFlow(
  labels: const ['下单', '付款', '完成'],
  style: const WStepStyle(itemSize: 28, labelSpacing: 8, separatorHeight: 2),
);

flow.build(current: step);            // 每次只传 current
flow.copyWith(labels: newLabels);     // 派生新流程

// 自定义节点 / 分割线 / 语义
WStep(
  current: 1,
  labels: const ['A', 'B'],
  itemBuilder: (context, index, state) => Text('$index:$state'),
  separatorBuilder: (context, index, completed) => const Divider(),
  semanticLabelBuilder: (current, total) => '第 $current 步，共 $total 步',
);
```

- `current` **从 1 开始**，范围 `1..labels.length`（assert）；
- `itemBuilder` 里的 widget 已被 `Expanded` 包住，不要再返回 `Expanded`；
- `WStepState` 三态：`completed` / `current` / `upcoming`，按 enum 分支，不要比字符串。

---

## 11. 通用小组件

### 11.1 `WBadge`

```dart
WBadge(
  badgeContent: const WText(text: '3', variant: WTextVariant.badge, color: Colors.white),
  badgeStyle: BadgeStyle(
    badgeColor: Colors.red,
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    borderRadius: BorderRadius.circular(10),
  ),
  position: BadgePosition.topEnd(top: -4, end: -4),
  child: const Icon(Icons.notifications),
);

// 显隐与空内容
WBadge(showBadge: unread > 0, badgeContent: Text('$unread'), child: icon);
```

- 默认 `badgeStyle` 是**透明**的，颜色靠 `badgeContent` 自带背景或显式传 `badgeStyle`；
- `badgeContent` 为空时静默不渲染；`position` 只决定角标相对 child 的锚点，不参与外部布局；
- 状态点（无文字）不要用 `WBadge`，用原生 `Container`。

### 11.2 `WClipRRect`

```dart
WClipRRect(
  borderRadius: BorderRadius.circular(12),
  child: content,
);

WClipRRect(
  config: WClipRRectConfig.all(12),
  clipBehavior: Clip.antiAlias,
  child: content,
);
```

图片圆角别用它，走 `WImageStyle.borderRadius`（否则会多一层裁剪、影响阴影）。

### 11.3 横向操作行

```dart
SizedBox(
  height: 44,
  child: WActionRow(
    spacing: 8,
    children: [
      WButton(label: '全部', size: WButtonSize.small, onTap: () {}),
      WButton(label: '待付款', size: WButtonSize.small, onTap: () {}),
      WButton(label: '已完成', size: WButtonSize.small, onTap: () {}),
    ],
    onScroll: (offset) {},
  ),
);

// 单选高亮
WSelectableRow(
  itemCount: filters.length,
  selectedIndex: selected,
  onSelected: (index) => setState(() => selected = index),
  scrollToSelected: true,
  builder: (context, index, isSelected) => ChoiceChip(
    label: Text(filters[index]),
    selected: isSelected,
    onSelected: (_) => setState(() => selected = index),
  ),
);
```

`WActionRow` 无选中语义；纯静态排列直接用 `Row`，别为了滚动硬套。

### 11.4 进度、保活、通知

```dart
// 环形渐变进度；value 必传（默认 0 = 空环，不是转圈）
const WGradientCircularProgressIndicator(
  radius: 24,
  colors: [Colors.indigo, Colors.lightBlue],
  value: 0.6,
  strokeCapRound: true,
);

// 列表项保活（Tab / PageView 里保留滚动位置与 State）
WKeepAliveWrapper(child: page);

// 声明式监听（新代码优先）
WNotificationListener<ScrollNotification>(
  onNotificationPercentage: (percentage) => setState(() => _progress = percentage),
  onNotification: (notification) => false, // 返回 true 会阻止继续向上传递
  child: listView,
);

// 旧 Builder 链式写法（8.0 前仍可用）
WNotificationListenerBuilder<ScrollNotification>(child: listView)
    .onNotification((notification) => true)
    .onNotificationPercentage((percentage) {})
    .build();
```

百分比只在 `depth == 0` 的 `ScrollUpdateNotification` 上回调。

---

## 12. 屏幕与资源

```dart
class ScreenInfo extends StatelessWidget {
  const ScreenInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final screen = WScreen.of(context); // 跟随最近 MediaQuery，推荐
    return Column(
      children: [
        Text('${screen.width} x ${screen.height}'),
        Text('状态栏 ${screen.statusBarHeight} / 底部安全区 ${screen.bottomSafeAreaHeight}'),
        SizedBox(width: WScreen.w(16), height: WScreen.h(24)),
        Text('标题', style: TextStyle(fontSize: WScreen.sp(14))),
      ],
    );
  }
}
```

- 静态 `WScreen.screenWidth` 等依赖 `WidgetsBinding`，不要在 binding 初始化前调用；
- `.sp` 不要出现在 `main()` / 顶层 `final` / `static` 初始化里；
- 测试里改过 delegate 要 `WScreen.reset()`。

```dart
WAssets.imagePath = 'assets/icons/'; // 自动补 `/`；空串 = 不加前缀
'logo.png'.assetImagePath;           // assets/icons/logo.png
```

---

## 13. 扩展方法速查

| 扩展 | 成员 | 示例结果 |
| --- | --- | --- |
| `WNumExtension` | `heightBox` / `widthBox` / `squareBox` | `16.heightBox` |
| | `allPadding` / `horizontalPadding` / `verticalPadding` | `16.allPadding` → `EdgeInsets.all(16)` |
| | `borderRadius` / `borderSide` / `borderSideOf` | `12.borderRadius` |
| | `toThousandsSeparated` | `1234` → `1,234` |
| | `toCurrency` | `1234.56.toCurrency(symbol: '¥')` → `¥1,234.56` |
| | `toPercent` / `toPercentWithFixed` | `0.125.toPercent` → `12.5%` |
| | `toPadLeft` | `7.toPadLeft(2)` → `07` |
| `WStringExtension` | `toInt` / `toDouble` / `toNum` | `'12'.toInt()` |
| | `trimAll` | `' 1 2 '.trimAll()` → `12` |
| | `toColor` / `assetImagePath` | `'#FF5733'.toColor()` |
| `WColorExtension` | `fromHex` / `toHex` | 支持 `#rgb` / `#argb` / `#rrggbb` / `#aarrggbb` |
| `WTextStyleExtension` | `bold` / `withColor` / `withSize` | `style.withSize(14).bold` |
| `WWidgetExtension` | `expanded` / `with*Padding` / `withDecoration` / `withIntrinsicHeight` / `withTopSafeSpace` / `withBottomBarSpace` | `child.expanded()` |
| `WUiWidgetExtension` | `toPressable` | `card.toPressable(onTap: open)` |
| `WBoxDecorationExtension` | `withColor` / `withoutColor` / `withBorder` / `withBorderRadius` / `withShadow` / `withGradient` / `withShape` / `circle` | 链式组合 |
| `WGlobalKeyExtension` | `offset()` / `rect()` | 读取位置与边界 |
| `WGradients` | `vertical` / `horizontal` / `diagonal` / `radial` | 只给方向，颜色由调用方传 |
| `WShadows` | `none` / `card` / `elevated` / `floating` | 中性预设 |

```dart
final decoration = const BoxDecoration()
    .withColor(Colors.white)
    .withBorderRadius(BorderRadius.circular(8))
    .withShadow(WShadows.card)
    .withBorder(Border.all(color: Colors.black12));

Text('${1234.toThousandsSeparated} 次');       // 1,234 次
Text(1234.56.toCurrency(symbol: '¥'));         // ¥1,234.56
Text(0.125.toPercent);                          // 12.5%
Text('', style: const TextStyle().withSize(14).bold);
```

`WGlobalKeyExtension.offset()` / `rect()` 在首帧前返回 `null`，只能读位置，不要拿它替代状态传递。

---

## 14. 易错点清单

| 场景 | 现象 | 原因 / 正确做法 |
| --- | --- | --- |
| `WImage` 没给尺寸 | 加载前一片空白 | 父级没有约束；补 `width` / `height` / `aspectRatio` 或 `SizedBox` |
| `WImageStyle` 同时给 `aspectRatio` 和宽高 | debug assert | 二选一 |
| `WImageStyle` 的 padding | 总尺寸比预期大 | padding / margin 计入总尺寸（与 Container 不同） |
| `asset` 图片 404 | 路径缺前缀 | `WImageSource.asset(name)` 默认不拼前缀；用 `prefix: true` 或 `WAssets.imagePath` |
| 重试按钮被主题盖住 | 看不到内置重试 | `showRetryButton: true` 时不继承主题 error builder；要自定义就在 builder 里放按钮 |
| 列表图片内存高 | 大图全尺寸解码 | 配 `WImageLoadOptions.memCacheWidth/Height`，与预加载尺寸保持一致 |
| `WButton` 只给 icon | debug assert | 纯图标必须传 `semanticLabel` |
| `WButton` 同时传 label 和 content | debug assert | `content` / `contentBuilder` / `label+icon` 三选一 |
| `WButton(enabled: true)` 没给回调 | debug assert | 可交互按钮至少给 `onTap` 或 `onLongPress` |
| `WPressable` 当按钮用 | 读屏 / 键盘不可用 | 需要 button 语义、loading、最小点击区时用 `WButton` |
| `WScaffold(appBar: ...)` 又传 title | debug assert | 两种模式互斥 |
| `WScaffold(appBar: WAppBar(includeStatusBar: false))` | assert | 作为 appBar 时必须包含状态栏 |
| `WTabBar` 单独用 | 运行时缺 TabController | 外面套 `DefaultTabController` 或传 `controller` |
| `WNavController` 没 dispose | 动画资源泄漏 | 页面 `dispose` 里释放；`vsync` 用 `TickerProviderStateMixin` |
| `WStep(current: 0)` | debug assert | `current` 从 1 开始 |
| `WStep.itemBuilder` 返回 `Expanded` | 布局异常 | 外层已经包了 `Expanded` |
| `WGradientCircularProgressIndicator` 不传 value | 显示空环 | `value` 默认 0；必须显式传进度 |
| `WNotificationListener` 百分比不回调 | 收不到值 | 只处理 `depth == 0` 的 `ScrollUpdateNotification` |
| 在 `main()` 里写 `.sp` / `Theme.of` | 崩溃或取不到主题 | 移到 `builder` / `build` 期 |
| `WText` 里写整段 `style` | 暗色模式 / 字号失效 | 用 `variant` + 只覆盖差异字段 |
| 表单字段用 `WButton` 做值选择 | 语义 / 校验不统一 | 用 `WFormButton` |

---

## 15. 与示例工程的对照

示例工程 [`packages/ui/example`](../../packages/ui/example/README.md) 是这些用法的可运行版本，
每页对应本文一节：

| 页面 | 文件 | 覆盖本文 |
| --- | --- | --- |
| Playground | `lib/playground_page.dart` | §5 图片全参数实时调整 + 代码生成 |
| 状态矩阵 | `lib/states_page.dart` | §5.5 / §5.6 成功 / 失败 / 空 / 加载 / 主题兜底 / 预加载 |
| 常用配方 | `lib/recipes_page.dart` | §5.2 / §5.3 avatar / thumbnail / cover / prefix / provider |
| 按钮 | `lib/buttons_page.dart` | §6 四态 / loading / 尺寸 / 语义 / contentBuilder / 动效 / `WPressable` |
| 组件 | `lib/components_page.dart` | §11 徽标 / 裁剪 / 进度 / 步骤 / 列表 / 操作行 / tab / 通知 / 保活 |
| WScaffold / WAppBar / WScreen | `lib/scaffold_page.dart` | §7 / §12 |
| WText / WTextStyles | `lib/text_page.dart` | §4 |
| 扩展方法 | `lib/extensions_page.dart` | §13 |
| 列表 / 通知 / 保活 | `lib/lists_page.dart` | §8 / §11.4 |
| 导航 / Tab | `lib/nav_page.dart` | §9 |
| 步骤 | `lib/steps_page.dart` | §10 |

运行：

```bash
cd packages/ui/example
flutter pub get
flutter run
```

示例使用 `https://picsum.photos` 远程图；重试演示用必然失败的 `example.invalid`。

---

## 16. 验证与门禁

```bash
# 单包测试
cd packages/ui && flutter test

# 示例工程（页面可切换、二级页可打开、代码面板 API 正确）
cd packages/ui/example && flutter test

# 仓库门禁（改公开 API / catalog 后）
python3 scripts/check_public_catalog.py
python3 scripts/check_package_docs.py
bash scripts/preflight.sh --with-tests
```

公开组件增删改时，事实源顺序是：`packages/cli/catalog/components.yaml` →
`dart run tool/gen_catalog.dart` → README / example → 文档门禁。本文是分析记录，
不替代 [`docs/modules/components.md`](../../docs/modules/components.md) 与各包 README。

---

## 17. 一句话选择口诀

```text
文字要语义（WText variant），样式要值对象（*Style + copyWith），
图片分三层（Source / Style+Options / Slots），
按钮看语义（WButton vs WPressable），
骨架用 WScaffold，列表用 WListViewSliver，
导航 controller 自己拿、自己释放，
适配走 WScreen，路径走 WAssets。
```
