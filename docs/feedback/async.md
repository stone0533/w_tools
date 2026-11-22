# w_tools_async 反馈

## 待处理






### [待处理] async: WAsyncPagedController 末页返回空数组时 footer 变 hidden，不显示 noMore

- 包/版本：w_tools_async 8.1.1（经 w_tools_async_ui 2.1.1 的 `WAsyncPagedList` 复现）
- 环境：macOS 26.6.2 arm64 / Flutter 3.44.9（fvm）/ Dart 3.12.2 / flutter_test widget test
- 命令 / 输入：下面的 `WAsyncPagedController` 片段（末页返回空数组）。

```dart
final c = WAsyncPagedController<int>.list(
  (page, _) async => page == 1 ? const <int>[1, 2] : const <int>[],
);
await c.refresh();
await c.loadMore();
expect(c.snapshot.value.hasMore, isFalse);                 // 通过
expect(c.snapshot.value.footerStatus,
       WAsyncPagedFooterStatus.noMore);                    // 实际 hidden
```

- 期望：第 2 页请求返回空数组（page 型接口最常见的「到底」信号）后，footer 显示 noMore，用户知道没有更多了。
- 实际：`loadMore` 在 `items.isEmpty` 时只把 `_hasMore = false` 并 `_emit()`，不增加 `_page`；`_footerStatus` 要求 `_page > _initialPage + 1` 才返回 `noMore`（`packages/async/lib/src/state/async_paged_controller.dart:297-313`、`:367-379`）。第一页成功后 `_page = 2`，第 2 页空 → `_page` 仍是 2 → footer 直接 hidden，默认 footer 从「加载中」消失。
- 影响（我因此做错了什么 / 多花了什么）：用 `WAsyncPagedController.list`（没有 hasMore，只能靠空页判断结束）的列表，到底时没有任何提示，用户以为还没加载完；如果换成 `WAsyncPagedList`，默认 footer 会从转圈直接消失，业务只能自己维护「到底」标记。
- 建议：把「已请求过第 N 页」作为独立标记（请求前/后递增，或 `attemptedPage`），空页时返回 noMore；第一页空仍保持 hidden。补一条「末页空数组 → noMore」的回归测试。
- 复现数据：本地探针 `paged_list_test.dart` 的「末页返回空数组时应提示没有更多（常见分页接口）」用例；断言实际得到 `WAsyncPagedFooterStatus.hidden`。
- 验证（2026-11-22，8.1.2）：末页空数组 → noMore 已通过；首屏空仍 hidden；新增「到末页后刷新失败回退 hidden」见新条目。
- 验证（2026-11-23，8.2.0）：已修复；首屏空 hidden / 末页空 noMore / replaceData 空 hidden 均通过；replaceData 非空回退 noMore 另见新条目。
- 状态变更：2026-11-22 待处理

### [待处理] async: WAsyncHooks 没有声明式关闭 onError 的方式（只能 no-op 或另建 executor）

- 包/版本：w_tools_async 8.1.1
- 环境：macOS 26.6.2 arm64 / Flutter 3.44.9（fvm）/ Dart 3.12.2
- 命令 / 输入：下面的 `WAsyncExecutor` 配置与调用片段（共享 hooks 带 onError）。

```dart
final appAsync = WAsyncExecutor(WAsyncHooks(
  onStart: showLoading,
  onError: toast,
  onFinally: hideLoading,
));

// 某个调用要自己映射字段错误、不弹全局 toast：
await appAsync.tryRun(task, hooks: WAsyncHooks.none); // loading 也没了
// 想只关 onError，只能再造一个 WAsyncExecutor(_loadingHooks)
```

