# UI 组件选择规则

高风险的组件选择先看这里；完整目录见 [`docs/modules/components.md`](../modules/components.md)。

## 图片

```text
网络图 → WImage.network
资源图 → WImage.asset(name, prefix: true)
不要裸用 Image.network / Image.asset
```

`WImageStyle` 管视觉，`WImageConfig` 管加载 / 重试 / 占位；普通图片也优先复用 `WImage`。

## 扩展方法

```text
数字格式化 → toThousandsSeparated / toCurrency / toPercent
hex 颜色 → HexColor.fromHex / '#rrggbb'.toColor()
间距 → num.heightBox / allPadding
BoxDecoration → withColor / withBorderRadius / withShadow
```

新增通用工具前先看 `packages/ui/lib/src/extensions/` 是否已有。

## 工具

```text
屏幕 / 字体适配 → WScreen.w / h / sp
资源前缀 → WAssets.imagePath
间距 / 尺寸 → WSizeBox / WPadding / WColumn / WRow
```

WScreen 无 delegate 时返回原始值；需要 ScreenUtil 时注入 delegate。

`WColumn.left/right` / `WRow.top/bottom` 默认 `MainAxisSize.max`；需要包裹内容时显式传 `MainAxisSize.min`。

## 页面骨架

```text
普通页面 → WScaffold + WAppBar
底部 tab → WNavBar / WNavController
顶部 tab → WTabBar（依赖 TabController / DefaultTabController）
步骤流程 → WStep / WStepFlow
```

不要为了统一把任意叠放布局塞进 `WScaffold`；需要自定义覆盖时在页面层用 `Container` / `Stack`。

## 状态与反馈

```text
加载指示 → WGradientCircularProgressIndicator
列表项保活 → WKeepAliveWrapper
滚动通知 / 百分比 → WNotificationListenerBuilder
```

WNotificationListenerBuilder 的百分比只在 depth 0 的 ScrollUpdateNotification 上回调。

## 弹层

```text
锚定下拉 / 选择 → WFormPopup
底部面板 → WBottomSheet
确认弹窗 → Flutter showDialog（当前无统一 WDialog）
```

`WFormPopup` 是锚定式弹层，不是居中确认框。

## 图标 + 文字

当前没有统一的“图标和文字垂直居中一行”组件，不要直接用 `Row + Icon + Text` 当作稳定方案；中文行盒可能导致图标偏高。

## 轻提示

```text
轻提示 → WToast
```

不要在页面里重复实现 toast；需要页面内常驻提示时再用普通 Widget。

## 异步

异步四态、分页、刷新规则见根目录 `AGENTS.md` 的异步区块规则。

## 文字

文字、字号、行高规则见根目录 `AGENTS.md` 的文字规则；新代码使用 `WText` + `WTextStyles`。


## 文字样式规则

默认：

```dart
WText(text: '标题', variant: WTextVariant.title)
```

`style` 是合法的一次性覆盖，但只写需要覆盖的字段：

```dart
WText(
  text: '¥128.00',
  variant: WTextVariant.price,
  style: const TextStyle(
    fontFeatures: [FontFeature.tabularFigures()],
  ),
)
```

规则：

1. 默认用 `variant`，不要从整段 `TextStyle` 开始。
2. 先查已有 variant：`price` / `number` / `badge` 已覆盖常见价格、数字、角标。
3. 一次性局部差异允许 `style`，但只写要覆盖的字段。
4. 语义颜色用主题 / `ColorScheme`；一次性状态色用 `color`；不要写 `style: TextStyle(color: ...)`。
5. 同一语义角色、同一套样式签名，跨 2 个以上页面重复 3 次以上，才考虑提升为 variant。
6. 消费方不能自行新增 `WTextVariant` enum；跨页面重复样式先用本地 helper / 常量，确需全局语义再提给 `w_tools_ui`。
7. 库内新增 variant 必须同步 `WTextVariant` / `WTextStyles` 字段 / `fromTextTheme` / `copyWith` / `lerp` / `resolve` / 测试 / 文档。
8. 价格、品牌标题、表格数字优先复用已有 variant；现有 variant 表达不了时，才保留局部 `style` 或本地 helper。
9. 不要用 `style` 绕过主题字体、暗色模式颜色、ScreenUtil 响应式字号。
10. 非显然的一次性 `style` 加一行注释说明原因。

样式签名按这些字段判断：

```text
fontSize / fontWeight / fontFamily / height / letterSpacing / fontFeatures
```

颜色、`maxLines`、`textAlign` 不算语义签名。

新增 variant 时按角色命名，例如：

```text
priceLarge
brandTitle
tableNumeric
```

不要用：

```text
font18W600
bigText
```

注意：`priceLarge` 等名字只是“若库内确实需要新增 variant”时的命名示例；当前已有 `price` 时先复用它。
