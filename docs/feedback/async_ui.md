# w_tools_async_ui 反馈

## 待处理

（暂无）

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
| 2026-11-23 | WAsyncSection 空态 / 失败态不可滚动，外层 RefreshIndicator 失效 | ✅ 2.3.0：新增 `scrollableStates` |
| 2026-11-23 | 程序化 reload 后不回到顶部 | ✅ 2.2.0 / 2.3.0：新增 `resetScrollOnReload` |
| 2026-11-23 | 标准 footer 失败无文案，loadMore 无手动入口 | ✅ 2.3.0：failed 文案 + 重试；null 显示加载更多 |
| 2026-11-23 | 标准分页壳没有 headerSlivers / sliverPadding | ✅ 2.3.0：新增两个参数 |
| 2026-11-23 | 刷新在飞时第二次 reload 不回顶 | ✅ 2.3.0：jumpTo 前移 |
| 2026-11-23 | resetScrollOnReload 未写进 README | ✅ 2.3.0：README / agents 已补 |
