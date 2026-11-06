# UI 模块文档

## 概述

UI 模块（`w_tools_ui` 子包）提供了一套基于 Flutter 的 UI 组件层，包含通用组件、布局组件、导航组件、扩展方法和工具类。

**模块特点：**

- **零业务框架依赖**：不依赖其他 w_tools 子包；`qr` 和 `toast` 是独立子包，ui 本身不直接依赖它们，根聚合包负责 re-export
- **最低 Flutter 版本 3.38**：已修复 `ListView cacheExtent` 的版本兼容（Flutter 3.27–3.43 使用 `cacheExtent`，3.44+ 被标记 deprecated，源码已用 `// ignore: deprecated_member_use` 保留兼容性）
- **依赖第三方包**：`badges` ^3.1.2（徽章组件）、`cached_network_image` ^3.3.1（图片缓存）
- **屏幕适配可选**：`WScreen` 内置设备信息获取，适配函数通过委托注入，可与 `flutter_screenutil` 共存，无 delegate 时返回原始值

## 快速判断
- 普通按钮 → `WButton`；任意 child 点击 → `WPressable`
- 图片 → `WImage`
- 页面骨架 → `WScaffold` / `WAppBar`
- 找组件先看 [`components.md`](components.md)
- 可运行示例：[packages/ui/example](../../packages/ui/example/README.md)

- 强制规则：根 [`AGENTS.md`](../../AGENTS.md)

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
    │   │   │   ├── image_config.dart           # WImageLoadOptions
    │   │   │   ├── image_loader.dart           # 内部加载器（不导出）
    │   │   │   ├── image_load_state.dart       # 内部状态基类
    │   │   │   ├── image_frame.dart            # WImageFrame
    │   │   │   ├── image_defaults.dart         # WImageTheme / WImageSlots
    │   │   │   ├── image_types.dart            # WImageType / WImageProgress / WImageError
    │   │   │   ├── image_retry_policy.dart     # 重试判定与退避（内部）
    │   │   │   └── _image_file_*.dart          # file provider 条件实现
    │   │   ├── keep_alive_wrapper.dart        # WKeepAliveWrapper
    │   │   ├── notification_listener.dart      # WNotificationListenerBuilder
    │   │   ├── row_actions.dart               # WActionRow / WSelectableRow
    │   │   ├── gradient_circular_progress_indicator.dart
    │   │   ├── text/                  # 文字组件
    │   │   │   ├── w_text.dart                 # WText
    │   │   │   ├── w_text_styles.dart          # WTextStyles / WTextVariant
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
    │   ├── color.dart                         # WHexColor（Color 扩展）
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
        ├── screen.dart                        # WScreen
```

---

## 1. WScreen - 屏幕适配

### 功能说明

零第三方依赖的屏幕尺寸与适配工具。支持获取设备信息（永远可用），也可通过委托注入与 `flutter_screenutil` 共享配置。

无 delegate 时 `w()` / `h()` / `sp()` 返回原始值，不影响未启用屏幕适配的应用。

### 设备信息

推荐用 `WScreen.of(context)`（跟随树内 `MediaQuery`，分屏 / 多窗口 / 测试都正确）：

```dart
final screen = WScreen.of(context);
screen.width / screen.height / screen.statusBarHeight / screen.bottomSafeAreaHeight;
```

| 成员 | 类型 | 说明 |
|------|------|------|
| `of(context)` | `WScreenData` | 树内屏幕信息（推荐） |
| `screenWidth` | double | 设备屏幕宽度（逻辑像素，来自平台 view） |
| `screenHeight` | double | 设备屏幕高度（逻辑像素，来自平台 view） |
| `statusBarHeight` | double | 状态栏高度（刘海屏会更高） |
| `bottomSafeAreaHeight` | double | 底部安全区高度 |

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

### ⚠️ `.sp` 初始化时机

不要在 `main()`、顶层 `final` 或 `static final` 中调用 `.sp`：

```dart
// 错：ScreenUtil 还没 configure
final typography = WTextStyles(... fontSize: 16.sp ...);
```

`ScreenUtil._minTextAdapt` 是 late 字段，未 configure 时调用会抛
`LateInitializationError`。应在 `ScreenUtilInit.builder` 或
`WAppOptions.builder`（或消费方自建插件的 `builderWrapper`）的 build 期再计算。

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
final bottomSafe = WScreen.bottomSafeAreaHeight;
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
| `style` | `WButtonStyle?` | null | 样式；null 时使用 `WButtonStyles.of(context).primary` |
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
| `alignment` | AlignmentGeometry | 内容对齐，默认 `Alignment.center`；全宽按钮居中 |
| `clipBehavior` | Clip | 背景裁剪（静态） |
| `foregroundColor` | `WidgetStateProperty<Color?>?` | 文字/图标前景色 |
| `textStyle` | `WidgetStateProperty<TextStyle?>?` | 文本样式 |
| `focusColor` / `hoverColor` | Color? | 焦点/悬停 overlay |
| `disabledOpacity` | double | 禁用透明度 |
| `minWidth` / `minHeight` | double | 视觉/布局最小尺寸 |
| `tapTargetSize` | double | 实际 hit area 下限；与 `minWidth` / `minHeight` 配合计算 |
| `iconSize` / `gap` | double | 图标尺寸 / 间距 |

状态色说明：

- `WButtonStyle.filled / outlined / text` 只是单色快捷构造；`pressed / disabled /
  hovered / focused` 由项目级 `AppButtons` 通过 `WidgetStateProperty.resolveWith` 定义。
- `foregroundColor` 会合并进最终 `textStyle`；`label` / `icon` 不需要自己设置颜色，
  `textStyle.color` 会被 `foregroundColor` 覆盖。
- 如果已经在 `backgroundColor` / `foregroundColor` 中解析了禁用色，必须设置
  `disabledOpacity: 1`，否则 `WButton` 还会再叠一层透明度。
- `hoverColor` / `focusColor` 是 WButton 的 overlay；项目通过 `_bg` 处理 hover 时，
  通常应把 `hoverColor` 设为 `Colors.transparent`，避免双重叠加。

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

> `WButtonSize` 不包含 `width`。宽度由父布局决定，不要为了“撑满”给
> `WButtonSize` / `WButtonStyle` 加 `width`：
>
> - 撑满：`SizedBox(width: double.infinity, child: WButton(...))` 或 `Expanded`
> - 固定宽度：外层 `SizedBox(width: ...)`
> - 一行多个：`Row` + `Expanded`
>
> `minWidth` 只是最小视觉 / 点击尺寸，不是固定宽度；`double.infinity` 应交给父约束。

```dart
// 撑满
SizedBox(
  width: double.infinity,
  child: WButton(label: '提交', onTap: _submit),
)