- 期望：单次调用可以只关闭 executor 的 `onError`，保留 `onStart` / `onFinally`；例如 `WAsyncHooks.overlay(onError: null)` 或 `executor.tryRun(..., disableError: true)`。
- 实际：`WAsyncHooks` 三个字段都是非空回调，解析规则是「显式参数 ?? 本次 hooks ?? executor hooks」（`packages/async/lib/src/task/async_task.dart:69-72`、`packages/async/lib/src/task/async_executor.dart:45-61`）。hooks 层没有「显式置空」的表达；传 `onError: (_) {}` 虽然可行，但语义是「有一个空监听」，文档里也没有写。
- 影响（我因此做错了什么 / 多花了什么）：本项目 `lib/app/w/w_async.dart` 为此建了 `appAsync` / `appAsyncOwnError` / `appAsyncQuiet` / `appAsyncQuietOwnError` 四个执行器，并在注释里解释「hooks 里的 onError 无法用 null 关掉，只能换一个不带 onError 的执行器」。执行器数量随「是否 loading × 是否 toast」组合增长，新增一个组合就要多一个实例。
- 建议：支持 per-call 的 null / 哨兵覆盖（`WAsyncHooks.overlay`、`disableOnError`），或把 `WAsyncHooks` 字段改成可空并在 merge 时区分「未设置」与「显式关闭」；至少在 dartdoc 里给出 `onError: (_) {}` 的写法。
- 复现数据：源码路径见上；项目用法 `lib/app/w/w_async.dart` 顶部注释与四个执行器定义。
- 验证（2026-11-22，8.1.2）：源码与行为未变，仍复现。
- 验证（2026-11-23，8.2.0）：已修复；disableOnError 只关默认 onError，显式 onError 仍优先。
- 状态变更：2026-11-22 待处理

### [待处理] async: WAsyncState 区分不了首屏 loading 与重试 loading，业务只能另加 RxBool

- 包/版本：w_tools_async 8.1.1
- 环境：macOS 26.6.2 arm64 / Flutter 3.44.9（fvm）/ Dart 3.12.2
- 命令 / 输入：下面的 `WAsyncController` / `WAsyncSection` 片段（失败后重试）。

```dart
// 首页 banner：首屏用骨架，失败后点重试要转圈（设计稿要求两者不同）
final c = WAsyncController.list<Banner>((_) => api.banners());
await c.load();               // 首屏 loading，data == null
// 失败后重试：
c.load();                     // WAsyncState.loading(previousData: null)，与首屏完全相同
WAsyncSection(
  loadingBuilder: (context) => /* 拿不到「这次是重试」*/ ...,
);
```

- 期望：状态能区分「首屏 loading」与「重试 loading」，`loadingBuilder` 可以按需切换骨架 / 转圈。
- 实际：`WAsyncState.loading` 只有 `previousData`，重试时 `previousData` 仍为 null，与首屏状态相等；`WAsyncController` 也没有 `isRetrying`。项目只能另建 `RxBool homeBannersRetrying`，在 `loadingBuilder` 里再套一层 `Obx`。
- 影响（我因此做错了什么 / 多花了什么）：本项目 `lib/app/services/top_service.dart:115-120` 和 `lib/app/modules/home/views/home_view.dart:102-118` 都在维护这套旁路状态；`WAsyncState` 值相等时 `Obx` 漏了会静默不刷新，正是 README 警告的那类问题。每个「首屏骨架、重试转圈」的区块都要复制一遍。
- 建议：controller 记录 previous status，提供 `isRetrying`（或 `WAsyncState.loading(previousStatus: WAsyncStatus.failed)`）；这比业务自己维护一套 Rx 更可靠，也不破坏现有四态。
- 复现数据：项目文件与行号见上；源码 `packages/async/lib/src/state/async_state.dart:42-45`。
- 验证（2026-11-22，8.1.2）：源码与行为未变，仍复现。
- 验证（2026-11-23，8.2.0）：已修复；isRetrying 首屏 false / 重试 true / 成功 false；isEmpty 抛错残留另见新条目。
- 状态变更：2026-11-22 待处理

### [待处理] async: README 主要 API 表格被 settle 弃用说明截断

- 包/版本：w_tools_async 8.1.1
- 环境：macOS 26.6.2 arm64 / 浏览器 GitHub Markdown 渲染
- 命令 / 输入：打开 `packages/async/README.md` 的「主要 API」表（90-107 行）。
- 期望：表格完整渲染；`WAsyncController.replaceData`、`WCancelToken`、`WAsyncState` 三行和其它入口一样留在表内。
- 实际：`> WAsync.settle 是旧名...` 的引用块插在表格中间（第 104 行）；它后面的三行（105-107 行）脱离了表头，GitHub 渲染成普通段落。
- 影响（我因此做错了什么 / 多花了什么）：查 API 时看不到 `replaceData` / 取消 token / 四态快照的入口；新人按 README 找「单区块本地替换」会以为没有这个能力。
- 建议：把 `WAsync.settle` 的弃用说明移到整张表之后，或在表后用一个小节写；补 `check_docs_facts` 一类校验，确认表格行都在表头之后。
- 复现数据：`packages/async/README.md:90-107`，第 104 行的 blockquote；本地 `flutter test` 的 `docs_examples_test` 没有覆盖渲染，只覆盖代码可编译。
- 验证（2026-11-22，8.1.2）：settle 说明已移到表后，表格已恢复。
- 验证（2026-11-23，8.2.0）：表格已恢复。
- 状态变更：2026-11-22 待处理

