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
    │   │   ├── button/                 # 按钮组件
    │   │   │   ├── button.dart                 # WButton
    │   │   │   ├── button_content.dart         # label/loading（part）
    │   │   │   ├── button_effect.dart          # 按下/overlay 效果（part）
    │   │   │   ├── button_tap_target.dart      # 48×48 hit area（part）
    │   │   │   ├── button_style.dart           # WButtonStyle
    │   │   │   ├── button_resolved_style.dart  # WButtonResolvedStyle
    │   │   │   ├── button_motion.dart          # WButtonMotion / WButtonEffectType
    │   │   │   ├── button_semantics.dart       # WButtonSemantics
    │   │   │   ├── button_size.dart            # WButtonSize
    │   │   │   └── button_styles.dart          # WButtonStyles 预设
    │   │   ├── clip.dart                      # WClipRRect
    │   │   ├── pressable.dart                 # WPressable
    │   │   ├── image/                  # 图片组件
    │   │   │   ├── image.dart                  # WImage, WImageController
    │   │   │   ├── image_source.dart           # WImageSource（sealed）
    │   │   │   ├── image_style.dart            # WImageStyle
    │   │   │   ├── image_config.dart           # WImageConfig
    │   │   │   ├── image_cache_policy.dart     # WImageCachePolicy
    │   │   │   ├── image_loader.dart           # WImageLoader / WImageLoadSnapshot
    │   │   │   ├── image_load_state.dart       # 内部状态基类
    │   │   │   ├── image_frame.dart            # WImageFrame
    │   │   │   ├── image_defaults.dart         # WImageDefaultsScope
    │   │   │   ├── image_types.dart            # WImageType / WImageProgress / WImageError
    │   │   │   ├── image_retry_policy.dart     # 重试判定与退避（内部）
    │   │   │   └── _image_file_*.dart          # file provider 条件实现
    │   │   ├── keep_alive_wrapper.dart        # WKeepAliveWrapper
    │   │   ├── notification_listener.dart      # WNotificationListenerBuilder
    │   │   ├── row_buttons.dart               # WRowButtons
    │   │   ├── text.dart                      # WText, WTextConfig
    │   │   ├── gradient_circular_progress_indicator.dart
    │   │   └── rich_text.dart                 # WRichText
    │   ├── layout/                 # 布局组件
    │   │   ├── appbar.dart                    # WAppBar / WAppBarStyle
    │   │   ├── list_view.dart                 # WListView / WListViewSliver
    │   │   ├── scaffold.dart                  # WScaffold
    │   │   └── step.dart                      # WStep
    │   └── navigation/             # 导航组件
    │       ├── nav_bar.dart                   # WNavBar / WNavBarConfig
    │       ├── nav_controller.dart            # WNavController
    │       └── tab_bar.dart                   # WTabBar
    ├── extensions/                 # 扩展方法
    │   ├── box_decoration.dart                # WBoxDecorationExtension
    │   ├── color.dart                         # HexColor（Color 扩展）
    │   ├── global_key.dart                    # WGlobalKeyExtension
    │   ├── num.dart                           # WNumExtension
    │   ├── string.dart                        # WStringExtension
    │   ├── text_style.dart                    # WTextStyleExtension
    │   └── widget.dart                        # WWidgetExtension
    ├── styles/                     # 样式预设
    │   ├── gradients.dart                     # WGradients
    │   └── shadows.dart                       # WShadows
    └── utils/                      # 工具类
        ├── assets.dart                        # WAssets
        ├── column.dart                        # WColumn
        ├── image_preloader.dart              # WImagePreloader
        ├── padding.dart                       # WPadding
        ├── row.dart                           # WRow
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

真正的按钮组件：`label` / `icon` / `content` / `contentBuilder`、显式 `style`、size、
loading、button 语义、键盘焦点、48×48 点击区域。

**没有命名工厂，也没有 WButton 主题**。样式通过 `WButtonStyle` 显式传入；
项目用 `AppButtons` 统一维护样式。

任意 child 点击用 `WPressable`，不要用 `WButton`。

### WButton 参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `style` | `WButtonStyle?` | null | 样式；null 时使用 `WButtonStyles.primary` fallback |
| `label` / `icon` | String? / IconData? | null | 简单内容 |
| `content` | Widget? | null | 静态复杂内容 |
| `contentBuilder` | `WButtonContentBuilder?` | null | 需要最终 style 的复杂内容 |
| `size` | `WButtonSize?` | null | 尺寸 |
| `semanticLabel` | `String?` | null | 显式无障碍标签 |
| `onTap` / `onLongPress` | 回调 | null | 点击 / 长按 |
| `enabled` / `loading` | bool | true / false | 状态 |
| `loadingBuilder` | `WidgetBuilder?` | null | 加载中占位 |
| `focusNode` / `autofocus` | — | null / false | 键盘焦点 |

`content`、`contentBuilder`、`label/icon` 只能选一种；可交互按钮的 `onTap` / `onLongPress` 至少提供一个。

### 使用方式

```dart
WButton(
  style: AppButtons.primary(context),
  label: '提交',
  loading: isSubmitting,
  onTap: submit,
)

WButton(
  style: AppButtons.secondary(context),
  label: '取消',
  onTap: cancel,
)

WButton(
  style: AppButtons.danger(context),
  icon: Icons.delete_outline,
  semanticLabel: '删除',
  onTap: delete,
)
```

### AppButtons：项目样式注册表

```dart
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
        if (states.contains(WidgetState.hovered)) {
          return scheme.primary.withValues(alpha: 0.92);
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

  static WButtonStyle secondary(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return WButtonStyle.outlined(
      foregroundColor: scheme.primary,
      borderColor: scheme.primary,
    );
  }

  static WButtonStyle danger(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return WButtonStyle.filled(
      backgroundColor: scheme.error,
      foregroundColor: scheme.onError,
    );
  }
}
```

示例页第 12 节可直接查看 primary 按钮的 normal / pressed / hovered / disabled 状态。

### WButtonContentBuilder

