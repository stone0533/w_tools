# qr 使用规则（给人和 AI）

## 什么时候用

相机扫码（二维码 / 条形码）。

## 最小用法

```dart
final controller = WQrController();

WQrView(
  controller: controller, // 必传
  onScanned: (result) => debugPrint(result.code), // WQrScanResult
);
// 需要再扫
await controller.restart();
```

`WQrController` 由页面创建并持有，`dispose()` 里释放；`WQrViewState` 已移除（2.0），
不要再通过 `GlobalKey` 取状态。

只监听广播流时可省略 `onScanned`；需要持续接收流就显式传 `scanOnce: false`：

```dart
controller.scannedDataStream.listen((barcode) => debugPrint(barcode.code));
WQrView(controller: controller, scanOnce: false);
```

## 不要用

- 直接 `QRView`（用 `WQrView`）；
- 在 `onScanned` 里做重 UI 操作（先暂停相机、再跳转）；
- 在 Web 上调 `WQrController.pauseCamera()` / `resumeCamera()`（插件未实现，组件已跳过）。

## 常见坑

- Android 配 `CAMERA`；iOS 配 `NSCameraUsageDescription`；
- 默认 `scanOnce = true`：首条有效码后暂停相机，再扫要 `controller.restart()`；
- `scanThrottle` 默认 400ms，只在连续模式（`scanOnce: false`）对连续相同内容节流，
  `Duration.zero` 关闭；
- 运行期改 `cameraFacing` / `formatsAllowed` 会重建平台视图（相机重启、扫描状态重置）；
- 未挂载（`isAttached == false`）时相机方法与 `restart()` 都抛 `StateError`；
- 扫中变绿用 `WQrOverlayStyle.successColor`（opt-in，单次模式，保持到 `restart()`）；
  不要自绘扫描框几何，透明 `overlayColor` 会把边框一起抹掉（`explain WQrOverlayStyle`）。

完整说明：[qr_module.md](../modules/qr_module.md) · 示例：`packages/qr/example`
