- **分层**：`lib/app/ui/` 是项目永久 UI 层（AppBar / 按钮 / 页面骨架 / 盒子装饰），
  由 CLI 生成脚手架，**不走 STAGED、不计划上移**；只有待上移的通用组件才放
  `lib/app/design_system/`（受 R5 约束）。
- **页面骨架**：标准页面默认用 `AppScaffold`（`lib/app/ui/app_scaffold.dart`）；
  不要直接使用 `WScaffold` / `WAppBar`。特殊顶部栏用 `AppScaffold(appBar: WAppBar(...))`；
  需要 drawer / bottomSheet / 非标准安全区时用 `WScaffold` 或原生 `Scaffold`，并在 PR 说明。
  AppBar 默认样式只在 `AppBars.style` 修改。
- **底部导航**：用 `WNavBar` + `WNavController`；`WNavController` 需要 `vsync`，
  在页面 State 创建并 `dispose`；顶部 tab 用 `WTabBar`，它依赖
  `TabController` / `DefaultTabController`，不自带 controller。不要自己写 `BottomNavigationBar`。
- **按钮**：统一用 `AppButtons.primary/secondary/text/danger(context)`；页面不要直接写
  `WButtonStyle`，除非是明确的局部一次性样式。真按钮用 `WButton`，任意 child/卡片点击用
  `WPressable`；不要用 `WButton` 包任意 child。
  按钮宽度由父布局决定，`WButtonStyle` 不含 `width`。`WButton` 没有 `variant`；
  样式用 `style`，`label` 和 `content` 不能同时传。`loading` 时同时设置 `enabled: !loading`；
  纯图标按钮提供 `semanticLabel`。状态色放 `AppButtons`。
- **图片**：网络图用 `WImage.network`；资源图用 `WImage.asset(name, prefix: true)`；
  视觉用 `WImageStyle`，加载 / 重试 / 占位用 `WImageLoadConfig`；不要裸用
  `Image.network` / `Image.asset`。
- **文字**：新代码用 `WText(variant: WTextVariant.xxx)` + `WTextStyles`；字体/字号/行高放主题，
  `WTextConfig` 已移除；不要逐字段拼样式。局部用 `style` / `color` / `maxLines` / `overflow` 覆盖。
  最小示例：`WText(text: '标题', variant: WTextVariant.title)`。
  先复用已有 variant（含 `price` / `number` / `badge`）。variant 不够时：一次性差异用
  `variant + style`；项目内重复抽本地 helper；消费方不能自行新增 `WTextVariant` enum，
  稳定跨页面语义再提给 `w_tools_ui`。
- **扩展**：数字格式化用 `toThousandsSeparated` / `toCurrency` / `toPercent`；
  hex 颜色用 `WHexColor.fromHex` 或 `'#rrggbb'.toColor()`；`EdgeInsets` 值用 `num.allPadding`；
  BoxDecoration 用 `withColor` / `withBorderRadius` / `withShadow` 组合。
- **工具**：屏幕 / 字体适配用 `WScreen.w/h/sp`；资源前缀用 `WAssets.imagePath`；
  `SizedBox` / `Padding` / `Row` / `Column` 直接用 Flutter 原生组件；需要 `EdgeInsets` 值时用 `num.allPadding`。
  `WSizeBox` / `WPadding` / `WRow` / `WColumn` 已弃用（5.0 移除），新代码不要再用。
- **列表 / 通知**：列表项保活用 `WKeepAliveWrapper`；滚动通知 / 百分比用 `WNotificationListenerBuilder`
  （百分比只处理 depth 0 的 `ScrollUpdateNotification`）。
- **初始化时机**：不要在 main / 顶层 final 中调用 `.sp`；`WTextStyles` 若用 `.sp`，
  在 `ScreenUtilInit.builder` / `WAppPlugin.builderWrapper` 的 build 期构建。
  `wrapApp` 没有 Theme；需要 Theme 的排版扩展用 `builderWrapper`。
- **盒子**：重复 `BoxDecoration` 收进 `AppBoxes`；重复卡片用 `AppCard`；
  一次性盒子用 `Container` + `BoxDecoration`；需要 width/height/constraints/transform
  时直接用 `Container`。不要新增 `AppBox` / `AppContainer` 万能包装。
