## 1.1.0

### Added
- `WAsyncPagedSliver.onRetry`：自建 `SmartRefresher` 时可以把错误态重试接到
  `refreshController.requestRefresh()`，默认仍是 `controller.refresh()`。
- `WAsyncPagedList.refreshController`：可选注入 `RefreshController`，支持
  `requestRefresh()` 的 header 动画、`isRefresh`、`resetNoData()` 等；外部传入时由 app
  dispose，未传入时组件内部创建并 dispose。
- `WAsyncPagedList` 的错误态 Retry 改为 `refreshController.requestRefresh()`，
  标准壳的重试也走 header 动画。

## 1.0.0

### Breaking
- 删除 `WAsyncPagedStrings`；分页 footer 文案由 app 自己的 header/footer 维护。
- 删除 `WAsyncPagedFooter`；`WAsyncPagedList` 默认使用 `SmartRefresher` 自带 header/footer。
- 删除 `WAsyncPagedList.strings`；`WAsyncPagedList.new` 改为可选
  `WAsyncPagedList.header` / `footer`，原样转发给 `SmartRefresher`，app 可传
  `CustomHeader` / `CustomFooter` 自定义样式。
- 删除 `WAsyncPagedSliver.footer` / `WAsyncPagedSliver.strings`；`WAsyncPagedSliver.new`
  只保留四态、`emptyBuilder` 和标准列表；`WAsyncPagedSliver.itemBuilder` 改为可空字段，
  由默认构造保证非空；header / footer 由调用方自己的滚动壳负责。
- `WAsyncPagedSliver.ready` 改名为 `WAsyncPagedSliver.custom`；默认构造仍是标准列表。

## 0.2.0

### Added
- `WAsyncSection` 增加 `onRetry` 与 per-block `loadingBuilder` / `errorBuilder` /
  `errorBannerBuilder` / `refreshingBuilder`，设计稿口径区块不再需要项目再包一层。
- `WAsyncPagedSliver` 增加 `readySliverBuilder`（叠卡 / 自定义 sliver）与 `footer` 覆盖；
  `itemBuilder` 与 `readySliverBuilder` 二选一；传 `footer: SizedBox.shrink()` 可关闭内部 footer。

### Changed
- `WAsyncPagedList` 保持标准壳：不新增 header/footer 参数；需要自定义 header/footer 时用
  `WAsyncPagedSliver` + 自己的 `SmartRefresher`。

## 0.1.0

### Added
- 首发前补齐 README / example smoke test / widget tests。

- 新增 `WAsyncSection`：业务页面单区块四态入口，默认把失败重试接到
  `WAsyncController.load`。
- 新增 `WAsyncPagedList`：标准分页列表，内部处理 SmartRefresher、刷新 generation、
  上拉加载、footer 状态与重试。
- 新增 `WAsyncPagedSliver`：自定义滚动壳里的分页内容。
- 新增 `WAsyncPagedStrings`：分页 footer 文案。
