# w_tools_async_ui 反馈

## 待处理



### [待处理] async_ui: WAsyncSection 空态/失败态不可滚动，外层 RefreshIndicator 失效

- 包/版本：w_tools_async_ui 2.1.1（w_tools_async 8.1.1）
- 环境：macOS 26.6.2 arm64 / Flutter 3.44.9（fvm）/ Dart 3.12.2 / flutter_test widget test
- 命令 / 输入：下面的 widget test（空态下拉，`refreshes` 期望 1、实际 0）。

```dart
final c = WAsyncController.list<String>((_) async => const <String>[]);
await c.load();
var refreshes = 0;
await tester.pumpWidget(MaterialApp(
  home: Scaffold(
    body: RefreshIndicator(
      onRefresh: () async { refreshes++; await c.load(); },
      child: WAsyncSection<List<String>>(
        controller: c,
        builder: (_, data) => ListView(
          children: [for (final item in data) Text(item)],
        ),
      ),
    ),
  ),
));
await tester.pumpAndSettle();
await tester.drag(find.text('No data'), const Offset(0, 300));
await tester.pumpAndSettle();
// 期望 refreshes == 1；实际 refreshes == 0
```

- 期望：页面主体只有一个 `WAsyncSection` 时，空态 / 失败态也应该能下拉刷新。
- 实际：`WAsyncSection` 在非 ready 状态直接返回 `WAsyncView` 的 `Center` 分支（`packages/async_ui/lib/src/async_section.dart:40-50` + `packages/async/lib/src/view/async_view.dart:101-111`），树里没有 `Scrollable`；外层 `RefreshIndicator` 收不到滚动通知，`onRefresh` 一次都不触发。失败态还有 Retry 按钮，空态则完全没有恢复入口。
- 影响（我因此做错了什么 / 多花了什么）：按 README「把 `RefreshIndicator` 放进 `readyBuilder`」写出来的页面，只有 ready 能下拉；空态/失败态不行。本项目钱包页、首页 banner 都是这个形态，空态时用户只能杀页面重进，或者业务在 `emptyBuilder` 里手写一个 `SingleChildScrollView` 绕。
- 建议：给 `WAsyncSection` 一个可选的「四态滚动壳」（例如 `scrollableStates: true` 时用 `LayoutBuilder` + `SingleChildScrollView(AlwaysScrollableScrollPhysics)` + `ConstrainedBox(minHeight)` 包住 loading/empty/error），或者提供 `refreshIndicator` 包装参数；至少 README 里写明自定义 `emptyBuilder` / `errorBuilder` 返回可滚动组件的绕法，并补一条空态下拉的测试。
- 复现数据：本地探针 `section_test.dart` 的「空态下拉刷新也应可用（常见需求）」「失败态下拉刷新也应可用（常见需求）」两个用例，实际 `refreshes` 为 0（期望 1）。
- 验证（2026-11-22，2.2.0）：仍复现；空态/失败态下拉刷新仍不触发。
- 验证（2026-11-23，2.3.0）：已修复，需传 scrollableStates: true；空态/失败态下拉均通过。
- 状态变更：2026-11-22 待处理

### [待处理] async_ui: WAsyncPagedList 程序化 reload 后不回到顶部，换筛选停在旧列表尾部

- 包/版本：w_tools_async_ui 2.1.1
- 环境：macOS 26.6.2 arm64 / Flutter 3.44.9（fvm）/ Dart 3.12.2 / flutter_test widget test
- 命令 / 输入：下面的 widget test（滚动到底 → 换筛选 → `reloadRequests++`）。

```dart
// 30 条 → 换筛选后 20 条；autoLoadThreshold: null，避免自动加载干扰
final c = WAsyncPagedController<int>((page, _) async => WAsyncPage(
  items: List<int>.generate(filtered ? 20 : 30, (i) => i),
  hasMore: false,
));
await c.refresh();
await tester.pumpWidget(MaterialApp(home: Scaffold(
  body: WAsyncPagedList<int>(
    controller: c,
    reloadRequests: reload,
    autoLoadThreshold: null,
    itemBuilder: (_, item) => SizedBox(height: 40, child: Text('item:$item')),
  ),
)));
await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
filtered = true;
reload.value++;
await tester.pumpAndSettle();
// 期望 scroll position == 0；实际 200（新列表的最大偏移）
```