```dart
typedef WButtonContentBuilder = Widget Function(
  BuildContext context,
  WButtonResolvedStyle style,
);
```

`style` 是当前 WidgetState 下解析后的最终视觉值，可直接使用 `style.iconSize`、
`style.gap`、`style.textStyle`、`style.foregroundColor`，也可以通过 `style.states`
判断当前状态：

```dart
contentBuilder: (context, style) {
  final disabled = style.states.contains(WidgetState.disabled);
  final pressed = style.states.contains(WidgetState.pressed);

  if (disabled) return const Icon(Icons.lock);
  if (pressed) return const Text('提交中…');
  return const Text('提交');
}
```

`style.states` 是不可变 Set。

> 建议只用 `contentBuilder` 处理 disabled / selected 等结构性状态；pressed / hover / focus
> 优先通过 `WidgetStateProperty` 和 `WButtonMotion` 表达，避免内容尺寸和文案跳动。
> loading 内容用 `loadingBuilder`，不要混进 `contentBuilder`。
>
> 如果 `contentBuilder` 改变了内容含义（例如“提交”变成“不可用”），要同步提供匹配的
> `semanticLabel`；否则屏幕阅读器仍会播报旧含义。
>
> 只有 `onLongPress` 时不会启用键盘焦点；键盘激活依赖 `onTap`，此时仅保留指针和
> 屏幕阅读器的长按操作。

### WButtonStyle

| 字段 | 类型 | 说明 |
|------|------|------|
| `motion` | `WButtonMotion` | 按压效果 |
| `semantics` | `WButtonSemantics` | 语义 / loading 文案 |
| `backgroundColor` | `WidgetStateProperty<Color?>?` | 纯色背景 |
| `gradient` | `WidgetStateProperty<Gradient?>?` | 渐变背景 |
| `border` | `WidgetStateProperty<BoxBorder?>?` | 边框 |
| `borderRadius` | BorderRadius? | 圆角（静态） |
| `boxShadow` | `WidgetStateProperty<List<BoxShadow>?>?` | 阴影 |
| `padding` | EdgeInsetsGeometry? | 内容 padding（静态） |
| `clipBehavior` | Clip | 背景裁剪（静态） |
| `foregroundColor` | `WidgetStateProperty<Color?>?` | 文字/图标前景色 |
| `textStyle` | `WidgetStateProperty<TextStyle?>?` | 文本样式 |
| `focusColor` / `hoverColor` | Color? | 焦点/悬停 overlay |
| `disabledOpacity` | double | 禁用透明度 |
| `minWidth` / `minHeight` | double | 视觉/布局最小尺寸 |
| `tapTargetSize` | double | 实际 hit area 下限；与 `minWidth` / `minHeight` 配合计算 |
| `iconSize` / `gap` | double | 图标尺寸 / 间距 |

颜色/边框/阴影/文字都使用 `WidgetStateProperty`：

```dart
WButtonStyle(
  backgroundColor: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) return Colors.grey.shade300;
    if (states.contains(WidgetState.pressed)) return brandDark;
    if (states.contains(WidgetState.hovered)) return brandHover;
    return brand;
  }),
  foregroundColor: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) return Colors.grey.shade600;
    return Colors.white;
  }),
  disabledOpacity: 1, // 已用状态色表达禁用，不再叠加整体透明度
)
```

> 使用 `disabled` 状态色时，把 `disabledOpacity` 设为 `1`，避免双重禁用效果。

简单静态值可用工厂或 `WidgetStatePropertyAll`：

```dart
WButtonStyle.filled(
  backgroundColor: brand,
  foregroundColor: Colors.white,
)
```

需要单按钮静态覆盖时：

```dart
style.withBackgroundColor(Colors.red)
style.withForegroundColor(Colors.white)
```

`withBackgroundColor` / `withForegroundColor` 会包成 `WidgetStatePropertyAll`，
覆盖整套状态；如果只想改 normal 状态，请直接用
`WidgetStateProperty.resolveWith`。

`withBackgroundColor` 还会清空 `gradient`，避免 `BoxDecoration` 里 gradient 覆盖 color。
`tapTargetSize` 的 padding 基于 `minWidth` / `minHeight` 计算，自定义时应让这两个值反映
视觉基准尺寸；设置为 0 可能产生额外 padding。

`copyWith(null)` 表示“不修改”，不是清空。清空 nullable 字段用 `without...`：

```dart
style.withoutBorder()
style.withoutBoxShadow()
style.withoutDecoration()
style.withoutTextStyle() // 只清 textStyle
style.withoutText()      // 清 textStyle + foregroundColor
```

需要静态覆盖时也可以：

```dart
style.withBorder(Border.all(color: Colors.red))
style.withBoxShadow(const [BoxShadow(...)])
style.withTextStyle(const TextStyle(fontSize: 12))
```

`WButton` 会把当前 `WidgetState`（disabled / pressed / hovered / focused）
解析成 `WButtonResolvedStyle` 后再渲染。

### WButtonMotion

| 字段 | 默认值 | 说明 |
|------|--------|------|
| `effect` | opacity | none / opacity / scale |
| `pressedOpacity` | 0.7 | 按下透明度 |
| `pressedScale` | 0.95 | 按下缩放 |
| `duration` | 100ms | 动画时长 |
| `curve` | easeInOut | 动画曲线 |

### WButtonSemantics

```dart
WButtonStyle(
  semantics: const WButtonSemantics(
    label: '关闭',
    hint: '关闭当前弹窗',
    loadingLabel: '提交中…',
  ),
)
```

### WButtonSize

```dart
WButtonSize.small   // 视觉 32 高，13 号字，hit target 48
WButtonSize.medium  // 视觉 40 高，14 号字，hit target 48
WButtonSize.large   // 视觉 48 高，15 号字，hit target 48
```

支持 `minWidth/minHeight`、`padding`、`fontSize`、`fontWeight`、`lineHeight`、
`letterSpacing`、`iconSize`、`gap`、`tapTargetSize`。

