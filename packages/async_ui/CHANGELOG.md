# Changelog

## 2.1.0

### Changed
- `w_tools_async` 最低版本抬到 `>=8.1.0 <9.0.0`，标准 footer 的 noMore 使用
  `WAsyncTheme.strings.noMore`。

### Fixed
- `reloadRequests` 在 `RefreshIndicator` 收尾动画期间不会丢刷新请求，也不会卡住刷新状态。
- `autoLoadThreshold` 增加非负数断言。

## 2.0.0

### Breaking
- `WAsyncPagedList.new` 构造参数变化：删除 `refreshController`、`header`、`footer`，
  新增 `reloadRequests` / `autoLoadThreshold` / `footerBuilder`。
  不再依赖 `pull_to_refresh` / `SmartRefresher` / `RefreshController`。
- 下拉刷新改用 Flutter `RefreshIndicator`；自定义下拉头 / 上拉 footer
  改用 `WAsyncPagedSliver` + 自己的滚动壳。

### Added
- `WAsyncPagedList.reloadRequests`：程序化刷新，不需要外部 controller。
- `WAsyncPagedList.autoLoadThreshold`：滚动接近底部时自动 `loadMore`。
- `WAsyncPagedList.footerBuilder`：自定义底部状态展示；默认展示 loading /
  失败重试 / 没有更多。
- `WAsyncPagedList.refreshIndicatorStyle` / `WAsyncRefreshIndicatorStyle`：
  配置标准 `RefreshIndicator` 的颜色、背景、线宽、位移和触发模式。
- 内置 footer 展示 `WAsyncPagedSnapshot.footerStatus`，失败可点击重试。

### Changed
- `w_tools_async` 兼容范围 `>=7.4.0 <9.0.0`。
- 上拉加载改为滚动阈值自动触发；不再有 pull-up footer 手势。
- 程序化刷新与并发刷新统一走 `RefreshIndicator` 和 generation gate。

### Fixed
- `reloadRequests` 在刷新进行中再次触发时，旧请求不会提前收起刷新状态；
  最新请求完成后才结束。

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
