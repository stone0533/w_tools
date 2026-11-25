# w_tools_app 反馈

## 待处理

（暂无）

## 已确认

（暂无）

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
| 2026-11-25 | `WAppPlugin` 没有首帧钩子，文档却写了 `onLazyInit`；插件无 timeout / critical | ✅ 4.1.0：新增 `onFirstFrame` / `timeout` / `critical`，失败抛 `WAppPluginInitException`；生命周期文档拆 App 级 / 插件级 |
