# w_tools_ui 反馈

## 待处理

（暂无）

## 已确认

（暂无）

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
| 2026-11-23 | WNavBar 默认项高 42（<48），底部导航点击区域偏小 | ✅ 14.1.0：新增 `minItemHeight`（默认 48），点击项撑满 |
| 2026-11-23 | WButton 设了 semanticLabel 时 loading 的 liveRegion 被排除 | ✅ 14.1.0：loading 文案并入无障碍 label 与 liveRegion，分隔符按 locale |
| 2026-11-23 | WButton 同时传 tooltip 和 onLongPress 时长按只显示后者 | ✅ 14.1.0：长按同时触发回调并显示 tooltip |
| 2026-11-25 | `WListViewSliver.overlap` 最后一项的绘制溢出区域收不到点击（卡片底部点不动） | ✅ 14.1.1：最后一项按自然高度布局，命中盒 = 视觉盒；`itemExtent` 文档明确为视觉高度 |
| 2026-11-25 | ui 14.1.1 overlap 最后一项顶部被上一项溢出盖住（`SliverMainAxisGroup` 倒序绘制） | ✅ 14.1.2：最后一个固定项 `OverflowBox` 裁到命中盒；像素取样回归测试 |
| 2026-11-25 | `WImage` 构建期收到 loading 通知会 setState during build（12.0.0 报告） | ✅ 14.1.1：回归测试确认 build 期 `markLoading` 走 post-frame（14.1.0 起已有 guard） |
