- **Async blocks** (`explain WAsyncSection` / `WAsyncPagedList`; paged controller:
  `explain WAsyncPagedController`): app pages use `WAsyncController` + `WAsyncSection`
  (onRetry=controller.load) and `WAsyncPagedList` for paged lists; `WAsyncPagedSliver`.
  `WAsyncView` / `WAsyncStateSliver` are library-only. `WAsyncStatus` /
  `WAsyncStrings` come from `WAsyncTheme`. Footer reads
  `snapshot.footerStatus` (hidden / loading / failed / noMore / loadMore); `loadMore` failure
  writes `snapshot.loadMoreError`; no `hasLoadedMorePage`; don't use `data != null` for states; branch on `WAsyncSuccess` /
  `WAsyncFailure` / `WAsyncCancelled`; cancellation throws `WCancellationException`; execution uses `WAsync.tryRun` / `run`; default hooks via `WAsyncExecutor(WAsyncHooks(...))`;
  no global defaultHooks; per-call hooks override; use `WAsync.settle`;
  `WAsyncView.state` is `ValueListenable`, keep outer `Obx`.