### Style 工厂

```dart
WButtonStyle.filled(
  backgroundColor: brand,
  foregroundColor: Colors.white,
  borderRadius: BorderRadius.circular(8),
)

WButtonStyle.outlined(
  foregroundColor: brand,
  borderColor: brand,
)

WButtonStyle.text(
  foregroundColor: brand,
)
```

### 复杂按钮内容

静态内容：

```dart
WButton(
  style: AppButtons.primary(context),
  onTap: openOrder,
  semanticLabel: '订单 A123，3 件商品，待支付，共 128 元',
  content: Row(
    children: [
      WImage.asset('demo.png', prefix: true),
      const SizedBox(width: 12),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('订单 #A123'),
            Text('3 件商品 · 待支付'),
          ],
        ),
      ),
      const Icon(Icons.chevron_right),
    ],
  ),
)
```

需要最终样式：

```dart
WButton(
  style: AppButtons.primary(context),
  onTap: add,
  contentBuilder: (context, style) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.add, size: style.iconSize),
        SizedBox(width: style.gap),
        Text('新增', style: style.textStyle),
      ],
    );
  },
)
```

### 键盘与效果

- Enter / Space 通过 `ActivateIntent` 触发 `onTap`；
- 禁用 / loading 时 `Semantics.onTap` 为空、`onTap` 不执行；
- 没有 `onTap` 时键盘不触发按下效果；
- loading 保持按钮内容占位尺寸。

## 2.1 WPressable - 任意 child 点击

`WPressable` 不是按钮：只负责指针点击和基础效果，不声明 `button` 语义，不负责样式、size、
loading、键盘焦点或最小点击区域。需要键盘操作时用 `WButton`。

```dart
WPressable(
  onTap: openOrder,
  effect: WPressEffect.opacity,
  child: Card(
    child: ListTile(
      title: const Text('订单 #A123'),
      subtitle: const Text('3 件商品 · 待支付'),
    ),
  ),
)
```

注意：

- `WPressable` 不保证 48×48 点击区域；小目标请用 `WButton.icon` 或外层约束。
- 内部不要再嵌套 `WButton` / `IconButton` / `Switch` 等交互控件。
- 默认 `excludeChildSemanticsWhenDisabled: false` 只阻断指针，不会清理 child 的交互语义；
  如果确实嵌套了交互控件，禁用时请开启 `excludeChildSemanticsWhenDisabled: true`。
- 只有 `onLongPress` 时，短按只提供视觉反馈，不执行动作。
- 键盘操作请用 `WButton`，`WPressable` 不参与 Tab 焦点。

需要真正的按钮语义时，用 `WButton`，或显式：

```dart
Semantics(
  button: true,
  label: '订单 A123',
  child: WPressable(onTap: openOrder, child: card),
)
```

可运行示例见 [`packages/ui/example/lib/buttons_page.dart`](../../packages/ui/example/lib/buttons_page.dart)。

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

图片组件，支持网络 URL、本地资源、本地文件、Base64 与任意 `ImageProvider`。

**新代码优先使用 `WImage.source(...)` 或命名构造**（`WImage.network` / `WImage.asset` /
`WImage.file` / `WImage.base64`）；`WImage(data: ...)` 的自动判定只作为便利入口。
提供占位符、错误处理、加载进度、网络重试、解码尺寸限制与图片变换。

### 新 API（推荐）

```dart
WImage.source(
  source: WImageSource.network(
    url,
    headers: {'Authorization': token},
    cacheKey: 'home-hero',
  ),
  style: const WImageStyle(
    width: 120,
    height: 120,
    fit: BoxFit.cover,
    borderRadius: BorderRadius.all(Radius.circular(12)),
  ),
  config: const WImageConfig(retryCount: 1),
)
```

- `WImageSource` 是 sealed：`network` / `asset` / `file` / `base64`，`WImageSource.parse` 保留字符串自动判定；
- `WImageStyle` 不可变，只管视觉/布局/语义；`WImageConfig` 不可变，管加载/重试/占位/进度；
- `WImageDefaultsScope`（InheritedWidget）可按子树覆盖默认占位符/错误占位/进度 UI；
- `WImageController.state` 暴露 `ValueListenable<WImageLoadSnapshot>`（status / progress / attempt）；
- 重试定时器、错误分类、进度上报与状态去重都在 `WImageLoader` 内，`WImage` 的 State 只负责构建与渲染；
- 网络图统一走 `CachedNetworkImageProvider` + `Image`：磁盘缓存仍由 `cached_network_image` 负责，
  进度来自 `Image.loadingBuilder` 的 `ImageChunkEvent`；
- 字符串入口 `WImage(data:, style:, config:)` 与命名构造仍保留，内部会转换成 `WImageSource` + `WImageStyle` + `WImageConfig`；
- 旧的可变 `WImageConfig` / `WImageConfigBuild` 已移除；新的 `WImageConfig` 是不可变配置。

### 构造参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `data` | String | 必需，图片数据 |
| `style` | `WImageStyle` | 视觉样式（默认 `const WImageStyle()`） |
| `config` | `WImageConfig` | 加载配置（默认 `const WImageConfig()`） |
| `onLoadStatusChanged` | `ValueChanged<WImageLoadStatus>?` | 加载状态回调 |
| `onProgress` | `ValueChanged<WImageProgress>?` | 类型化进度回调（仅网络） |
| `type` | `WImageType?` | 显式类型；null 表示按 data 自动判定 |

### 显式构造

| 构造 | 说明 |
|------|------|
| `WImage.network(url)` | 网络图；`//` 开头的协议相对地址会补 `https:` |
| `WImage.asset(path)` | 资产图；前后的空白会被裁掉 |
| `WImage.file(path)` | 本地文件；带不带 `file://` 都可以 |
| `WImage.base64(data)` | Base64；可带 `data:...;base64,` 前缀，也可裸串 |
| `WImage.avatar(data, size:)` | 正方形 + 全圆角 |
| `WImage.thumbnail(data, width:)` | 缩略图；`cacheSize` 会写入 `WImageConfig.memCache` |
| `WImage.cover(data, aspectRatio:)` | 固定比例封面 |
| `WImage.assetImage(name)` | 兼容入口；优先用 `WImage.asset(name, prefix: true)` |
| `WImage.memory(bytes)` | `Uint8List` → `MemoryImage` |
| `WImage.provider(provider)` | 任意 `ImageProvider` |

