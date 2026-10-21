# w_tools_map example

最小可运行示例：渲染 3 个门店，点 marker 选中并平滑移动相机，底部弹出卡片。

## 运行

```bash
cd packages/map/example
flutter pub get
flutter run
```

> **需要配置 Google Maps API Key**，否则地图区域会是空白：
> - Android：`android/app/src/main/AndroidManifest.xml` 里加
>   `<meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_KEY" />`
> - iOS：`ios/Runner/AppDelegate.swift` 里调用
>   `GMSServices.provideAPIKey("YOUR_KEY")`
>
> 配置方法见 <https://pub.dev/packages/google_maps_flutter>。

## 这个示例演示了什么

| 能力 | 对应代码 |
|---|---|
| 业务模型实现 `WMapItem` | `Shop implements WMapItem` |
| 用列表构造 `WMapZone` | `WMapZone<Shop>(maps: [...])` |
| 选中/关闭的缩放与偏移 | `WMapConfig(selectZoom:, closeZoom:, selectLatOffset:)` |
| 接收选中事件、渲染业务 UI | `onItemSelected` / `onItemClosed` + 底部 `Card` |

注意：示例故意**不内置列表页**，只演示地图与事件的接法——业务 UI 由使用方自己写。
