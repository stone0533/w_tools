# UI 模块文档

## 概述

UI 模块（`w_tools_ui` 子包）提供了一套基于 Flutter 的 UI 组件层，包含通用组件、布局组件、导航组件、扩展方法和工具类。

**模块特点：**

- **零业务框架依赖**：不依赖其他 w_tools 子包；`qr` 和 `toast` 是独立子包，ui 本身不直接依赖它们，根聚合包负责 re-export
- **最低 Flutter 版本 3.27**：已修复 `ListView cacheExtent` 的版本兼容（Flutter 3.27–3.43 使用 `cacheExtent`，3.44+ 被标记 deprecated，源码已用 `// ignore: deprecated_member_use` 保留兼容性）
- **依赖第三方包**：`badges` ^3.1.2（徽章组件）、`cached_network_image` ^3.3.1（图片缓存）
- **屏幕适配可选**：`WScreen` 内置设备信息获取，适配函数通过委托注入，可与 `flutter_screenutil` 共存，无 delegate 时返回原始值

---

## 模块结构

```
ui/
├── w_tools_ui.dart                 # 统一导出文件
└── lib/src/
    ├── components/
    │   ├── common/                 # 通用组件
    │   │   ├── badge.dart                     # WBadge / WBadgeConfig
    │   │   ├── button.dart                    # WButton, WButtonConfig, WButtonEffectType
    │   │   ├── clip.dart                      # WClipRRect
    │   │   ├── image.dart                     # WImage, WImageConfig, WImageGlobalConfig
    │   │   ├── keep_alive_wrapper.dart        # WKeepAliveWrapper
    │   │   ├── notification_listener.dart      # WNotificationListenerBuilder
    │   │   ├── row_buttons.dart               # WRowButtons
    │   │   ├── text.dart                      # WText, WTextConfig
    │   │   ├── gradient_circular_progress_indicator.dart
    │   │   ├── network_image_with_retry.dart
    │   │   └── rich_text.dart                 # WRichText
    │   ├── layout/                 # 布局组件
    │   │   ├── appbar.dart                    # WAppBar
    │   │   ├── container.dart                 # WContainer / WContainerConfig
    │   │   ├── list_view.dart                 # WListView / WListViewConfig
    │   │   ├── scaffold.dart                  # WScaffold / WScaffoldConfig
    │   │   └── step.dart                      # WStep
    │   └── navigation/             # 导航组件
    │       ├── nav_bar.dart                   # WNavBar / WNavBarConfig
    │       ├── nav_controller.dart            # WNavController
    │       └── tab_bar.dart                   # WTabBar
    ├── extensions/                 # 扩展方法
    │   ├── color.dart                         # HexColor（Color 扩展）
    │   ├── column.dart                        # WColumn / WColumnExtension
    │   ├── global_key.dart                    # WGlobalKeyExtension
    │   ├── image.dart                         # WImageExtension
    │   ├── num.dart                           # WNumExtension
    │   ├── row.dart                           # WRow / WRowExtension
    │   ├── string.dart                        # WStringExtension
    │   ├── strut_style.dart                   # WStrutStyleExtension
    │   ├── text_style.dart                    # WTextStyleExtension
    │   └── widget.dart                        # WWidgetExtension
    └── utils/                      # 工具类
        ├── assets.dart                        # WAssets
        ├── column.dart                        # WColumn / WColumnExtension（另实现）
        ├── image_cache_manager.dart           # WImageCacheManager
        ├── padding.dart                       # WPadding
        ├── row.dart                           # WRow / WRowExtension（另实现）
        ├── screen.dart                        # WScreen
        └── size_box.dart                      # WSizeBox
```

---

## 1. WScreen - 屏幕适配

### 功能说明

零第三方依赖的屏幕尺寸与适配工具。支持获取设备信息（永远可用），也可通过委托注入与 `flutter_screenutil` 共享配置。

无 delegate 时 `w()` / `h()` / `sp()` 返回原始值，不影响未启用屏幕适配的应用。

### 设备信息

| 成员 | 类型 | 说明 |
|------|------|------|
| `screenWidth` | double | 设备屏幕宽度（逻辑像素） |
| `screenHeight` | double | 设备屏幕高度（逻辑像素） |
| `statusBarHeight` | double | 状态栏高度（刘海屏会更高） |
| `bottomBarHeight` | double | 底部安全区高度 |

### 适配委托

| 成员 | 类型 | 说明 |
|------|------|------|
| `delegateWidth` | `double Function(double)?` | 宽度缩放委托（对应 flutter_screenutil 的 `.w`） |
| `delegateHeight` | `double Function(double)?` | 高度缩放委托（对应 flutter_screenutil 的 `.h`） |
| `delegateFont` | `double Function(double)?` | 字体缩放委托（对应 flutter_screenutil 的 `.sp`） |