### WImageType 与自动判定

| 类型 | 识别条件 |
|------|----------|
| `network` | `Uri` 解析出的 scheme 为 `http`/`https`（大小写无关）且 host 非空；或 `//` 开头 |
| `file` | scheme 为 `file` |
| `base64` | `data:` 开头（不限于 `data:image/`） |
| `provider` | 任意 `ImageProvider`（`WImage.provider` / `WImage.memory`） |

`data:` / `file:` 前缀大小写不敏感（`DATA:` / `FILE:` 同样识别）。
| `asset` | 其余；空串/纯空白会直接渲染错误占位 |

判定只在 `initState` / `didUpdateWidget` 执行一次，不使用跨实例的全局缓存。

### 错误类型

`errorWidgetBuilder` 的第三个参数是 `WImageError`，可用 `is` 分支：

| 类型 | 场景 |
|------|------|
| `WImageEmptyError` | 空串 / 纯空白 |
| `WImageNetworkError` | 网络请求失败（`cause` 为底层异常） |
| `WImageAssetError` | 资产不存在或解码失败 |
| `WImageDecodeError` | Base64 解码失败 |
| `WImageFileError` | 文件读取失败 |
| `WImageProviderError` | `WImage.provider` / `WImage.memory` 解码失败 |
| `WImageUnsupportedError` | Web 上的 `file://` |

### WImageStyle 配置

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `width` / `height` | `double?` | null | 图片内容尺寸 |
| `fit` | `BoxFit` | cover | 适配模式 |
| `alignment` | `Alignment` | center | 对齐方式 |
| `aspectRatio` | `double?` | null | 固定宽高比，加载前后不跳版 |
| `filterQuality` | `FilterQuality` | low | 采样质量 |
| `semanticLabel` | `String?` | null | 无障碍描述 |
| `excludeFromSemantics` | bool | false | 从语义树排除 |
| `borderRadius` / `border` / `boxShadow` | — | null | 装饰 |
| `margin` / `padding` | `EdgeInsets?` | null | 间距 |

### WImageConfig 配置

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `memCacheWidth` / `memCacheHeight` | `int?` | null | 解码尺寸上限（物理像素） |
| `gaplessPlayback` | bool | false | 换图保留上一帧 |
| `retryCount` / `retryDelay` | int / int | 0 / 1000 | 网络重试次数 / 间隔（毫秒） |
| `placeholderBuilder` | 函数 | null | 占位符（推荐） |
| `placeholder` | `Widget?` | null | 固定占位符 |
| `errorWidgetBuilder` | 函数 | null | 错误占位（推荐，第三参是 `WImageError`） |
| `errorWidget` | `Widget?` | null | 固定错误占位 |
| `progressBuilder` | 函数 | null | 进度（`WImageProgress`） |
| `showRetryButton` | bool | false | 无自定义错误占位时显示内置“错误 + 重试”视图 |
| `retryLabel` | String | 重试 | 内置重试按钮文案 |

`WImageStyle` / `WImageConfig` 都是不可变的：用 `copyWith` 覆盖字段，字段本身没有 setter。
新的 `WImageConfig` 不是旧版可变配置的回归。
`boxShadow` 列表在渲染时会复制为不可变快照，但不要依赖这一点去修改传入列表。
`httpHeaders` / `cacheKey` 属于来源，放在 `WImageSource.network(...)` 上。

- `width` / `height` 是**图片内容尺寸**；`padding` / `margin` 在外部叠加，
  实际总尺寸 = 内容尺寸 + 间距。
- `aspectRatio` 不要和固定的 `width` + `height` 同时设置（debug 下会 assert，约束会冲突）。
- `borderRadius` 同时作用于图片本体、`border` 与 `boxShadow`。
- 自定义 `placeholder` / `placeholderBuilder` / `errorWidget` / `errorWidgetBuilder`
  不会自动套 `SizedBox`；需要自己按 `width` / `height` 或 `AspectRatio` 处理尺寸。

### WImageDefaultsScope / WImageCachePolicy

- `WImageDefaultsScope`（InheritedWidget）按子树覆盖默认占位符/错误占位/默认进度构建器；
- `WImageCachePolicy` 是进程级缓存预算，直接同步 Flutter `ImageCache`：

```dart
WImageDefaultsScope(
  defaults: WImageDefaults(
    placeholderBuilder: (context, data) => const CircularProgressIndicator(),
    errorBuilder: (context, data, error) => const Icon(Icons.broken_image),
    progressBuilder: (context, data, progress) => _defaultProgress(progress),
  ),
  child: ...,
)

WImageCachePolicy.configure(maxSize: 200, maxMemoryBytes: 200 * 1024 * 1024);
WImageCachePolicy.reset();
```

优先级：`WImageConfig.placeholderBuilder` > `WImageConfig.placeholder` > `WImageDefaultsScope.placeholderBuilder` > 内置兜底。
`WImageDefaults.progressBuilder` 可作为所有网络图的默认进度 UI。
内置错误视图可用 `WImageConfig(showRetryButton: true)` 启用，或直接复用 `WImageErrorView`。
`WImageErrorView` 尺寸策略：

| 尺寸 | 图标 | 文案 | 重试按钮 |
|---|---|---|---|
| `< 64` | ✅ | ❌ | ❌ |
| `64–96` | ✅ | ❌ | ❌ |
| `96–120` | ✅ | ✅ | ❌ |
| `>= 120×112` | ✅ | ✅ | ✅（仅可重试错误） |

