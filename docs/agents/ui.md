# UI 组件选择规则

高风险的组件选择先看这里；完整目录见 [`docs/modules/components.md`](../modules/components.md)。

## 按钮

普通业务按钮用 `WButton`，任意 child 点击用 `WPressable`，表单里的值选择用 `WFormButton`；
什么时候用哪个见 [Button 选择](button.md)。

## 图片

```text
网络图 → WImageSource.network
资源图 → WImage.source(source: WImageSource.asset(name, prefix: true))
不要裸用 Image.network / Image.asset
```

`WImageStyle` 管视觉，`WImageLoadOptions` 管加载 / 重试，`WImageSlots` 管占位 / 空 / 错误 / 进度 / 重试 UI；普通图片也优先复用 `WImage`。
空 data（空字符串 / 纯空白）走 `WImageSlots.emptyWidget` / `emptyBuilder`，不算加载失败。
App 级默认占位 / 错误 / 进度用 `WImageTheme(slots: WImageSlots(...))`，需要预加载时用
`WImageSource.resolve(...)` + `precacheImage`。

## 扩展方法

```text
数字格式化 → toThousandsSeparated / toCurrency / toPercent
hex 颜色 → WColorExtension.fromHex / '#rrggbb'.toColor()
EdgeInsets → num.allPadding
RTL 侧边距 → withStartPadding / withEndPadding
BorderSide → num.borderSideOf(context)（borderSide 已弃用，9.0 删除）
BoxDecoration → withColor / withBorderRadius / withShadow
```

新增通用工具前先看 `packages/ui/lib/src/extensions/` 是否已有。

## 工具

```text
屏幕 / 字体适配 → WScreenScope + WScreen.of(context).w / h / sp（explain WScreen）
资源前缀 → WAssets.imagePath
SizedBox 间距 → 原生 SizedBox
Padding → 原生 Padding
EdgeInsets → num.allPadding
```

WScreen 无 delegate 时返回原始值；需要 ScreenUtil 时注入 delegate。
可运行示例：`packages/ui/example/README.md`。
`WSizeBox` / `WPadding` / `WRow` / `WColumn` 已在 5.0 删除，直接用 Flutter 原生布局组件。

## 页面骨架

```text
普通页面 → WScaffold + WAppBar
（消费方项目的标准页面默认用 CLI 生成的 AppScaffold；本文件是库 / 仓库内用法）
底部 tab → WNavBar / WNavController
顶部 tab → WTabBar（依赖 TabController / DefaultTabController；默认 overlay / ripple 跟
TabBarTheme，要关用 `WTabBarStyle.noSplash` 或 `splashFactory` + `overlayColor`）
步骤流程 → WStep / WStepFlow
```

不要为了统一把任意叠放布局塞进 `WScaffold`；需要自定义覆盖时在页面层用 `Container` / `Stack`。

## 状态与反馈

```text
加载指示 → WGradientCircularProgressIndicator
列表项保活 → WKeepAliveWrapper
滚动通知 / 百分比 → WNotificationListener
```

WNotificationListener 的百分比只在 depth 0 的 ScrollUpdateNotification 上回调。

## 弹层

```text
锚定下拉 / 选择 → WFormPopup
底部面板 → WBottomSheet
确认弹窗 → Flutter showDialog（当前无统一 WDialog）
```

`WFormPopup` 是锚定式弹层，不是居中确认框。

## 图标 + 文字

图标 + 文字一行用 `WIconText`（`explain WIconText`）；不要手拼 `Row + Icon + Text`，中文行盒会让图标偏高。纯图标 / 需要按钮语义用 `WButton(icon: ...)`。

## 轻提示

```text
轻提示 → WToast
```

不要在页面里重复实现 toast；需要页面内常驻提示时再用普通 Widget。

## 异步

异步四态、分页、刷新规则见根目录 `AGENTS.md` 的异步区块规则。

## 文字样式规则

默认：

```dart
WText(text: '标题', variant: WTextVariant.title)
```

### 现有 variant

| variant | 用途 |
|---|---|
| `display` | 超大展示文字 |
| `headline` | 页面主标题 |
| `title` | 区块标题 |
| `body` | 正文 |
| `bodyStrong` | 强调正文 |
| `caption` | 辅助说明 |
| `label` | 标签 |
| `button` | 按钮文字 |
| `price` | 价格 |
| `number` | 数字 / 指标 |
| `badge` | 角标 |

`style` 是合法的一次性覆盖，但只写需要覆盖的字段：

```dart
import 'dart:ui' show FontFeature;

WText(
  text: '¥128.00',
  variant: WTextVariant.price,
  style: const TextStyle(
    fontFeatures: [FontFeature.tabularFigures()],
  ),
)
```

### WTextStyles 安装

`WTextStyles` 是 `ThemeExtension`，提供 11 个语义角色。未安装时 `WTextStyles.of(context)`
会从当前 `TextTheme` 生成兜底样式（按 `TextTheme` 实例缓存，不会每次 build 重建）。

需要统一品牌字号时，在主题构建处**一次装好**：

```dart
theme: ThemeData(colorScheme: scheme, useMaterial3: true)
    .withWTextStyles(myStyles),
```

`withWTextStyles` 同时做两件事：

