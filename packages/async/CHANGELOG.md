# Changelog

## 5.2.0

### Added
- `WAsyncState.list`：与 `WAsyncController.list` 对称的列表状态构造；旧名 `ofList`
  标 `@Deprecated`，7.0 删除。
- `WAsyncPagedController.changes`：合并 `state` / `isLoadingMore` / `loadMoreError` /
  `hasMoreListenable` 的单监听入口，footer 不必再挂四个监听。

### Changed
- `WAsyncErrorBanner` 默认文案的冒号改为 ASCII `: `，避免英文 title 与全角标点混排。
- 分页追加改用 `List.unmodifiable(current.followedBy(value))`，去掉一次中间列表拷贝。

### Docs
- 说明 `WAsyncController` 原样保存 loader 返回值，`WAsyncPagedController.state.data`
  为 unmodifiable 列表。

## 5.1.0

### Changed
- `WAsyncController` / `WAsyncPagedController` 传入 `WAsyncOptions.activity` 现在在构造时抛
  `ArgumentError`（release 也一样），不再在 release 下静默忽略。控制器自己维护四态；
  需要并发活动计数请直接用 `WAsync`。

### Docs
- 修正已删除 API / 旧 null 语义的过期注释；补充并发组合器边界与分页 footer 的
  `hasMoreListenable` 说明，并补齐结果三态 getter、theme 通知、sliver / view retry 错误等测试。

## 5.0.1

### Changed
- README 补充 `WAsyncView` 的 per-view builder、`WAsyncStatus` 与 `WAsyncActivity` 适用边界。

## 5.0.0

### Breaking
- `WAsync.run` / `map` / `retry` / `timeout` / `parallel` / `pool` / `first` / `serial` 现在直接返回成功值；失败抛异常，取消抛 `WCancellationException`，不再用 `null` 吞错。
- 新增 `WAsyncResult` / `WAsyncSuccess` / `WAsyncFailure` / `WAsyncCancelled`；`WAsync.tryRun` 返回结果对象。
- 删除 `WAsync.runValue`；用 `WAsync.run`。
- `WAsyncLoading` 改名 `WAsyncActivity`；`WAsyncOptions.loading` 改名 `activity`，`withoutLoading` 改名 `withoutActivity`。
- 删除 `WAsyncOptions.copyWith`；直接构造 options。
- 删除 `WAsyncState.dataOrNull`；统一用 `data`。
- `WAsyncView.onRetry` 改为可选；无 retry 时不渲染重试按钮。
- 默认文案改由 `WAsyncStrings` 提供（默认为中性英文），可通过 `WAsyncTheme.strings` 注入。
- 分页 `initialPage` 必须 >= 1。

### Added
- `WAsyncOptions.withoutOnError()`：调用点自己处理错误时去掉兜底 onError，避免重复上报。

## 4.1.0

### Added
- `WAsyncThemeViews`：四态视图的统一解析入口（显式 builder > `WAsyncTheme` > 包内默认）。
  `WAsyncStateBuilder` 这类自建滚动壳也能复用全局默认，不必每页重写 loading / empty / error。
- `WAsyncTokenLoader` + `WAsyncController.withToken`、
  `WAsyncTokenPageLoader` + `WAsyncPagedController.withToken`：loader 能拿到
  `WCancelToken`，取消真正能传到请求层。
- `WAsync.runValue`：直接返回结果，不写 `onSuccess` 映射。
- `WAsyncPagedController.hasMoreListenable`：footer 可单独监听「加载更多 / 没有更多」。
- `WAsyncOptions.withoutLoading()`；`copyWith` 传错类型抛 `ArgumentError`，不再留到调用时炸。

### Changed
- `WAsyncStateSliver` 在 `onRetry == null` 时使用**不带重试按钮**的默认视图，不再渲染
  点了没反应的按钮；该配置下不调用自定义 error / banner builder（它们要求可用的 retry）。
- `WAsync.run` / `retry` / `serial` / `pool` 取消时会尽快返回 null，与
  `timeout` / `parallel` / `first` 对齐；底层任务仍继续执行，结果被丢弃。