// 固定宽度
SizedBox(
  width: 343,
  child: WButton(label: '保存', onTap: _save),
)

// 一行两个
Row(
  children: [
    Expanded(child: WButton(label: '取消', onTap: _cancel)),
    const SizedBox(width: 12),
    Expanded(child: WButton(label: '确认', onTap: _confirm)),
  ],
)
```

如果需要统一“宽按钮”，不要把 Widget 工厂塞进 `AppButtons`。`AppButtons` 只负责返回
`WButtonStyle`；宽度是布局职责，页面直接组合：

```dart
SizedBox(
  width: double.infinity,
  child: WButton(
    style: AppButtons.primary(context),
    label: '提交',
    onTap: _submit,
  ),
)
```

如果项目里大量重复，可以单独放一个布局 helper，例如
`AppButtonLayouts.fullWidth(child)`，而不是让 `AppButtons` 同时返回样式和 Widget。

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
      WImage.source(source: WImageSource.asset('demo.png', prefix: true)),
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

> `WText` 使用 `variant` + `WTextStyles`；`WTextConfig` 已移除。

### 推荐：语义文字样式

```dart
WText(
  text: '标题',
  variant: WTextVariant.title,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
)
```

`WTextStyles` 是 `ThemeExtension<WTextStyles>`：

```dart
ThemeData(
  extensions: [
    WTextStyles(
      display: ...,
      headline: ...,
      title: ...,
      body: ...,
      bodyStrong: ...,
      caption: ...,
      label: ...,
      button: ...,
      price: ...,
      number: ...,
      badge: ...,
    ),
  ],
)
```

没有安装时，`WTextStyles.of` 会从当前 `TextTheme` 生成兜底样式。

> 如果 `WTextStyles` 使用 `.sp`，不要写顶层 `final` / `static final`；
> 在 `ScreenUtilInit` 之后、推荐在 `WAppOptions.builder`（或自建插件的 `builderWrapper`）中构建。

### WTextVariant 不够用时

按顺序处理：

1. 一次性视觉差异：已有 variant + `style` 局部覆盖。
2. 项目内重复：抽本地 `TextStyle` helper 或包装组件。
3. 稳定、跨页面、主题级语义：再提给 `w_tools_ui` 新增 variant。

```dart
import 'dart:ui' show FontFeature;

