# w_tools_async_ui 反馈

## 待处理




### [待处理] async_ui: WAsyncPagedList：程序化「带动画的刷新」没有公开入口，业务只能持有 RefreshController

- 包/版本：w_tools_async_ui 1.1.0（配套 w_tools_async 7.4.0），以 pubspec.lock 为准
- 环境：Flutter 3.44.9 / Dart 3.12.2 / macOS 宿主；目标设备 Android 14 · Pixel 5（1080×2340，Adreno 620）；iOS 未验证
- 命令 / 输入：`WAsyncPagedList(controller: gifts, refreshController: _rc, itemBuilder: buildItem)` + 换筛选时 `if (_rc.isRefresh) { gifts.refresh(); } else { _rc.requestRefresh(); }`（完整片段见下）

  ```dart
  final _rc = RefreshController();                      // 页面持有
  final gifts = WAsyncPagedController<Gift>(loadPage);  // 数据层

  WAsyncPagedList(controller: gifts, refreshController: _rc, itemBuilder: buildItem);

  // 业务侧：换筛选后想「带动画」重载
  void onFilterChanged() {
    if (_rc.isRefresh) {
      gifts.refresh();       // requestRefresh() 在 isRefresh 时会被 pull_to_refresh 直接 return 吞掉
    } else {
      _rc.requestRefresh();  // 又必须持有 controller 才能拿到动画
    }
  }
  ```

- 期望：`WAsyncPagedList` 提供程序化刷新的一等入口：业务只表达「我要重载」，库内部在 header 空闲时 `requestRefresh()`（保留「刷新中 → 完成」动画）、header 已在转时直接 `controller.refresh()`（不吞请求），业务不需要持有 `RefreshController`
- 实际：唯一的程序化入口就是 `refreshController` 参数本身（注释写明「传入后可以 `requestRefresh()` 触发带动画的下拉刷新」），即「带动画的刷新」与「持有 RefreshController」被绑定成同一件事；同一个类里 `footer` 的注释又写「不要依赖内部 `RefreshController`」，两段说明互相抵消；库内部其实已在做同样的桥接（`onRetry: () => _refreshController.requestRefresh()`），说明需求通用但未对外暴露；且 `requestRefresh()` 断言 `position != null`，页面未挂载 / 已 detach 时调用会直接抛 `Try not to call requestRefresh() before build,please call after the ui was rendered`
- 影响：本项目 4 个分页列表页长出了 4 种 RefreshController 归属（controller 自持并自调 refreshCompleted/refreshFailed、页面持有+controller attach/detach 借用、每 tab 一个、controller 自持且 initialRefresh:true）；同一段 isRefresh 桥接在 3 个 controller 里各复制一份；为绕「controller 不能脱离 widget 生命周期」还写了兜底实例，且曾用 initialRefresh:true 造成「读一次 isRefresh 就多发一次无人收尾的首屏刷新」的隐性 bug；每接一个新列表页都要重新决策归属，属于持续性绕路成本
- 建议：新增可选参数 `ValueListenable<int>? reloadRequests`（每次递增触发一次），内部 `_onReloadRequested()` 吸收 isRefresh 分支（在转则 `controller.refresh()`，空闲则 `requestRefresh()`），`didUpdateWidget` 里换监听；`refreshController` 在文档里降级为「仅自定义 header/footer 联动等高级用例」，并注明程序化刷新请用 reloadRequests；footer 重试维持现有正解（监听 snapshot 后调 controller.loadMore()）；如需彻底封口可对 refreshController 标 @Deprecated 过渡一个版本
- 复现数据：业务侧调用点 `lib/app/modules/mCardExchange/controllers/m_card_exchange_controller.dart:237-252`（`_reloadNow()` 里的 isRefresh 分支，同样是 3 份复制之一）；最小 demo 即上面「命令 / 输入」那段——一个 WAsyncPagedList + 一个「换筛选」按钮，去掉 `refreshController` 后 `gifts.refresh()` 无任何 header 动画，要动画只能把控件借到业务层。旁证（非库缺陷）：本项目连点筛选时真机日志两行原文 `DioException [request cancelled]: The request was manually cancelled by the user.` 与 `Error: superseded by a newer refresh`，一次操作 19 次 gift/list、17 次被 cancel
- 状态变更：2026-11-18 待处理

### [待处理] async_ui: 程序化重载撞上进行中的刷新时，刷新头被提前收起，新刷新全程无反馈

