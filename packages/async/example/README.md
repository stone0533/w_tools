# w_tools_async 示例

真实场景示例，覆盖：

- 四态视图：`WAsyncController` + `WAsyncView`
- 分页：`WAsyncPagedController`、`loadMore`、`hasMore`、追加失败
- Sliver：`WAsyncStateSliver`
- 全局默认：`WAsyncViewDefaults` / `WAsyncSliverDefaults`
- 状态构建器：`WAsyncStateBuilder` / `WAsyncErrorView`
- 执行编排：`WAsync` / `WAsyncConfig` / `WCancelToken`

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
test/
  example_smoke_test.dart
```

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

footer 同时监听：

```text
isLoadingMore
loadMoreError
state
```

### Sliver

```dart
WAsyncStateSliver<List<String>>(
  state: state,
  onRetry: controller.load,
  readySliverBuilder: (context, items) => SliverList(...),
)
```

`WAsyncStateSliver` 放在 `CustomScrollView.slivers` 中，不使用 `WAsyncView` 包滚动组件。