- 期望：换筛选 / 搜索 / 排序触发的程序化 reload 后，新列表从顶部开始。
- 实际：`_onReloadRequested` 只做 `controller.refresh()` + `RefreshIndicator.show()`（`packages/async_ui/lib/src/paged_list.dart:142-165`），不碰内部 `_scrollController`；列表从 30 条变 20 条后，偏移从 600 clamp 到 200，停在新结果的中后段。`WAsyncPagedList` 自己持有 `ScrollController` 但不暴露，业务无法自己回顶。
- 影响（我因此做错了什么 / 多花了什么）：本项目兑换页的品牌筛选、搜索、排序都走 `reloadRequests`（`m_card_exchange_controller.dart:297`）；用户在列表下半部换品牌后，看到的是新列表的尾部，像筛选没生效。优惠券页 tab 内重载同理。
- 建议：程序化 reload（`_onReloadRequested`）时 `jumpTo(0)`（或 `animateTo(0)`），至少在新结果长度变化时；或者暴露 `scrollController` / `resetScrollOnReload` 让业务选择。
- 复现数据：本地探针 `usage_races_test.dart` 的「刷新后列表变短：滚动位置回到顶部（换筛选的常态）」用例；`ScrollPosition.pixels` 实际 200.0，期望 0。
- 验证（2026-11-22，2.2.0）：默认 resetScrollOnReload=true 已通过，false 保留位置也通过；刷新在飞时第二次 reload 仍不回顶（见新条目）。
- 验证（2026-11-23，2.3.0）：已修复；默认回顶、false 保留位置、刷新在飞时第二次 reload 也回顶。
- 状态变更：2026-11-22 待处理

### [待处理] async_ui: 标准 footer 失败只有 Retry、loadMore 不显示；autoLoadThreshold:null 没有手动加载入口

- 包/版本：w_tools_async_ui 2.1.1
- 环境：macOS 26.6.2 arm64 / Flutter 3.44.9（fvm）/ Dart 3.12.2 / flutter_test widget test
- 命令 / 输入：下面两段：loadMore 失败 + `autoLoadThreshold: null`。

```dart
// 输入 1：loadMore 失败
final c = WAsyncPagedController<int>((page, _) async {
  if (page == 1) return WAsyncPage<int>(items: List.generate(20, (i) => i), hasMore: true);
  throw StateError('load more failed');
});
// WAsyncPagedList 默认 footer：只出现一个 TextButton("Retry")，没有失败文案

// 输入 2：关闭自动加载
WAsyncPagedList<int>(
  controller: c,            // hasMore = true
  autoLoadThreshold: null,  // 文档：关闭自动加载
  itemBuilder: ...,
);
// 默认 footer = hidden；CustomScrollView 没有上拉手势；唯一入口是 controller.loadMore()
```

- 期望：默认 footer 在 `failed` 时显示失败文案 + 重试；在 `loadMore`（还能加载）时显示「加载更多」按钮；或者当 `autoLoadThreshold` 为 null 时明确要求业务提供 `footerBuilder`。
- 实际：`_footer` 的 `failed` 分支只有一个 `TextButton(strings.retry)`，没有失败说明；`loadMore` / `hidden` 分支直接 `SizedBox.shrink()`（`packages/async_ui/lib/src/paged_list.dart:221-255`）。`WAsyncStrings` 也没有 footer 失败 / loadMore 文案键（`packages/async/lib/src/view/async_strings.dart`）。`autoLoadThreshold: null` + 默认 footer 因此是死路：没有自动加载，也没有手动加载入口。
- 影响（我因此做错了什么 / 多花了什么）：本项目三个分页页全部传 `footerBuilder` 重写 `ListFooter`，只为补「加載失敗！+ 重試」；想关自动加载只能改用 `WAsyncPagedSliver` 自建壳。默认 footer 基本只能配合默认自动加载使用。
- 建议：`WAsyncStrings` 增加 `footerFailed` / `loadMore`；`failed` 用 `errorTitle + retry`，`loadMore` 渲染按钮；如果认为 `loadMore` 按钮不属于标准壳，就在 `autoLoadThreshold` 的 dartdoc 和 README 里写明「null 必须配 footerBuilder，否则没有加载入口」，并补测试。
- 复现数据：本地探针 `extra_usage_test.dart` 的「autoLoadThreshold: null + 默认 footer 时没有加载下一页的入口」用例；`paged_list_test.dart` 的「主题文案（noMore / retry）在标准壳生效」也走的是自定义 footer 之外的默认 footer。
- 验证（2026-11-22，2.2.0）：仍复现；默认 footer 未改。
- 验证（2026-11-23，2.3.0）：已修复；failed 显示失败文案 + Retry，autoLoadThreshold:null 显示 Load more。
- 状态变更：2026-11-22 待处理

