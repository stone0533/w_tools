## 10.1.0

### Added
- `WImageError.localizedMessage(BuildContext)`：按当前 `Locale` 返回图片错误文案
  （zh 中文 / 其他英文）；`message` 继续作为固定中文诊断文案。

## 10.0.0

### Breaking
- 删除全局 `WScreen.w` / `h` / `sp` 与 `WScreen.delegateWidth` / `delegateHeight` /
  `delegateFont` / `reset`；`WScreen.of` 不再回退全局 delegate，统一用 `WScreenScope`
  + `WScreen.of(context).w/h/sp`。

### Removed
- `WScreen.w`、`WScreen.h`、`WScreen.sp`、`WScreen.delegateWidth`、
  `WScreen.delegateHeight`、`WScreen.delegateFont`、`WScreen.reset`。
- `WNumExtension.borderSide`；改用 `borderSideOf(context)`。

## 9.0.0

### Breaking
- `WImageStyle.copyWith` 的参数从 `Object?` 改为具体类型；`null` 表示保留字段。
  清空可空字段改用 `withoutWidth` / `withoutHeight` / `withoutAspectRatio` /
  `withoutBorderRadius` / `withoutBorder` / `withoutBoxShadow` / `withoutMargin` /
  `withoutPadding` / `withoutSemanticLabel`。
- `WImageLoadOptions.copyWith` 的 `memCacheWidth` / `memCacheHeight` 改为 `int?`；
  `null` 表示保留。清空解码尺寸改用 `withoutMemCacheWidth` / `withoutMemCacheHeight`。

### Added
- `WIconText`：图标 + 文字一行，内部用 `WidgetSpan` + `PlaceholderAlignment.middle`
  对齐行盒中点，替代手写 `Row + Icon + Text`；支持 `variant` / `style` / `color`、
  `gap`、`iconSize`（默认随 `textScaler` 缩放）、`iconOffset`、`maxLines` / `overflow`、
  `semanticsLabel`。
- `WBadge.semanticLabel`：给角标提供读屏上下文（如「3 条未读」）；提供后气泡内容
  不再单独朗读，child 的语义保持不变。
- `WWidgetExtension.withStartPadding` / `withEndPadding`：跟随 `Directionality` 的侧边距；
  `withLeftPadding` / `withRightPadding` 继续表示物理方向。
- `WScreenScope`：在子树内注入宽度 / 高度 / 字体缩放，替代全局 delegate。
- `WScreenData.w` / `h` / `sp`：从 `WScreen.of(context)` 直接取缩放后的值；
  `WScreenData` 构造器新增可选 scaler 字段（默认恒等）。

### Changed
- `WSelectableRow` 内部改用 `WPressable`：增加按压 / hover 反馈与点击光标；外层仍是
  `Semantics(button: true, selected: ...)`。
- `WButton` 的 loading 语义增加 `liveRegion`：loading 切换时由读屏播报
  `WButtonSemantics.loadingLabel`。
- `WButton(icon:, label:)` 内部改用 `WIconText` 的行盒中点对齐；补按钮四态 golden。
- 内置文案按 `Locale`：`WButtonSemantics.loadingLabel` / `WImageErrorView.retryLabel`
  默认改为空字符串（空 = 按 Locale 取内置文案，zh 中文 / 其他英文）；
  `WImageErrorView` 的错误文案同步本地化；`WImageError.message` 仍为固定中文。
- `WImageError` / `WTextStyles` / `WButtonResolvedStyle` 增加值相等；文档移除 8.0 已删除的
  `badges` 引用、修正 example README 的 `topRight` / config 残留，并补充中文默认文案说明。

### Removed
- `WImageErrorKind.empty`：空 data 从 8.1 起不再产生该错误，继续用
  `WImageSlots.emptyWidget` / `emptyBuilder`。

### Deprecated（10.0 移除）
- `WScreen.w` / `h` / `sp` 与 `WScreen.delegateWidth` / `delegateHeight` / `delegateFont`：
  改用 `WScreenScope` + `WScreen.of(context).w/h/sp`；`WScreen.of` 在无 scope 时回退旧 delegate。
- `WNumExtension.borderSide`：改用 `borderSideOf(context)` 跟随 `ColorScheme.outline`。

## 8.2.0

### Breaking
- `WTabBarStyle.copyWith` 签名新增可选 `splashFactory`：源码兼容，旧调用不需要改；
  公开 API 快照把方法签名变化视为 Breaking。

### Added
- `WTabBarStyle.splashFactory` / `WTabBarStyle.noSplash`：可显式关闭 tab 的 overlay 与水波纹；
  默认仍交给 `TabBarTheme`，不强制透明。

### Changed
- `WImage` 无尺寸提示带脱敏后的 source，并按 source + 轴去重；避免同一张图在测试 /
  多个实例里反复刷屏。补充 `width + fitWidth` 仍需要 height / aspectRatio / 有界父级的文档。

## 8.1.0

### Added
- `WImageSlots.emptyWidget` / `emptyBuilder`：空 data 的占位 UI（与加载失败分开）。

### Changed
- `WImage` 空 data（空字符串 / 纯空白）不再按加载失败处理：默认渲染中性 empty 占位，
  不触发 `errorWidgetBuilder`，也不回调 `onLoadStatusChanged(failed)`。需要错误态时在
  `emptyBuilder` 里自行返回；`WImageErrorKind.empty` 仍然保留，但不再由空 data 产生。

## 8.0.1

### Fixed
- `example/recipes_page.dart` 补「宽度铺满 + 高度上限」配方与回归测试；
  README / example README 同步。

## 8.0.0

### Breaking

- 删除 `WNavBarConfig` / `WTabBarConfig` / `WBadgeConfig` / `WClipRRectConfig`：统一用
  `WNavBarStyle` / `WTabBarStyle` 与直接字段；`WTabBar` / `WNavBar` 只接受 `style`。
