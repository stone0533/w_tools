# w_tools_ui · WImage example

`WImage` 的可运行示例，包含三个页面：

- **Playground**：实时调整 width / height / aspectRatio / fit / memCache / borderRadius / retryCount / placeholder，并显示对应 `WImageStyle` 代码；
- **状态矩阵**：加载成功、失败、空数据、加载中占位、主题默认错误占位、文件/Web 不支持；
- **常用配方**：`WImage.avatar` / `thumbnail` / `cover` / `assetImage` / `memory` / `provider` / `showRetryButton`。

覆盖：

- 网络图 + 圆角 + `aspectRatio`
- 本地 asset（`WAssets.imagePath` / `prefix`）
- Base64
- 圆形头像 + 边框/阴影
- 进度、自动重试、手动重试
- `WImageDefaultsScope` 默认占位符/错误占位
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
| Playground 参数与代码生成 | `lib/playground_page.dart` |
| 状态矩阵 | `lib/states_page.dart` |
| 常用配方 | `lib/recipes_page.dart` |
| 进度 + 重试 | `WImage.network(..., retryCount:, progressBuilder:, errorWidgetBuilder:)` |
| 默认加载 UI | `main()` 里的 `WImageDefaultsScope` |
| 缓存预算 | `main()` 里的 `WImageCachePolicy.configure` |
| 预加载 | `states_page.dart` 里的 `WImagePreloader` 示例（可移到 Playground） |
