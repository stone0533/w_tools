# Changelog

## 2.0.0

### Breaking
- `WImageConfig.progressIndicatorBuilder`（旧 `DownloadProgress` 签名）删除，统一用 `progressBuilder`。
- `WImage.onLoadProgress` / `toImage(onLoadProgress:)` 删除，统一用 `onProgress`。
- `WImageConfig.cacheEnabled` 删除（资产统一走 `Image.asset` + `ImageCache`）。
- `WImageConfig.size(w, h)` 改名为 `dimensions(w, h)`；新增 `square(side)`。
- `WImageConfig.fitCenter()` 删除，用 `fitContain()`。
- `WImageConfigBuild.build` 返回类型从 `Widget` 收窄为 `WImage`。

### Added
- `WImageConfig.copy()`：复制全部配置字段，便于"以现有配置为底再覆盖少量字段"。
- `String.toImage` 增加 `key` / `config` / `type` / `semanticLabel` / `controller` /
  `onProgress` 参数；`config` 会被复制，不会修改调用方对象。
- 新增 `String.toAssetImage({prefix})` / `toBase64Image()` / `toFileImage()` / `toNetworkImage()`，
  避免自动判定在「纯 Base64」「无 file:// 前缀」「短资源名」上猜错。
- `WImage` 默认构造支持显式 `type`，与命名构造一致。

### Changed
- `String.toImage` 的尺寸优先级改为显式 `width` / `height` 优先，`size` 仅作 fallback
  （旧行为是 `size` 覆盖宽高）。

### Fixed
- `WImage` 的 `key` 之前没有传给 `StatefulWidget`，导致所有构造方式的 `key` 实际失效；
  现在会正确传递。

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
