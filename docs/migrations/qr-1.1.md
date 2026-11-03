# qr 1.1 迁移：可选回调 / 扫描间隔 / 错误输出

| 旧 | 新 | 说明 |
| --- | --- | --- |
| `WQrView(onScanned: ...)` 必填 | `onScanned` 可省略（与 `onQRViewCreated` 至少提供一个） | 只监听 `scannedDataStream` 时不必再传空回调 |
| `scanInterval` 默认 `Duration.zero` | 默认 `400ms` | 连续扫码默认按内容去重；需要每个码都回调时显式传 `Duration.zero` |
| 未传 `onError` 时 `FlutterError.reportError` | debug 下 `debugPrint` | 不再污染错误上报；需要上报请传 `onError` |
| `WQrViewOverlayShape` 无 `==` | 已加 `==` / `hashCode` | 相同配置可比较，便于重建判断 |
