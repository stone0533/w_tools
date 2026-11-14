# 独立区块并行：不要让一个超时拖垮整页

`Future.wait` 是 all-or-nothing：

- 任一 Future 失败，整个 `Future.wait` 抛错；
- 其余 Future 会继续执行，但结果拿不到；
- `.then` 不会执行；
- `eagerError: false` 只是等全部完成后再抛，**仍然不会返回部分结果**。

所以它适合“整页必须全部成功”的原子加载；banner、推荐位、辅助信息这类互相独立的区块，
不要直接用一个 `Future.wait` 包住。

## 错误写法

```dart
final results = await Future.wait([
  api.mobileRegionCodes(),
  api.registerColumnList(),
  api.homeBanners(),
]);

setState(() {
  columnList = results[1];
  homeBanners = results[2];
});
```

只要 `mobile-region-codes` 超时，`setState` 不会执行：`columnList` 和 `banners`
即使成功也不会赋值，banner 区就一直为空。

## 正确写法：用 `settle`

`WAsync.settle` 保留每个结果，单个失败不会让整批抛错；结果顺序与输入一致。

```dart
final results = await WAsync.settle<Object?>([
  () => api.mobileRegionCodes(),
  () => api.registerColumnList(),
  () => api.homeBanners(),
], concurrency: 3);

final codes = results[0];
final columns = results[1];
final banners = results[2];

setState(() {
  if (columns is WAsyncSuccess) columnList = columns.value as List<String>;
  if (banners is WAsyncSuccess) {
    homeBanners = banners.value as List<String>;
  } else {
    homeBanners = const [];
    bannerError = true; // 该区块显示占位 / 重试，而不是永远空白
  }
});
```

`settle` 的参数是任务工厂 `Future<T> Function()`，要写 `() => api.xxx()`，
不要直接传 `api.xxx()`（那样请求在进入 `settle` 前就已经启动，限流也失效）。
每个失败任务会触发一次 `onError` 通知，但不会改变结果列表。

如果几个请求返回不同类型，也可以用 record `.wait`（并行且每个结果独立）：

```dart
final (codes, columns, banners) = await (
  WAsync.tryRun(() => api.mobileRegionCodes()),
  WAsync.tryRun(() => api.registerColumnList()),
  WAsync.tryRun(() => api.homeBanners()),
).wait;
```

如果页面确实是“全成功才展示”的原子加载，直接用 `Future.wait`，让异常进入页面级错误态，
不要留下“页面看似正常、banner 空白”的半失败状态。

## 边界

- `settle` 失败后其他任务**不会自动取消**；需要整体取消时传同一个 `WCancelToken`；
- `onError` 是通知回调，不会把失败变成成功；
- 独立区块用 `settle`（或 record `.wait`）；原子页面用 `Future.wait` + 页面级错误；
- 不要在多个独立区块之间共享一个加载布尔；每个区块自己的 loading 由自己的状态负责。
