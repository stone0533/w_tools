> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

# async 3.0 迁移

`WAsyncViewDefaults` / `WAsyncSliverDefaults` 已删除：统一用 `WAsyncTheme`。

```dart
WAsyncTheme(
  loadingBuilder: (_) => const AppLoading(),
  sliverLoadingBuilder: (_) => const AppSliverLoading(),
  child: MaterialApp(...),
);
```
