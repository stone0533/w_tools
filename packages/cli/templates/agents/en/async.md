- **Async blocks**: use `WAsyncController + WAsyncView` for pages; do not hand-write
  `ValueNotifier<WAsyncState>` or repeat `when + RetryView` per page. One Controller per
  independent block; use `WAsyncTheme` at the app root. Use `WAsyncView` for normal
  blocks; use `WAsyncStateBuilder` for scroll pages / `SmartRefresher`, never wrap
  `SmartRefresher` around `WAsyncView`. `builder` must always return the same
  `SmartRefresher + CustomScrollView`; loading/empty/error go inside slivers. Use
  `WAsyncTheme`'s `sliver*Builder` / `WAsyncStateSliver` for sliver pages; `readySliverBuilder` returns a sliver.
  Pagination: use `WAsyncPagedController`; on `loadMore` failure write `loadMoreError` / footer,
  never replace the list with `WAsyncController.failed`.
  For pure execution without UI use `WAsync.tryRun` + `WAsyncResult`, or `WAsync.run` (throws on failure);
  do not use old `WAsync.run(onSuccess:)` / `runValue` / `WAsyncLoading`.