### 适配函数

| 函数 | 说明 |
|------|------|
| `WScreen.w(double value)` | 宽度缩放，无 delegate 时返回原始值 |
| `WScreen.h(double value)` | 高度缩放，无 delegate 时返回原始值 |
| `WScreen.sp(double value)` | 字体缩放，无 delegate 时返回原始值 |

### 使用示例

```dart
// 1. 不使用任何屏幕适配库
Text('标题', style: TextStyle(fontSize: WScreen.sp(14)));
Container(width: WScreen.w(375), height: WScreen.h(667));

// 2. 与 flutter_screenutil 共存
void main() {
  runApp(ScreenUtilInit(
    designSize: const Size(375, 667),
    builder: (context, child) {
      // 注入委托
      WScreen.delegateWidth = (v) => ScreenUtil().setWidth(v);
      WScreen.delegateHeight = (v) => ScreenUtil().setHeight(v);
      WScreen.delegateFont  = (v) => ScreenUtil().setSp(v);
      return child!;
    },
  ));
}

// 3. 获取设备信息
final statusBar = WScreen.statusBarHeight;
final bottomSafe = WScreen.bottomBarHeight;
```

---

## 2. WButton - 按钮组件

### 功能说明

为子组件添加点击时的视觉反馈效果，支持透明度 / 缩放 / 震动三种效果类型，提供 `button` 语义、鼠标光标与 Enter/Space 键盘激活。禁用时不再响应点击与键盘操作。

### WButtonEffectType 枚举

| 类型 | 说明 |
|------|------|
| `opacity` | 透明度变化：点击时子组件透明度降低（默认 0.7） |
| `scale` | 缩放效果：点击时子组件轻微缩小（默认 0.95） |
| `shake` | 震动效果：点击时子组件产生震动动画 |

### WButton 构造参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `child` | Widget | - | 必需，子组件 |
| `onTap` | `GestureTapCallback?` | null | 点击回调 |
| `onLongPress` | `GestureLongPressCallback?` | null | 长按回调 |
| `config` | `WButtonConfig?` | null | 按钮配置 |

### WButtonConfig 配置参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `tapOpacity` | double | 0.7 | opacity 效果点击时的透明度 |
| `animationDuration` | Duration | 100ms | 动画持续时间 |
| `enabled` | bool | true | 是否启用按钮 |
| `behavior` | HitTestBehavior | opaque | 点击行为 |
| `effectType` | WButtonEffectType | opacity | 按钮效果类型 |
| `scale` | double | 0.95 | scale 效果缩放比例（clamp 0.1~1.0） |
| `curve` | Curve | easeInOut | 动画曲线 |
| `containerConfig` | WContainerConfig? | null | 容器配置（装饰、变换） |
| `textButtonStyle` | WTextConfig? | null | 文本按钮默认样式 |

### WButtonConfig 缓存方法

| 方法 | 说明 |
|------|------|
| `WButtonConfig.opacityEffect({opacity})` | 创建透明度效果配置（带缓存） |
| `WButtonConfig.scaleEffect({scale})` | 创建缩放效果配置（带缓存） |
| `WButtonConfig.shakeEffect()` | 创建震动效果配置（带缓存） |
| `WButtonConfig.getCachedConfig(key, creator)` | 通用缓存获取，返回副本避免污染模板 |
| `WButtonConfig.clearCache()` | 清空所有配置缓存 |
| `WButtonConfig.trimCache()` | 清理超出阈值（100）的缓存 |
| `copy()` | 复制一份独立配置 |
| `buildText(text, {onTap, textStyle})` | 用配置创建文本按钮（WButton + WText） |

### 使用示例

```dart
// 基础用法：透明度效果（默认）
WButton(
  onTap: () => print('clicked'),
  child: Container(
    padding: const EdgeInsets.all(16),
    color: Colors.blue,
    child: const Text('按钮'),
  ),
)

// 使用配置类（链式）
WButton(
  config: WButtonConfig.scaleEffect(scale: 0.92),
  onTap: () => print('clicked'),
  child: const Text('缩放按钮'),
)

// 使用 WButtonConfig.buildText 快速创建文本按钮
final config = WButtonConfig()
  ..effectType = WButtonEffectType.opacity
  ..textButtonStyle = WTextConfig.button();

WButton(
  config: config,
  onTap: () {},
  child: WText(text: '立即开始', config: config.textButtonStyle),
)

// 带容器装饰的按钮
WButton(
  config: WButtonConfig.opacityEffect()
    ..containerConfig = (WContainerConfig()
      ..width = WScreen.w(200)
      ..height = 48
      ..bgColor = Colors.blue
      ..borderRadius = BorderRadius.circular(24)),
  onTap: () {},
  child: const Text('提交', style: TextStyle(color: Colors.white)),
)
```