WText(
  text: '¥128.00',
  variant: WTextVariant.price,
  style: WTextStyles.of(context).price.copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
  ),
)
```

`style` 会合并到 variant 上；颜色仍优先用 `color`。消费方不能自行新增 `WTextVariant` enum。

### WText 参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `variant` | `WTextVariant?` | 语义样式；null 时不额外应用语义样式 |
| `style` | `TextStyle?` | 一次性样式覆盖 |
| `color` | `Color?` | 一次性颜色覆盖 |
| `maxLines` | `int?` | 最大行数 |
| `overflow` | `TextOverflow?` | 溢出处理 |
| `textAlign` | `TextAlign?` | 对齐方式 |
| `softWrap` | `bool?` | 是否软换行 |
| `textDirection` | `TextDirection?` | 文本方向 |
| `textScaler` | `TextScaler?` | 文本缩放 |
| `semanticsLabel` | `String?` | 无障碍标签 |
| `locale` | `Locale?` | 语言 |
| `textWidthBasis` | `TextWidthBasis?` | 宽度基准 |
| `strutStyle` | `StrutStyle?` | 显式 strut |



### 功能说明

`WText` 只负责文本渲染和覆盖；字体、字号、字重、行高统一定义在
`WTextStyles` / `TextTheme`。多色或多字重混排使用 Flutter `Text.rich`。

有字体信息（fontFamily / fontSize / height）时，`WText` 会自动生成
`StrutStyle(forceStrutHeight: true)`，避免大字号 / 字体回退裁切；显式传
`strutStyle` 时以显式值为准。

### 使用示例

```dart
WText(
  text: '标题',
  variant: WTextVariant.title,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
)

WText(
  text: '正文内容',
  variant: WTextVariant.body,
  color: Colors.black54,
  maxLines: 3,
)

WText(
  text: '局部覆盖',
  variant: WTextVariant.body,
  style: const TextStyle(fontWeight: FontWeight.w700),
)
```

混排：

```dart
Text.rich(
  TextSpan(
    style: WTextStyles.of(context).body,
    children: [
      const TextSpan(text: '¥'),
      TextSpan(
        text: '100',
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
      ),
      const TextSpan(text: ' 起'),
    ],
  ),
)
```

## 4. WImage - 图片组件

### 功能说明

图片组件，支持网络 URL、本地资源、本地文件、Base64 与任意 `ImageProvider`。

新代码统一使用 `WImage.source` + `WImageSource`：

- 来源：`WImageSource.network` / `asset` / `file` / `base64` / `provider`
- 视觉：`WImageStyle`（尺寸、fit、圆角、边框、阴影、间距、语义）
- 加载行为：`WImageLoadOptions`（解码尺寸、重试、gapless）
- UI 插槽：`WImage.slots: WImageSlots(...)`；App 级默认值用 `WImageTheme(slots: ...)`
- 控制：`WImageController`，手动重试 + 非空加载状态

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
  config: const WImageLoadOptions(retryCount: 1),
)
```

- `WImageSource` 是 sealed：`network` / `asset` / `file` / `base64` / `provider`；
  `WImageSource.parse` 只作为动态字符串的便利入口，WImage 不再替调用方猜类型；
- `WImageStyle` / `WImageLoadOptions` 都是不可变值对象（实现 `==` / `hashCode`）；
- `WImageTheme` 只接收 `WImageSlots`，不会静默覆盖单图的解码/重试配置；
- `WImageController.state` 从创建起就是非空 `ValueListenable<WImageLoadSnapshot>`，初始 `idle`；
- 网络图统一走 `CachedNetworkImageProvider` + `Image`；磁盘缓存由 `cached_network_image` 负责；
- 旧 `WImage.network/asset/file/base64/provider` 在 5.0/6.0 删除，旧 `WImageLoadConfig` /
  `WImageDefaultsScope` 在 7.0 删除；迁移见 [`docs/migrations/ui-7.0.md`](../migrations/ui-7.0.md)。

### 构造参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `source` | `WImageSource` | 必需，图片来源 |
| `style` | `WImageStyle` | 视觉样式（默认 `const WImageStyle()`） |
| `config` | `WImageLoadOptions` | 加载行为（默认 `const WImageLoadOptions()`） |
| `slots` | `WImageSlots?` | 单图 UI 插槽；null 时使用 `WImageTheme` |
| `onLoadStatusChanged` | `ValueChanged<WImageLoadStatus>?` | 加载状态回调（post-frame） |
| `onProgress` | `ValueChanged<WImageProgress>?` | 进度回调（网络 / 自定义 provider 的 chunk） |
| `controller` | `WImageController?` | 手动重试 / 状态监听 |

### 显式构造

| 入口 | 说明 |
|------|------|
| `WImage.source(source: WImageSource.network(url))` | 网络图；`//` 开头的协议相对地址会补 `https:` |
| `WImage.source(source: WImageSource.asset(path))` | 资产图；前后的空白会被裁掉 |
| `WImage.source(source: WImageSource.file(path))` | 本地文件；带不带 `file://` 都可以 |
| `WImage.source(source: WImageSource.base64(data))` | Base64；可带 `data:...;base64,` 前缀，也可裸串 |
| `WImage.source(source: WImageSource.provider(MemoryImage(bytes)))` | `Uint8List` → `MemoryImage` |
| `WImage.source(source: WImageSource.provider(provider))` | 任意 `ImageProvider` |
| `WImageSource.resolve(...)` | 预加载：返回与 WImage 相同尺寸规则的 `ImageProvider` |

