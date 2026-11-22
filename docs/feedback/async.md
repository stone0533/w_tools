# w_tools_async 反馈

## 待处理

（暂无）

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
| 2026-11-23 | 末页返回空数组时 footer 变 hidden，不显示 noMore | ✅ 8.2.0：空页 loadMore → noMore；首屏空仍 hidden |
| 2026-11-23 | WAsyncHooks 无法只关闭 onError | ✅ 8.2.0：新增 `WAsyncExecutor.disableOnError` |
| 2026-11-23 | WAsyncState / Controller 区分不了首屏与重试 loading | ✅ 8.2.0：新增 `WAsyncController.isRetrying` |
| 2026-11-23 | README 主要 API 表格被 settle 弃用说明截断 | ✅ 8.1.2 / 8.2.0：说明移到表后 |
| 2026-11-23 | 到末页后刷新失败，noMore 回退成 hidden | ✅ 8.1.3 / 8.2.0：刷新失败保留 `_hasLoadedMore` |
| 2026-11-23 | replaceData 后非空完整列表 noMore 回退成 hidden | ✅ 8.2.0：非空完整列表保持 noMore |
| 2026-11-23 | isRetrying 在 isEmpty 抛错后残留 true | ✅ 8.2.0：异常分支复位 |
| 2026-11-23 | disableOnError / WAsyncView.scrollableStates / loadMore 未进 README | ✅ 8.2.0：README / catalog / agents 已补 |
| 2026-11-23 | scrollableStates 在无界高度里吞外层手势 | ✅ 8.2.0：无界高度直接交回外层 |
