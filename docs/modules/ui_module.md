# UI 模块文档

> 文档分工：本文负责**模块边界 / 设计取舍 / 反例**；安装、快速开始与常用配方见
> [`packages/ui/README.md`](../../packages/ui/README.md)。

## 概述

UI 模块（`w_tools_ui` 子包）提供基于 Flutter 的通用 UI 组件、布局、导航、扩展方法与屏幕适配工具。

> 本文只写**模块边界、架构与设计取舍**。
> 安装、最小用法与常用配方见 [`packages/ui/README.md`](../../packages/ui/README.md)；
> 组件选择见 [`components.md`](components.md) 与 [`docs/agents/ui.md`](../agents/ui.md)；
> 逐参数 API 以 [pub.dev API 文档](https://pub.dev/documentation/w_tools_ui/latest/) /
> `packages/ui/lib` 源码为准。

**模块特点：**

- **零业务框架依赖**：不依赖其他 w_tools 子包；`qr` 不聚合，需要时直接依赖 `w_tools_qr`。
- **最低 Flutter 版本 3.38**：列表组件不再单独声明 `cacheExtent`，交给 Flutter 默认行为，避免 3.44+ 的 deprecated 警告。
- **屏幕适配可选**：`WScreen` 内置设备信息获取，适配函数通过 `WScreenScope` 注入；无 scope 时返回原始值。
- **第三方依赖**：仅 `cached_network_image`（图片缓存）；`badges` 已在 8.0.0 移除，
  徽章使用包内 `WBadgePosition` / `WBadgeStyle`，具体约束见 `packages/ui/pubspec.yaml`。

## 重构取舍（2026-11）

- **catalog 粒度**：70 条子 API 保持逐条登记，不合并成"类型组"；`explain <具体类型>`
  需要精确命中，合并会降低可发现性。
- **token 层**：暂不引入 `WUiTokens`。当前颜色走 `ColorScheme`，尺寸走
  `WButtonSize` / `WStepStyle`，阴影/渐变走 `WShadows` / `WGradients`；
  等出现 3 个以上组件共享同一组 spacing/radius/duration 再评估。

## 快速判断

> 组件选择以 [`docs/agents/ui.md`](../agents/ui.md)、[`docs/agents/button.md`](../agents/button.md)
> 与 [`components.md`](components.md) 为准；这里不再维护“需求 → 入口”表，避免三份事实源漂移。


## 1. WScreen - 屏幕适配

- 推荐在 App 根节点用 `WScreenScope` 注入缩放，再用 `WScreen.of(context).w/h/sp` 读取；
  尺寸跟随最近 `MediaQuery`，分屏 / 多窗口 / 测试都能正确反映。
- 没有 scope 时 `w/h/sp` 是**恒等函数**，返回原值。
- 设备信息用 `WScreen.of(context)` 或 `WScreen.screenWidth` / `screenHeight` /
  `statusBarHeight` / `bottomSafeAreaHeight`；这些静态 getter 读平台 view，与 scope 无关。
- 10.0 起静态 `WScreen.w/h/sp` 与 `WScreen.delegateWidth/Height/Font` 已删除；
  统一用 `WScreenScope` + `WScreen.of(context)`。
- 静态 getter 依赖 `WidgetsBinding.instance`；不要在 binding 初始化前调用。
- 使用 `.sp` 的 `WTextStyles` 不得在 `main()` / 顶层 `final` 构建；必须放在
  `ScreenUtilInit.builder` 或 `WAppPlugin.builderWrapper` 的 build 期。
- `WScreenScope` 是子树级注入；测试里换 scope 即可，不要恢复全局可变状态。

## 2. WButton - 按钮组件

- `WButton` 负责按钮语义、键盘、最小点击区域（48×48）与 loading / enabled 状态。
- `WPressable` 只负责“任意 child 的点击反馈”，没有 button 语义；卡片、整行点击用它。
- 表单字段的“值选择”用 `WFormButton`，不要用 `WButton` 手写。
- 样式分层：
  - `WButtonStyle`：视觉（颜色、圆角、边框、内边距等）；
  - `WButtonStyleSet.of(context)`：组件层预设（`primary` / `secondary` / `text` / `danger`），返回 `WButtonStyleSet`；
  - `WButton(motion:, semantics:)`：按下、缩放、透明度与无障碍语义；
  - `WButtonSize`：尺寸令牌；
  - `WButtonContentBuilder`：复杂内容（多行、图标 + 文案 + 尾部）时使用。
- **项目页面优先用项目 UI 层的 `AppButtons`**（由 CLI 生成）；`WButtonStyleSet.of(context).primary`
  适合组件示例 / 独立 Demo。不要在每个调用点重复写完整 `WButtonStyle`。
- `WButton(icon:, label:)` 内部复用 `WIconText` 做行盒中点对齐；不要再手写
  `Row + Icon + Text` 补偏移。
- 图标按钮可传 `tooltip`；toggle 按钮用 `isSelected`（进入 `Semantics.selected`）。

### WButtonContentBuilder

复杂按钮内容用 `WButtonContentBuilder` 组合，不要在 `WButton` 里塞多层 `Row` / `Column` 后再补语义。

### WButtonMotion

按下缩放、透明度等效果由 `WButton.motion`（`WButtonMotion` + `WPressEffect`）控制；默认已满足大多数场景。

### WButtonSemantics

按钮语义、禁用态与 loading 态的朗读由 `WButton.semantics`（`WButtonSemantics`）负责；自定义 child 时不要绕过。

`WButtonSemantics.loadingLabel` 默认是空字符串，表示按当前 `Locale` 使用内置文案（zh：加载中；其他：Loading）；传非空字符串则覆盖。

### WButtonSize

尺寸与点击区域由 `WButtonSize` 控制；默认最小点击区域 48×48。

## 2.1 WPressable - 任意 child 点击

`WPressable` 只提供点击反馈，不提供 button 语义。卡片、列表行、整块区域点击用它；
需要键盘、焦点、最小点击区域或 button 语义时用 `WButton`。

## 2.2 WIconText - 图标 + 文字

- 图标 + 文字一行用 `WIconText`；不要手拼 `Row + Icon + Text`，中文行盒会让图标看起来偏高 1.5~2.5px。
- 内部用 `WidgetSpan` + `PlaceholderAlignment.middle` 对齐行盒中点；`gap` 默认 6，`iconSize` 默认 `(fontSize + 2) * textScaler`。
- 文本样式走 `variant` / `WTextStyles`；`style` / `color` 只覆盖差异。品牌字体的视觉重心不同时用 `iconOffset` 微调。
- 纯图标或需要按钮语义时用 `WButton(icon: ...)`，不要用 `WIconText` 代替按钮。

## 3. WText - 文本组件

- 新代码统一 `WText(variant:)` + `WTextStyles`；字体、行高、字重放在 `WTextStyles`。
- 混合样式用 `WText.rich(textSpan:, variant:)`；子 `TextSpan` 只写差异，不要重复 root 样式。
- 先复用已有 variant；新增 variant 按 breaking change 评估。
- 局部只覆盖需要的字段：`style` / `color` / `maxLines` / `overflow` / `textScaler`。
- 品牌样式在主题构建处装一次：`ThemeData.withWTextStyles(WTextStyles.fromTextTheme(...))`。

## 4. WImage - 图片组件

- 统一入口：`WImage.source(source: WImageSource..., style:, options:, slots:, controller:)`；7.0 起只接受 `options:`。
- 来源用 `WImageSource.network / asset / file / base64 / provider`；动态字符串先
  `WImageSource.parse`。需要精确控制来源类型时用具体 `W*ImageSource` 子类，一般优先工厂。
- `WImageSource.asset(name)` 默认**不**拼 `WAssets.imagePath`；需要前缀时显式传 `prefix: true`。
- 三层职责分开：
  - `WImageStyle`：尺寸、fit、圆角、边框等视觉；
  - `WImageLoadOptions`：缓存、重试、进度等加载行为；
  - `WImageSlots`：占位 / 错误 / 进度 / 重试 UI。
- App 级默认占位与错误用 `WImageTheme(slots: ...)`；单图覆盖用 `slots:`。
- `WImage` 不自动给尺寸：没有 `width` / `height` / `aspectRatio` 时，必须由父级
  （`SizedBox` / `Expanded` / `AspectRatio`）约束，否则加载前占位是 0 尺寸。
- `WImageStyle.width/height` 不含 `padding` / `margin`：它们会额外计入总尺寸
  （与 `Container` 的尺寸语义不同）。
- 宽度铺满 + 高度上限（长图截断）：`ConstrainedBox(maxHeight:)` +
  `WImageStyle(width: double.infinity, fit: BoxFit.fitWidth, alignment: ...)`；超限时按
  `alignment` 保留上 / 中 / 下。完整配方与坑见
  [`packages/ui/README.md`](../../packages/ui/README.md) 的「宽度铺满 + 高度上限」。

### 显式构造

需要精确控制来源类型时用具体 `W*ImageSource` 子类；一般优先 `WImageSource` 工厂。

### WImageStyle 配置

视觉与布局：尺寸、`fit`、圆角、边框、占位比例等。不要用它控制加载 / 重试行为。
9.0 起 `copyWith(null)` 表示保留字段；清空可空字段用 `withoutWidth` / `withoutBorderRadius` 等 `without*`。
设置 `width` / `height` 且未显式传 `aspectRatio` 时，`copyWith` 会清空比例，避免
`WImageStyle.cover().square(40)` 这类组合触发断言。

### WImageLoadOptions 配置

加载行为：缓存尺寸、重试与 `gaplessPlayback`。进度回调在 `WImage.onProgress`；不要把视觉参数或占位 UI 塞进来。
9.0 起清空解码尺寸用 `withoutMemCacheWidth` / `withoutMemCacheHeight`，`copyWith(null)` 只表示保留。

### WImageSlots 配置

单图的占位 / 错误 / 进度 / 重试 UI。App 级默认用 `WImageTheme`，单图覆盖用 `slots`。

### WImageTheme

App 级默认 `WImageSlots`，放在主题 / App 根节点；单图仍可用 `slots` 覆盖。

### 重试与手动重试

需要手动重试 / 读状态时用 `WImageController`；预加载用
`WImageSource.resolve(...)` + `precacheImage`。`WImageController.state` 返回
`WImageLoadSnapshot`，状态枚举是 `WImageLoadStatus`。

### 错误类型

错误分类用 `WImageError` / `WImageErrorKind`，进度用 `WImageProgress`；
默认错误 UI 是 `WImageErrorView`。`WImageSource.resolve` 在 Base64 非法时抛 `FormatException`、
Web 上的 `file` 抛 `UnsupportedError`；`WImage` 内部会转成 `WImageError` 并渲染错误占位。

`WImageErrorView` 的错误文案与重试文案按当前 `Locale` 本地化（zh / en）；
`WImageError.message` 仍是固定中文，业务直接使用 `message` 时需自行本地化。
`WImageSlots.retryLabel` 传空字符串 / 不传时使用内置本地化文案。

旧字符串图片入口已删除；新代码不要再使用 `WImage('url')` 形式。

## 5. WBadge - 徽章组件

`WBadge` 用于角标 / 数量提示；位置用 `position`，视觉用 `style`，显隐用 `showBadge`。
需要读屏上下文时传 `semanticLabel`（如「3 条未读」），气泡内容不再单独朗读。
数量角标用 `WBadge.count(count:, maxCount:)`，圆点用 `WBadge.dot()`。
位置用 `position`，额外位移用 `offset`（正值向右 / 向下）。

### WBadgeStyle / WBadgePosition

`WBadgePosition` 控制角标相对 child 的位置（`topEnd` / `center`）；`WBadgeStyle` 控制背景、前景、文字、padding、圆角与边框。默认背景 / 前景取 `ColorScheme.error` / `onError`。

## 6. WListView - 列表

- 普通 / 分隔线 / 网格 / 重叠列表分别用
  `WListViewSliver.list / separated / grid / overlap`，外层统一由 `WListView` 承载。
- `WListView` 的 controller 由页面持有并 `dispose`；不要在 build 里 new。
- 与 `SmartRefresher` 组合时，刷新壳在外、`WListView` 在内；不要把 `SmartRefresher`
  包在 `WAsyncView` 外面（异步场景见 `docs/agents/async.md`）。
- 头部 / 尾部 / 空状态通过对应 slot 传入，不要在 itemBuilder 里用 index 判断。

## 7. WScaffold - 增强脚手架

- 普通页面：`WScaffold` + `WAppBar`；需要自定义顶栏时 `WScaffold(appBar: WAppBar(...))`，
  也可以传任意 `PreferredSizeWidget`（Material `AppBar` / `SliverAppBar`）。
- `WAppBar` 自身实现 `PreferredSizeWidget`；传 `WAppBar` 时 `includeStatusBar` 必须为 true。
- 传了 `appBar` 时不要再传 `title` / `titleWidget` / `leading` / `actions` / `onBack` /
  `appBarStyle` / `appBarBottom`，否则 assert；且 `appBar` 必须 `includeStatusBar: true`，
  `WScaffold` 自身的 `automaticallyImplyLeading` / `centerTitle` 保持默认。
- `drawer` / `endDrawer` / `bottomSheet` / `persistentFooterButtons` / `extendBody` 直接透传给
  底层 `Scaffold`，不需要为此改用原生 `Scaffold`。
- 有 `bottomNavigationBar` 时 body 不再加底部安全区；底栏不是 `WNavBar`（已默认
  `safeArea: true`）时传 `bottomNavigationBarSafeArea: true`，由 `WScaffold` 包 `SafeArea`。

## 8. 其他组件速览

### WAppBar

`WAppBar` 是自定义顶栏；默认包含状态栏背景，嵌套在 `SafeArea` 中时可传
`includeStatusBar: false`。样式用 `WAppBarStyle`；`leadingWidth` / `actionsPadding`
控制两侧布局，`boxShadow` 提供阴影（自绘顶栏没有 Material elevation）。

### WStep

`WStep` / `WStepFlow` 用于步骤指示；样式与状态用 `WStepStyle` / `WStepState`，
自定义项 / 分隔线 / 语义用对应的 builder。`WStep` 与 `WStepFlow` 都会在构造时复制并冻结
`labels`；因此 `WStep` 不再是 `const` 构造器。`WStepStyle` 的完成 / 当前 / 未开始颜色
未显式设置时分别取 `ColorScheme.primary` / `primary` / `outline`，暗色主题下自动跟随。

### WNavBar / WNavController

底部导航：`WNavBar` + `WNavController`；`WNavController` 需要页面 State 提供 `vsync`，
并由调用方 `dispose`。配置用 `WNavBarStyle`。`WNavBar` 默认 `safeArea: true`，会避开
底部 home indicator；已在外层包 `SafeArea` 时传 `safeArea: false`。
切换前拦截用 `onBeforeTap`（`FutureOr<bool>`，返回 false 阻止）。
默认 item 用 `destinations: [WNavDestination(...)]`；需要完全自定义时用 `itemBuilder`，两者互斥。

### WTabBar

顶部 tab：`WTabBar` 不自带 controller，需要 `DefaultTabController` 或显式 `TabController`；
配置用 `WTabBarStyle`（含 `labelColor` / `unselectedLabelColor` / `labelPadding` /
`indicatorPadding` / `textScaler` / `indicatorAnimation` / `mouseCursor` /
`enableFeedback` / `splashBorderRadius`）。

### WActionRow / WSelectableRow

横向操作 / 可选行；按钮组用 `WActionRow`，需要选中态用 `WSelectableRow`。

### 圆角裁剪

直接用 Flutter 原生 `ClipRRect`。`WClipRRect` 已在 11.0 删除，它只是原生组件的纯别名。

### WGradientCircularProgressIndicator

渐变圆形进度指示器；颜色、半径、进度由构造参数控制。确定进度传 `value`；
不知道总进度时传 `indeterminate: true`，组件会旋转一段固定弧长且不暴露百分比语义。
未传 `backgroundColor` 时取 `ColorScheme.surfaceContainerHighest`，不写死浅灰。

### WKeepAliveWrapper

列表项保活；只包需要保活的子项，不要整页包。

### WNotificationListener

声明式监听；百分比只处理 depth 0 的 `ScrollUpdateNotification`。

## 9. 扩展方法

### WColorExtension（Color 扩展）

十六进制颜色解析 / 生成：`WColorExtension.fromHex` / `'#rrggbb'.toColor()`。

### WStringExtension

字符串转数字 / 去空格 / hex 颜色 / 资源路径；新增前先看 `packages/ui/lib/src/extensions/` 是否已有。

### WNumLayoutExtension / WNumFormatExtension

`num` 扩展按用途拆成两个：`WNumLayoutExtension` 提供 `heightBox` / `widthBox` /
`squareBox` / `padding` / `borderRadius` / `borderSideOf(context)`；
`WNumFormatExtension` 提供 `toThousandsSeparated` / `toCurrency` / `toPercent` /
`toPercentWithFixed` / `toPadLeft`。
`borderSide` 已在 10.0 删除；边框统一用 `borderSideOf(context)` 跟随 `ColorScheme.outline`。

### WWidgetExtension

容器装饰、布局调整、安全区与点击糖；`toPressable` 也在这里。
需要 RTL 时用 `withStartPadding` / `withEndPadding`；物理左右 / 上下 padding 直接用 Flutter
`Padding`（`withHorizontalPadding` / `withVerticalPadding` / `withLeftPadding` /
`withRightPadding` / `withTopPadding` / `withBottomPadding` 已在 11.0 删除）。

### WBoxDecorationExtension / WGradients / WShadows

`BoxDecoration` 的颜色 / 圆角 / 边框 / 阴影链式扩展，以及渐变 / 阴影预设。

### WGlobalKeyExtension

GlobalKey 查找 / 定位；不要用它替代正常的 controller 传递。

### TextStyle

直接用 Flutter `TextStyle.copyWith`；`WTextStyleExtension` 已在 11.0 删除。
品牌字体仍应放 `WTextStyles`。

## 10. 工具类

### WAssets

资源前缀：`WAssets.imagePath`；需要 `AssetImage` 时用 `assetImagePath`。

### 预加载

图片预加载用 `WImageSource.resolve(...)` + `precacheImage`；不要自己拼 provider。

## 组合示例

完整页面示例见 [`packages/ui/README.md`](../../packages/ui/README.md) 的「快速开始」；
本文件只保留模块边界与反例。

## 注意事项

### Flutter 版本兼容

`WListView` 不再单独声明 `cacheExtent`；不同 Flutter 版本使用框架默认值，避免 3.44+
deprecated 警告。

### WScreenScope

`WScreenScope` 是子树级注入：在 App 根节点包一层即可；测试里换新的 scope 包围被测组件，
不要恢复全局可变状态。

### WButton 样式复用

项目页面优先用项目 UI 层的 `AppButtons`；组件示例 / 独立 Demo 可用
`WButtonStyleSet.of(context)` 的预设。不要在每个调用点重复写完整 `WButtonStyle`。

### WImage 平台差异

`WImageSource.file` 在 Web 上抛 `UnsupportedError`；跨平台代码优先使用网络 / 资源 / Base64 来源。

### WListView / WNavController 生命周期

两者都由页面 State 持有并 `dispose`；不要在 build 里创建，否则滚动位置或动画会重置。

## 完整 API

- 用法与最小示例：[`packages/ui/README.md`](../../packages/ui/README.md)
- 组件选择：[`components.md`](components.md) / [`docs/agents/ui.md`](../agents/ui.md)
- 规则与反例：[`docs/agents/button.md`](../agents/button.md)
- 逐参数 API：[pub.dev API 文档](https://pub.dev/documentation/w_tools_ui/latest/)
- 源码：[`packages/ui/lib`](../../packages/ui/lib)
