# w_tools_async

`w_tools_async` 是 w_tools 的异步层，提供：

- `WAsync`：执行、重试、超时、并发控制与协作式取消；
- `WAsyncState`：loading / ready / empty / failed 四态快照；
- `WAsyncController`：状态流转与手动重试；
- `WAsyncView` / `WAsyncErrorView` / `WAsyncViewDefaults`：可复用异步视图。

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

Controller 会把所有异常转为 failed，方便 UI 展示；它只丢弃旧请求结果，不会中止
已启动的底层 Future。默认视图文案只是 fallback，项目可通过 `WAsyncViewDefaults`
统一覆盖。
