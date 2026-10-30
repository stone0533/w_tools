# w_tools_async

w_tools 的异步层：执行、四态状态、Controller 与可复用异步视图。

```text
页面展示异步结果  → WAsyncController + WAsyncView
只执行、不要 UI   → WAsync
全 App 默认视图   → WAsyncViewDefaults
```

## 安装

```yaml
dependencies:
  w_tools_async: ^1.0.0
```

## 快速开始

```dart
final controller = WAsyncController.list(() => api.gifts());

WAsyncView<List<Gift>>(
  state: controller.state,
  onRetry: controller.load,
  readyBuilder: (context, gifts) => GiftList(gifts),
)
```

`WAsyncView` 自动处理：

```text
loading  → 转圈
empty    → 暂无数据
failed   → 错误页 + 重试
ready    → readyBuilder
```

## 完整页面

```dart
class GiftPage extends StatefulWidget {
  const GiftPage({super.key});

  @override
  State<GiftPage> createState() => _GiftPageState();
}

class _GiftPageState extends State<GiftPage> {
  late final WAsyncController<List<Gift>> _gifts;

  @override
  void initState() {
    super.initState();
    _gifts = WAsyncController.list(() => api.gifts());
    _gifts.load();
  }

  @override
  void dispose() {
    _gifts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WAsyncView<List<Gift>>(
      state: _gifts.state,
      onRetry: _gifts.load,
      readyBuilder: (context, gifts) => GiftList(gifts),
    );
  }
}
```

## 多区块

每个区块一个独立 Controller：

```dart
final profile = WAsyncController<Profile>(() => api.profile());
final coupons = WAsyncController.list(() => api.coupons());

profile.load();
coupons.load();
```

不要用一个 `WAsyncConfig` 管理多个独立区块的 Loading；它会把并发请求合并成一次。

## 全局默认视图

```dart
WAsyncViewDefaults(
  errorBuilder: (context, error, retry) => AppRetryView(error, retry),
  errorBannerBuilder: (context, error, retry) => AppErrorBanner(error, retry),
  loadingBuilder: (_) => const AppLoadingView(),
  emptyBuilder: (_) => const AppEmptyView(),
  child: MaterialApp(...),
)

// 推荐放在 App 根节点：
// WAppPlugin.wrapApp / WApp.appWrapper
// 不要只放在 AppScaffold.body，否则 appBar actions、对话框、
// bottom sheet、Tab 页面不会继承默认值。
```

`WAsyncViewDefaults` 只作用于 `WAsyncView`；`WAsyncStateBuilder` 不会读取它。

优先级：

```text
WAsyncView 显式 builder
  ↓
WAsyncViewDefaults
  ↓
包内默认视图
```

## 刷新和旧数据

```dart
await controller.load();
```

如果已有数据：

```text
loading(previousData: oldData)
→ WAsyncView 保留旧内容 + 线性进度

failed + oldData
→ 保留旧内容 + WAsyncErrorBanner
```

## 自定义重试视图

```dart
WAsyncView<List<Gift>>(
  state: controller.state,
  onRetry: controller.load,
  readyBuilder: (context, gifts) => GiftList(gifts),
  errorBuilder: (context, error, retry) {
    return BrandRetryView(error: error, onRetry: retry);
  },
  errorBannerBuilder: (context, error, retry) {
    return BrandErrorBanner(error: error, onRetry: retry);
  },
)
```

## 低层 WAsync

只需要执行、不需要 View 时：

```dart
final result = await WAsync.runWithRetry<List<Gift>, List<Gift>>(
  () => api.gifts(),
  retryCount: 2,
  retryDelay: const Duration(milliseconds: 300),
  onSuccess: (data) => data,
  onError: (error) => logger.e(error),
);
```

## 约定

- Controller 会把所有异常（包括 `Error`）转为 `failed`，方便 UI 展示；
- Controller 只丢弃旧请求结果，不会中止底层 Future；
- 需要中止请求时，由 loader 自己接收 `WCancelToken`；
- 默认 loading / empty / error 文案只是 fallback；
- `WAsyncView` 为错误条/刷新条约束宽度，不强制高度；滚动组件的高度由页面父级提供。
- `onRetry` 应自行处理异常；推荐直接传 `WAsyncController.load`。
- 刷新进度条可通过 `refreshingBuilder` 或 `WAsyncViewDefaults.refreshingBuilder` 覆盖。

## 异步列表：WAsyncStateBuilder + SmartRefresher

滚动页面不要用 `WAsyncView` 包 `SmartRefresher`。用 `WAsyncStateBuilder` 把状态交给调用方，
让 `SmartRefresher` 的直接子节点始终是 `CustomScrollView`：

```dart
WAsyncStateBuilder<List<Gift>>(
  state: controller.state,
  builder: (context, state) {
    final gifts = state.dataOrNull ?? const <Gift>[];

    return SmartRefresher(
      controller: refreshController,
      onRefresh: controller.load,
      onLoading: loadMore,
      child: CustomScrollView(
        slivers: [
          if (state.isLoading && gifts.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('暂无数据')),
            )
          else if (state.isFailed && gifts.isEmpty)
            SliverFillRemaining(
              child: WAsyncErrorView(
                error: state.error!,
                onRetry: controller.load,
              ),
            )
          else
            SliverList.builder(
              itemCount: gifts.length,
              itemBuilder: (context, index) => GiftTile(gift: gifts[index]),
            ),
          if (state.isFailed && gifts.isNotEmpty)
            SliverToBoxAdapter(
              child: WAsyncErrorBanner(
                error: state.error!,
                onRetry: controller.load,
              ),
            ),
        ],
      ),
    );
  },
)
```