---

## 3. WText - 文本组件

### 功能说明

增强文本组件，支持链式配置（`WTextConfig`），自动处理 `StrutStyle` 以避免继承大字号时的裁切问题。提供预设样式工厂方法和便捷字号/粗细快捷方法。

### WText 构造参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `text` | String | 必需，文本内容 |
| `config` | `WTextConfig?` | 文本配置 |

### WTextConfig 配置参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `fontFamily` | `String?` | 字体系列 |
| `fontWeight` | `FontWeight?` | 字体粗细 |
| `fontSize` | `double?` | 字体大小 |
| `color` | `Color?` | 文本颜色 |
| `letterSpacing` | `double?` | 字母间距 |
| `height` | `double?` | 行高 |
| `forceStrutHeight` | `bool?` | 是否强制使用行高 |
| `overflow` | `TextOverflow?` | 溢出处理 |
| `decoration` | `TextDecoration?` | 文本装饰 |
| `decorationColor` | `Color?` | 装饰颜色 |
| `textAlign` | `TextAlign?` | 对齐方式 |

### WTextConfig 快捷方法（链式）

**字体系列：**
- `familyNotoSansTC()` → `NotoSansTC`
- `familyZenMaruGothic()` → `ZenMaruGothic`

**字体粗细（w100–w900）：**
- `w100()` / `w200()` / `w300()` / `w400()` / `w500()` / `w600()` / `w700()` / `w800()` / `w900()`

**字号（sp 适配）：**
- `fontSize12sp()` / `fontSize14sp()` / `fontSize16sp()` / `fontSize18sp()` / `fontSize20sp()`
- `fontSize24sp()` / `fontSize26sp()` / `fontSize28sp()` / `fontSize30sp()` / `fontSize32sp()`
- `fontSize34sp()` / `fontSize36sp()` / `fontSize38sp()`

**溢出：**
- `overflowEllipsis()` / `overflowClip()` / `overflowFade()` / `overflowVisible()`

**装饰：**
- `decorationUnderline({decorationColor})` / `decorationOverline({decorationColor})`
- `decorationLineThrough({decorationColor})` / `decorationNone()`

**对齐：**
- `textAlignCenter()` / `textAlignLeft()` / `textAlignRight()` / `textAlignJustify()`
- `textAlignStart()` / `textAlignEnd()`

**其他：**
- `forceStrutHeightFalse()`

### WTextConfig 预设样式工厂

| 工厂方法 | 默认样式 |
|----------|----------|
| `WTextConfig.title()` | fontSize 24, w700, black |
| `WTextConfig.subtitle()` | fontSize 20, w600, black87 |
| `WTextConfig.body()` | fontSize 16, w400, black87, height 1.5 |
| `WTextConfig.small()` | fontSize 14, w400, black54 |
| `WTextConfig.button()` | fontSize 16, w500, white |
| `WTextConfig.link()` | fontSize 16, w400, blue, underline |

### WTextConfig 转换方法

| 方法 | 说明 |
|------|------|
| `toTextStyle()` | 将配置转换为 Flutter `TextStyle` |
| `toStrutStyle()` | 将配置转换为 Flutter `StrutStyle` |
| `copyWith(...)` / `copy()` | 创建副本 |
| `build(text)` | 构建 WText 组件 |

### 使用示例

```dart
// 基础用法
WText(
  text: 'Hello World',
  config: WTextConfig()
    ..fontSize = 16
    ..color = Colors.black
    ..fontWeight = FontWeight.w500,
)

// 使用预设样式
WText(text: '标题', config: WTextConfig.title())
WText(text: '正文内容', config: WTextConfig.body())
WText(text: '小提示', config: WTextConfig.small())

// 链式快捷方法
WText(
  text: '大号粗体居中',
  config: WTextConfig()
    ..fontSize32sp()
    ..w700()
    ..textAlignCenter()
    ..color = Colors.black,
)

// 溢出省略
WText(
  text: '这是一段很长的文本会被省略号截断...',
  config: WTextConfig()
    ..fontSize14sp()
    ..overflowEllipsis(),
)
```

---

## 4. WImage - 图片组件

### 功能说明

智能图片组件，按 `data` 内容自动判定类型（网络 URL / 本地资源 / 文件路径 / Base64），提供占位符、错误处理、加载进度、重试机制和图片变换（圆角、边框、阴影、margin/padding）。