```dart
final provider = await WImageSource.asset('logo.png').resolve(
  memCacheWidth: 240,
  memCacheHeight: 240,
);
await precacheImage(provider, context);
```

`WImage.thumbnail` / `WImage.cover` / `WImage.assetImage` 已在 5.0 删除；
字符串图片扩展已在 6.0 删除。

### WImageSource.parse 自动判定

| 类型 | 识别条件 |
|------|----------|
| `network` | `Uri` 解析出的 scheme 为 `http`/`https`（大小写无关）且 host 非空；或 `//` 开头 |
| `file` | scheme 为 `file` |
| `base64` | `data:` 开头（不限于 `data:image/`） |
| `asset` | 其余；空串/纯空白会直接渲染错误占位 |

`WImageSource.parse` 由调用方执行（通常在自己的 build / 数据层），WImage 内部不会再猜一次。
无法识别来源优先显式传 `type`；`provider` 不能从字符串解析。

### 错误类型

`errorWidgetBuilder` 的第三个参数是 `WImageError`，用 `error.kind`（`WImageErrorKind`）区分：

| kind | 场景 |
|------|------|
| `empty` | 空串 / 纯空白 |
| `network` | 网络请求失败（`cause` 为底层异常） |
| `asset` | 资产不存在或解码失败 |
| `decode` | Base64 解码失败 / 图片解码失败 |
| `file` | 文件读取失败 |
| `provider` | 任意 `ImageProvider` 解码失败 |
| `unsupported` | Web 上的 `file://` |

```dart
errorWidgetBuilder: (context, url, error) => switch (error.kind) {
  WImageErrorKind.network => const Icon(Icons.wifi_off),
  WImageErrorKind.empty => const Icon(Icons.image_not_supported),
  _ => const Icon(Icons.broken_image),
},
```

### WImageStyle 配置

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `width` / `height` | `double?` | null | 图片内容尺寸 |
| `fit` | `BoxFit` | cover | 适配模式 |
| `alignment` | `Alignment` | center | 对齐方式 |
| `aspectRatio` | `double?` | null | 图片内容比例；不能与固定 width/height 同用 |
| `filterQuality` | `FilterQuality` | low | 采样质量 |
| `semanticLabel` | `String?` | null | 无障碍描述 |
| `excludeFromSemantics` | bool | false | 从语义树排除 |
| `borderRadius` / `border` / `boxShadow` | — | null | 装饰；边框绘制在图片之上 |
| `margin` / `padding` | `EdgeInsets?` | null | 间距 |

`WImageStyle` 是值对象：字段相同即 `==`，可用于 const / 外层缓存。

### WImageLoadOptions 配置

只包含加载行为，不包含 UI：

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `memCacheWidth` / `memCacheHeight` | `int?` | null | 解码尺寸上限（物理像素） |
| `gaplessPlayback` | bool | false | 换 source 时保留上一帧，直到新图加载完成 |
| `retryCount` / `retryDelay` | int / int | 0 / 1000 | 网络重试次数 / 基础间隔（毫秒，带抖动） |

### WImageSlots 配置

单图或 `WImageTheme` 的 UI 插槽：

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `placeholderBuilder` | 函数 | null | 占位符（推荐） |
| `placeholder` | `Widget?` | null | 固定占位符（有 width/height 时会套 SizedBox） |
| `errorWidgetBuilder` | 函数 | null | 错误占位（推荐，第三参是 `WImageError`） |
| `errorWidget` | `Widget?` | null | 固定错误占位（有 width/height 时会套 SizedBox） |
| `progressBuilder` | 函数 | null | 进度（`WImageProgress`） |
| `showRetryButton` | `bool?` | null | 可重试错误时显示内置“错误 + 重试”视图；null 继承主题 |
| `retryLabel` | `String?` | null | 内置重试按钮文案；null 继承主题 / 使用「重试」 |

- `width` / `height` 是图片内容尺寸；`padding` / `margin` 在外部叠加。
- 没有 `width` / `height` / `aspectRatio` 时，父级必须在至少一个轴上有界；否则加载前占位是
  0 尺寸（空白）。debug 下会打印一次提示。
- `aspectRatio` 不能和固定 `width` / `height` 同时设置。
- `placeholderBuilder` / `errorWidgetBuilder` 的返回值不会自动套 `SizedBox`；
  `WImageSlots` 的固定 `placeholder` / `errorWidget` 在设置 width/height 时会套。
- 网络 `headers` / `cacheKey` 属于 `WImageSource.network`，不要放到 options。

### 加载状态与进度

