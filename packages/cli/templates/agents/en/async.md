- **Async blocks** (`explain WAsyncSection` / `explain WAsyncPagedList`; paged controller:
  `explain WAsyncPagedController`): app pages use `WAsyncController` + `WAsyncSection` for one block
  (onRetry=controller.load) and `WAsyncPagedList` for paged lists; `WAsyncPagedSliver` for custom
  scroll. `WAsyncView` / `WAsyncStateSliver` are for libraries/design systems. Footer reads only
  `snapshot.footerStatus` (hidden / loading / failed / noMore / loadMore); `loadMore` failure
  writes `snapshot.loadMoreError`; do not maintain `hasLoadedMorePage`; one controller per
  independent block; do not use `data != null` for the four states; `WAsyncStatus` /
  `WAsyncStrings` come from `WAsyncTheme`; branch on `WAsyncSuccess` / `WAsyncFailure` /
  `WAsyncCancelled`, cancellation throws `WCancellationException`; use `WAsync.tryRun` / `run`
  for pure execution and `WAsync.settle` for independent sections; `WAsyncView.state` is a
  `ValueListenable`, not `Rx`, keep the outer `Obx`.
