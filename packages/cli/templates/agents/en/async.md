- **Async blocks** (`explain WAsyncPagedController`): `WAsyncController` + `WAsyncView`; put the
  scrollable inside `readyBuilder`, use `WAsyncStateSliver` for slivers; `WAsyncStatus` /
  `WAsyncStrings` come from `WAsyncTheme` (at the app root); branch on `WAsyncSuccess` /
  `WAsyncFailure` / `WAsyncCancelled`, cancellation throws `WCancellationException`; for execution
  without UI use `WAsync.tryRun` / `WAsync.run`; use `WAsync.settle` for independent sections so
  every result survives; replace one block locally with `WAsyncController.replaceData`; paginate
  with `WAsyncPagedController` and render the footer from `snapshot.footerStatus`
  (hidden / loading / failed / noMore / loadMore), write `snapshot.loadMoreError` on failure, and
  rebuild via `AnimatedBuilder(animation: c.snapshot)`; default loading / empty / error views carry
  `liveRegion`, keep semantics in custom builders.
  `WAsyncView`'s `state` is a `ValueListenable`, not `Rx`: keep the outer `Obx`; deleting it
  compiles, but other Rx state stops rebuilding.
