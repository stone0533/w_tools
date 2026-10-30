# Changelog

## 1.0.0

首次发布。

- `WAsync` / `WAsyncConfig` / `WCancelToken`：执行、重试、超时、并发控制与取消。
- `WAsyncState` / `WAsyncStatus`：四态异步状态快照。
- `WAsyncController`：每个异步区块独立管理状态、旧请求丢弃与手动重试。
- `WAsyncView` / `WAsyncErrorView` / `WAsyncErrorBanner` / `WAsyncViewDefaults`：异步视图、默认错误态与刷新错误条。
- `WAsyncStateBuilder`：滚动页面 / `SmartRefresher` / `CustomScrollView` 的状态构建入口。
- `WAsyncBuilder`：`WAsyncStateBuilder` 的兼容别名。
- `WAsyncPagedController`：分页列表的首屏、刷新、追加、hasMore 与 loadMore 错误。
- `WAsyncStateSliver`：CustomScrollView 的四态 sliver、failed+旧数据与 refreshing。
