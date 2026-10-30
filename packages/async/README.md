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
```

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
- `WAsyncView` 适合页面主体 / Column / ListView item；不要直接放进无界宽度的 Row。
- `onRetry` 应自行处理异常；推荐直接传 `WAsyncController.load`。
- 刷新进度条可通过 `refreshingBuilder` 或 `WAsyncViewDefaults.refreshingBuilder` 覆盖。