### WImage 构造参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `data` | String | 必需，图片数据 |
| `config` | `WImageConfig?` | 图片配置（可选） |
| `onLoadStatusChanged` | `ValueChanged<WImageLoadStatus>?` | 加载状态回调 |
| `onLoadProgress` | `ValueChanged<double>?` | 加载进度回调 |

### WImageType 枚举

| 类型 | 识别条件 |
|------|----------|
| `asset` | 非 `http://`、`https://`、`file://`、`data:image/` 的字符串 |
| `network` | `http://` 或 `https://` 开头 |
| `file` | `file://` 开头 |
| `base64` | `data:image/` 开头 |

### WImageConfig 配置参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `width` | `double?` | null | 图片宽度 |
| `height` | `double?` | null | 图片高度 |
| `fit` | BoxFit | cover | 图片适配模式 |
| `cacheEnabled` | bool | true | 是否启用缓存 |
| `placeholder` | `Widget?` | 灰色 Container | 加载中占位符 |
| `errorWidget` | `Widget?` | 灰色 Container + error icon | 错误占位符 |
| `progressIndicatorBuilder` | 可选 | - | 进度指示器构建器 |
| `retryCount` | int | 0 | 网络图片重试次数 |
| `retryDelay` | int | 1000 | 重试间隔（毫秒） |
| `borderRadius` | `BorderRadius?` | null | 圆角裁剪 |
| `border` | `BoxBorder?` | null | 边框 |
| `boxShadow` | `List<BoxShadow>?` | null | 阴影 |
| `margin` | `EdgeInsets?` | null | 外边距 |
| `padding` | `EdgeInsets?` | null | 内边距 |

### WImageConfig 链式方法

| 方法 | 说明 |
|------|------|
| `size(width, height)` | 设置尺寸 |
| `circle(radius)` | 设置圆形图片（width/height/borderRadius 一并设置） |
| `fitWidth(width)` / `fitHeight(height)` | 按宽度/高度适配 |
| `fitContain()` / `fitCover()` / `fitFill()` / `fitNone()` / `fitScaleDown()` / `fitCenter()` | 适配模式快捷方法 |
| `build(data, ...)` | 构建 WImage 组件 |
| `buildFilePath(path, ...)` | 从文件路径构建 |
| `buildBase64(base64, ...)` | 从 Base64 构建 |

### WImageGlobalConfig - 全局配置（单例）

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `defaultPlaceholder` | null | 默认加载中占位符 |
| `defaultErrorWidget` | null | 默认错误占位符 |
| `maxCacheSize` | 100 | 最大缓存数量 |
| `maxCacheMemory` | 100MB | 最大缓存内存 |

```dart
// 全局配置（在应用初始化时设置）
WImageGlobalConfig().configure(
  defaultPlaceholder: const CircularProgressIndicator(),
  defaultErrorWidget: const Icon(Icons.broken_image),
  maxCacheSize: 200,
);
```

### 使用示例

```dart
// 网络图片（自动识别 http:// 或 https://）
WImage(
  data: 'https://example.com/image.jpg',
  config: WImageConfig()
    ..size(WImageType.asset: 200, 200)
    ..borderRadius = BorderRadius.circular(12),
)

// 带重试机制的网络图片
WImage(
  data: 'https://example.com/image.jpg',
  config: WImageConfig()
    ..width = 150
    ..height = 150
    ..retryCount = 3
    ..retryDelay = 1500,
)

// 本地资源图片
WImage(data: 'assets/images/logo.png')

// 圆形图片（链式快捷方法）
WImage(
  data: 'https://example.com/avatar.jpg',
  config: WImageConfig()..circle(50),
)

// 带加载状态和进度
WImage(
  data: imageUrl,
  onLoadStatusChanged: (status) {
    if (status == WImageLoadStatus.completed) print('加载完成');
  },
  onLoadProgress: (progress) => print('进度: ${progress * 100}%'),
)
```

---

## 5. WBadge - 徽章组件

### 功能说明

基于 `badges` 包的徽章（角标）组件，用于在子组件上显示角标或标记。

### WBadge 构造参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `config` | WBadgeConfig | 必需，徽章配置 |
| `badgeContent` | `Widget?` | 徽章内容（如数字、图标） |
| `child` | `Widget?` | 子组件 |

### WBadgeConfig 链式方法

| 方法 | 说明 |
|------|------|
| `position({start, end, top, bottom, isCenter})` | 自定义位置 |
| `positionTopRight(top, right)` | 右上角位置 |
| `positionCenter()` | 居中位置 |
| `hideBadge()` | 隐藏徽章 |

