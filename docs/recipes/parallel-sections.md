# 独立区块并行：不要让一个超时拖垮整页

`WAsync.parallel` 是 `Future.wait(eagerError: true)` 的封装：

- 任一 Future 失败，整个 `parallel` 抛错；
- 其余 Future 会继续执行，但结果拿不到；
- `.then` 不会执行；
- `eagerError: false` 只是等全部完成后再抛，**仍然不会返回部分结果**。

所以它适合“整页必须全部成功”的原子加载；banner、推荐位、辅助信息这类互相独立的区块，
不要直接用一个 `parallel` 包住。

## 错误写法

```dart
final results = await WAsync.parallel([
  api.mobileRegionCodes(),
  api.registerColumnList(),
  api.homeBanners(),
]);

setState(() {
  columnList = results[0];
  homeBanners = results[1];
});
```

只要 `mobile-region-codes` 超时，`setState` 不会执行：`columnList` 和 `banners`
即使成功也不会赋值，banner 区就一直为空。

`onError: (Object e) {}` 也不会让结果回来；`onError` 只是通知，`parallel` 仍会抛错。
空回调只会让日志里连一行错误都没有。

## 正确写法：每个区块先 `tryRun`

让每个请求自己 settle，再组合结果。推荐 record `.wait`（并行且每个结果独立）：

```dart
final (codes, columns, banners) = await (
  WAsync.tryRun(() => api.mobileRegionCodes()),
  WAsync.tryRun(() => api.registerColumnList()),
  WAsync.tryRun(() => api.homeBanners()),
).wait;
```

如果三个请求返回同一类型，也可以用 `parallel<WAsyncResult<Object?>>`：

```dart
final results = await WAsync.parallel<WAsyncResult<Object?>>([
  WAsync.tryRun<Object?>(() => api.mobileRegionCodes()),
  WAsync.tryRun<Object?>(() => api.registerColumnList()),
  WAsync.tryRun<Object?>(() => api.homeBanners()),
]);

final codes = results[0];
final columns = results[1];
final banners = results[2];

setState(() {
  if (columns is WAsyncSuccess) columnList = columns.value;
  if (banners is WAsyncSuccess) {
    homeBanners = banners.value;
  } else {
    homeBanners = const [];
    bannerError = true; // 该区块显示占位 / 重试，而不是永远空白
  }
});
```

注意 `tryRun` 的参数是 `Future<T> Function()`，要写 `() => api.xxx()`，不要直接传 `api.xxx()`。
`tryRun` 不抛业务异常，返回值是 `WAsyncSuccess` / `WAsyncFailure` / `WAsyncCancelled`；
`parallel` 这一层拿到的是 `WAsyncResult` 列表，单个失败不会丢掉其他成功结果。

如果页面确实是“全成功才展示”的原子加载，反过来：直接用 `parallel`，删掉空 `onError`，
让异常进入页面级错误态，不要留下“页面看似正常、banner 空白”的半失败状态。

## 边界

- `parallel` 失败后其他 Future **不会自动取消**；
- `onError` 是通知回调，不会把失败变成成功；
- 独立区块用 `tryRun`；原子页面用 `parallel` + 页面级错误；
- 不要用 `WAsyncActivity` 合并多个独立区块。