- `WImageLoadStatus`：`idle` / `loading` / `completed` / `failed`；`WImageController.state` 初始为 `idle`。
- `WImageLoadSnapshot.status` 不再可空；`attempt` 每次自动/手动重试递增。
- `onProgress` 只在进度真正变化时回调；完成时收到 `WImageProgress.complete()`（`isComplete == true`，
  `fraction == 1.0`，字节数不再伪造为 1/1）。
- `WImageLoadSnapshot.retryScheduled == true` 时，`retryDelayMs` 是含抖动的实际排队延迟。

### WImageTheme

```dart
WImageTheme(
  slots: WImageSlots(
    placeholderBuilder: _placeholder,
    errorWidgetBuilder: _error,
    progressBuilder: _progress,
  ),
  child: app,
)
```

### WImageSlots

`WImageSlots` 承载占位 / 错误 / 进度 UI（builder 或固定 Widget）以及内置重试开关；
它不承载 `retryCount`、`memCacheWidth` 等行为配置（这些始终按单图 `WImageLoadOptions` 决定）。

默认优先级按字段分别合并：

- 占位：单图 `slots.placeholderBuilder` / `slots.placeholder` > `WImageTheme` 同名字段 > 内置
- 错误：单图 `slots.errorWidgetBuilder` / `slots.errorWidget` / `showRetryButton` >
  `WImageTheme` 同名字段 > 内置
- 进度：单图 `slots.progressBuilder` > `WImageTheme.progressBuilder` > 占位
- 单图 `showRetryButton: true` 会抑制从主题继承的错误 builder/widget；
  显式 `false` 则允许继承。

内置 `WImageErrorView` 的尺寸策略：

| 尺寸 | 图标 | 文案 | 重试按钮 |
|---|---|---|---|
| 宽 < 96 或高 < 64 | ✅ | ❌ | ❌ |
| 高 64–87 | ✅ | ✅ | ❌ |
| 高 88–111（可重试） | ✅ | ❌ | ✅ |
| 高 ≥ 112（可重试） | ✅ | ✅ | ✅ |

只有 `network` / `provider` / `file` 错误可重试；`empty` / `decode` / `asset` / `unsupported`
不显示重试按钮。小尺寸优先保留按钮而不是文案。

### 缓存与预加载

- 资产 / 文件 / Base64 / provider 统一走 Flutter `ImageCache`；`memCacheWidth` /
  `memCacheHeight` 通过 `ResizeImage` 生效。
- 网络图走 `cached_network_image`（内存 + 磁盘），可用 `headers` / `cacheKey` 定制。
- 预加载用 `WImageSource.resolve(...)` 生成与 WImage 一致的 provider，再 `precacheImage`。
- 注意：`CachedNetworkImageProvider` 的相等性与 Flutter ImageCache key 不包含 headers；
  同一 URL + cacheKey 换 token 不会自动重取。认证图请把用户/租户信息并入 `cacheKey`。

### 重试与手动重试

- `retryCount` 默认 0；只对可重试错误生效：`5xx` / `408` / `429` / 连接级失败。
- 重试间隔指数退避（`retryDelay` → 2× → 4×……，上限 30s）并带 20% 抖动。
- 修改 `retryCount` / `retryDelay` 会取消已排队重试。
- 一个 `WImageController` 只对应一张 `WImage`；同时绑定两张图 debug 下断言。
- `controller.state` 创建后即可监听（初始 `idle`），不需要 `!` / `?`；WImage 卸载后不再更新。
- controller 需要释放时调用 `dispose()`。

```dart
final controller = WImageController();

WImage.source(
  source: WImageSource.network(url),
  controller: controller,
  slots: const WImageSlots(showRetryButton: true),
);

controller.state.addListener(() {
  final snapshot = controller.state.value;
  debugPrint('${snapshot.status} ${snapshot.progress?.fraction}');
});

// 离开页面
controller.dispose();
```

`retry()` 对 network / asset / file / base64 都有效；组件卸载后是空操作。手动重试会清零自动重试预算。

### 使用示例

```dart
// 网络图片 + 固定宽高比 + 解码尺寸
WImage.source(
  source: WImageSource.network('https://example.com/image.jpg'),
  style: const WImageStyle(
    aspectRatio: 16 / 9,
    borderRadius: BorderRadius.all(Radius.circular(12)),
  ),
  config: const WImageLoadOptions(memCacheWidth: 480),
)

// 列表缩略图
WImage.source(
  source: WImageSource.network(url),
  config: const WImageLoadOptions(memCacheWidth: 240, memCacheHeight: 240),
)

// 带重试与进度
WImage.source(
  source: WImageSource.network(url),
  config: const WImageLoadOptions(retryCount: 3, retryDelay: 1500),
  slots: WImageSlots(
    progressBuilder: (context, url, progress) =>
        CircularProgressIndicator(value: progress.fraction),
  ),
  onProgress: (p) => debugPrint('${p.downloadedBytes}/${p.totalBytes}'),
)

// 本地资源 / 文件 / Base64 / provider
WImage.source(source: WImageSource.asset('assets/images/logo.png'))
WImage.source(source: WImageSource.file('/tmp/a.png'))
WImage.source(source: WImageSource.base64(base64String))
WImage.source(source: WImageSource.provider(MemoryImage(bytes)))

// 圆形头像
WImage.source(
  source: WImageSource.network(avatarUrl),
  style: WImageStyle.avatar(48),
)

// 错误分支
WImage.source(
  source: WImageSource.network(url),
  slots: WImageSlots(
    errorWidgetBuilder: (context, url, error) => switch (error.kind) {
      WImageErrorKind.network => const Icon(Icons.wifi_off),
      _ => const Icon(Icons.broken_image),
    },
  ),
)
```

