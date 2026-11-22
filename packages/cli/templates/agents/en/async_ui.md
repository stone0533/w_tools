- **Async entries** (`explain WAsyncSection` / `explain WAsyncPagedList`): use
  `WAsyncSection` / `WAsyncPagedList` for blocks / paging; `WAsyncPagedSliver` for custom
  refresh/scroll; `list --tier=app`. Don't maintain `hasLoadedMorePage`; footer reads
  `snapshot.footerStatus` (footer copy incl. noMore / loadMore uses `WAsyncTheme.strings`;
  `footerBuilder` overrides). `scrollableStates` only for bounded bodies; `resetScrollOnReload`
  defaults to top; `headerSlivers` / `sliverPadding` support headers and padding.
  `WAsyncView`/`WAsyncStateSliver` are library/design-system.
