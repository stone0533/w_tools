# Changelog

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
