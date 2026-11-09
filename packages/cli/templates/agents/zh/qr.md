- **扫码**：用 `WQrView`，不要直接用 `QRView`；控制器 `WQrController` 由页面创建并传
  `WQrView(controller: ...)`，重新扫描用 `controller.restart()`（`WQrViewState` 已移除）。
- **单次 / 连续**：`scanOnce` 控制扫完是否暂停（默认 true，只在传了 `onScanned` 时生效）；
  连续扫描用 `scanOnce: false` + `scanInterval` 去重；不传 `onScanned` 时不会暂停相机。