- 仅 `WImageNetworkError` / `WImageProviderError` / `WImageFileError` 显示重试按钮；
- 空数据、Base64 解码失败、asset 不存在、平台不支持不显示重试；
- 也可显式传 `compact: true` / `showAction: false`。
优先级：`WImageConfig.errorWidgetBuilder` > `WImageConfig.errorWidget` > `showRetryButton` > `WImageDefaultsScope` > 兜底。

`WImage.thumbnail(width)` 默认按 `max(width, height) × 3` 估算 `WImageConfig.memCache`；
需要精确控制时显式传 `cacheSize`（通常按 `devicePixelRatio` 计算）。
预设构造和显式 `style` 同时传时，`style` 会完整覆盖预设参数（`size` / `width` / `aspectRatio` 等）。
`WImageCachePolicy` 只影响 `ImageCache`，与 `WImagePreloader` 的字节缓存互不影响。

### 缓存

- 资产 / 文件 / Base64 统一走 `Image` + Flutter `ImageCache`；`memCacheWidth` / `memCacheHeight` 通过 `ResizeImage` 生效。
- 网络图走 `cached_network_image`（内存 + 磁盘），可用 `httpHeaders` / `cacheKey` 定制。
- `WImagePreloader` 是**独立**的资源字节预加载工具，`WImage` 不使用；
  `WImageCachePolicy` 只改 Flutter `ImageCache`，不会修改它的上限。

### 2.0 迁移

- 旧的可变 `WImageConfig` 删除；2.0 的 `WImageConfig` 是**新的不可变加载配置**；
  视觉样式由 `WImageStyle` 负责。
- `WImageConfigBuild` 删除，用 `WImage.source` / `WImage.network/asset/file/base64`；
- `WImage.onLoadProgress` 删除，用 `onProgress`；
- `cacheEnabled` / `fitCenter` / `size` 均已删除。

### 可运行示例

完整示例在 [`packages/ui/example`](../../packages/ui/example/README.md)：

```bash
cd packages/ui/example
flutter pub get
flutter run
```

包含 **Playground**（实时调参 + 生成 `WImageStyle` / `WImageConfig` 代码）与 **状态矩阵**（成功/失败/空数据/加载中/主题/文件不支持）。
覆盖网络图、asset、Base64、圆形头像、进度、自动/手动重试、主题、缓存预算与预加载。

### 重试与手动重试

- `retryCount` 默认 0（不自动重试）；开启后只对**可重试错误**生效：
  `5xx` / `408` / `429` / 连接级失败（拿不到状态码）。`4xx` 直接失败，不会白白等 N 次延迟。
- 重试间隔按指数退避（`retryDelay` → 2× → 4×……，上限 30s）并带 20% 抖动，
  避免同屏多张图在同一毫秒齐刷刷重试。
- 修改 `retryCount` / `retryDelay` 会取消已经排队的旧重试（避免关掉重试后仍多发一次请求）。
- 一个 `WImageController` 对应一个 `WImage`；同时绑定两张图会在 debug 下触发断言。
- `WImageController.state` 在首次绑定后保持同一 `ValueListenable`；WImage 卸载后不再更新，
  但外部持有的监听器仍可安全 `removeListener`。
- 需要用户手动重试时，传一个 `WImageController`，在错误占位里调用 `retry()`：

```dart
final controller = WImageController();

WImage.network(
  url,
  controller: controller,
  config: WImageConfig(
    errorWidgetBuilder: (context, url, error) => TextButton(
      onPressed: controller.retry,
      child: const Text('重试'),
    ),
  ),
)
```

`retry()` 会立即发起新请求（不等待自动重试的退避时间），对网络 / 资产 / 文件 / Base64 四种来源都有效；
组件卸载后调用是空操作。手动重试也会把已执行的重试计数清零。

### 使用示例

```dart
// 网络图片 + 固定宽高比 + 解码尺寸
WImage.network(
  'https://example.com/image.jpg',
  style: const WImageStyle(
    aspectRatio: 16 / 9,
    borderRadius: BorderRadius.all(Radius.circular(12)),
  ),
  config: const WImageConfig(memCacheWidth: 480),
)

// 列表缩略图：限制解码尺寸（大图按原尺寸解码很吃内存）
WImage.network(url, config: const WImageConfig(memCacheWidth: 240))

// 带重试与进度
WImage.network(
  url,
  config: WImageConfig(
    retryCount: 3,
    retryDelay: 1500,
    progressBuilder: (context, url, progress) =>
        CircularProgressIndicator(value: progress.fraction),
  ),
  onProgress: (p) => debugPrint('${p.downloadedBytes}/${p.totalBytes}'),
)

// 本地资源 / 文件 / Base64
WImage.asset('assets/images/logo.png')
WImage.file('/tmp/a.png')
WImage.base64(base64String)

// 圆形头像
WImage.network(
  avatarUrl,
  style: const WImageStyle(
    width: 100,
    height: 100,
    borderRadius: BorderRadius.all(Radius.circular(50)),
  ),
)

// 错误分支
WImage.network(
  url,
  config: WImageConfig(
    errorWidgetBuilder: (context, url, error) => switch (error) {
      WImageNetworkError() => const Icon(Icons.wifi_off),
      _ => const Icon(Icons.broken_image),
    },
  ),
)
```

### String 扩展：`toImage`

`'...'.toImage(...)` 是 `WImage` 的便捷入口，适合 URL / 资源路径直接从字符串来的场景。

```dart
'https://example.com/a.png'.toImage(width: 40);
'logo.png'.toAssetImage();                 // → assets/images/logo.png
'assets/icons/logo.png'.toAssetImage(prefix: false);
base64String.toBase64Image();
'/tmp/a.png'.toFileImage();
```

规则：

- 默认按内容自动判定类型（同 [WImageType]）；需要确定性时传 `type:`；
- `size` 只作为 `width` / `height` 的 fallback，**显式宽高优先**；
- `config:` 透传 `WImageConfig`，会被复制，`toImage` 内的覆盖不会修改调用方传入的配置；
- 支持 `key` / `controller` / `onProgress` / `semanticLabel`；
- 本地资源**不会**自动拼 `WAssets.imagePath`，需要时用 `toAssetImage()` 或其 `prefix: false`。

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