### [待处理] async_ui: 标准分页壳没有 header/padding sliver，常见列表头只能整壳重写

- 包/版本：w_tools_async_ui 2.1.1
- 环境：macOS 26.6.2 arm64 / Flutter 3.44.9（fvm）/ Dart 3.12.2
- 命令 / 输入：下面的调用形态：标准壳 + 需要跟随滚动的头部。

```dart
// 需要列表上方有一个跟随滚动的搜索/筛选头，或给列表加 sliver padding
WAsyncPagedList<Item>(
  controller: c,
  itemBuilder: ...,
  // 没有 headerSlivers / sliverPadding / scrollController 参数
);
```

- 期望：标准壳支持 `headerSlivers` / `sliverPadding`（以及可选的 `scrollController`），常见列表头不需要整壳重写。
- 实际：`WAsyncPagedList` 只有 `itemBuilder` / `emptyBuilder` / `reloadRequests` / `autoLoadThreshold` / `footerBuilder` / `refreshIndicatorStyle`（`packages/async_ui/lib/src/paged_list.dart:26-63`）。需要自定义滚动头 / 叠卡布局时只能改用 `WAsyncPagedSliver.custom` + 自建 `SmartRefresher` / `RefreshIndicator`，自己实现刷新、footer、自动加载和 `reloadRequests`。
- 影响（我因此做错了什么 / 多花了什么）：本项目 `m_card_view.dart:150-196` 为此保留了 `pull_to_refresh` 依赖和整套 `SmartRefresher` 壳；`paged_chrome.dart:12` 里还留着 `WAsyncPagedList(header:)` 的过时注释（2.0 已删除 `header`），说明迁移文档没有给出「头部 + 标准壳」的等价写法。自定义壳与标准壳的 auto-load / reload 行为容易分叉。
- 建议：给 `WAsyncPagedList` 增加 `headerSlivers` / `sliverPadding`（成本最低），或提供「标准壳 + 自定义 sliver 头」的组合；在 README / CHANGELOG 的 2.0 迁移段补一个从 `header:` 到 sliver 壳的完整示例（含 auto-load、footer、reloadRequests 如何保留）。
- 复现数据：源码与项目文件路径见上；本地探针里 `sliver_test.dart` 已覆盖自建壳的 ready/empty/error/refresh，但这也说明标准壳没有等价入口。
- 验证（2026-11-22，2.2.0）：仍复现；仍未新增 header/padding 参数。
- 验证（2026-11-23，2.3.0）：已修复；headerSlivers / sliverPadding 通过。
- 状态变更：2026-11-22 待处理

### [待处理] async_ui: resetScrollOnReload 在刷新在飞时的第二次 reload 不生效

- 包/版本：w_tools_async_ui 2.2.0
- 环境：macOS 26.6.2 arm64 / Flutter 3.44.9（fvm）/ Dart 3.12.2 / flutter_test widget test
- 命令 / 输入：下面的 widget test（刷新在飞时第二次程序化 reload）。

```dart
// 30 条，autoLoadThreshold: null；先 reload 一次进入刷新，再把列表拖到 600，然后再次 reload
reload.value++;
await tester.pump();
expect(position.pixels, 0);       // 第一次：jumpTo(0)，刷新 pending
await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
await tester.pump();
expect(position.pixels, 600);

reload.value++;
await tester.pump();
// 期望 0（resetScrollOnReload 默认 true）；实际 600
```

