## Unreleased

### Added
- 首发前补齐 README / example smoke test / widget tests；发布时折叠进 0.1.0。

## 0.1.0

### Added
- 新增 `WAsyncSection`：业务页面单区块四态入口，默认把失败重试接到
  `WAsyncController.load`。
- 新增 `WAsyncPagedList`：标准分页列表，内部处理 SmartRefresher、刷新 generation、
  上拉加载、footer 状态与重试。
- 新增 `WAsyncPagedSliver`：自定义滚动壳里的分页内容。
- 新增 `WAsyncPagedStrings`：分页 footer 文案。
