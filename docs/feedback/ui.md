# w_tools_ui 反馈

## 待处理

（暂无）

## 已确认

### [已确认] ui: WImage 构建期收到 loading 通知会 setState during build（真机首帧抛断言）

- 包/版本：w_tools_ui 12.0.0
- 环境：macOS 15.x / Flutter 3.44.9 / Dart 3.12.2 / iPhone 17 模拟器（iOS 26.2）
- 命令 / 输入：`flutter run -t tool/main_preview.dart --dart-define=PREVIEW_PAGE=wallet`
  （页面首帧渲染 `WImage(source: WImageSource.network(...))`）
- 期望：首帧渲染不产生 framework 异常
- 实际：debug 下抛 `setState() or markNeedsBuild() called during build`，堆栈落在
  `_WImageState._scheduleRebuild` / `WImageLoader.markLoading`；页面仍能渲染
- 影响：预览 / 像素对比每次首帧刷一条异常，排查真问题时要先排除它；widget test 里
  `takeException()` 为 null，只有真机 / `flutter run` 首帧复现
- 建议：`markLoading` 的 `notifyListeners` 不要在 build 期同步 `setState`；
  `_scheduleRebuild` 判断 `schedulerPhase`，build 期只记 pending，帧后再 setState
- 复现数据：`packages/ui/lib/src/components/image/image_state.dart` 的
  `_handleLoadStateChanged` / `_scheduleRebuild`；调用链
  `WImageLoader._notify` → `markLoading` → `_WImageState`；本仓库 `tool/main_preview.dart`
  + `PREVIEW_PAGE=wallet`
- 关联 issue：#284
- 状态变更：2026-11-25 已确认 → #284

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
| 2026-11-23 | WNavBar 默认项高 42（<48），底部导航点击区域偏小 | ✅ 14.1.0：新增 `minItemHeight`（默认 48），点击项撑满 |
| 2026-11-23 | WButton 设了 semanticLabel 时 loading 的 liveRegion 被排除 | ✅ 14.1.0：loading 文案并入无障碍 label 与 liveRegion，分隔符按 locale |
| 2026-11-23 | WButton 同时传 tooltip 和 onLongPress 时长按只显示后者 | ✅ 14.1.0：长按同时触发回调并显示 tooltip |
| 2026-11-25 | `WListViewSliver.overlap` 最后一项的绘制溢出区域收不到点击（卡片底部点不动） | ✅ 14.1.1：最后一项按自然高度布局，命中盒 = 视觉盒；`itemExtent` 文档明确为视觉高度 |
