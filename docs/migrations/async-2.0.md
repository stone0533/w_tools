> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

# async 2.0 迁移：执行核收敛

| 旧 | 新 | 说明 |
| --- | --- | --- |
| `WAsyncConfig` + 7 个转发方法（`config.run(...)`） | `WAsyncOptions` + `WAsync.run(..., options: ...)` | 转发方法删除 |
| `onLoadingStart` / `onLoadingEnd` / `showLoading` / `fallbackOnError` | `WAsyncLoading(onStart:, onEnd:)` + `WAsyncOptions(loading:, onError:)` | 合并改为显式 |
| `runWithRetry` / `runWithTimeout` / `wait` / `runAllWithConcurrency` / `any` / `sequence` | `retry` / `timeout` / `parallel` / `pool` / `first` / `serial` | 方法改名 |
| `WAsyncBuilder` | `WAsyncStateBuilder` | 别名删除 |
| 控制器直接调 loader | 控制器接 `options`，内部走 `WAsync`；`load`/`refresh` 取消上次 token | 行为增强 |
