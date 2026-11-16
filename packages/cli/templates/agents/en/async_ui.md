- **Async entries** (`explain WAsyncSection` / `explain WAsyncPagedList`): use
  `WAsyncSection` / `WAsyncPagedList` for blocks / paging (SmartRefresher/footer); use `WAsyncPagedSliver` for custom scroll; `WAsyncPagedStrings` for footer.
  Don't maintain `hasLoadedMorePage`; footer reads `snapshot.footerStatus`.
  `WAsyncView`/`WAsyncStateSliver` are library/design-system.
