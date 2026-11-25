# w_tools_ui 反馈

## 待处理

（暂无）

## 已确认

### [已确认] ui: WListViewSliver.overlap：最后一项的绘制溢出区域收不到点击（卡片底部点不动）

- 包/版本：w_tools_ui 14.1.0（本地检出 `packages/ui`，pub 14.1.0 同源）
- 环境：Flutter 3.44.9 / Dart 3.12.2、macOS 26；`flutter_tester` 下即可复现（纯布局问题，iOS / Android 表现一致）；项目 ureward_member_app
- 命令 / 输入：最小复现（widget test，`itemExtent=100`、`overlap=40`，布局步长 60、卡片视觉高 140）
  ```dart
  var taps = 0;
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: CustomScrollView(slivers: [
    WListViewSliver.overlap(
      itemExtent: 100,
      overlap: 40,
      itemCount: 1,
      itemBuilder: (context, i) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => taps++,
        child: Container(height: 140, color: Colors.red),
      ),
    ),
  ]))));
  await tester.tapAt(const Offset(200, 20));   // 布局盒内 → 命中 ✅
  await tester.tapAt(const Offset(200, 100));  // 视觉内、布局盒外 → 不命中 ❌
  ```
- 期望：叠卡列表（`WListViewSliver.overlap`）里每一项**完整的视觉高度**都能收到点击，至少最后一项不能有点不动的区域。
- 实际：`overlap` 分支用 `SliverFixedExtentList(itemExtent: itemExtent - overlap)` 把每项布局成 `itemExtent - overlap` 高（上面例子 60），再套 `OverflowBox(maxHeight: infinity)` 让卡片溢出绘制。Flutter 的 `RenderBox.hitTest` 先判 `size.contains(position)`，**溢出到布局盒外的部分收不到任何命中**。非最后一项的溢出区恰好被下一项的盒子/画面盖住（点下去打开的是下一张，掩盖了问题），只有**最后一项的底部是死区**。
- 影响（我因此做错了什么 / 多花了什么）：真机上「会员卡列表最后一张卡底部（红框约 80pt）点了没反应」，用户会以为卡片坏了；排查时先怀疑 `toPressable` 手势被覆盖 / 图片吞手势，实际是布局盒裁剪，写最小 test 才确认。任何用 `overlap > 0` 的列表都会带这个死区，只是通常被下一张卡遮住。
- 建议：让**命中盒 = 视觉盒**。成本最低的做法：把**最后一项**从 `SliverFixedExtentList` 里拆出来，用单独的 `SliverToBoxAdapter`（或额外 sliver）按完整高度布局，其余项维持固定行高 + OverflowBox —— 末尾本来就追加了 `SizedBox(height: overlap)` 占位，把这段计入最后一项即可，滚动几何不变。更彻底的做法是自定义 RenderSliver（子项按自然高度布局、滚动步长减 overlap）。另外建议在文档里写清：`itemExtent - overlap` 是**命中盒高度**，不是卡片视觉高度；卡片若比它高，底部就会变成不可点区域。
- 复现数据：
  - 最小 test：`tapAt(200, 100)` 断言失败（期望 `taps == 2`，实际 1）；`tapAt(200, 20)` 正常。
  - 真实场景（本项目）：`lib/app/modules/mCard/component/member_card_sliver.dart` 用 `WListViewSliver.overlap(itemExtent: 230.w, overlap: 80.w)`；卡片是 `Container > Column(mainAxisSize.min) > Stack(WImage + Positioned(height: 59.w) header)`，图片没给 `WImageStyle.height`，高度由商户图宽高比决定（实测约 244.w），所以死区 = 244 − (230 − 80) ≈ 94pt。
  - 库实现位置：`packages/ui/lib/src/components/layout/list_view_sliver.dart` 的 `_WListViewKind.overlap` 分支（`SliverFixedExtentList` + `OverflowBox(maxHeight: double.infinity)`），以及 `build()` 里末尾的 `SliverToBoxAdapter(child: SizedBox(height: overlap))`。
  - 现象截图：会员卡列表最后一张「麥當勞」，红框（卡片底部约 80pt）点击无响应；同样的位置在非最后一张卡上会打开下一张卡。
- 关联 issue：#405
- 状态变更：2026-11-25 已确认 → #405

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
