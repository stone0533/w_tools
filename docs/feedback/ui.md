# w_tools_ui 反馈

## 待处理

（暂无）

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
| 2026-11-23 | WNavBar 默认项高 42（<48），底部导航点击区域偏小 | ✅ 14.1.0：新增 `minItemHeight`（默认 48），点击项撑满 |
| 2026-11-23 | WButton 设了 semanticLabel 时 loading 的 liveRegion 被排除 | ✅ 14.1.0：loading 文案并入无障碍 label 与 liveRegion，分隔符按 locale |
| 2026-11-23 | WButton 同时传 tooltip 和 onLongPress 时长按只显示后者 | ✅ 14.1.0：长按同时触发回调并显示 tooltip |