`loadMore` 的追加与 footer 状态由业务侧维护，不要用 `WAsyncController.failed` 表示分页失败。

`WAsyncStateBuilder.builder` 必须始终返回同一个滚动壳：

```text
WAsyncStateBuilder
  → SmartRefresher
      → CustomScrollView
```

loading / empty / error 只能作为 `slivers` 内部的分支，不要在外层直接 return `Center` / `WAsyncErrorView`，否则 `SmartRefresher` 会被重新挂载。

## 用 WAsyncStateSliver 收口 sliver 状态

如果页面已经在 `CustomScrollView` 里，不需要自己写 `if (items.isEmpty)` 和
`SliverFillRemaining`：

```dart
WAsyncStateSliver<List<Gift>>(
  state: state,
  onRetry: controller.refreshGifts,
  readySliverBuilder: (context, gifts) {
    return WListViewSliver.list(
      itemCount: gifts.length,
      itemBuilder: (context, index) => GiftTile(gift: gifts[index]),
    );
  },
  emptyBuilder: (context) => const Center(child: Text('暂无数据')),
  errorBuilder: (context, error, onRetry) {
    return WAsyncErrorView(error: error, onRetry: onRetry);
  },
)
```

它会自动处理：

```text
ready                  → readySliverBuilder
loading / empty / failed（无数据）→ SliverFillRemaining
failed + 旧数据        → ready sliver + WAsyncErrorBanner
refreshing + 旧数据    → ready sliver（默认不额外加速进度，避免和 SmartRefresher 重复）
```

`readySliverBuilder` 必须返回 sliver，例如 `WListViewSliver.list` / `SliverList`。

## Sliver 页面的全局默认

`WAsyncStateSliver` 使用独立的 `WAsyncSliverDefaults`，不要复用 `WAsyncViewDefaults`：

```dart
WAsyncSliverDefaults(
  loadingBuilder: (_) => const AppAsyncStatusLoading(), // 非滚动
  emptyBuilder: (_) => const AppAsyncStatusEmpty(),     // 非滚动
  errorBuilder: (context, error, retry) => AppAsyncStatusError(error, retry),
  errorBannerBuilder: (context, error, retry) => AppErrorBanner(error, retry),
  child: MaterialApp(...),
)
```

约束：

```text
loading / empty / error builder 必须是非滚动 Widget
refreshingSliverBuilder 必须返回 sliver
```

不要放 `AppRefreshable` / `SingleChildScrollView` 到 `SliverFillRemaining(hasScrollBody: false)` 里。

App 根部可以同时安装两套：

```dart
WAsyncViewDefaults(
  ...,
  child: WAsyncSliverDefaults(
    ...,
    child: MaterialApp(...),
  ),
)
```

## App 层固定滚动壳

为了避免每个页面都重复 `WAsyncStateBuilder → SmartRefresher → CustomScrollView`，
建议在 App 层封装一个 helper（不要放进 `w_tools_async`，因为它依赖 `pull_to_refresh`）：

```dart
class AsyncRefreshShell<T> extends StatelessWidget {
  const AsyncRefreshShell({
    super.key,
    required this.state,
    required this.controller,
    required this.onRefresh,
    required this.onLoading,
    required this.slivers,
  });

  final ValueListenable<WAsyncState<T>> state;
  final RefreshController controller;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoading;
  final List<Widget> Function(BuildContext, WAsyncState<T>) slivers;

  @override
  Widget build(BuildContext context) {
    return WAsyncStateBuilder<T>(
      state: state,
      builder: (context, value) {
        return SmartRefresher(
          controller: controller,
          onRefresh: onRefresh,
          onLoading: onLoading,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: slivers(context, value),
          ),
        );
      },
    );
  }
}
```

这样页面只负责 `slivers`，不会被允许把 `SmartRefresher` 包到错误的位置。

## 分页列表

分页使用独立的 `WAsyncPagedController`，不要把它塞进普通 `WAsyncController`：

```dart
final gifts = WAsyncPagedController<Gift>(
  (page) => api.gifts(page: page),
);

await gifts.refresh();   // 第一页
await gifts.loadMore();  // 下一页
```

可用状态：

```text
gifts.state           WAsyncState<List<Gift>>
gifts.isLoadingMore   ValueListenable<bool>
gifts.loadMoreError   ValueListenable<Object?>
gifts.hasMore         bool
```

`loadMore` 失败只写 `loadMoreError`，不会清空已有列表；`SmartRefresher` 的 footer 状态：

```dart
Future<void> _loadMore() async {
  await gifts.loadMore();

  if (gifts.loadMoreError.value != null) {
    refreshController.loadFailed();
  } else if (!gifts.hasMore) {
    refreshController.loadNoData();
  } else {
    refreshController.loadComplete();
  }
}
```

`WAsyncStateBuilder` 可以直接消费：

```dart
WAsyncStateBuilder<List<Gift>>(
  state: gifts.state,
  builder: (context, state) {
    ...
  },
)
```

## 选择哪个入口

```text
普通页面区块 / 非滚动内容  → WAsyncView
SmartRefresher / 滚动页面  → WAsyncStateBuilder
```

`WAsyncView` 的 ready / refreshing / failed + 旧数据使用稳定内容容器，
但滚动页面仍应使用 `WAsyncStateBuilder`，不要把 `SmartRefresher` 长期塞进 `WAsyncView.readyBuilder`。

`WAsyncBuilder` 是旧名，保留为兼容别名；新代码使用 `WAsyncStateBuilder`。
