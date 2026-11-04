> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

# async 5.0 迁移

## 错误与 null

5.0 不再用 null 表示失败或取消。

```dart
// before
final value = await WAsync.runValue(() => api.gift());
if (value == null) { /* 失败？超时？取消？成功 null？ */ }

// after：不抛异常
final result = await WAsync.tryRun(() => api.gift());
switch (result) {
  case WAsyncSuccess(:final value): ...
  case WAsyncFailure(:final error, :final stackTrace): ...
  case WAsyncCancelled(:final reason): ...
}

// after：失败抛异常
final value = await WAsync.run(() => api.gift());
```

## 方法

```text
WAsync.run<T,R>(task, onSuccess: ...)  → WAsync.map<T,R>(task, onSuccess: ...)
WAsync.run<T,R>(task)                  → WAsync.run<T>(task)
WAsync.retry<T,R>(...)               → WAsync.retry<T>(...)
WAsync.timeout<T,R>(...)             → WAsync.timeout<T>(...)
WAsync.parallel<T,R>(...)            → WAsync.parallel<T>(...)
WAsync.pool<T,R>(...)                → WAsync.pool<T>(...)
WAsync.serial<T,R>(...)              → WAsync.serial<T>(...)
```

## 命名

```text
WAsyncLoading          → WAsyncActivity
WAsyncOptions.loading  → WAsyncOptions.activity
withoutLoading()       → withoutActivity()
WAsyncState.dataOrNull → WAsyncState.data
```

## 视图

- `WAsyncView.onRetry` 可选；
- 没有 retry 时不显示重试按钮；
- `WAsyncTheme.strings` 注入文案；默认 `WAsyncStrings` 为中性英文。

## 分页

`initialPage` 必须 >= 1。

## first([])

旧版 `first([])` 返回 null；5.0 抛 `StateError`。需要空集合返回 null 时，先判断集合是否为空。
