# qr 使用规则（给人和 AI）

## 什么时候用

相机扫码（二维码 / 条形码）。

## 最小用法

```dart
final controller = WQrController();

WQrView(
  controller: controller,
  onScanned: (result) => debugPrint(result.code), // WQrScanResult
);
// 需要再扫
await controller.restart();
```

`WQrController` 由页面创建并持有，`dispose()` 里释放；`WQrViewState` 已移除（2.0），
不要再通过 `GlobalKey` 取状态。

只监听广播流时不用传 `onScanned`，也不会自动暂停相机：

```dart
controller.scannedDataStream.listen((barcode) => debugPrint(barcode.code));
WQrView(controller: controller);
```

## 不要用

- 直接 `QRView`（用 `WQrView`）；
- 在 `onScanned` 里做重 UI 操作（先暂停相机、再跳转）；
- 用 `scanInvert`（2.0 已移除，改用 `setInvert`）。

## 常见坑

- Android 配 `CAMERA`；iOS 配 `NSCameraUsageDescription`；
- 默认 `scanOnce = true`：传了 `onScanned` 时扫完暂停，再扫要 `controller.restart()`；
  没传 `onScanned` 则不会暂停，`scanOnce` 不生效；
- `scanInterval` 默认 400ms：同一内容最快每 400ms 回调一次（单次 / 连续模式都生效），
  `Duration.zero` 关闭去重；
- 运行期改 `cameraFacing` / `formatsAllowed` 会重建平台视图（相机重启、扫描状态重置）；
- 未挂载（还没收到 `onControllerReady` 或视图已销毁）时，相机方法抛 `StateError`，
  `controller.restart()` 是 no-op。

完整说明：[qr_module.md](../modules/qr_module.md) · 示例：`packages/qr/example`