- 包/版本：w_tools_async_ui 1.2.0（配套 w_tools_async 7.4.0），以 pubspec.lock 为准
- 环境：Flutter 3.44.9 / Dart 3.12.2 / macOS 宿主；Android 14 · Pixel 5；UAT 接口（同一接口单次耗时实测 1.8s ~ 42s）
- 命令 / 输入：连续两次递增同一个 reloadRequests 通道，间隔小于一次请求耗时：`c.reloadRequests.value++` 生效后（header 已在 refreshing）再 `c.reloadRequests.value++`，等价于「点一下筛选，再点一下取消」
- 期望：第二次重载也应该有可见的刷新反馈 —— header 继续保持 refreshing，或至少给出另一种可见的 loading 状态，让用户知道「数据在重取」
- 实际：第二次重载全程没有任何可见反馈。header 被**上一次**刷新的收尾提前收起，而新的刷新因为走了「已经在刷新 → 直接 controller.refresh()」分支，从未撑开 header；界面只剩下筛选 chip 的选中态变化，列表在等待期间保持上一次的数据
- 影响：本项目真机演示时被误判成「取消选中后没有重新获取列表数据」（实际请求已发出，参数也正确）。UAT 慢的时候（实测单次 42s）用户会认为界面卡死；因为没有任何进度提示，只能靠再点一次或者下拉刷新来确认。这是 1.2.0 新通道在「并发重载」场景下的反馈空洞，会让业务方怀疑通道没生效
- 建议：`_onRefresh` 收尾前判断数据是否还在加载（例如 `controller.state.value.isLoading` / `controller.snapshot.value`），仍在加载就不要 `refreshCompleted()`，等状态落定再收；或者让 `_onReloadRequested` 走 `controller.refresh()` 分支时也维持一个「刷新中」标记，由 state 落定后统一收尾。两种改法都不需要业务方持有 RefreshController
- 复现数据：库侧位置 `lib/src/paged_list.dart:132-142`（`_onRefresh` 用 `_refreshId` 判断收尾）与 `lib/src/paged_list.dart:101-108`（`_onReloadRequested` 在 `isRefresh` 时直接 `controller.refresh()`，不递增 `_refreshId`）。真机时间线（Pixel 5，debug 包）：第一次点击 → 20:45:36.040 请求 `"merchant": "MCD"`；第二次点击 → 20:45:48.068 旧请求被取消（`Error: superseded by a newer refresh`）+ 20:45:48.076 新请求 `"merchant": null`；20:45:49.909 响应 200。截图证据：第一次刷新期间 header 转圈可见（点击后 12s 抓帧），第二次点击后 1s / 3s / 7s 三帧均无 header、列表仍显示旧数据
- 状态变更：2026-11-18 待处理

### [待处理] async_ui: WAsyncPagedList：底层 pull_to_refresh 在布局期 enterLoading，debug 抛 Build scheduled during frame

- 包/版本：w_tools_async_ui 1.2.0（配套 w_tools_async 7.4.0，底层依赖 pull_to_refresh 2.0.0），以 pubspec.lock 为准
- 环境：Flutter 3.44.9 / Dart 3.12.2 / macOS 宿主；Android 14 · Pixel 5（1080×2340）；debug 构建（该断言仅 debug 生效）
- 命令 / 输入：使用 `WAsyncPagedList` 的两个常规操作之一：①上拉加载下一页（手指仍在拖拽时内容追加）；②列表在惯性滚动或拖拽中点击筛选 chip，经 `reloadRequests` 触发库内部的 `requestRefresh()`（其实现会 `setCanDrag(false)` 再 `setCanDrag(true)`）
- 期望：包装层应吸收底层 `pull_to_refresh` 在布局期 `setState` 的已知缺陷；或给 `WAsyncPagedList` 暴露 `enablePullUp` / 自动加载阈值，让业务用滚动位置驱动加载，不必自己搭 `WAsyncPagedSliver` 重写一套分页壳
- 实际：debug 下抛框架断言 `Build scheduled during frame`，栈为 `LoadIndicatorState.enterLoading` → `LoadIndicatorState._listenScrollEnd` → `isScrollingNotifier` 通知 → `ScrollPosition.beginActivity` → `goBallistic` → 拖拽被 `cancel` → `ScrollableState.setCanDrag` → `applyNewDimensions` → `RenderViewport.performLayout`。即：布局过程中 `setCanDrag` 取消了正在进行的拖拽，滚动状态变为「停止」并通知 footer，footer 判定可加载后直接 `setState`
- 影响：debug 控制台被这条断言刷屏，画面出现半帧/滞后，干扰业务问题定位（本项目一度把它造成的异常画面误判成「列表没刷新」「错误条上边框丢失」）；想避开只能改用 `WAsyncPagedSliver` + 自建 `SmartRefresher`，等于每个项目重抄一遍分页壳
- 建议：①把 footer 的 `enterLoading` 触发改为经 `SchedulerBinding.addPostFrameCallback` 调度（由包装层吸收，或 fork 后修）；②给 `WAsyncPagedList` 增加 `enablePullUp: false` 与 `autoLoadThreshold` 两个开关，关闭 pull-up 后改用滚动位置自动加载；③若短期不修，至少在 README 记录该断言与触发条件，避免使用方反复排查
- 复现数据：真机 Pixel 5 debug 包，栈关键帧原文 `#5 LoadIndicatorState.enterLoading (package:pull_to_refresh/src/internals/indicator_wrap.dart:364:5)`、`#6 LoadIndicatorState._listenScrollEnd (package:pull_to_refresh/src/internals/indicator_wrap.dart:507:51)`、`#16 ScrollPositionWithSingleContext.applyNewDimensions`、`#18 RenderViewport.performLayout`、`#19 RenderObject._layoutWithoutResize`；源码依据 `indicator_wrap.dart:360-362` 内 `enterLoading()` 首行即 `setState(() { floating = true; })`，`_listenScrollEnd` 在 `_checkIfCanLoading()` 为真时直接调用它
- 状态变更：2026-11-18 待处理

