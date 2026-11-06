# w_tools_map 示例

真实场景示例，覆盖：

- `WMapItemMapper` 适配普通业务模型
- `WMapZone` 数据与 marker
- `WMapOptions` 选中 / 关闭 / 地图点击
- `WMapController.select` / `closeSelection`
- `WMapZone.update` 筛选门店
- `WMapOptions.padding` 避免底部卡片遮住 marker

## 运行

```bash
cd packages/map_google/example
flutter pub get
flutter run
```

## Google Maps API Key

示例本身不包含 API Key，运行前需要按 `google_maps_flutter` 文档配置：

```text
Android: AndroidManifest.xml meta-data com.google.android.geo.API_KEY
iOS: AppDelegate / Info.plist 对应配置
```

未配置时地图底图可能空白，但页面与门店卡片仍可交互。

## 页面

```text
门店地图
点击 marker 或底部门店按钮 → 选中
底部卡片 → 关闭选中
点击地图空白 → 关闭选中
```

## 测试

测试只验证 widget wiring 与选择流程，不依赖真实 Google Maps 平台视图。
