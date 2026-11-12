- **Async blocks** (`explain WAsyncPagedController`): `WAsyncController` + `WAsyncView`;
  `WAsyncStateBuilder` for scroll pages, `WAsyncStateSliver` for slivers; `WAsyncStatus` /
  `WAsyncStrings` come from `WAsyncTheme` (at the app root); branch on `WAsyncSuccess` /
  `WAsyncFailure` / `WAsyncCancelled`, cancellation throws `WCancellationException`; for execution
  without UI use `WAsync.tryRun` / `WAsync.run`; use `WAsync.settle` for independent sections so
  every result survives; replace one block locally with `WAsyncController.replaceData`; paginate
  with `WAsyncPagedController` and write `loadMoreError` on failure; render the paged footer from
  `footerStatus` (hidden / loading / failed / noMore / loadMore) and rebuild via `changes`.
  `WAsync`'s `state` is a `ValueListenable`, not `Rx`: after switching to `WAsyncStateBuilder` the
  outer `Obx` still has to wrap it; deleting it compiles, but other Rx state stops rebuilding.
