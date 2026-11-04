# async 4.0 迁移

## WAsyncStateSliver

`state` 从裸值改为 `ValueListenable`，与 `WAsyncView` / `WAsyncStateBuilder` 一致：

```dart
// before
WAsyncStateSliver<List<Gift>>(
  state: state,
  onRetry: () {},
  ...
)

// after
WAsyncStateSliver<List<Gift>>(
  state: controller.state,
  onRetry: controller.load,
  ...
)
```

`onRetry` 现在是异步回调；没有重试入口时可传 `null`。