### 字符串入口已删除

`String.toImage` / `toAssetImage` / `toBase64Image` / `toFileImage` 已在 6.0 删除。

改用：

```dart
WImage.source(source: WImageSource.parse(url))
WImage.source(source: WImageSource.asset('logo.png', prefix: true))
WImage.source(source: WImageSource.base64(base64String))
WImage.source(source: WImageSource.file('/tmp/a.png'))
```

---

## 5. WBadge - 徽章组件

### 功能说明

基于 `badges` 包的徽章（角标）组件，用于在子组件上显示角标或标记。

### WBadge 构造参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `config` | `WBadgeConfig?` | 可选，默认 `const WBadgeConfig()` |
| `badgeContent` | `Widget?` | 徽章内容；为 null 时不渲染徽章（不报错） |
| `child` | `Widget?` | 子组件 |

### WBadgeConfig

不可变配置：直接构造 / factory，或用 `copyWith` 派生。

| 入口 | 说明 |
|------|------|
| `WBadgeConfig({position, showBadge, badgeStyle})` | 完整构造 |
| `WBadgeConfig.topRight({top, end})` | 右上角位置 |
| `WBadgeConfig.center()` | 居中位置 |
| `copyWith({position, showBadge, badgeStyle})` | 派生；可空字段传 null 表示清空 |

### 使用示例

```dart
// 右上角显示数字角标
WBadge(
  config: WBadgeConfig.topRight(top: -5, end: -5),
  badgeContent: const Text('3', style: TextStyle(color: Colors.white, fontSize: 12)),
  child: Icon(Icons.notifications),
)

// 自定义位置
WBadge(
  config: WBadgeConfig(
    position: badges.BadgePosition.custom(top: 10, end: 10),
  ),
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

圆角裁剪组件，`ClipRRect` 的便捷封装；支持 `borderRadius` 与 `clipBehavior`。

### WActionRow / WSelectableRow

- `WActionRow`：横向滚动的操作按钮行，无选中语义（`children` + `onTap` 由子项自己处理）；
- `WSelectableRow`：单选高亮行，`selectedIndex` + `onSelected`，默认把选中项滚到视口中间。

```dart
WSelectableRow(
  itemCount: tabs.length,
  selectedIndex: current,
  onSelected: (index) => setState(() => current = index),
  builder: (context, index, selected) =>
      WButton(label: tabs[index], style: selected ? primary : secondary, onTap: () {}),
)
```

### WRowButtons（弃用，5.0 移除）

旧的横向滚动按钮行，选中态与滚动耦合在一起；用 `WActionRow` / `WSelectableRow` 替代。
`WRowButtonsController` 也一并删除。

### WKeepAliveWrapper

保持组件状态的包装器，自动混入 `AutomaticKeepAliveClientMixin`；只暴露 `keepAlive`，不提供不可靠的 activate/deactivate 回调。

### WNotificationListenerBuilder

通知监听构建器，便捷封装 `NotificationListener`（链式配置回调）。

`onNotificationPercentage` 只在 `depth == 0` 的 `ScrollUpdateNotification` 上回调；
滚动开始 / 结束不会触发。`preventNotificationPropagation(true)` 可阻止通知继续向上传递。

### 富文本

多色 / 多字重 / 可点击片段使用 Flutter 原生 `Text.rich`，基础样式从
`WTextStyles.of(context).body` 等语义样式获取：

```dart
Text.rich(
  TextSpan(
    style: WTextStyles.of(context).body,
    children: [
      const TextSpan(text: '已阅读并同意'),
      TextSpan(
        text: '《服务协议》',
        style: const TextStyle(color: Colors.blue),
        recognizer: TapGestureRecognizer()..onTap: _openAgreement,
      ),
    ],
  ),
)
```

不再提供 `WRichText` / `WRichTextConfig`。

### WGradientCircularProgressIndicator

带渐变效果的圆形进度指示器；支持 `semanticsLabel`，并向读屏暴露当前进度。
`colors` 不能为空，`stops` 长度必须与 `colors` 一致。

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
- `labels` 不能为空；直接传 `WStep` 时由调用方保证 list 不再修改，复用流程请用 `WStepFlow`；
- `current` 必须在 `1..labels.length`；
- 默认最多适合 3–5 步；步骤过多时横向空间不足；
- 背景、高度、padding 由外层 `Container` 负责，不用 `backgroundBuilder`。

### WNavBar / WNavController

底部导航栏，由 `WNavController` 驱动选中态切换动画，`itemBuilder(context, index, isSelected)` 渲染每项。

> `onItemTap` 支持异步拦截；如果内部发请求，调用方需要自己做防抖 / loading / 禁用点击。
> `WNavController` 只保证最终动画以最后一次切换为准，不会阻止业务回调重复执行。

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
      itemBuilder: (ctx, index, isSelected) {
        final items = ['首页', '消息', '我的'];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(index == 0 ? Icons.home : Icons.message),
            WText(text: items[index], variant: WTextVariant.caption),
          ],
        );
      },
      onItemTap: (index) async {
        // 返回 false 可阻止切换
        return true;
      },
    );
  }
}
```

