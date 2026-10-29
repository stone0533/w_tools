# Changelog

## 2.0.0

### Breaking
- `WImageConfig` 删除，改为不可变 `WImageStyle`（`copyWith` / `validate`）。
- `WImageConfigBuild` 扩展删除；用 `WImage.source` / `WImage.network/asset/file/base64`。
- `toImage(config:)` 改为 `toImage(style:)`；`placeholder` / `errorWidget` 改为构造参数。
- `WImage.onLoadProgress`、`progressIndicatorBuilder`、`cacheEnabled`、`fitCenter`、`size` 均已删除。
- `WImageCacheManager` 改名 `WImagePreloader`；`WImageGlobalConfig` 拆为 `WImageTheme` + `WImageCachePolicy`。
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
  `WImageFrame`、`WImageTheme`。
- 场景预设：`WImage.avatar` / `WImage.thumbnail` / `WImage.cover` / `WImage.assetImage` /
  `WImage.memory` / `WImage.provider`，以及 `WImageStyle.avatar/thumbnail/cover`。
- `WImageStyle` 链式糖：`square()` / `rounded()` / `decodeSize()`。
- `WImageStyle(showRetryButton: true)` + `WImageErrorView` 内置错误/重试视图；
  小尺寸自动只显示图标。
- `WImageProviderError`：`provider` / `memory` 解码失败的错误类型。
- `WImageThemeData.defaultProgressBuilder`。
- `WImageSource.parse` 保留字符串自动判定；`WImage(data:, style:)` 与命名构造作为便利入口。
- `WImageController.state`：`ValueListenable<WImageLoadSnapshot>`（status/progress/attempt/error/retryScheduled）。
- `WImageLoadSnapshot` 实现 `==`/`hashCode`，`emit()` 相同快照不重复通知。
- `WImageCachePolicy`：进程级 `ImageCache` 预算；`WImageTheme` 管默认占位符。
- 重试定时器、错误分类、进度上报与状态去重移入 `WImageLoader`；`WImage` 的 State 只做构建/渲染。
- 网络路径统一为 `CachedNetworkImageProvider` + `Image`，进度改用 `ImageChunkEvent`；
  磁盘缓存仍走 `cached_network_image`。
- `String.toImage` 增加 `key` / `style` / `type` / `semanticLabel` / `controller` /
  `onProgress` 参数；`style` 不可变，不会被修改。
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
- `WImage` 的 `key` 之前没有传给 `StatefulWidget`，导致所有构造方式的 `key` 实际失效。
- 修改 `retryCount` / `retryDelay` 时会取消已排队的重试。
- 网络图的 `completed` 状态改为在首帧到达时上报。
- `borderRadius` 现在同时作用于 `border` 与 `boxShadow`。
- `WImageStyle.validate()` 在构造、更新、build 时复用；`aspectRatio` 与固定宽高冲突时 debug assert。
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