## 6. WListView - 列表

### 功能说明

`WListView` 只负责独立滚动，`WListViewSliver` 只负责列表内容：

```text
WListView        + controller / physics / shrinkWrap
WListViewSliver  + list / separated / grid / overlap
```

需要嵌入 SmartRefresher / NestedScrollView 时，直接使用 `WListViewSliver`：

```dart
SmartRefresher(
  child: CustomScrollView(
    slivers: [
      WListViewSliver.overlap(
        itemExtent: 230,
        overlap: 60,
        itemCount: items.length,
        itemBuilder: (context, index) => card(items[index]),
      ),
    ],
  ),
)
```

### WListView

```dart
WListView(
  controller: controller,
  physics: const AlwaysScrollableScrollPhysics(),
  sliver: WListViewSliver.list(
    itemCount: items.length,
    itemBuilder: (context, index) => Text('$index'),
  ),
)
```

参数：

| 参数 | 说明 |
|------|------|
| `sliver` | 必需，列表内容 |
| `controller` | 可选，滚动控制器，由调用方管理 |
| `physics` | 可选，只属于最终滚动层 |
| `shrinkWrap` | 可选，独立列表使用；嵌套滚动请用 sliver |
| `scrollDirection` | 可选，默认垂直 |
| `reverse` | 可选，默认 false |

### WListViewSliver 构造

| 构造 | 说明 |
|------|------|
| `WListViewSliver.list` | 普通列表，可选 `itemExtent` |
| `WListViewSliver.separated` | 分隔列表，`separatorBuilder` 必填 |
| `WListViewSliver.grid` | 网格列表，`gridDelegate` 必填 |
| `WListViewSliver.overlap` | 重叠列表，`itemExtent` + `overlap` 必填 |

公共参数：

| 参数 | 说明 |
|------|------|
| `itemCount` | 子项数量 |
| `itemBuilder` | 子项构建器 |
| `padding` | 整个 sliver 组的内边距 |
| `header` / `footer` | 头部 / 尾部 |
| `empty` | `itemCount == 0` 时显示；header/footer 仍保留 |
| `emptyFill` | 是否填满剩余视口；`shrinkWrap: true` 时必须为 false，否则断言 |
| `keepAlive` | 标准 `addAutomaticKeepAlives` |

### 重叠列表

```dart
WListViewSliver.overlap(
  itemExtent: 230,
  overlap: 60,
  itemCount: items.length,
  itemBuilder: (context, index) => card(items[index]),
)
```

语义：

```text
itemExtent = 卡片自身高度
overlap = 相邻卡片重叠高度
有效布局高度 = itemExtent - overlap
```

约束：

```text
itemExtent > 0
0 <= overlap < itemExtent
```

重叠仅由 `WListViewSliver.overlap` 提供，不再使用 `useOverlap` / `overlapOffset`。
`overlap` 只支持垂直方向，且不支持 `reverse`；水平列表请使用 `WListViewSliver.list` / `.separated` / `.grid`。

### 与 SmartRefresher 配合

```dart
GetBuilder(
  builder: (c) => SmartRefresher(
    controller: controller.refreshController,
    onRefresh: controller.onRefresh,
    child: CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        WListViewSliver.list(
          itemCount: c.items.length,
          itemBuilder: (context, index) => card(c.items[index]),
        ),
      ],
    ),
  ),
)
```

关键约束：

- `SmartRefresher` 的 child 必须直接是 `CustomScrollView`；
- 不要把 `GetBuilder` 放在 `SmartRefresher` 和 `CustomScrollView` 之间；
- 不要在 `WListViewSliver` 内部放 controller / physics；
- 不要再使用 `shrinkWrap` 作为嵌套适配。

### 头部 / 尾部 / 空状态

```dart
WListViewSliver.list(
  itemCount: items.length,
  header: const Text('Header'),
  footer: const Text('Footer'),
  empty: const Center(child: Text('暂无数据')),
  itemBuilder: ...,
)
```

- `empty` 只替换列表主体；
- `emptyFill: true` 且无 header/footer 时填满剩余空间；否则按自然高度显示；
- `shrinkWrap: true` 时必须使用 `emptyFill: false`；直接放进 `CustomScrollView` 时同样受此限制；
- header / footer 继续显示；
- 不再有 `WListViewConfig`、`buildByList`、`itemBuilderByT`。

---

## 7. WScaffold - 增强脚手架

### 功能说明

增强版 Scaffold，提供安全区域自动处理、状态栏样式设置、underlay 底层 widget 叠加（用于渐变背景）。

### WScaffold 构造参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `title` / `titleWidget` | — | null | 自动构建默认 `WAppBar` |
| `leading` / `actions` | — | null / [] | 默认 AppBar 的左右内容 |
| `onBack` | VoidCallback? | null | 自定义返回；不传走 canPop |
| `appBarStyle` | WAppBarStyle? | null | 默认 AppBar 样式 |
| `appBarBottom` | PreferredSizeWidget? | null | 默认 AppBar 的 bottom |
| `appBar` | WAppBar? | null | 完全覆盖默认顶部栏 |
| `body` | Widget? | null | 主体内容 |
| `bottomNavigationBar` | Widget? | null | 底部导航 |
| `floatingActionButton` | Widget? | null | FAB |
| `backgroundColor` | Color? | null | 背景颜色 |
| `systemStatusBarStyle` | SystemUiOverlayStyle? | null | 状态栏样式 |
| `underlayWidget` | Widget? | null | 底层 widget |
| `includeTopSafeArea` | bool | false | 无 AppBar 时是否加顶部安全区 |
| `includeBottomSafeArea` | bool | true | 无 bottomNavigationBar 时是否加底部安全区 |
| `resizeToAvoidBottomInset` | bool | true | 键盘避让 |

不再提供 `WScaffoldConfig`；直接构造参数。

说明：

