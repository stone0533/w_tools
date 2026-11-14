> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

# async 7.0 迁移

受影响的公开符号：`WAsync.parallel` / `WAsync.pool` / `WAsync.serial` / `WAsync.first` /
`WAsync.map`、`WAsyncOptions` / `WAsyncActivity`、`WAsyncStateBuilder` /
`WAsyncThemeViews` / `WAsyncRetryErrorHandler`、`WAsyncView.onRetryError` /
`WAsyncStateSliver.onRetryError` / `WAsyncStateSliver.refreshingSliverBuilder`、
`WAsyncController.withToken` / `WAsyncController.listWithToken` /
`WAsyncController.retry` / `WAsyncController.reload`、
`WAsyncPagedController.withToken` / `WAsyncPagedController.withPage` /
`WAsyncPagedController.withPageToken`、`WAsyncPagedController.page` /
`WAsyncPagedController.initialPage` / `WAsyncPagedController.isLoadingMore` /
`WAsyncPagedController.loadMoreError` / `WAsyncPagedController.hasMore` /
`WAsyncPagedController.hasMoreListenable` / `WAsyncPagedController.changes` /
`WAsyncPagedController.hasLoadedMoreThanOnePage` / `WAsyncPagedController.footerStatus`、
`WAsyncPage.fromTotal`、`WAsyncState.ofList`、`WCancelToken.clearListeners`、
`WAsyncTokenPageLoader`、`WAsyncPageLoader` 的签名、`WAsyncErrorView.error` /
`WAsyncErrorBanner.error`、`replaceData(page:)`、
`WAsyncTheme.sliver*Builder` / `WAsyncTheme.refreshingSliverBuilder`。

## 1. 执行层只保留 tryRun / run / retry / timeout / settle

`parallel` / `pool` / `serial` / `first` / `map` 删除；并发直接用 `Future.wait` /
`Future.any`，需要限流用 `settle(concurrency:)`。

```dart
// before
final values = await WAsync.parallel([api.config(), api.profile()]);
final name = await WAsync.map(() => api.gift(id), onSuccess: (v) => v.name);

// after
final values = await Future.wait([api.config(), api.profile()]);
final name = (await api.gift(id)).name;
```

独立区块保留每个结果：

```dart
// before
final results = await WAsync.parallel([
  WAsync.tryRun(() => api.banners()),
  WAsync.tryRun(() => api.columns()),
]);

// after
final results = await WAsync.settle([
  () => api.banners(),
  () => api.columns(),
]);
```

## 2. WAsyncOptions / WAsyncActivity 删除

`onError` 直接传给执行方法；需要 loading 时在调用点自己维护布尔。

```dart
// before
final options = WAsyncOptions(
  activity: WAsyncActivity(onStart: ..., onEnd: ...),
  onError: (error) => log(error),
);
await WAsync.run(() => api.fetch(), options: options);

// after
await WAsync.run(() => api.fetch(), onError: (error) => log(error));
```

## 3. Controller 构造函数收敛

所有 loader 都接收 `WCancelToken`；不需要取消时写 `(_) => ...`。

```dart
// before
final a = WAsyncController(() => api.gift());
final b = WAsyncController.withToken((token) => api.gift(token: token));
final c = WAsyncController.listWithToken((token) => api.list(token: token));

// after
final a = WAsyncController((_) => api.gift());
final b = WAsyncController((token) => api.gift(token: token));
final c = WAsyncController.list((token) => api.list(token: token));
```

`reload()` / `retry()` 删除，统一用 `load()`；自动重试用 `WAsync.retry`。

## 4. 分页：构造函数 + snapshot

分页 loader 统一返回 `WAsyncPage`，观察只读 `snapshot`。

```dart
// before
final c = WAsyncPagedController.withPage((page) async {
  final resp = await api.list(page: page);
  return WAsyncPage(items: resp.list, hasMore: resp.total > page * 20);
});
c.changes.addListener(() { ... });
final status = c.footerStatus;
final error = c.loadMoreError.value;

// after
final c = WAsyncPagedController((page, token) async {
  final resp = await api.list(page: page, token: token);
  return WAsyncPage(items: resp.list, hasMore: resp.total > page * 20);
});
c.snapshot.addListener(() { ... });
final footer = c.snapshot.value;
final status = footer.footerStatus;
final error = footer.loadMoreError;
```

`WAsyncPage.fromTotal` 删除，直接算 `hasMore`：

