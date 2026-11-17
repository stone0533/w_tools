- **Async entries** (`explain WAsyncSection` / `explain WAsyncPagedList`): use
  `WAsyncSection` / `WAsyncPagedList` for blocks / paging; `WAsyncPagedSliver` for custom scroll;
  `list --tier=app`. Don't maintain `hasLoadedMorePage`; footer reads `snapshot.footerStatus`.
  `WAsyncView`/`WAsyncStateSliver` are library/design-system.