- 不传非空 `title` / `actions` / `onBack` / `appBarBottom` / `appBar` 时不会创建顶部栏；
- 安全区使用 `MediaQuery.padding`，与 WAppBar 的状态栏来源一致；
- 没有顶部栏且 `includeTopSafeArea` 为 false 时，body 会顶到状态栏下方；
- 有 `bottomNavigationBar` 时不再重复加底部安全区；
- `WScaffold` 是轻量页面壳，不提供 drawer / bottomSheet / extendBody；需要时用原生 `Scaffold`；
- `appBar` 覆盖时，appBar 必须 `includeStatusBar: true`；appBar 自身的
  `automaticallyImplyLeading` / `centerTitle` 不受限制；WScaffold 上同名参数必须保持默认。

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

### 盒子：Container + BoxDecoration

不再提供 `WContainer` / `WContainerConfig`。盒子直接用 Flutter 原生 `Container` +
`BoxDecoration`，完整支持背景、渐变、边框、圆角、阴影、前景装饰、约束和 transform。

```dart
Container(
  width: 200,
  height: 48,
  decoration: BoxDecoration(
    color: Colors.blue,
    borderRadius: BorderRadius.circular(24),
  ),
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: const Text('内容'),
)
```

需要 1px 描边且不占宽度时用 `foregroundDecoration`：

```dart
Container(
  foregroundDecoration: BoxDecoration(
    border: Border.all(color: Colors.black12),
    borderRadius: BorderRadius.circular(12),
  ),
  child: ...,
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

标准顶部导航栏：leading / title / actions / bottom。

```dart
WScaffold(
  title: '订单详情',
  actions: [
    IconButton(
      tooltip: '搜索',
      icon: const Icon(Icons.search),
      onPressed: search,
    ),
  ],
  body: ...,
)
```

WScaffold 会自动构建 `WAppBar`；特殊页面可直接传 `appBar`：

```dart
WScaffold(
  appBar: WAppBar(
    title: '自定义',
    style: const WAppBarStyle(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    ),
  ),
  body: ...,
)
```

功能契约：

- `leading` 优先；否则 `onBack`（优先于 `automaticallyImplyLeading`）；否则
  `Navigator.canPop` 时显示默认返回；
- 默认返回按钮是 `BackButton` / `IconButton`，支持键盘和语义；
- `title` 与 `titleWidget` 二选一；
- `actions` 是 `List<Widget>`；
- `includeStatusBar` 默认 true，负责状态栏背景与 padding；
- 高度为 `style.height`，bottom 额外计算；
- WScaffold 内部的 PreferredSize 只包含 `contentHeight`（toolbar + bottom），状态栏由 WAppBar 自己绘制，避免重复计算；
- `WAppBarStyle` 提供 `copyWith` 与 `validate`；`backgroundColor` 与 `gradient` 只能选一个；
  `height` / `titleSpacing` 必须非负；
- `foregroundColor` 只作用于默认标题和默认图标主题；`titleWidget` / 自定义 leading 由调用方负责颜色；
- WAppBar 的 `systemOverlayStyle` 优先于 WScaffold 的 `systemStatusBarStyle`；
- actions 建议控制在 2–3 个，更多操作放 overflow menu。
- WAppBar 只暴露 `contentHeight`，不提供 totalHeight。

需要完全自定义叠放时，直接在页面里使用 `Container` / `Stack`，不使用 WAppBar。

### WStep

步骤条，`current` 从 **1** 开始。

```dart
WStep(
  current: 2,
  labels: const ['確認電郵', '電郵驗證', '基本資料'],
  style: const WStepStyle(
    completedColor: Colors.green,
    currentColor: Colors.green,
  ),
)
```

#### WStep 参数

| 参数 | 说明 |
|------|------|
| `current` | 当前步骤，1..labels.length |
| `labels` | 步骤标题，不能为空 |
| `itemBuilder` | 可选，`(context, index, state)`；index 从 1 开始 |
| `separatorBuilder` | 可选，`(context, index, completed)`；index 表示第 index 步后的分割线 |
| `semanticLabelBuilder` | 可选，自定义读屏文案 |
| `style` | `WStepStyle`，默认蓝/灰 |

#### WStepState

```dart
enum WStepState { completed, current, upcoming }
```

#### WStepFlow

同一套步骤在多个页面复用时，先定义 flow：

```dart
final registerStepFlow = WStepFlow(
  labels: const ['確認電郵', '電郵驗證', '基本資料'],
  style: const WStepStyle(completedColor: Colors.green),
);

// 页面只传 current
registerStepFlow.build(current: step)
```

#### 约束

- `itemBuilder` 返回的 widget 会被放进 `Expanded` 单元格，不要返回 `Expanded`；
- `labels` 不能为空；
- `current` 必须在 `1..labels.length`；
- 默认最多适合 3–5 步；步骤过多时横向空间不足；
- 背景、高度、padding 由外层 `Container` 负责，不用 `backgroundBuilder`。

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

输入前后的空格会被忽略。

```dart
final c = HexColor.fromHex('#FF5733');    // RRGGBB
final c2 = HexColor.fromHex('#80FF5733'); // AARRGGBB
final hex = c.toHex();                    // '#ffff5733'
final hex2 = c.toHex(leadingHashSign: false); // 'ffff5733'
```

### WStringExtension

字符串扩展，提供格式化、验证、转换等便捷方法。

### WNumExtension

数值扩展，提供尺寸、间距、圆角、格式化与补零：

| 方法 | 说明 |
|------|------|
| `10.heightBox` / `10.widthBox` / `10.squareBox` | 创建 SizedBox |
| `10.allPadding` / `horizontalPadding` / `verticalPadding` | 创建 EdgeInsets |
| `10.borderRadius` | `BorderRadius.circular(10)` |
| `1234.toThousand` | `1,234` |
| `1234.toCurrency(symbol: '¥')` | `¥1,234` |
| `(-1234.56).toCurrency(symbol: '\$')` | `-\$1,234.56` |
| `0.5.toPercent` | `50%` |
| `0.333.toPercentWithFixed(1)` | `33.3%` |
| `1.toPadLeft(3)` | `001` |
| `(-1).toPadLeft(3)` | `-01` |

补零时负号计入总长度；`toPercent` 的整数结果不带 `.0`。

### WWidgetExtension

Widget 扩展，提供间距、展开、点击糖和单层装饰；盒子装饰仍用 `Container` +
`BoxDecoration`：

```dart
Text('Hello')
  .withHorizontalPadding(16)
  .withVerticalPadding(8)
  .expanded()
