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
