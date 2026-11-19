# w_tools_async 8.0 迁移

8.0 删除全局 `WAsync.defaultHooks`。默认 hooks 改由 `WAsyncExecutor` 实例携带。

## 删除

```text
WAsync.defaultHooks
```

不传 `hooks:` 时等价于：

```dart
WAsyncHooks.none
```

不再有隐式全局默认。

## 旧代码

```dart
WAsync.defaultHooks = WAsyncHooks(
  onStart: AppLoading.show,
  onError: AppToast.error,
  onFinally: AppLoading.hide,
);

await WAsync.run(() => api.save());
```

## 新代码

```dart
final appAsync = WAsyncExecutor(
  WAsyncHooks(
    onStart: AppLoading.show,
    onError: AppToast.error,
    onFinally: AppLoading.hide,
  ),
);

await appAsync.run(() => api.save());
```

在 composition root 创建一次并注入；不要做成全局静态。

单次覆盖：

```dart
await appAsync.run(task, hooks: WAsyncHooks.none);
```

## 其他变化

- `WAsyncStrings` 增加 `noMore`，用于分页 footer 文案。
- `WAsyncController.replaceData` 的 `isEmpty` / `normalize` 抛错时转为 `failed`，
  与 `load()` 一致。

`WAsyncController` / `WAsyncPagedController` 本来就不继承全局 hooks，不需要迁移。
