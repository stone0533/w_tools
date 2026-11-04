# w_tools_ui · 组件示例

`w_tools_ui` 的可运行示例，页面壳使用 `WScaffold` + `WAppBar` + `WNavBar`；包含五个页面：

- **Playground**：实时调整 width / height / aspectRatio / fit / memCacheWidth / memCacheHeight / borderRadius / retryCount / placeholder，并显示对应 `WImageStyle` / `WImageLoadConfig` 代码；
- **状态矩阵**：加载成功、失败、空数据、加载中占位、主题默认错误占位、文件/Web 不支持；
- **常用配方**：`WImageStyle` 圆形头像 / 缩略图 / 封面 / asset / memory / provider / `showRetryButton`；
- **按钮**：`WButton` / `WButtonSize` / `WButtonStyle` / loading / tap target；
- **组件**：WText / WBadge / WClipRRect / Gradient / WStep / WListView / WActionRow / WSelectableRow / WTabBar / WNavBar / Notification / KeepAlive。

覆盖：

- 网络图 + 圆角 + `aspectRatio`
- 本地 asset（`WAssets.imagePath` / `prefix`）
- Base64
- 圆形头像 + 边框/阴影
- 进度、自动重试、手动重试
- `WImageDefaultsScope` 默认占位符/错误占位
- 直接配置 `PaintingBinding.instance.imageCache` 的缓存预算
- `precacheImage` 预热 `ImageCache`
- WText / WBadge / WClipRRect / Gradient / WStep / WListView
- WActionRow / WSelectableRow / WTabBar / WNavBar / Notification / KeepAlive
- WListViewSliver.grid / Row / Column / WImageController
- WGradients / WShadows / BoxDecoration 扩展
- WScaffold / WAppBar / WNavBar / WScreen / extensions

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
| 进度 + 重试 | `WImage.network(..., config: WImageLoadConfig(retryCount:, progressBuilder:, errorWidgetBuilder:))` |
| 默认加载 UI | `main()` 里的 `WImageDefaultsScope` |
| 缓存预算 | `main()` 里直接配置 `PaintingBinding.instance.imageCache` |
| 预加载 | `states_page.dart` 里的 `precacheImage` 示例（可移到 Playground） |
| 通用组件 | `lib/components_page.dart` |
| 按钮样式 | `lib/buttons_page.dart` |

## 真实引擎 keep-alive / TickerMode 测试

`integration_test/app_keepalive_smoke_test.dart` 是参考示例，验证 `WKeepAliveWrapper`
在真实引擎上的 State/滚动保留与不可见页 TickerMode 关闭：

```bash
cd packages/ui/example
flutter test integration_test/app_keepalive_smoke_test.dart -d <device>
```

它使用固定 `_Harness`，不能替代业务 App 自己的页面测试；只需在需要时复制/改写。