- `WBadge` 改用自有 `WBadgePosition` / `WBadgeStyle`，不再转出 `badges` 包的
  `BadgePosition` / `BadgeStyle`；默认背景 / 前景改为 `ColorScheme.error` / `onError`，
  `badgeContent` 为空或 `showBadge: false` 时只渲染 child。
- `WButtonStyle` 不再承载 `motion` / `semantics`，改由 `WButton(motion:, semantics:)`；
  删除 `WButtonMetrics` 与 `WButtonStyle.metrics`。
- 删除 `WButtonEffectType`，统一用 `WPressEffect`；`WButtonMotion.effect` 类型随之改变。
- `WButtonStyles.of` 返回 `WButtonStyleSet`，不再返回匿名 record。
- 删除 `WNotificationListenerBuilder`，统一用 `WNotificationListener`。
- `WStepStyle.resolve` 返回 `WStepColors`；`WStep` 默认语义标签改为
  `"<label> (<current>/<total>)"`，不再写死英文 "Step X of Y"。
- `WPressable.excludeChildSemanticsWhenDisabled` 更名 `hasChildSemanticsWhenDisabled`，
  默认 true（与旧默认行为一致）。
- `WAppBarStyle.copyWith` / `WStepStyle.copyWith` 改为传 null 表示保留，不再能清空字段。
- `WScaffold` 未显式设置标题样式时优先 `WTextStyles.title`（未安装时仍是 `titleLarge`）。

成员级（逐条）：
- `WClipRRect.config` 删除；`WClipRRectConfig` 类型删除。
- `WNavBar.config` / `WTabBar.config` 删除；`WTabBar.style` 改为非空并使用默认值。
- `WTabBarStyle.toConfig` 删除。
- `WButtonStyle.filled` / `WButtonStyle.outlined` / `WButtonStyle.text` 去掉 `motion` / `semantics` 参数。
- `WButtonStyle.motion` / `WButtonStyle.semantics` / `WButtonStyle.metrics` 删除。
- `WPressable.new` 的 `excludeChildSemanticsWhenDisabled` 更名 `hasChildSemanticsWhenDisabled`。
- `WWidgetExtension.withBottomBarSpace` / `WWidgetExtension.withTopSafeSpace` 删除。
- `WBadge.config` / `WBadge.badgeStyle` / `WBadge.position` 改为 8.0 自有类型或删除。
- `WButton.debugStyleResolutionCount` 删除。
- `WButtonMotion.new` / `WButtonMotion.copyWith` 的 `effect` 类型改为 `WPressEffect`。
- `WButtonStyle.copyWith` 去掉 `motion` / `semantics` 参数。
- `WButtonSize.copyWith` 改为传 null 表示保留，不再使用 `_unset` 哨兵。
- `WClipRRect.new` / `WNavBar.new` / `WActionRow.createState` 随构造 / 继承变化调整。

### Removed

- `WNavBarConfig`、`WTabBarConfig`、`WBadgeConfig`、`WClipRRectConfig`
- `WButtonMetrics`、`WButtonEffectType`、`WNotificationListenerBuilder`
- `badges` 依赖与 barrel 里的 `BadgePosition` / `BadgeStyle` 转出

### Added

- `WButtonStyleSet`、`WStepColors`、`WBadgeStyle`、`WBadgePosition`
- `WButton.motion` / `WButton.semantics`
- `WAppBarStyle.withBackground` / `WAppBarStyle.withoutBackground`：在纯色与渐变之间安全切换
- `WTabBarStyle.copyWith` 与 `WTabBarStyle` 值相等
- `WScreenData` 值相等

### Changed

- README / example / catalog / AGENTS 模板全部切到 `style` 与自有类型。
- `WImage` 的 provider cache key 只随来源变化（解码尺寸仍由 `ResizeImage` 统一应用）。
- `WImageLoadOptions` 文件更名 `image_load_options.dart`；`WImageSlots` / `WImageTheme`
  拆到独立文件（公开 API 不变）。

## 7.0.0

### Breaking
- `WImageLoadConfig` 更名 `WImageLoadOptions`；同时把占位 / 错误 / 进度 / 重试 UI 拆到
  `WImageSlots`，Options 只保留解码、重试与 gapless 行为。
- `WImageDefaultsScope(defaults: WImageLoadConfig(...))` → `WImageTheme(slots: WImageSlots(...))`；
  作用域只承载 UI 插槽，不再静默忽略重试/解码配置。
- 删除 `WImage.type` / `WImage.data`（改用 `image.source.type` / `image.source.raw`）。
- 删除 `WImageStyle.merge`（无法区分“未设置”和默认值，且无内部调用方）；用 `copyWith`。
- `WImageController.state` 改为非空，`WImageLoadStatus` 新增 `idle`，`WImageLoadSnapshot.status` 不再可空；
  controller 增加 `dispose()`。
- `aspectRatio` 不能再与固定 `width` / `height` 同时设置。
- `WImage.source` 只接受 `options:`；7.0 重构期间新增的 `config:` 兼容别名未发布，直接删除。
- 删除未使用的 `WImageSlots.isEmpty`。
- 扩展改名：`WImageStyleX` → `WImageStyleExtension`、`WHexColor` → `WColorExtension`、
  `WTextStylesThemeData` → `WThemeDataExtension`；`WNotificationListenerBuilderExtension` 删除。
- `WStepStyle.completedColor` / `currentColor` / `upcomingColor` 改为可空；未显式设置时
  分别取 `ColorScheme.primary` / `primary` / `outline`（6.1.1 默认是 `Colors.blue` / `Colors.grey`）。
- `WGradientCircularProgressIndicator.backgroundColor` 改为可空；未设置时取
  `ColorScheme.surfaceContainerHighest`（6.1.1 固定为 `0xFFEEEEEE`）。
- `WNavBar.config` 改为可空（默认不再注入 `const WNavBarConfig()`）；读取 `.config` 的代码
  需要处理 null，或改用 `style:`。
