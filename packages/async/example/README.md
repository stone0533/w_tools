# w_tools_async 示例

真实场景示例，覆盖：

- 四态视图：`WAsyncController` + `WAsyncView`，含 `replaceData` 本地替换
- 分页：`WAsyncPagedController`、`loadMore`、`hasMore`、追加失败、`snapshot.footerStatus`
- Sliver：`WAsyncStateSliver`
- 全局默认：`WAsyncTheme`（普通 + sliver 一套）
- 执行编排：`WAsync` / `WCancelToken`
- 执行入口：`tryRun` / `run` / `retry` / `timeout` / `settle`
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
    paged_page.dart         WAsyncPagedController + snapshot footer
    sliver_page.dart        WAsyncStateSliver
    execution_page.dart     WAsync / 重试 / 超时 / 取消 / settle
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
final results = await WAsync.settle<String>([
  () => loadConfig(),
  () => loadProfile(),
  () => loadNotifications(),
], onError: (error) => log(error));
```

`settle` 保留每个结果；页面自己在调用点维护 loading 布尔。

### 上传文件

```dart
final results = await WAsync.settle<String>(
  files.map((file) => () => upload(file)),
  concurrency: 2,
  cancelToken: token,
);
```

限制并发数，结果顺序与输入一致；取消时未完成任务以 `WAsyncCancelled` 结束。

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

### 默认 hooks：WAsyncExecutor

`WAsyncExecutor` 在 composition root 创建一次，携带默认 hooks：

```dart
final appAsync = WAsyncExecutor(
  WAsyncHooks(
    onStart: showLoading,
    onFinally: hideLoading,
  ),
);
```

业务调用：

```dart
await appAsync.run(() => api.save());
```

单次覆盖：

```dart
await appAsync.run(task, hooks: WAsyncHooks.none);
```

没有全局 `defaultHooks`；默认值只属于这个 executor 实例。

### 四态视图

```dart
final controller = WAsyncController<List<String>>((_) => load());

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
final controller = WAsyncPagedController.list<String>(
  (page, _) => loadPage(page),
);

await controller.refresh();
await controller.loadMore();
```

footer 只监听 `snapshot`：

```dart
AnimatedBuilder(
  animation: controller.snapshot,
  builder: (context, _) {
    final footer = controller.snapshot.value;
    return switch (footer.footerStatus) {
      WAsyncPagedFooterStatus.hidden => const SizedBox.shrink(),
      WAsyncPagedFooterStatus.loading => const Text('加载中...'),
      WAsyncPagedFooterStatus.failed => TextButton(
          onPressed: controller.loadMore,
          child: const Text('重试'),
        ),
      WAsyncPagedFooterStatus.noMore => const Text('没有更多'),
      WAsyncPagedFooterStatus.loadMore => TextButton(
          onPressed: controller.loadMore,
          child: const Text('加载更多'),
        ),
    };
  },
);
```

最后一页返回空列表时 `snapshot.hasMore` 会变，但 `state` 不变；只由 `state` 重建的
footer 不会刷新，所以统一监听 `snapshot`。

### Sliver

```dart
WAsyncStateSliver<List<String>>(
  state: controller.state,
  onRetry: controller.load,
  readySliverBuilder: (context, items) => SliverList(...),
)
```

`WAsyncStateSliver` 放在 `CustomScrollView.slivers` 中，不使用 `WAsyncView` 包滚动组件。
