# w_tools_async 示例

真实场景示例，覆盖：

- 四态视图：`WAsyncController` + `WAsyncView`，含 `replaceData` 本地替换
- 分页：`WAsyncPagedController`、`loadMore`、`hasMore`、追加失败
- Sliver：`WAsyncStateSliver`
- 全局默认：`WAsyncTheme`（普通 + sliver 一套）
- 状态构建器：`WAsyncStateBuilder` / `WAsyncErrorView`
- 执行编排：`WAsync` / `WAsyncOptions` / `WAsyncActivity` / `WCancelToken`
- 执行入口补充：`map` / `serial` / `first` / `settle`
- 真实场景：提交重试+取消、启动并行、限流上传、搜索竞态
- 重试增强：`retryDelayBuilder` 退避、`onRetry` 观测

## 运行

```bash
cd packages/async/example
flutter pub get
flutter run
```

没有连接设备时：

```bash
flutter analyze
flutter test
```

## 目录

```text
lib/
  main.dart                 示例入口 + 全局默认 + 底部导航
  pages/
    async_view_page.dart    WAsyncController + WAsyncView
    paged_page.dart         WAsyncPagedController
    sliver_page.dart        WAsyncStateSliver
    state_builder_page.dart WAsyncStateBuilder
    execution_page.dart     WAsync / 重试 / 超时 / 取消
    scenarios_page.dart     提交 / 启动 / 上传 / 搜索竞态
test/
  example_smoke_test.dart
```

## 真实场景页

底部导航的「真实场景」页把 `WAsync` 放进了四类真实用法：

### 提交订单

```dart
await WAsync.retry(
  () => WAsync.timeout(
    () => api.createOrder(token: token),
    const Duration(seconds: 2),
    cancelToken: token,
  ),
  retryCount: 2,
  retryDelay: const Duration(milliseconds: 200),
  retryIf: (error) => error is Exception,
  cancelToken: token,
);
```

- 失败自动重试；
- 超时抛 `TimeoutException`；
- 页面销毁 / 用户取消时 token 取消，抛 `WCancellationException`；
- 页面提供「取消提交」按钮。

### App 启动

```dart
await WAsync.parallel<String>(
  [loadConfig(), loadProfile(), loadNotifications()],
  options: WAsyncOptions(activity: activity),
);
```

多个任务共享 `WAsyncActivity`，loading 只触发一次 0→1→0。

### 上传文件

```dart
await WAsync.pool<String>(
  files.map((file) => () => upload(file)),
  concurrency: 2,
  cancelToken: token,
);
```

限制并发数，结果顺序与输入一致。

### 搜索竞态

```dart
final token = WCancelToken();
final result = await WAsync.tryRun(
  () => api.search(keyword, cancelToken: token),
  cancelToken: token,
);
```

页面上可输入关键词；每次搜索取消旧 token；旧结果返回时用 `identical` 丢弃。

## 示例说明

### 四态视图

```dart
final controller = WAsyncController<List<String>>(load);

WAsyncView<List<String>>(
  state: controller.state,
  onRetry: controller.load,
  readyBuilder: (context, items) => ListView(...),
)
```

页面右上角可以模拟：

```text
刷新
下一次失败
下一次为空
```

用于观察全局 loading / empty / error 默认视图。

### 分页

```dart
final controller = WAsyncPagedController<String>(loadPage);

await controller.refresh();
await controller.loadMore();
```

footer 监听：

```text
isLoadingMore
loadMoreError
hasMoreListenable
```

`hasMoreListenable` 不能省：最后一页返回空列表时 `hasMore` 会变，但 `state` 不变。
如果 footer 只由 `state` 重建，就必须再监听 `hasMoreListenable`；示例里的 footer 还监听
`isLoadingMore`，而它在每次 `loadMore` 前后都会翻转，所以能顺带刷新。

### Sliver

```dart
WAsyncStateSliver<List<String>>(
  state: controller.state,
  onRetry: controller.load,
  readySliverBuilder: (context, items) => SliverList(...),
)
```

`WAsyncStateSliver` 放在 `CustomScrollView.slivers` 中，不使用 `WAsyncView` 包滚动组件。