### 使用示例

```dart
// 右上角显示数字角标
WBadge(
  config: WBadgeConfig().positionTopRight(-5, -5),
  badgeContent: const Text('3', style: TextStyle(color: Colors.white, fontSize: 12)),
  child: Icon(Icons.notifications),
)

// 自定义位置
WBadge(
  config: WBadgeConfig().position(top: 10, end: 10),
  badgeContent: Container(
    width: 8, height: 8,
    decoration: const BoxDecoration(
      color: Colors.red, shape: BoxShape.circle,
    ),
  ),
  child: Image.asset('assets/avatar.png'),
)
```

---

## 6. WListView - 增强列表组件

### 功能说明

支持普通列表、带分隔线列表、网格布局；支持头尾组件、重叠效果、空列表占位、子项缓存。使用 `SliverMainAxisGroup` 组织带头尾的列表，`cacheExtent` 兼容 Flutter 3.27–3.44 各版本。

### 构造函数

| 构造函数 | 说明 |
|----------|------|
| `WListView({config, itemBuilder, itemCount, ...})` | 普通列表 |
| `WListView.separated({...})` | 带分隔线的列表 |
| `WListView.grid({gridDelegate, ...})` | 网格布局列表 |

### WListView 构造参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `config` | WListViewConfig | 必需，列表配置 |
| `itemBuilder` | `Widget Function(BuildContext, int)` | 子项构建器 |
| `itemCount` | int | 子项数量 |
| `controller` | `ScrollController?` | 滚动控制器 |
| `header` | `Widget?` | 头部组件 |
| `footer` | `Widget?` | 尾部组件 |
| `cacheItems` | bool | false | 是否启用子项缓存 |
| `gridDelegate` | `SliverGridDelegate?` | 网格代理（grid 构造函数中必填） |
| `emptyWidget` | `Widget?` | 空列表占位符（优先级高于 config） |

### WListViewConfig 配置参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `padding` | `EdgeInsetsGeometry` | EdgeInsets.zero | 列表内边距 |
| `scrollDirection` | Axis | vertical | 滚动方向 |
| `reverse` | bool | false | 是否反向滚动 |
| `physics` | ScrollPhysics | AlwaysScrollableScrollPhysics | 物理滚动特性 |
| `cacheExtent` | `double?` | 垂直 200, 水平 100 | 预加载区域大小 |
| `itemExtent` | `double?` | null | 子项固定尺寸 |
| `emptyWidget` | `Widget?` | null | 空列表占位符 |
| `usePreciseCache` | bool | false | 是否使用精确缓存 |
| `backgroundColor` | `Color?` | null | 背景色 |
| `borderRadius` | `BorderRadius?` | null | 圆角 |
| `border` | `BoxBorder?` | null | 边框 |
| `shrinkWrap` | bool | false | 是否自适应高度 |
| `separatorBuilder` | `Widget Function(BuildContext, int)?` | null | 分隔线构建器 |
| `useOverlap` | bool | false | 子项重叠效果 |
| `overlapOffset` | double | 0.0 | 重叠偏移量（≤ 0） |

### WListViewConfig 预设工厂

| 工厂方法 | 说明 |
|----------|------|
| `WListViewConfig()` | 默认配置 |
| `WListViewConfig.vertical(...)` | 垂直列表（cacheExtent 200） |
| `WListViewConfig.horizontal(...)` | 水平列表（cacheExtent 100） |
| `WListViewConfig.card(...)` | 卡片风格（白色背景、圆角 8、padding 16） |
| `WListViewConfig.compact(...)` | 紧凑风格（cacheExtent 150） |

### WListViewConfig 构建方法

| 方法 | 说明 |
|------|------|
| `build({itemBuilder, itemCount, ...})` | 构建普通列表 |
| `buildSeparated({...})` | 构建带分隔线列表 |
| `buildGrid({itemBuilder, itemCount, gridDelegate, ...})` | 构建网格列表 |
| `buildByList<T>({data, itemBuilder, ...})` | 从数据列表构建泛型列表 |
| `copyWith(...)` / `copy()` | 创建副本 |

### 使用示例