```

可用方法：`expanded`、`withHorizontalPadding`、`withVerticalPadding`、
`withLeftPadding`、`withRightPadding`、`withTopPadding`、`withBottomPadding`、
`withTopSafeSpace`、`withBottomSafeSpace`、`withDecoration`、
`withIntrinsicHeight`。`withBottomSpace` 已废弃，用 `withBottomPadding`。

`withDecoration` 只包一层 `DecoratedBox`，不提供 padding / margin；
需要圆角裁剪时用 `Container(clipBehavior: Clip.antiAlias)`。

`withTopSafeSpace` / `withBottomSafeSpace` 读取 `WScreen`，不读取当前 `MediaQuery`。

### WBoxDecorationExtension / WGradients / WShadows

`BoxDecoration` 可组合扩展，避免重复写完整构造：

```dart
const base = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(12)),
);

Container(
  decoration: base
      .withGradient(WGradients.vertical([
        Color(0xFF3949AB),
        Color(0xFF5C6BC0),
      ]))
      .withShadow(WShadows.card),
  child: ...,
)
```

- `withGradient` / `withColor` 只设置对应字段，不自动清空另一个；
- 需要唯一背景时显式 `withoutColor()` / `withoutGradient()`；
- `withBorderRadius` 不能用于 circle；`circle()` 会自动清空 borderRadius；
- `WGradients` 只提供方向，不绑定品牌色；
- `WShadows` 提供 `none` / `card` / `elevated` / `floating` 中性预设。

### WRow / WColumn

便捷创建 Row / Column 的工厂类：

```dart
WRow.min(children: [...])
WRow.iconWithText(icon: ..., spacing: 8, text: ...)
WColumn.min(children: [...])
```

### WGlobalKeyExtension

GlobalKey 扩展，支持查找、定位、获取 Widget 状态等。

### WImageExtension

Image 相关扩展，便捷创建 CachedNetworkImage、带圆角的图片等。

### WTextStyleExtension

`TextStyle` 的便捷扩展：`bold` / `withColor` / `withSize`。
配置转换仍用 `WTextConfig.toTextStyle()` / `WTextConfig.toStrutStyle()`。

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

### WImagePreloader

1.0 的资产原始字节缓存（LRU + 内存上限 + 命中率统计）。1.1.0 起 `WImage` 不再使用它：资产图片直接走 `Image.asset` + Flutter `ImageCache`。该类保留用于 `preloadImage` 预加载与缓存统计。

### WAssets

资源前缀的**唯一开关**：`'logo.png'.assetImagePath` 读的就是 `WAssets.imagePath`；
聚合包中的 `WConfig.assetImagePath` 也是它的转发，两处设置等价。

```dart
WAssets.imagePath = 'assets/icons/';
'logo.png'.assetImagePath; // → 'assets/icons/logo.png'
```

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
    return WListView(
      physics: const AlwaysScrollableScrollPhysics(),
      sliver: WListViewSliver.separated(
        padding: EdgeInsets.all(WScreen.w(16)),
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
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
            style: WButtonStyles.danger,
            label: '删除',
            size: WButtonSize.small,
            onTap: () => setState(() => _items.removeAt(i)),
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
              style: WButtonStyles.primary,
              label: '提交',
              onTap: () => print('提交'),
            ),
          ),
        ),
        empty: const Center(child: Text('暂无数据')),
      ),
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
| 3.27+ | ✅ 兼容 | `WListViewSliver` 使用 `SliverMainAxisGroup` 与 sliver API |

> 最低 Flutter 版本锁定为 3.27。列表不再单独声明 `cacheExtent`，滚动缓存由外层 `CustomScrollView` 决定。

### WScreen 委托注入

- 委托在 `runApp` 之前设置即可，也可在 `ScreenUtilInit.builder` 内设置
- **非延迟初始化**：`WScreen.screenWidth` 等设备信息可在应用任何时刻调用，但依赖 `WidgetsBinding.instance.platformDispatcher.views.first`，因此 WidgetsBinding 必须已初始化（默认 `Flutter.ensureInitialized()` 或 `runApp` 后自动满足）
- 无委托时 `w()` / `h()` / `sp()` 直接返回原值，可安全用作统一 API

### WButton 样式复用

- 样式用 `WButtonStyle`（不可变），跨页面复用静态预设 `WButtonStyles.*`；
- 样式通过 `AppButtons` / `WButtonStyle` 显式传入，`WButtonStyles.primary` 仅作 fallback；
- 不再有 `WButtonConfig` / 全局配置缓存；运行时 `enabled` / `loading` 由 `WButton` 参数承载。

### WImage 平台差异

- 文件图片使用条件导入（`_image_file_native.dart` vs `_image_file_web.dart`）；判断条件是 `dart.library.io`，Web/WASM 都走 Web 实现并返回 `WImageUnsupportedError`
- Base64：≤64KB 在主 isolate 解码，超过 64KB 才用 `compute()`
- 网络进度与重试依赖 `cached_network_image`

### WListView controller 生命周期

- `WListView.controller` 由调用方持有并释放
- 组件不创建内部 controller
- `WListViewSliver` 不持有 controller / physics
- header/footer/empty 统一使用 `SliverMainAxisGroup`

### WNavController 生命周期

- 与 `WListView controller` 同理，controller 由调用方管理
- `dispose()` 需在 `State.dispose()` 中调用

---

相关文档：[模块索引](README.md) · [组件目录](components.md) · [接入约定](../conventions.md)
