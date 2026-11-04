# async 4.1 迁移

4.1 没有破坏性 API 改动，但有三处可观察行为修正，升级前值得确认：

## 1. 取消会立即返回

所有执行入口（`run` / `retry` / `timeout` / `parallel` / `pool` / `first` / `serial`）现在
在 `cancelToken.cancel()` 后都会尽快返回 `null`。此前 `run` / `retry` / `serial` / `pool`
会等当前任务结束后才返回。

取消仍然**不会中止**底层 Future：任务继续执行，结果被丢弃。如果依赖「取消后必须等任务跑完」
来做清理，请改为在任务内部用 `WCancelToken` 主动检查。

## 2. 控制器的失败统一回调 `options.onError`

`WAsyncController` / `WAsyncPagedController` 仍然把所有异常转成 `failed`，但现在连
`Error`（`TypeError` / `StateError`）也会回调 `options.onError`，方便记录堆栈。

## 3. `WAsyncStateSliver.onRetry == null`

失败态不再渲染一个点了没反应的重试按钮：使用不带按钮的默认视图，并且**不调用**
自定义 / 主题的 `errorBuilder` / `errorBannerBuilder`（它们的契约要求可用的 retry）。
需要自定义错误 UI 时请传一个真实的 `onRetry`（哪怕是 no-op，也由调用方显式决定）。

## 4. 控制器不再接受 `options.loading`

给控制器传 `WAsyncOptions(loading: ...)` 现在会在 debug 断言失败（此前静默忽略）。
并发 loading 合并请直接用 `WAsync`。

## 新增 API

- `WAsyncThemeViews.of(context)`：四态视图解析入口，`WAsyncStateBuilder` 可用它复用全局默认；
- `WAsyncController.withToken` / `WAsyncPagedController.withToken`：loader 接收 `WCancelToken`；
- `WAsync.runValue`：直接返回结果；
- `WAsyncPagedController.hasMoreListenable`；
- `WAsyncOptions.withoutLoading()`；`copyWith` 传错类型抛 `ArgumentError`。