- `WScaffold.appBar` 类型从 `WAppBar?` 放宽为 `PreferredSizeWidget?`；读取 `.appBar` 并依赖
  `WAppBar` 类型的代码需要显式收窄。

### Added
- `WImageSource.resolve(...)`：生成与 WImage 一致尺寸规则的 provider，配合 `precacheImage`。
- `WImageProgress.isComplete` / `WImageProgress.complete()`：完成不再伪造 1/1 字节。
- `WImageTheme` / `WImageSlots` 公开类型；`WImageSlots` 同时支持固定 Widget、
  `showRetryButton` / `retryLabel`；新的 `WImageTheme` 只承载 slots，
  与 4.x 已删除的同名类型语义不同。
- `gaplessPlayback` 现在真正保留上一帧。
- `WNavBarStyle` / `WTabBarStyle`；`WNavBar` / `WTabBar` 新增 `style:`（`config:` 仍是兼容入口）。
- `WStepStyle.resolve(ColorScheme)`，把完成 / 当前 / 未开始颜色解析集中到一处。
- `WNotificationListener<T>` 声明式滚动通知 / 百分比监听；旧 `WNotificationListenerBuilder` 仍是兼容入口。
- `WButtonMetrics`：`WButtonStyle` 的布局 / 尺寸子集，支持 `fromStyle` / `applyTo` / `WButtonStyle.metrics`。
- `WBadge` 直接传 `position` / `showBadge` / `badgeStyle`；`WClipRRect` 直接传 `borderRadius`。
- `WButtonSize.name` 改为可选，省略时为空字符串；自定义尺寸不再强制命名。
- `WWidgetExtension.withTopSafeSpaceOf` / `withBottomBarSpaceOf`，读取当前 `MediaQuery`。
- `WNumExtension.borderSideOf(context)`（主题 outline）与 `WBoxDecorationExtension.withBackground(...)`。
- `WScreen.reset()` / `WAssets.reset()`（测试隔离用）。

### Fixed
- `borderRadius + border` 的边框改为绘制在图片之上，不再被图片盖住。
- `aspectRatio` 作用在图片内容上，padding/margin 在外层。
- `WImageStyle` 实现 `==` / `hashCode`，避免相同样式被误判为变化。
- build 期状态通知延后到 post-frame，外部监听器 `setState` 不再崩溃。
- 相同进度只回调一次；progress-only 变化不再重建 WImage 子树。
- `onProgress` 完成回调、`retryDelayMs` 实际延迟、尺寸提示的重复/单轴漏报修正。
- 默认占位/错误占位改为从 `ColorScheme` 派生，深色主题不再出现亮灰块。
- `WImageErrorView` 小尺寸优先保留重试按钮；160×90 等常见尺寸可操作。


### Changed
- `appbar.dart` / `tab_bar.dart` 拆出 style / config；`list_view.dart` 的 sliver 拆为 part 文件。
- `step.dart` 拆为 `step_types` / `step_style` / `step_flow`；`row_actions.dart` 拆为 `action_row` / `selectable_row`。
- `WImage` 内部拆出 provider 工厂、slots 合并 / 构建、Base64 解码、尺寸提示与 source 构建；
  `WImageState` 从 526 行降到约 335 行，公开行为不变。
- `WButton` 增加 `debugStyleResolutionCount`（`@visibleForTesting`），用于验证样式缓存命中。
- `WTabBar` 未配置 `overlayColor` 时不再强制透明，交给 `TabBarTheme` / Material 默认。
- `WButtonStyle` / `WButtonMotion` / `WButtonSemantics` / `WAppBarStyle` / `WStepStyle` 支持值相等。
- `WButton` 样式解析按 Theme 实例命中缓存，避免每次 build 计算 `ThemeData` 深哈希。

### Deprecated
- `WNotificationListenerBuilder`（用 `WNotificationListener`，8.0 移除）。
- `WClipRRect.config` / `WBadge.config` / `withTopSafeSpace` / `withBottomBarSpace`（8.0 移除）。