### [待处理] async: 8.1.2 空页 noMore 修复的回退：到末页后刷新失败又变 hidden

- 包/版本：w_tools_async 8.1.2
- 环境：macOS 26.6.2 arm64 / Flutter 3.44.9（fvm）/ Dart 3.12.2 / flutter_test widget test
- 命令 / 输入：下面的 controller 片段（到末页后下拉刷新失败）。

```dart
var fail = false;
final c = WAsyncPagedController<int>((page, _) async {
  if (fail) throw StateError('refresh failed');
  if (page == 1) {
    return WAsyncPage<int>(items: const <int>[1, 2], hasMore: true);
  }
  return const WAsyncPage<int>(items: <int>[3], hasMore: false);
});
await c.refresh();
await c.loadMore();
expect(c.snapshot.value.footerStatus, WAsyncPagedFooterStatus.noMore); // 通过

fail = true;
await c.refresh();
expect(c.snapshot.value.state.isFailed, isTrue);                       // 通过
expect(c.snapshot.value.footerStatus, WAsyncPagedFooterStatus.noMore);  // 实际 hidden
```

- 期望：刷新失败保留旧列表（`failed` + `previousData`）时，之前已经到底的 `noMore` 不应丢失。
- 实际：8.1.2 的 `_refresh` 在开头把 `_hasLoadedMore` 重置为 false；失败分支只写 `failed(previousData)`，没有恢复它；`_footerStatus` 用 `_hasLoadedMore` 判断，因此返回 `hidden`。8.1.1 用 `_page > _initialPage + 1` 判断时这里是 `noMore`，属于 8.1.2 修复引入的回退。
- 影响（我因此做错了什么 / 多花了什么）：用户在列表底部下拉刷新、网络失败时，列表和错误条都还在，但「沒有更多」凭空消失；footer 状态和保留的数据不一致。本项目列表（兑换 / 优惠券 / 门店）都可能走到。
- 建议：进入 refresh 时先保存旧的 `_hasLoadedMore`，失败保留旧列表时恢复它；或者从保留的 `_state.data` 是否包含追加页来派生 noMore。补一条「末页 + 刷新失败」的回归测试。
- 复现数据：本地探针 `fixes_v2_test.dart` 的「到末页后刷新失败：noMore 不应被重置成 hidden」用例；实际 `hidden`，期望 `noMore`。
- 验证（2026-11-23，8.2.0）：已修复；末页后刷新失败仍保持 noMore。
- 状态变更：2026-11-22 待处理

### [待处理] async: replaceData 后非空完整列表的 noMore 回退成 hidden

- 包/版本：w_tools_async 8.2.0
- 环境：macOS 26.6.2 arm64 / Flutter 3.44.9（fvm）/ Dart 3.12.2 / unit test
- 命令 / 输入：下面的 controller 片段（到末页后 replaceData 非空列表）。

```dart
final c = WAsyncPagedController<int>((page, _) async {
  if (page == 1) {
    return WAsyncPage<int>(items: const <int>[1, 2], hasMore: true);
  }
  return const WAsyncPage<int>(items: <int>[3], hasMore: false);
});
await c.refresh();
await c.loadMore();
expect(c.snapshot.value.footerStatus, WAsyncPagedFooterStatus.noMore); // 通过

c.replaceData(const <int>[1, 2], hasMore: false);
expect(c.snapshot.value.footerStatus, WAsyncPagedFooterStatus.noMore);  // 实际 hidden

// 不传 hasMore、继承当前的 false 也一样：
c.replaceData(const <int>[1, 2]);
// footerStatus 仍是 hidden
```

