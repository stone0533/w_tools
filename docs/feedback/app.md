# w_tools_app 反馈

## 待处理

（暂无）

## 已确认

（暂无）

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
| 2026-11-25 | `WAppPlugin` 没有首帧钩子，文档却写了 `onLazyInit`；插件无 timeout / critical | ✅ 4.1.0：新增 `onFirstFrame` / `timeout` / `critical`，失败抛 `WAppPluginInitException`；生命周期文档拆 App 级 / 插件级 |
| 2026-11-25 | app 4.1 文档示例 `onFirstFrame` 里 remove 原生闪屏，post-frame 阶段 `allowFirstFrame` 不再排帧，静态首屏停在闪屏 | ✅ 4.1.1：`WAppPluginRunner.firstFrame` 在所有 hook 后补排一帧；`deferFirstFrame` + post-frame 回归测试 |
