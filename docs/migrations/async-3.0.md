# async 3.0 迁移

`WAsyncViewDefaults` / `WAsyncSliverDefaults` 已删除：统一用 `WAsyncTheme`。

```dart
WAsyncTheme(
  loadingBuilder: (_) => const AppLoading(),
  sliverLoadingBuilder: (_) => const AppSliverLoading(),
  child: MaterialApp(...),
);
```
