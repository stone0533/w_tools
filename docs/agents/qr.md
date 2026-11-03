# qr 使用规则（给人和 AI）

## 什么时候用

相机扫码（二维码 / 条形码）。

## 最小用法

```dart
final key = GlobalKey<WQrViewState>();

WQrView(
  key: key,
  onScanned: (barcode) {
    final code = barcode.code;
    if (code != null) { ... }
  },
);
// 需要再扫：单次模式下先重启
key.currentState?.restartScan();
```

只监听流时可不传 `onScanned`（与 `onQRViewCreated` 至少提供一个）。

## 不要用

- 直接 `QRView`（用 `WQrView`）；
- 在 `onScanned` 里做重 UI 操作（先暂停相机、再跳转）。

## 常见坑

- Android 配 `CAMERA`；iOS 配 `NSCameraUsageDescription`；
- 默认 `scanOnce = true`，扫完暂停，再扫要 `restartScan()`；
- 连续扫描默认 `scanInterval = 400ms`，同一内容不会每秒重复回调；
- 用 `GlobalKey<WQrViewState>` 才能调用 `restartScan()`。

完整说明：[qr_module.md](../modules/qr_module.md) · 示例：`packages/qr/example`
