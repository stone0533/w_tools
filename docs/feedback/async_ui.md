# w_tools_async_ui 反馈

## 待处理

（暂无）

## 已确认

### [已确认] async_ui：空结果后再切筛选，WAsyncPagedList 同时显示下拉圈 + 居中 loading（两个加载提示）

- 包/版本：w_tools_async_ui 2.3.0（配套 w_tools_async 8.2.0），Flutter 3.44.9 / Dart 3.12.2
- 环境：Android 真机（Pixel 5，1080×2340，dpr 2.75，Impeller）+ flutter_test 状态探针；项目 ureward_member_app
- 命令 / 输入：
  1. 「找優惠」页 = `WAsyncPagedList<Gift>` + 顶部商家筛选（`reloadRequests` 驱动）；
  2. 先点 Demo Merchant（该品牌没有礼品 → 空结果）；
  3. 再点 Franco@sampras.hk。
- 期望：列表区域只有一个加载提示。
- 实际：**两个**加载提示同时出现 —— 列表顶部一个 `RefreshIndicator`，列表中间一个 `appLoadingIndicator`（`CircularProgressIndicator`）。
- 原因：
  - `WAsyncPagedList._onReloadRequested()`（packages/async_ui/lib/src/paged_list.dart）对程序化重载**无条件** `_refreshKey.currentState?.show()`；
  - 而 `WAsyncPagedController.refresh()`（packages/async/lib/src/state/async_paged_controller.dart）在当前 `data == null`（empty / 首屏还没回来）时把状态置为 `WAsyncState.loading(previousData: null)`；
  - `WAsyncStateSliver` 只有 `data != null` 才保留内容，否则渲染 `views.loading` → 又出现一个居中 loading。
- 证据（状态探针，flutter_test）：
  ```dart
  final c = WAsyncPagedController.list<String>((page, token) async => <String>[]);
  await c.refresh();               // 空结果
  // c.state.value == WAsyncState(status: empty, hasData: false)
  final f = c.refresh();           // 模拟再切筛选
  // c.state.value == WAsyncState(status: loading, hasData: false, isRefreshing: false)
  ```
  `isRefreshing == false` 说明不是「保留旧数据的刷新」，`WAsyncStateSliver` 必然走 loading 视图；此时 refresh indicator 也在转 → 两个圈。
- 影响：所有「筛到空结果后再切筛选」或「首屏未回就切筛选」的分页列表；我们三个页面（找優惠、優惠券、分店）共用同一套商家筛选条，三个页面都会出现；用户会误以为重复加载 / 卡住。
- 建议（二选一，倾向 1）：
  1. `_onReloadRequested()` 里当 `controller.state.value.data == null` 时不 `show()`，直接 `refresh()` —— 下拉头只用于「刷新已有内容」，没有内容时让居中 loading 承担反馈；
  2. 或反过来：没有数据时只保留下拉头、不渲染居中 loading（但空页面上边缘小圈反馈更弱）。
  另建议补一个 widget 回归测试：empty 状态 `reloadRequests++` 后，屏幕上加载指示器数量应为 1。
- 复现数据：上面的状态探针；项目侧可落成 `test/component/paged_list_empty_reload_test.dart`（需要的话我可以补上）。
- 状态变更：2026-11-25 待处理
- 状态变更：2026-11-25 已确认 → #422（两条路径都要收：程序化 reload + 空态手动下拉）

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
| 2026-11-23 | WAsyncSection 空态 / 失败态不可滚动，外层 RefreshIndicator 失效 | ✅ 2.3.0：新增 `scrollableStates` |
| 2026-11-23 | 程序化 reload 后不回到顶部 | ✅ 2.2.0 / 2.3.0：新增 `resetScrollOnReload` |
| 2026-11-23 | 标准 footer 失败无文案，loadMore 无手动入口 | ✅ 2.3.0：failed 文案 + 重试；null 显示加载更多 |
| 2026-11-23 | 标准分页壳没有 headerSlivers / sliverPadding | ✅ 2.3.0：新增两个参数 |
| 2026-11-23 | 刷新在飞时第二次 reload 不回顶 | ✅ 2.3.0：jumpTo 前移 |
| 2026-11-23 | resetScrollOnReload 未写进 README | ✅ 2.3.0：README / agents 已补 |
