# w_tools_ui · WImage example

`WImage` 的最小可运行示例，覆盖：

- 网络图 + 圆角 + `aspectRatio`
- 本地 asset（`WAssets.imagePath` / `prefix`）
- Base64
- 圆形头像 + 边框/阴影
- 进度、自动重试、手动重试
- `WImageTheme` 默认占位符
- `WImageCachePolicy` 缓存预算
- `WImagePreloader` 预加载

## 运行

```bash
cd packages/ui/example
flutter pub get
flutter run
```

> 示例使用 `https://picsum.photos` 和 `https://i.pravatar.cc` 的远程图片；
> 重试演示使用必然失败的 `example.invalid`，用于观察错误占位和重试按钮。

## 文件

| 能力 | 位置 |
|---|---|
| 网络图 / 资源 / Base64 / 头像 | `lib/main.dart` 的 `ListView` |
| 进度 + 重试 | `WImage.network(..., retryCount:, progressBuilder:, errorWidgetBuilder:)` |
| 主题 | `main()` 里的 `WImageTheme` |
| 缓存预算 | `main()` 里的 `WImageCachePolicy.configure` |
| 预加载 | 底部“预加载”按钮 |