```dart
// before
return WAsyncPage<Gift>.fromTotal(items: resp.list, total: resp.total, page: page, pageSize: 20);

// after
return WAsyncPage<Gift>(items: resp.list, hasMore: page * 20 < resp.total);
```

`replaceData(data, page: ...)` 的 `page` 参数删除；`page` / `hasLoadedMoreThanOnePage`
不再公开，footer 只读 `snapshot.footerStatus`。

## 5. 视图：删 WAsyncStateBuilder / onRetryError

滚动页面把滚动组件放进 `WAsyncView.readyBuilder`；`onRetryError` 删除，`onRetry` 改为
`VoidCallback?`（同步 / 异步回调都能传，但失败由调用方自己处理）。

```dart
// before
WAsyncStateBuilder(
  state: c.state,
  builder: (context, state) => SmartRefresher(...),
);

// after
WAsyncView<List<Gift>>(
  state: c.state,
  readyBuilder: (context, gifts) => SmartRefresher(
    onRefresh: c.load,
    child: ListView(...),
  ),
);
```

`WAsyncThemeViews` 不再导出；主题只保留 `loading` / `empty` / `error` / `errorBanner` /
`refreshing` 五个 builder，sliver 复用同一组 builder（返回普通 Widget，不是 sliver）。

## 6. 默认错误视图不再渲染异常原文

```dart
// before
WAsyncErrorView(error: error, onRetry: retry);

// after
WAsyncErrorView(title: '加载失败', onRetry: retry);
// 需要详情时显式传 message（确认不含 token / 内部异常原文）：
WAsyncErrorBanner(title: '刷新失败', message: '请稍后重试', onRetry: retry);
```

## 7. 移除符号 → 替代速查

| 旧 | 新 |
| --- | --- |
| `WAsync.parallel` | `Future.wait`（原子加载）/ `WAsync.settle`（独立区块） |
| `WAsync.pool` | `WAsync.settle(concurrency:)` |
| `WAsync.serial` | `for` 循环 / `Future.wait` |
| `WAsync.first` | `Future.any` |
| `WAsync.map` | `WAsync.run` + 自己映射 |
| `WAsyncOptions` | 直接给执行方法传 `onError` |
| `WAsyncActivity` | 调用点维护 bool，或读 `controller.state` |
| `WAsyncStateBuilder` | `WAsyncView(readyBuilder: ...)` |
| `WAsyncThemeViews` | 不再导出；需要完全自定义时自建视图 |
| `WAsyncRetryErrorHandler` / `onRetryError` | 无替代；在 `onRetry` / `onError` 自己处理 |
| `WAsyncState.ofList` | `WAsyncState.list` |
| `WAsyncController.withToken` / `listWithToken` | 主构造 / `list`（loader 统一收 token） |
| `WAsyncController.reload` / `retry` | `load` |
| `WAsyncPagedController.withToken` / `withPage` / `withPageToken` | 主构造（loader 返回 `WAsyncPage`） |
| `WAsyncPagedController.page` / `initialPage` | 不再公开；footer 读 `snapshot.footerStatus` |
| `WAsyncPagedController.hasLoadedMoreThanOnePage` | `snapshot.footerStatus` |
| `WAsyncPagedController.isLoadingMore` / `loadMoreError` / `hasMore` / `hasMoreListenable` / `changes` | `snapshot` |
| `WAsyncPagedController.footerStatus` getter | `snapshot.value.footerStatus` |
| `WAsyncPage.fromTotal` | `WAsyncPage(items:, hasMore: page * pageSize < total)` |
| `WAsyncTokenPageLoader` | `WAsyncPageLoader`：`(page, token) => Future<WAsyncPage<T>>` |
| `WAsyncErrorView.error` / `WAsyncErrorBanner.error` | `message`，或自定义 `errorBuilder` |
| `WCancelToken.clearListeners` | 无替代，直接删除调用 |
| `WAsyncTheme.sliver*Builder` | 普通 builder（返回非滚动 Widget） |
| `WAsyncStateSliver.refreshingSliverBuilder` | 外层 `SmartRefresher` / 页面自己显示进度 |
| `replaceData(page:)` | `replaceData(...)` 后 `await refresh()` 重置分页 |

7.0.1 无公开 API 变化：修复 `loadMore` 在 `onError` 重入 `refresh` / `replaceData`
时的 stale `loadMoreError`；升级到 `^7.0.1` 即可。