- 控制器把失败（含 `Error`）统一回调 `options.onError`，编程错误不再完全静默。
- 控制器构造时断言 `options.loading == null`（控制器自己维护四态，传了会被忽略）。
- `WAsyncPagedController.refresh()` 会取消在途 `loadMore` 的 token；`loadMore` 同样传入 token。
- `WAsyncLoading.begin` / `end` 保持公开（聚合包 API 契约），文档明确为框架内部使用。

### Docs
- 修正 `docs/modules/async_module.md` 模块结构里的已删除文件，README 安装版本同步。

## 4.0.0

### Breaking
- `WAsyncStateSliver.state` 改为 `ValueListenable<WAsyncState<T>>`，与 `WAsyncView` /
  `WAsyncStateBuilder` 一致；`onRetry` 改为 `Future<void> Function()?`。
  迁移：`state: state` → `state: controller.state`，`onRetry: () {}` → `onRetry: controller.load`。

## 3.0.0

### Removed
- `WAsyncViewDefaults` / `WAsyncSliverDefaults`：统一用 `WAsyncTheme` 的普通 builder 与 `sliver*Builder`。

## 2.1.0

### Added
- `WAsyncTheme`：把普通视图与 sliver 视图的默认 loading / empty / error / 刷新 builder 合到一个
  InheritedWidget，放在 App 根部一次装完；显式 builder 仍然优先。

### Deprecated
- `WAsyncViewDefaults` / `WAsyncSliverDefaults`：3.0 移除，改用 `WAsyncTheme` 的对应字段
  （`sliver*Builder` 前缀区分 sliver 视图）。旧类仍被识别（优先级低于 `WAsyncTheme`）。

## 2.0.0

### Breaking
- `WAsyncConfig` 改名为 `WAsyncOptions` 并改为纯数据：删除 `showLoading` / `onLoadingStart` / `onLoadingEnd` / `fallbackOnError` 字段和 7 个转发方法（`config.run(...)` 等），统一用 `WAsync.xxx(options: ...)`。
- 加载状态合并改为显式 `WAsyncLoading`（放进 `WAsyncOptions.loading`）：不传就完全不跟踪，不再“共享配置即隐式合并”。
- 方法改名：`runWithRetry → retry`、`runWithTimeout → timeout`、`wait → parallel`、`runAllWithConcurrency → pool`、`any → first`、`sequence → serial`。
- 删除 `WAsyncBuilder` 兼容别名（使用 `WAsyncStateBuilder`）。
- `WAsyncController` / `WAsyncPagedController` 新增 `options` 参数，内部改走 `WAsync`；`load` / `refresh` 会取消上一次的 `WCancelToken`，`dispose` 也会取消（取消仍是协作式的）。

### Added
- `WAsyncLoading`：`onStart` / `onEnd` / `isLoading` / `begin()` / `end()`。
- `WAsyncOptions.copyWith` 用哨兵实现，传 `null` 可清空 `loading` / `onError`。

### Fixed
- 非法参数（负数 `retryCount` / `retryDelay` / `timeout`、`concurrency < 1`）以失败的 Future 返回 `ArgumentError`，与旧行为一致。

## 1.0.0

首次发布。

- `WAsync` / `WAsyncConfig` / `WCancelToken`：执行、重试、超时、并发控制与取消。
- `WAsyncState` / `WAsyncStatus`：四态异步状态快照。
- `WAsyncController`：每个异步区块独立管理状态、旧请求丢弃与手动重试。
- `WAsyncView` / `WAsyncErrorView` / `WAsyncErrorBanner` / `WAsyncViewDefaults`：异步视图、默认错误态与刷新错误条。
- `WAsyncStateBuilder`：滚动页面 / `SmartRefresher` / `CustomScrollView` 的状态构建入口。
- `WAsyncBuilder`：`WAsyncStateBuilder` 的兼容别名。
- `WAsyncPagedController`：分页列表的首屏、刷新、追加、hasMore 与 loadMore 错误。
- `WAsyncStateSliver`：CustomScrollView 的四态 sliver、failed+旧数据；默认不额外添加 refreshing 进度。
- `WAsyncSliverDefaults`：Sliver 页面独立的默认 loading/empty/error/banner 与 refreshing sliver。
- `WAsyncPagedController` 的 `initial: WAsyncState.ready(...)` 下一次 `loadMore()` 从 `initialPage + 1` 开始，避免重复追加第一页。