手动控制：

```dart
_controller.animateTo(1);
_controller.currentIndex; // 当前选中索引
```

### WTabBar

增强版标签栏，支持自定义样式、指示器、分割线。

`WTabBarConfig` 是不可变配置，用构造 / `copyWith` 派生；`overlayColor` 控制点击 / hover overlay，默认透明。

`WTabBar` 不自带 controller，必须由 `DefaultTabController` 提供，或显式传入 `TabController`。
完整示例见 [`packages/ui/README.md`](../../packages/ui/README.md) 的「顶部 tab」一节（本文不重复维护同一段代码）。

---

## 9. 扩展方法

### WHexColor（Color 扩展）

十六进制颜色转换，兼容多种格式：

| 方法 | 说明 |
|------|------|
| `WHexColor.fromHex(String)` | 静态方法，从十六进制字符串创建 Color（旧名 `HexColor` 已移除） |
| `color.toHex({leadingHashSign: true})` | Color → 十六进制字符串 |

**支持的输入格式：**
- `#AARRGGBB`（带透明度）
- `#RRGGBB`（默认 FF alpha）
- `AARRGGBB` / `RRGGBB`（无 `#`）
- `#ARGB`（简写，每字符重复）
- `#RGB`（简写）

输入前后的空格会被忽略；只允许一个前缀 `#`，其他位置的 `#` 会抛
`FormatException`。

```dart
final c = WHexColor.fromHex('#FF5733');    // RRGGBB
final c2 = WHexColor.fromHex('#80FF5733'); // AARRGGBB
final hex = c.toHex();                    // '#ffff5733'
final hex2 = c.toHex(leadingHashSign: false); // 'ffff5733'
```

### WStringExtension

字符串扩展，提供格式化、验证、转换等便捷方法。

### WNumExtension

数值扩展，提供尺寸、间距、圆角、格式化与补零：

| 方法 | 说明 |
|------|------|
| `10.heightBox` / `10.widthBox` / `10.squareBox` | 创建 SizedBox（保留；不要与已删除的 `WSizeBox` 混淆） |
| `10.allPadding` / `horizontalPadding` / `verticalPadding` | 创建 EdgeInsets |
| `10.borderRadius` | `BorderRadius.circular(10)` |
| `1234.toThousandsSeparated` | `1,234` |
| `1234.toCurrency(symbol: '¥')` | `¥1,234` |
| `(-1234.56).toCurrency(symbol: '\$')` | `-\$1,234.56` |
| `0.5.toPercent` | `50%` |
| `0.333.toPercentWithFixed(1)` | `33.3%` |
| `1.toPadLeft(3)` | `001` |
| `(-1).toPadLeft(3)` | `-01` |

补零时负号计入总长度；`length` 必须为非负数；`toPercent` 的整数结果不带 `.0`，`NaN` / `Infinity` 原样加 `%`。

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
`withTopSafeSpace`、`withBottomBarSpace`、`withDecoration`、
`withIntrinsicHeight`。

`withDecoration` 只包一层 `DecoratedBox`，不提供 padding / margin；
需要圆角裁剪时用 `Container(clipBehavior: Clip.antiAlias)`。

`withTopSafeSpace` / `withBottomBarSpace` 读取 `WScreen`，不读取当前 `MediaQuery`；
`withBottomBarSpace` 使用的是 `WScreen.bottomSafeAreaHeight`，不是系统 safe area。

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

### 布局（原生）

`WRow` / `WColumn` / `WPadding` / `WSizeBox` 已在 5.0 删除，直接用 Flutter 原生组件：

```dart
Row(mainAxisSize: MainAxisSize.min, children: [...])
Column(mainAxisSize: MainAxisSize.min, children: [...])
```

### WGlobalKeyExtension