```dart
// 基础用法
WListView(
  config: WListViewConfig.vertical(),
  itemCount: 20,
  itemBuilder: (ctx, i) => ListTile(title: Text('Item $i')),
)

// 使用配置类链式构建（推荐）
WListViewConfig.card()
  ..itemExtent = 60
  ..padding = EdgeInsets.symmetric(horizontal: WScreen.w(16))
  ..backgroundColor = Colors.white
  ..borderRadius = BorderRadius.circular(12)
  ..build(
    itemCount: 20,
    itemBuilder: (ctx, i) => ListTile(title: Text('Item $i')),
    header: const Text('头部'),
    footer: const Text('尾部'),
  )

// 带分隔线
WListViewConfig.vertical()
  ..separatorBuilder = (_, __) => const Divider(height: 1)
  ..buildSeparated(
    itemCount: 20,
    itemBuilder: (ctx, i) => ListTile(title: Text('Item $i')),
  )

// 网格布局
WListViewConfig.vertical().buildGrid(
  itemCount: 20,
  itemBuilder: (ctx, i) => Container(color: Colors.blue, child: Text('$i')),
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2, childAspectRatio: 1.0,
  ),
)

// 从数据列表构建（泛型）
final List<User> users = [...];
WListViewConfig.vertical().buildByList<User>(
  data: users,
  itemBuilder: (ctx, user) => ListTile(title: Text(user.name)),
  emptyWidget: const Center(child: Text('暂无数据')),
)

// 子项重叠效果（卡片堆叠）
WListViewConfig.vertical()
  ..itemExtent = 100
  ..useOverlap = true
  ..overlapOffset = -20
  ..backgroundColor = Colors.transparent
  ..build(
    itemCount: 10,
    itemBuilder: (ctx, i) => Card(child: ListTile(title: Text('Card $i'))),
  )
```

---

## 7. WScaffold - 增强脚手架

### 功能说明

增强版 Scaffold，提供安全区域自动处理、状态栏样式设置、underlay 底层 widget 叠加（用于渐变背景）。

### WScaffold 构造参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `body` | `Widget?` | null | 主体内容 |
| `backgroundColor` | `Color?` | null | 背景颜色 |
| `systemStatusBarStyle` | `SystemUiOverlayStyle?` | null | 状态栏样式（通过 AnnotatedRegion 设置） |
| `underlayWidget` | `Widget?` | null | 底层 widget（Stack 叠加在 body 下方） |
| `includeTopSafeArea` | bool | false | 是否包含顶部安全区域 |
| `includeBottomSafeArea` | bool | true | 是否包含底部安全区域 |

### WScaffoldConfig 链式构建

```dart
WScaffoldConfig()
  ..backgroundColor = Colors.white
  ..includeTopSafeArea = true
  ..systemStatusBarStyle = SystemUiOverlayStyle.dark
  ..build(body: const HomePage())
```

### 使用示例

```dart
// 基础用法
WScaffold(
  backgroundColor: Colors.white,
  includeTopSafeArea: true,
  includeBottomSafeArea: false,
  systemStatusBarStyle: SystemUiOverlayStyle.dark,
  body: const Center(child: Text('Hello')),
)

// 带 underlay（渐变背景）
WScaffold(
  backgroundColor: Colors.white,
  underlayWidget: Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.blue, Colors.cyan],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
  ),
  body: ListView(
    children: [/* 内容 */],
  ),
)
```

---

## 8. 其他组件速览

### WContainer / WContainerConfig

增强版容器，支持装饰（背景色、圆角、边框、阴影）、变换（alignment、padding、margin、transform）。被 `WButton`、`WImage`、`WNavBar` 等组件复用。

```dart
WContainer(
  config: WContainerConfig()
    ..width = 200
    ..height = 48
    ..bgColor = Colors.blue
    ..borderRadius = BorderRadius.circular(24)
    ..padding = EdgeInsets.symmetric(horizontal: 16),
  child: const Text('内容'),
)
```

### WClipRRect

圆角裁剪组件，`ClipRRect` 的便捷封装。

### WRowButtons

行内多个按钮的便捷组合组件。

### WKeepAliveWrapper

保持组件状态的包装器，自动混入 `AutomaticKeepAliveClientMixin`。

### WNotificationListenerBuilder

通知监听构建器，便捷封装 `NotificationListener` + `Builder`。

### WRichText

富文本组件，`RichText` 的增强封装。

### WGradientCircularProgressIndicator

带渐变效果的圆形进度指示器。

### WAppBar

自定义应用栏，可作为 `WScaffold` 的 appBar 或独立使用。

### WStep

步骤指示器，支持当前步骤高亮、自定义样式。

### WNavBar / WNavController

底部导航栏，由 `WNavController` 驱动选中态切换动画，`itemBuilder(context, index, isSelected)` 渲染每项。

```dart
final controller = WNavController(length: 3);

WNavBar(
  config: WNavBarConfig(),
  controller: controller,
  itemBuilder: (ctx, index, isSelected) {
    final items = ['首页', '消息', '我的'];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(index == 0 ? Icons.home : Icons.message),
        WText(text: items[index], config: WTextConfig()..fontSize12sp()),
      ],
    );
  },
  onItemTap: (index) async {
    // 返回 false 可阻止切换
    return true;
  },
)

// controller 手动控制
controller.animateTo(1);
controller.currentIndex; // 当前选中索引
```