### [待处理] async_ui: WAsyncPagedList：标准壳的下拉头没有配色/文案入口，接入方只能接受 Material 默认样式

- 包/版本：w_tools_async_ui 2.0.0（配套 w_tools_async 8.0.0），以 pubspec.lock 为准
- 环境：Flutter 3.44.9 / Dart 3.12.2 / macOS 宿主；Android 14 · Pixel 5（1080×2340）
- 命令 / 输入：任意页面直接用 2.0 标准壳 `WAsyncPagedList(controller: gifts, itemBuilder: buildItem)`，做下拉刷新；本项目为「找優惠」「優惠券」「分店」三个列表页
- 期望：标准壳能配置下拉刷新头的**颜色**（品牌绿）与**文案/外观**，或至少允许通过 `WAsyncTheme` 统一定制；这样接入方升级到 2.0 后不必为了视觉回退而自建壳
- 实际：标准壳内部固定 `return RefreshIndicator(key: _refreshKey, onRefresh: _onRefresh, child: ...)`，没有 `color` / `backgroundColor` / `displacement` 等参数，也没有 builder 入口。由于本项目未自定义 `colorScheme`，下拉头呈现 Material 默认色（偏紫），同时失去了原来自定义头上「刷新完成」「刷新失敗，請稍後重試」的中文文案
- 影响：从 1.x 升级到 2.0 的项目要么接受与设计稿不符的紫色 spinner 和缺失的中文文案，要么退回 `WAsyncPagedSliver` + 自建 `SmartRefresher` 壳——后者等于放弃 2.0 的分页能力，并把刚被 2.0 移除的 `pull_to_refresh` 重新引回来。本项目为此专门保留了一套品牌绿刷新头（`lib/app/ui/app_refresh_header.dart`，注释里写明了规避 Material 默认紫的原因），升级后这套配置失去落点
- 建议：①`WAsyncPagedList` 增加 `refreshIndicatorColor`（默认取 `Theme.of(context).colorScheme.primary`）；②增加 `refreshIndicatorBuilder` 或 `WAsyncTheme.refreshIndicator`，允许完全自定义头（含完成/失败文案）；③若短期不加参数，请在 README 明确写「标准壳的下拉头是 Material `RefreshIndicator`，需要品牌色/文案时请用 `WAsyncPagedSliver` 自建壳」，避免接入方升级后才发现视觉回退
- 复现数据：库侧位置 `packages/async_ui/lib/src/paged_list.dart` 的 `build()` 中 `return RefreshIndicator(key: _refreshKey, onRefresh: _onRefresh, child: NotificationListener<ScrollNotification>)`，构造参数里没有任何样式入口；本项目参考位置 `lib/app/ui/app_refresh_header.dart` 顶部注释「WaterDropHeader 的默认 refresh 在 iOS 是灰色 Cupertino、Android 是 Material primary（本项目未自定义 colorScheme，实际是默认紫）」以及 `appPagedRefreshHeader` 的品牌绿实现
- 状态变更：2026-11-19 待处理

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