- 期望：本地替换成非空、且已知没有更多的列表后，footer 继续显示 `noMore`，不要从 `noMore` 回退成 `hidden`。
- 实际：`replaceData` 会无条件把 `_hasLoadedMore` 重置为 false（`packages/async/lib/src/state/async_paged_controller.dart:337-350`）；`_footerStatus` 只看 `_hasLoadedMore`，所以非空完整列表也变成 hidden。8.1.1 用 `_page` 判断时这里是 noMore。
- 影响（我因此做错了什么 / 多花了什么）：用 `replaceData` 做乐观更新 / 本地删除一条数据时，已到底列表的「沒有更多」会凭空消失；`replaceData` 文档说的是「本地替换 / 乐观更新」，这是它承诺的正常用法。本项目目前没用到 `replaceData`，但公共 API 一旦使用就会遇到。
- 建议：`replaceData` 在 `data.isNotEmpty && hasMore == false`（显式或继承）时保留 `_hasLoadedMore`，或增加 `preserveFooter` / `hasLoadedMore` 参数；至少文档写清「replaceData 会重置分页到底状态」。补一条「replaceData 非空 → 保持 noMore」的测试。
- 复现数据：本地探针 `replace_data_test.dart` 的两个用例「到末页后 replaceData(非空, hasMore:false) 仍应 noMore」「…继承 hasMore 时也应 noMore」；实际 `hidden`，期望 `noMore`。
- 验证（2026-11-23 复测，8.2.0）：已修复；非空 hasMore:false / 继承 false 都保持 noMore。
- 状态变更：2026-11-23 待处理

### [待处理] async: isRetrying 在 isEmpty 抛错后残留 true

- 包/版本：w_tools_async 8.2.0
- 环境：macOS 26.6.2 arm64 / Flutter 3.44.9（fvm）/ Dart 3.12.2 / unit test
- 命令 / 输入：下面的 controller 片段（isEmpty 回调抛错）。

```dart
final c = WAsyncController<String>(
  (_) async => 'x',
  isEmpty: (_) => throw StateError('bad isEmpty'),
);
await c.load();              // 首屏失败，isRetrying == false
await c.load();              // 从 failed 重试；isEmpty 再抛错
expect(c.state.value.isFailed, isTrue);
expect(c.isRetrying, isFalse);  // 实际 true
```

- 期望：loading 已结束（state 为 failed）时 `isRetrying` 应为 false；这个标记只描述「当前正在失败后重试」。
- 实际：`load` 的 `isEmpty` / `normalize` 抛错分支只写 `failed(previousData)`，没有把 `_isRetrying` 复位（`packages/async/lib/src/state/async_controller.dart:127-142`）。重试时先置 true，之后一直残留。
- 影响（我因此做错了什么 / 多花了什么）：`isRetrying` 是本轮新增给 UI / 埋点读的状态；自定义 `errorBuilder`、页面其它位置读到它会把失败态误判成「仍在重试」。`isEmpty` 是公开回调，文档也允许自定义（只有 `list` 用默认实现）。
- 建议：在 `isEmpty` / `normalize` 的 catch 分支里补 `_isRetrying = false`（和 success / failure / 取消路径一致）；补一条「isEmpty 抛错后 isRetrying 为 false」的测试。
- 复现数据：本地探针 `replace_data_test.dart` 的「isRetrying 在 isEmpty 抛错后不应残留 true」用例；实际 true，期望 false。
- 验证（2026-11-23 复测，8.2.0）：已修复；isEmpty 抛错后 isRetrying 为 false。
- 状态变更：2026-11-23 待处理

### [待处理] async: 8.2.0 新增 disableOnError / WAsyncView.scrollableStates 未进 async README

- 包/版本：w_tools_async 8.2.0
- 环境：macOS 26.6.2 arm64 / Flutter 3.44.9（fvm）/ Dart 3.12.2
- 命令 / 输入：在仓库根执行下面的 grep（无输出即 README 缺这两个新 API）。

```bash
grep -n "disableOnError\|scrollableStates" packages/async/README.md
# 无输出
```

- 期望：`WAsyncExecutor.disableOnError` 与 `WAsyncView.scrollableStates` 出现在 async 包的 README（pub.dev 页面）对应小节，至少各有一行说明 + 示例。
- 实际：这两个 8.2.0 新增的公开能力只在 `docs/agents/async.md` / `docs/modules/async_module.md` 出现；`packages/async/README.md` 只补了 `isRetrying`。`WAsyncSection.scrollableStates` 在 async_ui README 有，但 core 的 `WAsyncView.scrollableStates` 和 `disableOnError` 没有。
- 影响（我因此做错了什么 / 多花了什么）：上一轮反馈 #5（onError 无法单次关闭）的修复入口 `disableOnError` 在包 README 里查不到，消费方仍会继续建第二个 executor；`WAsyncView.scrollableStates` 是「外层 RefreshIndicator + 空态/失败态」的关键开关，库/设计系统直接用 `WAsyncView` 的人只能翻源码。
- 建议：在 README 的 WAsyncExecutor 小节补 `disableOnError: true` 示例，在 WAsyncView 小节补 `scrollableStates: true` 的用途和「只在非 ready 状态包滚动」的边界；顺带在 WAsyncStrings 的示例里补 `loadMore`。
- 复现数据：`grep` 命令无输出；`docs/agents/async.md:31-32`、`docs/agents/async.md:46-47` 有对应说明，`packages/async/README.md` 没有。
- 验证（2026-11-23 复测，8.2.0）：README 已补 disableOnError / WAsyncView.scrollableStates / WAsyncStrings.loadMore。
- 状态变更：2026-11-23 待处理