1. 把 11 个角色写进 `ThemeData.textTheme`（`WTextStyles.toTextTheme`）；
2. 把 `WTextStyles` 注册为 ThemeExtension（供 `WText` 使用）。

**为什么必须两步都有**：form / toast / async 只读 `Theme.of(context).textTheme`
（不依赖 `w_tools_ui`），所以只装扩展时它们看不到品牌排版；只写 `textTheme` 时
`WText` 的 `price` / `number` / `badge` 又读不到语义角色。

#### 角色 ↔ TextTheme 槽位（`fromTextTheme` 兜底 / `toTextTheme` 投影）

| 角色 | TextTheme 槽位 |
| --- | --- |
| `display` | `displayLarge` |
| `headline` | `headlineMedium` |
| `title` | `titleLarge` |
| `price` | `headlineSmall` |
| `bodyStrong` | `titleMedium` |
| `body` | `bodyLarge` + `bodyMedium` |
| `number` | **不投影**（兜底取 `bodyLarge`） |
| `caption` | `bodySmall` |
| `label` | `labelMedium` |
| `button` | `labelLarge` |
| `badge` | `labelSmall` |

两条规则：

- **按 Material 的消费点投，不追求一一对应**：`TextField` 读 `bodyLarge`、普通正文读
  `bodyMedium`，所以 `body` 两个槽位都写；
- **`number` 不投影**：`bodyLarge` 已被 `body` 占用，把 `number` 写进去会让所有表单输入
  变成数字样式。它是 `WText` 专属语义，Material 组件看不到。

未涉及的槽位保留原 `TextTheme`。

兜底（未安装扩展）时的取值就是上表：`price` 取 `headlineSmall`、`number` 取 `bodyLarge`、
`badge` 取 `labelSmall`、`bodyStrong` 取 `titleMedium`；品牌设计稿仍应显式提供 `WTextStyles`。

如果 `WTextStyles` 使用 `flutter_screenutil` 的 `.sp`，这段构建必须放在 `ScreenUtilInit.builder` 或 `WAppOptions.builder`（或消费方自建插件的 `builderWrapper`）中，不能放 `main()` / 顶层 `final`。

规则：

- 默认用 `variant`，不要从整段 `TextStyle` 开始。
- 先查已有 variant：`price` / `number` / `badge` 已覆盖常见价格、数字、角标。
- 一次性局部差异允许 `style`，但只写要覆盖的字段。
- 语义颜色用主题 / `ColorScheme`；一次性状态色用 `color`；不要写 `style: TextStyle(color: ...)`。
- 同一语义角色、同一套样式签名，跨至少 2 个页面、合计出现 3 次以上，才考虑提升为 variant。
- 消费方不能自行新增 `WTextVariant` enum；跨页面重复样式先用本地 helper / 常量，确需全局语义再提给 `w_tools_ui`。
- 库内新增 variant 必须同步 `WTextVariant` / `WTextStyles` 字段 / `fromTextTheme` / `copyWith` / `lerp` / `resolve` / 测试 / 文档。
- 价格、品牌标题、表格数字优先复用已有 variant；现有 variant 表达不了时，才保留局部 `style` 或本地 helper。
- 不要用 `style` 绕过主题字体、暗色模式颜色、ScreenUtil 响应式字号。
- 非显然的一次性 `style` 加一行注释说明原因。
- 新增 `WTextVariant` 属于公开 API 变更：可能破坏消费方 exhaustive switch。新增 `WTextStyles` 字段时，required 字段会破坏手写构造；提供默认值才可能保持兼容。需要按 breaking change 评估，并在 CHANGELOG 说明。

#### 颜色示例

```dart
WText(
  text: '保存失败',
  variant: WTextVariant.body,
  color: Theme.of(context).colorScheme.error,
)
```

`Theme.of(context)` 只能在 build / builder 内调用，不要放 `main()` 或顶层 `final`。

### 审计方法

不要只按 `WText(style:)` 出现次数判断。按下面建表：

| 位置 | 样式签名 | 页面数 | 次数 | 已有 variant | 结论 |
|---|---|---|---|---|---|
| A | 18/w600 | 3 | 5 | title | 复用 title |
| B | 28/w700 + tabular | 1 | 2 | price | 复用 price + tabular style |
| C | 13/w400 | 1 | 1 | caption | 保留局部 style |

“样式签名”只比较：

```text
fontSize / fontWeight / fontFamily / height / letterSpacing / fontFeatures
```

颜色、`maxLines`、`textAlign`、`overflow` 不参与签名比较。

新增 variant 时按角色命名，例如：

```text
priceStrong   // 仅当 price 确实不够时，由库维护者新增 enum；当前不存在
brandTitle    // 已有 title，但品牌标题语义不同
metricValue   // 已有 number，但需要独立指标语义
```

已有 `price` / `number` / `badge` 能表达时，不要新增。

不要用：

```text
font18W600
bigText
```

以上名字只是“若库内确实需要新增 variant”时的命名示例；当前已有 `price` 时先复用它。

## 容器 / 列表

```text
角标 / 数量提示 → WBadge
圆角裁剪 → WClipRRect
普通 / 分隔线 / 网格 / 重叠列表 → WListView + WListViewSliver
```
