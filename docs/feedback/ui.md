# w_tools_ui 反馈

## 待处理

（暂无）

## 已确认

### [已确认] ui: ui 14.1.1：WListViewSliver.overlap 最后一项被上一项溢出盖住（SliverMainAxisGroup 倒序绘制）

- 包/版本：w_tools_ui 14.1.1（本地检出 + pub 同源），Flutter 3.44.9
- 环境：Android 真机（Pixel 5，dpr 2.75）与 flutter_tester 都能复现；项目 ureward_member_app
- 命令 / 输入：
  ```dart
  WListViewSliver.overlap(
    itemExtent: 200,
    overlap: 60,
    itemCount: 3,
    itemBuilder: (_, i) => GestureDetector(          // 每项纯色、高 200
      behavior: HitTestBehavior.opaque,
      onTap: () => taps.add(i + 1),
      child: Container(height: 200, color: colors[i]),
    ),
  )
  ```
- 期望：重叠区（后一项顶部 60）露出**后一项**；三项都一样。
- 实际：前两项正确，**最后一项的顶部被上一项的溢出盖住**（像素取样：item2 顶部 #00ff00 ✓、item3 顶部 #00ff00 ✗ 期望 #0000ff、item3 中段 #0000ff ✓）。点击归属正常（item2 顶部点中 2、item3 顶部点中 3）。
- 原因：`_buildOverlapSlivers` 把最后一项放进独立的 `SliverToBoxAdapter`，而 `SliverMainAxisGroup.paint` 从 `lastChild` **倒序**绘制（`rendering/sliver_group.dart`），于是先画最后一项、再画前面的固定 sliver；固定 sliver 里每项溢出行高（200 in 140）的那 60 会盖住最后一项顶部。14.1.1 之前所有项都在同一个 `SliverFixedExtentList` 里按顺序绘制，没有这个问题 —— 是「最后一项命中盒 = 视觉盒」那次改动的回归。
- 影响：所有 `itemExtent < item 实际高度` 的叠卡列表，最后一项顶部的内容（标题条 / 白条 / 按钮）被上一项盖住。本项目会员卡页就是最后一张卡的白条（商家名 + 钱包余额）看不见。
- 建议：`_buildFixedOverlapSliver` 里给每个 item 包 `ClipRect`（溢出的那截本来就被下一项遮住，视觉无损，最后一项也就不会被盖）；或把最后一项与其它项放进同一个 sliver（最后一行高 = itemExtent），保证绘制顺序与命中盒都对。
- 复现数据：项目仓库 `test/component/w_list_overlap_test.dart`（纯色 + 像素取样，`flutter test test/component/w_list_overlap_test.dart`；最后一项用例目前 `skip: true`，去掉 skip 即红）。
- 关联 issue：#416
- 状态变更：2026-11-25 已确认 → #416


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