### [待处理] async: WAsyncView.scrollableStates 在无界高度（外层滚动容器）里仍包 AlwaysScrollable，吞掉页面手势

- 包/版本：w_tools_async 8.2.0（`WAsyncView.scrollableStates`，经 `w_tools_async_ui 2.3.0` 的 `WAsyncSection` 复现）
- 环境：macOS 26.6.2 arm64 / Flutter 3.44.9（fvm）/ Dart 3.12.2 / flutter_test widget test
- 命令 / 输入：下面的 widget test（section 放在外层 SingleChildScrollView 里）。

```dart
final c = WAsyncController.list<String>((_) async => const <String>[]);
await c.load();

await tester.pumpWidget(MaterialApp(
  home: Scaffold(
    body: RefreshIndicator(
      onRefresh: () async { refreshes++; await c.load(); },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(children: [
          const SizedBox(height: 100, child: Text('top')),
          WAsyncSection<List<String>>(
            controller: c,
            scrollableStates: true,
            builder: (_, data) => Text(data.join(',')),
          ),
          const SizedBox(height: 1000, child: Text('bottom')),
        ]),
      ),
    ),
  ),
));

await tester.drag(find.text('No data'), const Offset(0, -300));
// 期望：外层 SingleChildScrollView.pixels > 0；实际 0
// 期望：在空态上下拉能触发外层 RefreshIndicator；实际 refreshes == 0
```

- 期望：`scrollableStates` 只解决「有界页面主体 + 外层 RefreshIndicator」的空态/失败态下拉；放在已有的外层滚动容器里时，不应吞掉页面滚动和下拉刷新。
- 实际：`_wrapState` 无条件包 `SingleChildScrollView(AlwaysScrollableScrollPhysics)`；`LayoutBuilder` 在无界高度时 `minHeight = 0`，仍然创建内层滚动区（`packages/async/lib/src/view/async_view.dart:125-145`）。内层 AlwaysScrollable 吃掉 vertical drag，外层 `SingleChildScrollView` 的 pixels 保持 0，外层 RefreshIndicator 也收不到。
- 影响（我因此做错了什么 / 多花了什么）：README 只说「外层需要 RefreshIndicator 时传 `scrollableStates: true`」，没说只适用于有界高度。`SingleChildScrollView` + RefreshIndicator 是很常见的页面形态（本项目首页/记录页都是 SingleChildScrollView，钱包页是 Expanded+有界），一旦在这种页面上给 section 加 `scrollableStates`，空态/失败态区域会变成「拖不动」的死区，下拉刷新也失效。
- 建议：`_wrapState` 在 `!constraints.hasBoundedHeight` 时直接返回 `child`（让外层滚动容器接管），或对内层用 `NeverScrollableScrollPhysics` / `primary: false`；至少在 `WAsyncView.scrollableStates` / `WAsyncSection.scrollableStates` 的 dartdoc 和 README 写清「只用于有界页面主体，不要套在已有滚动容器里」。补一条外层 SingleChildScrollView 的回归测试。
- 复现数据：本地探针 `edge_v4_test.dart` 的「scrollableStates 放在外层 SingleChildScrollView 里」用例；外层 `pixels` 实际 0（期望 >0），`refreshes` 实际 0（期望 1）。
- 验证（2026-11-23 复测，8.2.0）：已修复；外层 SingleChildScrollView 可滚动、外层 RefreshIndicator 正常触发；有界模式仍通过。
- 状态变更：2026-11-23 待处理

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
| 2026-11-04 | `refresh()` 未完成时调用 `loadMore()`，会用被重置的页码重复追加第一页 | ✅ 2.1.0（49e07e0）：refresh 期间拒绝 loadMore，页码请求前快照 |
