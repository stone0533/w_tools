# w_tools_qr 示例

真实场景示例，覆盖：

- `WQrView` 单次扫码
- 扫描结果展示
- `WQrController.restart()` 继续扫描
- `WQrController.scannedDataStream` 广播流
- `WQrController` 闪光灯 / 摄像头翻转
- 连续扫描 / 扫描框 / 仅二维码开关
- 无权限提示与错误提示

## 运行

```bash
cd packages/qr/example
flutter pub get
flutter run
```

> 需要真机或模拟器相机；桌面端不支持。

## 权限

Android：

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

iOS `Info.plist`：

```xml
<key>NSCameraUsageDescription</key>
<string>需要相机权限用于扫码</string>
```

## 页面

```text
二维码扫描
扫描成功 → 底部展示结果
继续扫描 → controller.restart()
右上角 → 闪光灯 / 翻转摄像头
顶部 → 连续扫描 / 扫描框 / 仅二维码开关
```

## 测试

测试使用 MethodChannel mock 模拟平台视图与扫码事件，不需要真实相机。