### WTabBar

增强版标签栏，支持自定义样式、指示器、分割线。

---

## 9. 扩展方法

### HexColor（Color 扩展）

十六进制颜色转换，兼容多种格式：

| 方法 | 说明 |
|------|------|
| `HexColor.fromHex(String)` | 静态方法，从十六进制字符串创建 Color |
| `color.toHex({leadingHashSign: true})` | Color → 十六进制字符串 |

**支持的输入格式：**
- `#AARRGGBB`（带透明度）
- `#RRGGBB`（默认 FF alpha）
- `AARRGGBB` / `RRGGBB`（无 `#`）
- `#ARGB`（简写，每字符重复）
- `#RGB`（简写）

```dart
final c = HexColor.fromHex('#FF5733');    // RRGGBB
final c2 = HexColor.fromHex('#80FF5733'); // AARRGGBB
final hex = c.toHex();                    // '#ffff5733'
final hex2 = c.toHex(leadingHashSign: false); // 'ffff5733'
```

### WStringExtension

字符串扩展，提供格式化、验证、转换等便捷方法。

### WNumExtension

数值扩展，提供格式化、范围检查、数字转颜色等。

### WWidgetExtension

Widget 扩展，提供链式装饰、布局、padding、margin：

```dart
// 链式装饰
Text('Hello')
  .padding(16)
  .margin(all: 8)
  .bgColor(Colors.blue)
  .borderRadius(BorderRadius.circular(8))
  .shadow([BoxShadow(...)])
```

### WRow / WColumn

便捷创建 Row / Column 的函数扩展：

```dart
WRow([Widget1, Widget2]).mainCenter().spaceBetween()
WColumn([Widget1, Widget2]).crossStart()
```

### WGlobalKeyExtension

GlobalKey 扩展，支持查找、定位、获取 Widget 状态等。

### WImageExtension

Image 相关扩展，便捷创建 CachedNetworkImage、带圆角的图片等。

### WTextStyleExtension

从 `WTextConfig` 创建 `TextStyle` 的扩展。

### WStrutStyleExtension

从 `WTextConfig` 创建 `StrutStyle` 的扩展。

---

## 10. 工具类

### WPadding / WSizeBox

便捷创建内边距和尺寸框：

```dart
WPadding.all(16)
WPadding.symmetric(h: 8, v: 4)
WSizeBox.width(100)
WSizeBox.height(WScreen.h(20))
WSizeBox.square(50)
```

### WImageCacheManager

图片缓存管理，配合 `WImageGlobalConfig` 设置缓存上限（数量 + 内存），提供清理方法。

### WAssets

资源路径管理，支持统一的资源目录前缀。

---

## 完整配置示例

### WScreen 适配 + WListView + WButton 组合

```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:w_tools/w_tools.dart';

void main() {
  runApp(ScreenUtilInit(
    designSize: const Size(375, 667),
    builder: (context, child) {
      // 将 flutter_screenutil 的适配函数注入 WScreen
      WScreen.delegateWidth = (v) => ScreenUtil().setWidth(v);
      WScreen.delegateHeight = (v) => ScreenUtil().setHeight(v);
      WScreen.delegateFont  = (v) => ScreenUtil().setSp(v);
      return child!;
    },
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WScaffold(
        backgroundColor: Colors.grey[100],
        includeTopSafeArea: true,
        includeBottomSafeArea: true,
        body: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> _items = List.generate(20, (i) => 'Item ${i + 1}');

  @override
  Widget build(BuildContext context) {
    return WListViewConfig.card()
      ..padding = EdgeInsets.all(WScreen.w(16))
      ..itemExtent = WScreen.h(60)
      ..separatorBuilder = (_, __) => const Divider(height: 1, indent: 16, endIndent: 16)
      ..build(
        itemCount: _items.length,
        itemBuilder: (ctx, i) => ListTile(
          leading: CircleAvatar(child: Text('${i + 1}')),
          title: WText(
            text: _items[i],
            config: WTextConfig()
              ..fontSize16sp()
              ..w500()
              ..color = Colors.black87,
          ),
          trailing: WButton(
            config: WButtonConfig.opacityEffect(opacity: 0.6),
            onTap: () => setState(() => _items.removeAt(i)),
            child: WText(
              text: '删除',
              config: WTextConfig()..fontSize14sp()..color = Colors.red,
            ),
          ),
        ),
        header: WText(
          text: '标题',
          config: WTextConfig.title()..color = Colors.black,
        ),
        footer: SizedBox(
          height: WScreen.h(80),
          child: Center(
            child: WButton(
              config: WButtonConfig.scaleEffect(scale: 0.92)
                ..containerConfig = (WContainerConfig()
                  ..width = WScreen.w(200)
                  ..height = WScreen.h(48)
                  ..bgColor = Colors.blue
                  ..borderRadius = BorderRadius.circular(WScreen.w(24))),
              onTap: () => print('提交'),
              child: WText(
                text: '提交',
                config: WTextConfig.button(),
              ),
            ),
          ),
        ),
        emptyWidget: const Center(child: Text('暂无数据')),
      );
  }
}
```