- 期望：`resetScrollOnReload: true` 时每次程序化 reload 都回到顶部。
- 实际：`_onReloadRequested` 在 `_refreshRequested` 为 true 时先走「取消旧请求并替换」分支并 `return`；`jumpTo(0)` 插在这个分支之后，所以刷新在飞时的第二次 reload 不回顶（`packages/async_ui/lib/src/paged_list.dart:142-168`）。
- 影响（我因此做错了什么 / 多花了什么）：快速连点筛选/刷新、且在刷新期间滚动列表时，第二次筛选的结果会落在旧滚动位置；新选项的契约不完整。本项目筛选有 debounce，概率不高，但逻辑上仍会发生。
- 建议：把 `resetScrollOnReload` 的 jump 移到 `_refreshRequested` 分支之前（或两个分支都执行），并补一条「刷新在飞时再次 reload」的回归测试。
- 复现数据：本地探针 `reload_race_v2_test.dart`；`afterSecond = 600`（期望 0），第一次 reload 后为 0。
- 验证（2026-11-23，2.3.0）：已修复。
- 状态变更：2026-11-22 待处理

### [待处理] async_ui: 2.2.0 新增 resetScrollOnReload 未写进 README

- 包/版本：w_tools_async_ui 2.2.0
- 环境：macOS 26.6.2 arm64 / Flutter 3.44.9（fvm）/ Dart 3.12.2
- 命令 / 输入：`grep -n "resetScrollOnReload" packages/async_ui/README.md`（无输出）；该参数只在 CHANGELOG 和 `paged_list.dart` 的 dartdoc 里。
- 期望：README 的「程序化刷新」小节说明 `resetScrollOnReload` 的默认值 true、`false` 的用途（例如后台静默刷新保留位置），以及它只作用于 `reloadRequests`、不影响下拉刷新。
- 实际：2.2.0 新增的公开参数没有进 README；升级后的消费方不知道所有程序化 reload 默认会回顶，可能把滚动位置变化当成别的 bug。README 的「程序化刷新」仍只讲 `reloadRequests`（`packages/async_ui/README.md:117-135`）。
- 影响（我因此做错了什么 / 多花了什么）：本项目兑换 / 优惠券 / 门店页都用 `reloadRequests` 做筛选重载；升级后行为变化，但 README 里查不到开关；新人和 AI 也只能从 CHANGELOG 猜。
- 建议：在 README「程序化刷新」小节补参数表和示例；`docs/agents/async.md` 也补一句「程序化 reload 默认回顶，可用 resetScrollOnReload: false 关闭」。
- 复现数据：`packages/async_ui/README.md:117-135`；`packages/async_ui/CHANGELOG.md` 的 2.2.0 段；`packages/async_ui/lib/src/paged_list.dart:65-67`。
- 验证（2026-11-23，2.3.0）：README 已补 resetScrollOnReload。
- 状态变更：2026-11-22 待处理

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
| 2026-11-20 | `reloadRequests` 递增与 `autoLoadThreshold` 自动加载竞争：刷新前先发旧页码，且可能重复请求 page1 | ✅ 2.1.1：立即刷新 + 抑制 indicator 回调，去掉 1 秒 fallback；刷新期间挂起 auto-load；回归测试见 `packages/async_ui/test/paged_list_reload_test.dart` |
| 2026-11-19 | `WAsyncPagedList` 程序化带动画刷新只能靠业务持有 `RefreshController` | ✅ 2.0.0：新增 `reloadRequests` / `RefreshIndicator` 刷新壳；业务不再需要 `RefreshController` |
| 2026-11-19 | 并发重载时旧刷新提前收起 header，新刷新无反馈 | ✅ 2.0.0：refresh generation gate，最新请求完成后才收尾 |
| 2026-11-19 | `pull_to_refresh` 在布局期 `enterLoading` 抛 `Build scheduled during frame` | ✅ 2.0.0：移除 `pull_to_refresh`；改用 `RefreshIndicator` + post-frame 自动加载 |
| 2026-11-19 | 标准分页壳下拉头没有颜色 / 背景入口 | ✅ 2.0.0（部分）：`WAsyncRefreshIndicatorStyle` 支持颜色 / 背景 / 线宽 / 位移 / 触发模式；完成失败文案仍需 `WAsyncPagedSliver` 自建壳 |
