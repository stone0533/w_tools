# w_tools_async_ui 反馈

## 待处理

（暂无）

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
| 2026-11-20 | `reloadRequests` 递增与 `autoLoadThreshold` 自动加载竞争：刷新前先发旧页码，且可能重复请求 page1 | ✅ 2.1.1：立即刷新 + 抑制 indicator 回调，去掉 1 秒 fallback；刷新期间挂起 auto-load；回归测试见 `packages/async_ui/test/paged_list_reload_test.dart` |
| 2026-11-19 | `WAsyncPagedList` 程序化带动画刷新只能靠业务持有 `RefreshController` | ✅ 2.0.0：新增 `reloadRequests` / `RefreshIndicator` 刷新壳；业务不再需要 `RefreshController` |
| 2026-11-19 | 并发重载时旧刷新提前收起 header，新刷新无反馈 | ✅ 2.0.0：refresh generation gate，最新请求完成后才收尾 |
| 2026-11-19 | `pull_to_refresh` 在布局期 `enterLoading` 抛 `Build scheduled during frame` | ✅ 2.0.0：移除 `pull_to_refresh`；改用 `RefreshIndicator` + post-frame 自动加载 |
| 2026-11-19 | 标准分页壳下拉头没有颜色 / 背景入口 | ✅ 2.0.0（部分）：`WAsyncRefreshIndicatorStyle` 支持颜色 / 背景 / 线宽 / 位移 / 触发模式；完成失败文案仍需 `WAsyncPagedSliver` 自建壳 |