迁移见 [`docs/migrations/ui-7.0.md`](https://github.com/stone0533/w_tools/blob/main/docs/migrations/ui-7.0.md)。

## 6.1.1

### Fixed
- 补齐 6.1.0 发布归档遗漏的示例与 README 同步：新增 6 个二级页，
  Playground 代码面板改用 `WImage.source`，并补充 WText / WPressable / 布局 / 状态章节。

## 6.1.0

### Added
- `WImage` 在没有 `width` / `height` / `aspectRatio` 且父级约束无界时，debug 下输出一次性提示
  （加载前占位为 0 尺寸，会表现为空白）；release 无行为变化。

### Changed
- `WStepStyle.copyWith` / `WButtonSize.copyWith` 支持传 `null` 清空可空字段
  （与 ADR-0004 的哨兵约定一致；数值字段仍接受 `int` 字面量）。

### Fixed
- `WBadge` 的 `badgeContent` 为空时不再断言崩溃，改为不渲染徽章。
- README 安装约束同步为 `^6.1.0`，并补充 `WImage` 尺寸要求。

## 6.0.1

### Fixed
- README 安装约束同步为 `^6.0.0`。

## 6.0.0

### Removed
- 移除 `WImage(data:)` / `WImage.network` / `asset` / `file` / `base64` / `provider` / `memory`。
- 移除 `String.toImage` / `toAssetImage` / `toBase64Image` / `toFileImage` / `toNetworkImage`。
- 统一使用 `WImage.source(source: WImageSource...)`；迁移见 `docs/migrations/ui-6.0.md`。

## 5.1.0

### Deprecated
- `WImage(data:)` 与 `WImage.network/asset/file/base64/provider/memory` 标记 deprecated，
  统一迁移到 `WImage.source(WImageSource...)`；计划在 ui 6.0 移除。

## 5.0.1

### Fixed
- `WImageLoadConfig` 实现 `==` / `hashCode`，`WImageDefaultsScope.updateShouldNotify`
  现在比较完整配置；修改 placeholder/errorWidget/retryLabel 等会通知。

# Changelog

## 5.0.0

### Removed
- `WRowButtons` / `WRowButtonsController`：用 `WActionRow` / `WSelectableRow`。
- `WImage.avatar` / `thumbnail` / `cover` / `assetImage`：用 `WImage` + `WImageStyle`。
- `WImageCachePolicy`：直接配置 `PaintingBinding.instance.imageCache`。
- `WImageConfig` typedef：用 `WImageLoadConfig`。
- `WImageDefaults`：用 `WImageDefaultsScope`。
- 7 个 `WImage*Error` 子类：用 `WImageError.kind`。
- `WRow` / `WColumn` / `WPadding` / `WSizeBox`：用 Flutter 原生布局组件。
- `WButtonStyles.primary` / `secondary` / `text` / `danger`：用 `WButtonStyles.of(context)`。

### Changed（破坏性）
- `WTabBarConfig` / `WBadgeConfig` / `WClipRRectConfig` 改为不可变：setter / 链式方法移除，
  用 `const` 构造、factory 或 `copyWith`。`WClipRRectConfig.borderRadiusAll(12)` → `WClipRRectConfig.all(12)`。

## 4.7.1

- 内部重构：`image.dart`（846 行）拆为 `image.dart` + `image_state.dart`（`part`，公开 API 不变）。

## 4.7.0

### Changed
- `WClipRRect` / `WBadge` / `WTabBar` / `WNavBar` 的 `config` 改为可选；省略时使用默认配置，
  只传 `child` / `tabs` / `badgeContent` 即可渲染。

## 4.6.0

### Added
- `WActionRow`：横向滚动操作行（无选中语义）。
- `WSelectableRow`：单选高亮行，默认把选中项滚到视口中间。

### Deprecated（5.0 移除）
- `WRowButtons` / `WRowButtonsController`：改用 `WActionRow` / `WSelectableRow`。

## 4.5.0

### Added
- `WScreen.of(context)` / `WScreenData`：读取树内 `MediaQuery` 的宽高与安全区。

### Fixed
- `WImageFrame`：`padding` 移入装饰层内、`margin` 留在最外（与 `Container` 语义一致）。
- `WNetworkImageSource.hashCode` 改为与 `==` 一致的顺序无关。

### Removed
- 未导出的死代码 `WImageStyleIO.buildFile`。

## 4.4.0

### Breaking
- `HexColor` 扩展更名 `WHexColor`（`fromHex` / `toHex` 成员不变）；旧名不保留。
- `WStringExtension` 与 `WUiStringExtension` 合并为一个 `WStringExtension`（成员不变）。

### Deprecated（5.0 移除）
- `WRow` / `WColumn` / `WSizeBox` / `WPadding`：改用 Flutter 原生组件与 num 扩展。

## 4.3.0

### Breaking
- `WImageDefaultsScope.defaults` 类型改为 `WImageLoadConfig`（`errorBuilder` → `errorWidgetBuilder`）；
  `WImageDefaults` 弃用（5.0 移除）。

### Deprecated（5.0 移除）
- `WImage.avatar` / `WImage.thumbnail` / `WImage.cover` / `WImage.assetImage`：
  改用 `WImage` + `WImageStyle` 预设 / `WImage.asset(prefix: true)`。

## 4.2.0

### Changed
- `WImageConfig` 更名 `WImageLoadConfig`（字段不变）；旧名保留为弃用 typedef，5.0 移除。
- `WImageError` 新增 `kind`（`WImageErrorKind`）；7 个错误子类弃用（5.0 移除）。

## 4.1.0

### Changed
- `WImageLoader` / `WImageLoadSnapshot` 不再从公共 barrel 导出（内部实现）；测试改用 src 导入。
- `WImageCachePolicy` 弃用（5.0 移除）：直接配置 `PaintingBinding.instance.imageCache`。

## 4.0.0

### Breaking
- `WButton` 未传 `style` 时默认使用 `WButtonStyles.of(context).primary`，颜色来自
  `ColorScheme`（`primary` / `onPrimary`、`error` / `onError`、`outline`）；不再使用写死的
  `#3949AB` / `#D32F2F`。依赖旧默认色的页面请显式传 `WButtonStyle`。
- `WButtonStyles.primary` / `secondary` / `text` / `danger` 静态预设弃用（5.0 移除），
  改用 `WButtonStyles.of(context)`。

### Added
- `WButtonStyles.of(context)`：按 `ThemeData` 缓存的主题派生样式组。

## 3.2.0

### Added
- `WTextStyles.toTextTheme()`：把 11 个语义角色写进 Material `TextTheme`，每个角色占一个独立槽位；未涉及的槽位保留传入的 `TextTheme`。
- `ThemeData.withWTextStyles()`：一次装好 `TextTheme` 与 ThemeExtension。form / toast / async 只读 `Theme.of(context).textTheme`，因此**不需要依赖 w_tools_ui** 就能跟随品牌排版。

### Changed
- `toTextTheme` / `fromTextTheme` 按 Material 的消费点映射：`body` 同时写 `bodyLarge`（输入框）与 `bodyMedium`（正文），`number` 不投影（避免表单输入变成数字样式）；`price` 从「等于 title」改为 `headlineSmall`，`bodyStrong` 改为 `titleMedium`。依赖兜底样式的页面外观会略有变化。
- `WTextStyles.of` 的兜底样式按 `TextTheme` 实例缓存（`Expando`），不再每次 build 重建 11 个 `TextStyle`。

## 3.1.0

### Changed
- `WAppBar` 的图标改为 `IconTheme.merge`：默认不再丢失 `ThemeData.iconTheme`（此前会回落到黑色）；标题按 `style.titleStyle` → `AppBarTheme.titleTextStyle` → `TextTheme.titleLarge` 回退，不再显示为正文样式。
- `WImage.avatar` / `thumbnail` / `cover` 的 `style` 改为与预设合并（原来整体替换）：显式字段覆盖预设，尺寸 / 圆角不再被静默丢掉；正方形预设只覆盖宽度时仍保持正方形。
- 新增 `WImageStyle.merge`。

### Fixed
- `WImage.thumbnail` 的解码上限按合并后的尺寸推导，只覆盖宽度时不再沿用旧宽度的缓存尺寸。

## 3.0.0

### Fixed
- `WImageLoader.dispose` 会清除排队中的重试状态；新增 retry 配置变化 / dispose 测试。
- `WImageLoader` 在失败后修改 retry 配置时保留已有 error，避免 failed 状态变成无错误；补对应测试。
- `GlobalKey` 扩展在非 `RenderBox` 上返回 null；`HexColor.fromHex` 拒绝多个 `#`；`toPadLeft` 校验负数长度。

### Changed
- 移除已废弃的 `Widget.withBottomSpace`，改用 `withBottomPadding`。
- 移除 `WRow.iconWithText`（与图标 + 文字光学对齐规范冲突）。
- `WSizeBox.size` 的 `child` 改为命名参数，与其他 `WSizeBox` 方法一致。
- `WBadgeConfig` 增加 `showBadge()` / `isShown` / `badgeStyle()`；`WClipRRect` 增加 `clipBehavior`；`WGradientCircularProgressIndicator` 增加 `semanticsLabel`、colors/stops 校验与列表比较。
- `WNotificationListenerBuilder.setPreventNotificationPropagation` 重命名为 `preventNotificationPropagation`，并增加 `preventsPropagation` 只读 getter。
- 移除 `WKeepAliveWrapper.onDeactivated` / `onRevive`：`AutomaticKeepAlive` 下滚动保活不会触发这些 State 生命周期回调，保留会误导。
- `WGradientCircularProgressIndicator` 语义进度与绘制进度统一 clamp；`WBadge` 显示徽章时断言 `badgeContent` 非空。
- `WBadge` 在 build 时再次校验 `badgeContent`，并防止空角标；`WGradientCircularProgressIndicator` 增加 `value.isFinite` 断言与非有限数兜底。
- `WRowButtonsController` 删除未使用的 `scrollThreshold`；相同索引不再重复通知；补充 controller dispose 顺序文档。
- `WRowButtonsController` 首次布局自动居中 `initialIndex`，新增 `ensureVisible`；`overScroll` 增加非负断言；`onCanTap` 文档说明应为轻量纯函数。
- `WRowButtons` 初始居中现在尊重 `scrollToCenter`；显式 `ensureVisible` 不受该开关限制。
- `WRowButtonsController.selectedIndexNotifier` 改为只读 `ValueListenable<int?>`，避免外部直接写 value 导致索引不同步。
- 重命名：`num.toThousand` → `num.toThousandsSeparated`；`Widget.withBottomSafeSpace` → `Widget.withBottomBarSpace`（后者明确是底部导航栏空间，不是系统 safe area）；`WScreen.bottomBarHeight` → `WScreen.bottomSafeAreaHeight`。
- Navigation 加固：`WNavController.currentIndex` 会停止进行中的动画并在 dispose 后安全返回；`WNavBar` 增加 button/selected 语义；`WTabBar` 改为无状态并支持 `overlayColor`。

### Removed
- 移除 `WImagePreloader`；`WImage` 使用 Flutter `ImageCache`，预加载用 `precacheImage`。
- 移除 `WRichText` / `WRichTextConfig`；多色 / 多字重 / 可点击片段统一使用
  Flutter `Text.rich` + `WTextStyles`。
- 移除 `WTextConfig` 与 `WText.config`；`WText` 统一使用 `WTextVariant` /
  `WTextStyles`，局部覆盖用 `style` / `color`；有字体信息时自动生成 strut。

## 2.1.0

- 新增 `WTextVariant` / `WTextStyles`：语义文字样式与 `ThemeExtension`；
- `WText` 增加 `variant`、`style`、`color`、`maxLines`、`softWrap`、`textScaler` 等参数；
- `WTextConfig` 保留兼容。

## 2.0.0

### Added
- `WListViewSliver` 增加 `emptyFill`，显式控制空态是否填满视口；
  `shrinkWrap: true` 时必须为 false。
- `WBoxDecorationExtension`：`withGradient` / `withShadow` / `withBorder` /
  `withBorderRadius` / `withColor` 及对应 `without...` / `circle`。
- `WGradients`：vertical / horizontal / diagonal / radial 方向预设。
- `WShadows`：none / card / elevated / floating 中性阴影预设。
- `withShadow` 复制为不可变列表；`WGradients` 校验 colors/stops。
- `toCurrency` 负数符号改为 `-$1,234.56`；`toPadLeft` 负数补零保留符号；
  `toPercent` 整数结果不再带 `.0`。
- `HexColor.fromHex` 忽略前后空格；`trimAll` 正则简化。
- 删除 `WImageExtension`；图片预加载用 `precacheImage`。
- `withIntrinsicHeight` 合并到 `WWidgetExtension`，删除 Row/Column 专用扩展。
- `withBottomSpace` 标记废弃，改用 `withBottomPadding`。
- 删除 `WStrutStyleExtension` 与 `WUiTextStyleExtension.fromConfig`；使用
  `WTextConfig.toTextStyle()` / `toStrutStyle()`。
- `WWidgetExtension.withDecoration`：给 Widget 包一层 `DecoratedBox`。

### Breaking
- `WStepConfig` 删除；`WStep` 改为 `current`（1 基）+ `labels` + `WStepState` +
  `WStepStyle`，新增可复用 `WStepFlow`，并支持 `semanticLabelBuilder`。
- `WListView` 拆为 `WListView` + `WListViewSliver`：前者只负责独立滚动，后者只提供
  sliver，可直接嵌入 SmartRefresher / NestedScrollView；删除 `WListViewConfig`、
  `buildByList`、`itemBuilderByT`；重叠改为 `WListViewSliver.overlap` 的正向 `overlap`。
- 删除 `WContainer` / `WContainerConfig`；盒子直接用 `Container` + `BoxDecoration`。
- 删除 `WWidgetExtension.withContainer`；`WWidgetExtension` 只保留间距、展开和点击糖。
- `WNavBarConfig.containerConfig` 改为 `decoration` + `padding`。
- 旧的可变 `WImageConfig` / `WImageConfigBuild` 删除；`WImageStyle` 改为不可变视觉样式。
- `WImageConfigBuild` 扩展删除；用 `WImage.source` / `WImage.network/asset/file/base64`。
- `toImage(config:)` 改为 `toImage(style:)`；`placeholder` / `errorWidget` 改为构造参数。
- `WImage.onLoadProgress`、`progressIndicatorBuilder`、`cacheEnabled`、`fitCenter`、`size` 均已删除。
- `WImageCacheManager` 改名 `WImagePreloader`（3.0 已移除）；`WImageGlobalConfig` 拆为 `WImageDefaultsScope` + `WImageCachePolicy`。
- `WImageTheme` / `WImageThemeData` 改为 `WImageDefaultsScope` / `WImageDefaults`；
  默认占位/错误/进度统一为 builder。
- `WImageStyle` 拆为视觉 `WImageStyle` + 加载 `WImageConfig`；`WImage` / 所有命名构造新增
  `config` 参数，`style` 不再包含 retry / placeholder / memCache / gaplessPlayback。
- `WAppBarConfig` / `WScaffoldConfig` 删除；`WAppBar` 改为显式 `WAppBarStyle` + leading/title/actions/bottom。
- `WScaffold` 改为页面壳：title/actions 自动生成默认 `WAppBar`，新增 `appBar` 覆盖、
  `bottomNavigationBar`、`floatingActionButton`、`resizeToAvoidBottomInset`。
- `WScaffold` 的 PreferredSize 只包含 toolbar + bottom，状态栏由 WAppBar 绘制，避免重复；
  `appBarBottom` 会触发默认 AppBar；`WAppBarStyle` 增加 copyWith / validate。
- `WScaffold.appBar` 覆盖只要求 WAppBar 包含状态栏；WAppBar 自身的 leading/centerTitle 不受限制，
  但 WScaffold 上的同名参数必须保持默认。WAppBar 移除未使用的 `totalHeight`；
  WAppBarStyle 的 backgroundColor/gradient 改为二选一。
- `WScaffold` 安全区改用 MediaQuery；`onBack` 优先于 automaticallyImplyLeading；
  空字符串 title 不再创建默认 AppBar。
- `WAppBarStyle.titleSpacing` 增加非负校验；补 appBarBottom + 状态栏高度测试。
- `WAppBar` 默认包含状态栏背景；不再提供 `WAppBarPreferred` / `WTopBar`。
- `WButtonConfig` / 配置缓存 / `WButtonThemeData` 删除；`WButton` 改用显式 `WButtonStyle`。
- `WButton.enabled` / `loading` 改为组件参数。
- `WButton` 删除任意 `child`；改用 `content` / `contentBuilder`，任意区域点击用 `WPressable`。
- `WButton` 删除 `shake`、`onSecondaryTap`、`onTapDown/Up/Cancel`、`onFocusChange/onHover`、
  `onPressedChanged`、`tooltip`、`enableFeedback`、`behavior`、`sizeName`。
- `WButton` 所有命名工厂（`primary/secondary/text/danger`）删除；统一用 `WButton(style: ...)`。
- 项目样式通过 `AppButtons` / `WButtonStyle` 显式传入；`WButtonStyles.primary` 仅作 fallback。
- `WButtonStyle` 的 `effect/pressedOpacity/pressedScale/animationDuration/curve/semanticLabel/
  semanticHint/loadingLabel` 移到 `WButtonMotion` / `WButtonSemantics`。
- `WButtonStyle` 不再依赖 `WContainerConfig` / `WTextConfig`；改为显式
  `backgroundColor/gradient/border/borderRadius/boxShadow/padding/foregroundColor/textStyle`。
- 颜色/边框/阴影/文字改为 `WidgetStateProperty`，`WButton` 解析为 `WButtonResolvedStyle`；
  支持 disabled/pressed/hovered/focused 状态组合。使用 disabled 状态色时需将
  `disabledOpacity` 设为 1，避免双重禁用效果。
- `WButtonResolvedStyle` 暴露不可变 `states`，`contentBuilder` 可按状态改变内容结构。
- 示例 `AppButtons.primary` 改为 `WidgetStateProperty` 状态样式，示例页新增第 12 节演示。
- `WButton` 要求可交互按钮至少提供 `onTap` / `onLongPress`，并让指针回调在禁用中不再触发；
  release 下没有回调时按 disabled 渲染；无 `onLongPress` 时不再安装长按识别器，避免延迟普通点击。
- 只有 `onLongPress` 时不启用键盘焦点，避免出现可聚焦但 Enter/Space 无响应的按钮。
- `withBackgroundColor` 同时清空 `gradient`，避免背景色被渐变覆盖。
- `WPressable` 保持纯指针点击，不参与键盘焦点；键盘操作统一用 `WButton`。
- `WPressable` 禁用时重置按下态；没有 `onTap`/`onLongPress` 时不再安装手势或 click cursor；
  增加动画参数断言。
- `WPressable` 回调增加 `_actionable` 守卫，禁用中手势不会触发 onTap/onLongPress。
- `WPressable` 默认只阻断指针，不清理 child 的交互语义；可选
  `excludeChildSemanticsWhenDisabled` 在禁用时排除 child 语义。
- 增加 `withBackgroundColor` / `withForegroundColor` / `withBorder` / `withBoxShadow` /
  `withTextStyle` 静态覆盖便利方法，以及 `withoutDecoration` / `withoutBorder` /
  `withoutBoxShadow` / `withoutTextStyle` / `withoutText` / `withoutForegroundColor` /
  `withoutFocusColor` / `withoutHoverColor`。
- `withoutTextStyle` 只清 textStyle；同时清 textStyle 和 foregroundColor 用 `withoutText`。
- `Widget.toButton(config:)` / `toButton(style:)` 改为 `Widget.toPressable(...)`。

### Added
- 新架构入口：`WImage.source(source:, style:)`、sealed `WImageSource`、不可变 `WImageStyle`、
  `WImageFrame`、`WImageDefaultsScope`。
- 场景预设：`WImage.avatar` / `WImage.thumbnail` / `WImage.cover` / `WImage.assetImage` /
  `WImage.memory` / `WImage.provider`，以及 `WImageStyle.avatar/thumbnail/cover`。
- `WImageStyle` 链式糖：`square()` / `rounded()`。
- `WImageConfig(showRetryButton: true)` + `WImageErrorView` 内置错误/重试视图；
  小尺寸自动只显示图标。
- `WImageProviderError`：`provider` / `memory` 解码失败的错误类型。
- `WImageDefaults.progressBuilder`。
- `WImageSource.parse` 保留字符串自动判定；`WImage(data:, style:)` 与命名构造作为便利入口。
- `WImageController.state`：`ValueListenable<WImageLoadSnapshot>`（status/progress/attempt/error/retryScheduled）。
- `WImageLoadSnapshot` 实现 `==`/`hashCode`，`emit()` 相同快照不重复通知。
- `WImageCachePolicy`：进程级 `ImageCache` 预算；`WImageDefaultsScope` 管默认占位/错误/进度。
- 重试定时器、错误分类、进度上报与状态去重移入 `WImageLoader`；`WImage` 的 State 只做构建/渲染。
- 网络路径统一为 `CachedNetworkImageProvider` + `Image`，进度改用 `ImageChunkEvent`；
  磁盘缓存仍走 `cached_network_image`。
- `String.toImage` 增加 `key` / `style` / `config` / `type` / `semanticLabel` / `controller` /
  `onProgress` 参数；`style` / `config` 不可变，不会被修改。
- 新增 `String.toAssetImage({prefix})` / `toBase64Image()` / `toFileImage()` / `toNetworkImage()`。
- `WImage` 默认构造支持显式 `type`，与命名构造一致。
- `WButtonStyle` 拆分为视觉 `WButtonStyle` + 动效 `WButtonMotion` + 语义 `WButtonSemantics`；
  `WButtonStyles.primary/secondary/text/danger` 预设保留。
- `WButton` 支持 `label` / `icon` / `content` / `contentBuilder`；复杂内容保留 button 语义、
  loading、键盘和点击区域。
- `WButton` 保留 `loading`、`loadingBuilder`、`focusNode`、`autofocus`、`semanticLabel`、
  48×48 hit target、focus/hover overlay、禁用隔离。
- `WButtonSize` 支持 `lineHeight` / `letterSpacing`，默认 small/medium/large 视觉高度 32/40/48，
  实际 hit target 保持 48。
- 新增 `WButtonStyle.filled/outlined/text` 工厂。
- 新增 `WPressable`：任意 child 点击 + opacity/scale，不声明 button 语义、不负责样式/loading/最小区域。
- `button.dart` 拆出 content / effect / tap target 三个 part 文件。

### Changed
- `String.toImage` 的尺寸优先级改为显式 `width` / `height` 优先，`size` 仅作 fallback。
- 网络图的进度改由 `Image.loadingBuilder` 的 `ImageChunkEvent` 上报。
- `WImage` 相关源码集中到 `lib/src/components/common/image/`，导入路径统一为
  `package:w_tools_ui/src/components/common/image/image.dart`。

### Fixed
- `WImageLoader` 在 `completed/failed` 后忽略迟到的进度/`markLoading`/错误，完成时取消已排队的重试，`beginAttempt` 清空旧进度。
- 迟到的 `loadingBuilder`/`errorBuilder` 不再覆盖已完成的图片；style 变化会清空上一帧缓存。
- `WImageController.state` 首次绑定后保持稳定，WImage 卸载后仍可安全移除监听。
- `data:` / `file:` 前缀改为大小写不敏感（`DATA:` / `FILE:`）。
- `showRetryButton` 只对网络/provider/文件错误显示重试，空数据/Base64/asset/unsupported 不显示。
- `WImageErrorView` 的尺寸完全交给 `LayoutBuilder` 判断；`compact` / `showAction` 仅作为显式覆盖参数。
- `WImage.provider` / `WImage.memory` 复用 provider，避免每次 build 重新解析。
- `WImageController` 同时绑定多个 WImage 时在 debug 下断言；`WImageFrame` 渲染时复制 `boxShadow`
  为不可变快照。
- `WImage` 的 `key` 之前没有传给 `StatefulWidget`，导致所有构造方式的 `key` 实际失效。
- 修改 `retryCount` / `retryDelay` 时会取消已排队的重试。
- 网络图的 `completed` 状态改为在首帧到达时上报。
- `borderRadius` 现在同时作用于 `border` 与 `boxShadow`。
- `WImageStyle.validate()` / `WImageConfig.validate()` 在构造、更新、build 时复用；`aspectRatio` 与固定宽高冲突时 debug assert。
- 每个 `WImage` 缓存 provider，避免每次 build 重新创建 `CachedNetworkImageProvider` / `AssetImage` / `FileImage`。
- `WImagePreloader` 与 `WImageCachePolicy` 解耦（缓存预算只作用于 Flutter `ImageCache`）。

## 1.1.0

> 说明：本版本删除了公开组件 `WNetworkImageWithRetry`。按 semver 这应当作为 2.0.0 发布；
> 发布时没有外部使用者，因此未回滚、也未提供兼容垫片。自 1.1.0 起该组件不再存在，
> 后续破坏性变更会按 major 发布。

### Added
- `WImage.network` / `WImage.asset` / `WImage.file` / `WImage.base64` 命名构造：
  跳过字符串嗅探，类型确定，也不会因为 asset 名长得像 URL 而走错分支。
- `WImageProgress` + `WImage.onProgress` + `WImageConfig.progressBuilder`：
  进度回调不再暴露 `cached_network_image` 的 `DownloadProgress`。
- `WImageError`（sealed）与 6 个子类型（空数据 / 网络 / 资产 / Base64 / 文件 / 不支持平台）：
  `errorWidgetBuilder` 的第三个参数声明为 `WImageError`（以前是 `dynamic`），可以直接 `is` 分支。
- `error.data` 统一为调用方传给 `WImage` 的原始 `data`（网络错误以前给的是规范化后的 URL）。
- `WImageConfig.memCacheWidth` / `memCacheHeight`：限制解码尺寸（物理像素），
  网络、资产、文件、Base64 全路径生效；列表缩略图必传。
- `WImageConfig.aspectRatio`：图片与占位符按固定宽高比布局，加载前后尺寸一致、列表不跳版。
- 常用参数：`semanticLabel`、`excludeFromSemantics`、`gaplessPlayback`、`filterQuality`、
  `alignment`、`httpHeaders`、`cacheKey`。
- `WImageConfig` 的配置项都是公开字段，可以直接读写（测试/调试不必再反查组件树）；
  `placeholder` / `errorWidget` 是只写的固定 Widget 便捷 setter，读回用对应的 builder 字段。
- `WImageController`：新增手动重试入口 `retry()`（网络 / 资产 / 文件 / Base64 都有效），
  可在错误占位里放"重试"按钮，不必再销毁重建。
- 重试策略：只对 `5xx` / `408` / `429` / 连接级失败重试，`4xx` 直接失败；
  间隔改为指数退避 + 抖动（上限 30s），避免同屏多图同时重试。

### Changed
- 资产图片统一走 `Image.asset` + Flutter `ImageCache`：支持 2x/3x 变体与 `package:` 资产，
  不再额外缓存一份原始字节；`WImageCacheManager` 因此不再被 `WImage` 使用（保留给预加载/统计）。
- `WImageGlobalConfig.maxCacheSize` / `maxCacheMemory` 现在同步到 Flutter `ImageCache`
  （`maximumSize` / `maximumSizeBytes`），asset 与网络共用同一份缓存预算。
- 网络图片只剩一条渲染路径：`WImage` 内部直接构建 `CachedNetworkImage`，
  重试/进度/状态都在自己的 State 里处理，不再经过额外的包装组件。
- 类型判定只在 `initState` / `didUpdateWidget` 计算一次，去掉跨实例的全局类型缓存。
- Base64 解码后 ≤64KB 在主 isolate 解码（按 Base64 文本长度估算），超过才用 `compute`。
- 平台条件导入改用 `dart.library.io` 判断，WASM 构建不再误编译 `dart:io`。
- `WImageGlobalConfig.maxCacheSize` 默认值改为 1000，与 Flutter `ImageCache` 保持一致。
- 进度换算（`DownloadProgress` → `WImageProgress`）改为内部函数，
  `WImageProgress.fromDownloadProgress` 不再暴露第三方类型。
- `WImageConfig` / 图片类型拆到独立文件；`build` / `buildFilePath` / `buildBase64`
  改为 `WImageConfigBuild` 扩展（通过 `image.dart` 导出，调用方式不变）。

### Fixed
- `data:` 前缀剥离只认 `data:image/`：`data:application/octet-stream;base64,...`
  会被整串丢进 `base64Decode` 而失败。
- `//` 开头的协议相对地址被判成网络图后没有补 `https:`，请求必然失败。
- 类型判定用 trim 后的值、但 asset/file/base64 分支仍用原始串：带空白的路径会加载失败。
- 文件图片忽略 `memCacheWidth` / `memCacheHeight`。
- 状态/进度回调的 post-frame 没有判断 `mounted`，组件已卸载仍会回调。
- `WImageConfig.buildBase64(裸串)` 会被判定成 asset（现在走显式构造）。
- 重试不再对 `404` / `403` 等永久失败生效，也不会让错误占位延迟 `retryCount × retryDelay` 才出现。
- 重试间隔固定、无抖动的问题（同屏图片会同步重试）。
- 状态去重与进度上报原本在网络路径重复实现一份，现在只剩一处，并补上了网络路径测试。

### Removed
- `WNetworkImageWithRetry`：重试已内联到 `WImage`，不再保留独立的公共组件。
  迁移：`WNetworkImageWithRetry(imageUrl: url, retryCount: 3, ...)` →
  `WImage.network(url, config: WImageConfig()..retryCount = 3)`；
  需要手动重试时用 `WImageController`。

### Deprecated
- `WImageConfig.cacheEnabled`：资产图片已统一走 Flutter `ImageCache`，该开关不再生效。
- `WImageConfig.fitCenter()`：等价于 `fitContain()`，将在 2.0 移除。

## 1.0.0

首次发布。

- 新增通用组件：`WText` / `WImage` / `WButton` / `WBadge` / `WNetworkImageWithRetry` / `WRowButtons` 等
- 新增布局组件：`WScaffold` / `WAppBar` / `WContainer` / `WListView` / `WStep`
- 新增导航组件：`WNavBar` / `WNavController` / `WTabs`
- 新增颜色、字符串、数字、Row / Column、TextStyle、Widget 等扩展
- 新增屏幕适配与间距工具：`WScreen` / `WSizeBox` / `WPadding` / `WAssets` / `WImageCacheManager`
- 最低要求 Flutter 3.27.0
- `WListView` 保留 `cacheExtent`（Flutter 3.44 起标记 deprecated）以兼容 3.27–3.43