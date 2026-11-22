- **Async blocks** (`explain WAsyncSection` / `WAsyncPagedList`; paged controller:
  `explain WAsyncPagedController`): app pages use `WAsyncController` + `WAsyncSection`
  (onRetry=controller.load) and `WAsyncPagedList`. Footer reads `snapshot.footerStatus`;
  `loadMore` failure writes `snapshot.loadMoreError`; no `hasLoadedMorePage`; don't use
  `data != null`; branch on `WAsyncSuccess` / `WAsyncFailure` / `WAsyncCancelled`;
  cancellation throws `WCancellationException`; `WAsync` execution; `WAsyncStatus` /
  `WAsyncStrings` from `WAsyncTheme`; default hooks via `WAsyncExecutor(WAsyncHooks(...))`;
  `disableOnError` clears default onError; `controller.isRetrying` distinguishes retry;
  `WAsyncView.state` is `ValueListenable`, keep Obx.
