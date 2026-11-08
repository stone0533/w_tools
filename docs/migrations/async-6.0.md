> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

# async 6.0 迁移

受影响的公开符号：`WAsyncController.new` / `WAsyncController._` /
`WAsyncController.options`、`WAsyncPagedController.new` /
`WAsyncPagedController._` / `WAsyncPagedController.options`。

## Controller 不再接受 WAsyncOptions

`WAsyncController` / `WAsyncPagedController` 只接收失败兜底回调，不再接收整个
`WAsyncOptions`；`activity` 只属于 `WAsync` 直接执行。

```dart
// before
final controller = WAsyncController(
  () => api.gifts(),
  options: WAsyncOptions(onError: (error) => log(error)),
);

// after
final controller = WAsyncController(
  () => api.gifts(),
  onError: (error) => log(error),
);
```

`WAsyncController.list` / `WAsyncController.withToken` /
`WAsyncPagedController.withToken` 同样把 `options:` 换成 `onError:`。
传 `activity` 的代码直接删除；需要并发活动计数时用 `WAsync`。

## onError 去 nullable

```dart
// before
WAsyncOptions(onError: (Object? error) => log(error));

// after
WAsyncOptions(onError: (Object error) => log(error));
```

lambda 参数不显式标注类型时不需要改。

## error builder 的 retry 可空

`WAsyncErrorWidgetBuilder` 的第三个参数改为 `VoidCallback?`。没有重试入口时
（`onRetry == null`）builder 仍会被调用并收到 `null`，不再回退到包内默认视图。

```dart
// before
errorBuilder: (context, error, retry) => AppRetry(error, retry),

// after
errorBuilder: (context, error, retry) =>
    retry == null ? AppError(error) : AppRetry(error, retry),
```

包内默认视图在没有 retry 时不渲染按钮；自定义 builder 需要自己决定是否渲染。

## WAsyncController.list 的 state.data 不可变

`WAsyncController.list` 现在和 `WAsyncPagedController` 一样，把列表包成 unmodifiable。
原地 `add` / `remove` 会抛 `UnsupportedError`；需要可变副本时自己 `List.of(data)`。
泛型 `WAsyncController` 仍原样保存 loader 返回值。
