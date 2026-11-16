- **Async blocks** (`explain WAsyncView` / `explain WAsyncPagedController`): `WAsyncController` + `WAsyncView`;
  put the scrollable in `readyBuilder`, use `WAsyncStateSliver` for slivers; failed states **must** pass
  `onRetry` (or a custom `errorBuilder` with retry) — the default error view has no button; the paged footer
  reads only `snapshot.footerStatus` (hidden / loading / failed / noMore / loadMore); write
  `snapshot.loadMoreError` on failure — do not maintain `hasLoadedMorePage`; one controller + WAsyncView
  per independent block; do not use `data != null` for
  the four states; `WAsyncStatus` / `WAsyncStrings` come from `WAsyncTheme`; branch on `WAsyncSuccess` /
  `WAsyncFailure` / `WAsyncCancelled`, cancellation throws `WCancellationException`; use
  `WAsync.tryRun` / `WAsync.run` for pure execution and `WAsync.settle` for independent sections;
  `WAsyncView.state` is a `ValueListenable`,
  not `Rx`, keep the outer `Obx`.