### WNavBar 完整示例

```dart
class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _controller = WNavController(length: 3);

  final _pages = const [
    HomeScreen(),
    MessageScreen(),
    ProfileScreen(),
  ];

  @override
  void dispose() {
    _controller.dispose(); // controller 由调用方管理
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WScaffold(
      backgroundColor: Colors.white,
      includeTopSafeArea: true,
      body: ValueListenableBuilder(
        valueListenable: _controller,
        builder: (ctx, index, _) {
          return _pages[index];
        },
      ),
      // 可自定义 body 下方的导航栏区域
    );
  }
}

class MainNavBar extends StatelessWidget {
  const MainNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.findAncestorStateOfType<_MainPageState>()!._controller;

    return Container(
      padding: EdgeInsets.only(bottom: WScreen.bottomBarHeight),
      color: Colors.white,
      child: WNavBar(
        config: WNavBarConfig(),
        controller: controller,
        onItemTap: (index) async {
          // 可在此做拦截判断，返回 false 阻止切换
          return true;
        },
        itemBuilder: (ctx, index, isSelected) {
          final items = const [
            _NavItem(Icons.home, '首页'),
            _NavItem(Icons.message, '消息'),
            _NavItem(Icons.person, '我的'),
          ];
          final item = items[index];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                color: isSelected ? Colors.blue : Colors.grey,
                size: WScreen.w(24),
              ),
              SizedBox(height: WScreen.h(4)),
              WText(
                text: item.label,
                config: WTextConfig()
                  ..fontSize12sp()
                  ..color = isSelected ? Colors.blue : Colors.grey,
              ),
            ],
          );
        },
      ),
    );
  }
}
```

---

## 注意事项

### Flutter 版本兼容

| 版本 | 状态 | 说明 |
|------|------|------|
| 3.27 – 3.40 | ✅ 兼容 | `cacheExtent` 正常使用 |
| 3.41 – 3.43 | ✅ 兼容 | `cacheExtent` 仍可用，同时存在 `scrollCacheExtent` |
| 3.44+ | ✅ 兼容（deprecated） | `cacheExtent` 被标记 deprecated，源码使用 `// ignore: deprecated_member_use` 保持兼容 |

> 最低 Flutter 版本锁定为 3.27。源码中 `WListView` 所有 ListView/GridView 分支均使用 `cacheExtent`，并带 deprecation 忽略注释。未来统一迁移到 `scrollCacheExtent` 时需同步提升最低 Flutter 版本。

### WScreen 委托注入

- 委托在 `runApp` 之前设置即可，也可在 `ScreenUtilInit.builder` 内设置
- **非延迟初始化**：`WScreen.screenWidth` 等设备信息可在应用任何时刻调用，但依赖 `WidgetsBinding.instance.platformDispatcher.views.first`，因此 WidgetsBinding 必须已初始化（默认 `Flutter.ensureInitialized()` 或 `runApp` 后自动满足）
- 无委托时 `w()` / `h()` / `sp()` 直接返回原值，可安全用作统一 API

### WButtonConfig 缓存机制

- `getCachedConfig` 用 LinkedHashMap 按 LRU 管理（key 被访问时移到末尾）
- 返回的是**副本**，调用方修改不会污染缓存模板
- 缓存阈值 100，超出自动清理最旧条目

### WImage 平台差异

- `file://` 图片使用条件导入（`_image_file_native.dart` vs `_image_file_web.dart`），Web 端安全编译
- Base64 图片使用 `compute()` 在后台线程解码

### WListView controller 生命周期

- `controller` 由调用方持有，组件只负责添加/移除监听
- 内部创建的 controller（未传入时）在组件 dispose 时自动释放
- 带 header/footer 时使用 `SliverMainAxisGroup`（最低 Flutter 3.27 提供）

### WNavController 生命周期

- 与 `WListView controller` 同理，controller 由调用方管理
- `dispose()` 需在 `State.dispose()` 中调用
