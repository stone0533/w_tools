# async 使用规则（给人和 AI）

## 什么时候用

页面区块的加载 / 空 / 失败 / 刷新四态；或不需要 UI 状态的异步执行（重试、超时、并发、取消）。

## 最小用法

```dart
final controller = WAsyncController<List<Gift>>(() => api.gifts())..load();

WAsyncView<List<Gift>>(
  state: controller.state,
  onRetry: controller.load,
  readyBuilder: (context, gifts) => ListView(...),
);
```

无 UI 场景：

```dart
final options = WAsyncOptions(
  loading: WAsyncLoading(onStart: () => ..., onEnd: () => ...),
);
await WAsync.retry(() => api.gifts(), options: options, retryCount: 3);
```

## 不要用

- `WAsyncConfig` / `WAsyncBuilder` / `WAsyncViewDefaults`（已移除或弃用）；
- 手写 `ValueNotifier<WAsyncState>`，或每页重复 `when + RetryView`；
- 用一个 `WAsyncLoading` 合并多个独立区块的 loading。

## 常见坑

- 每个区块一个 Controller；页面 `dispose` 时 `controller.dispose()`；
- 控制器自己管四态，不要再给 `options.loading`（会双份 loading）；
- 取消是协作式的：loader 要接收 `WCancelToken` 并检查；
- 全局默认视图用 `WAsyncTheme`（放 App 根节点），不是 `WAsyncViewDefaults`。

完整说明：[async_module.md](../modules/async_module.md) · 示例：`packages/async/example`
