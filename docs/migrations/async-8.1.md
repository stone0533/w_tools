# async 8.1 迁移

`WAsync.settle` / `WAsyncExecutor.settle` 改名为 `tryAll`，行为不变。

```dart
// 旧
final results = await WAsync.settle(tasks);

// 新
final results = await WAsync.tryAll(tasks);

// executor 同理
final results2 = await appAsync.tryAll(tasks);
```

`settle` 仍可用，但已标记 `@Deprecated`，`remove-in: 9.0.0`。