GlobalKey 扩展，支持查找、定位、获取 Widget 状态等。

### WTextStyleExtension

`TextStyle` 的便捷扩展：`bold` / `withColor` / `withSize`。

---

## 10. 工具类

### 尺寸与间距（原生）

`WPadding` / `WSizeBox` 已在 5.0 删除，直接用 Flutter 原生组件：

```dart
Padding(padding: const EdgeInsets.all(16), child: ...)
SizedBox(width: 100, height: WScreen.h(20))
SizedBox.square(dimension: 50)
```

### 预加载

`WImage` 使用 Flutter `ImageCache`；预加载用 `precacheImage`：

```dart
await precacheImage(
  AssetImage('${WAssets.imagePath}demo.png'),
  context,
);
```

### WAssets

资源前缀的**唯一开关**：`'logo.png'.assetImagePath` 读的就是 `WAssets.imagePath`；
聚合包不再提供 `WConfig`（core 3.0 已删除）；资源前缀直接使用这里的 `WAssets.imagePath`。

```dart
WAssets.imagePath = 'assets/icons/';
'logo.png'.assetImagePath; // → 'assets/icons/logo.png'
```

写入时会自动补齐末尾 `/`；空字符串表示不添加前缀。

---

## 组合示例

完整可运行版本见 [`packages/ui/example/`](../../packages/ui/example/README.md)。这里只保留三处最容易接错的线：

1. **适配委托**：在 `ScreenUtilInit.builder` 里把适配函数注入 `WScreen`；不要在顶层 `final` / `static final` 里算 `.sp`。
2. **列表**：`WScaffold` 负责安全区与 AppBar，列表用 `WListView(sliver: WListViewSliver.*)` 组合 header / footer / empty。
3. **底部导航**：`WNavController` 由页面 `State` 创建并释放；`WNavBar` 只渲染，不持有 controller。

```dart
// 1) 适配委托
ScreenUtilInit(
  designSize: const Size(375, 667),
  builder: (context, child) {
    WScreen.delegateWidth = (v) => ScreenUtil().setWidth(v);
    WScreen.delegateHeight = (v) => ScreenUtil().setHeight(v);
    WScreen.delegateFont = (v) => ScreenUtil().setSp(v);
    return child!;
  },
  child: const MyApp(),
);
```

```dart
// 2) 页面 + 列表
WScaffold(
  body: WListView(
    sliver: WListViewSliver.separated(
      padding: EdgeInsets.all(WScreen.w(16)),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) => ListTile(
        title: WText(text: items[i], variant: WTextVariant.body),
      ),
    ),
  ),
);
```

```dart
// 3) 底部导航：controller 归页面所有
class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  late final WNavController _nav = WNavController(length: 3, vsync: this);

  @override
  void dispose() {
    _nav.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => WScaffold(
        body: IndexedStack(index: _nav.currentIndex, children: const [HomePage(), MessagePage(), ProfilePage()]),
        bottomNavigationBar: WNavBar(
          controller: _nav,
          itemBuilder: (ctx, index, selected) => WText(
            text: labels[index],
            variant: WTextVariant.caption,
            color: selected ? Theme.of(ctx).colorScheme.primary : null,
          ),
        ),
      );
}
```

---

## 注意事项

### Flutter 版本兼容

| 版本 | 状态 | 说明 |
|------|------|------|
| 3.38+ | ✅ 兼容（CI 验证的最低版本） | `WListViewSliver` 使用 `SliverMainAxisGroup` 与 sliver API |

> 最低 Flutter 版本锁定为 3.38。列表不再单独声明 `cacheExtent`，滚动缓存由外层 `CustomScrollView` 决定。

### WScreen 委托注入

- 委托在 `runApp` 之前设置即可，也可在 `ScreenUtilInit.builder` 内设置
- **非延迟初始化**：`WScreen.screenWidth` 等设备信息可在应用任何时刻调用，但依赖 `WidgetsBinding.instance.platformDispatcher.views.first`，因此 WidgetsBinding 必须已初始化（默认 `Flutter.ensureInitialized()` 或 `runApp` 后自动满足）
- 无委托时 `w()` / `h()` / `sp()` 直接返回原值，可安全用作统一 API

### WButton 样式复用

- 样式用 `WButtonStyle`（不可变），跨页面复用静态预设 `WButtonStyles.*`；
- 样式通过 `AppButtons` / `WButtonStyle` 显式传入，`WButtonStyles.primary` 仅作 fallback；
- 不再有 `WButtonConfig` / 全局配置缓存；运行时 `enabled` / `loading` 由 `WButton` 参数承载。

### WImage 平台差异

- 文件图片使用条件导入（`_image_file_native.dart` vs `_image_file_web.dart`）；判断条件是 `dart.library.io`，Web/WASM 都走 Web 实现并返回 `WImageErrorKind.unsupported`
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
