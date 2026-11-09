## 2.0.0

### Breaking
- `WQrViewOverlayShape` → `WQrOverlayStyle`：扫描框颜色、是否显示与外边距收进该类型。
  `WQrView.borderColor` / `WQrView.checkedBorderColor` / `WQrView.showOverlay` /
  `WQrView.overlay` / `WQrView.overlayMargin` 五个参数合并为 `style`。
- `WQrView.onQRViewCreated` → `WQrView.onControllerReady`；
  `WQrView.noPermissionCallback` → `WQrView.onPermissionDenied`。
- `WQrView.onScanned` 的参数由 `Barcode` 改为 `WQrScanResult`（`code` / `format` / `rawBytes` / `timestamp`）。
- `WQrViewState` 已移除：命令式入口由 `GlobalKey<WQrViewState>.restartScan()` 改为
  `WQrController.restart()`。
- `WQrController` 改为调用方创建并持有（`WQrView(controller: ...)`）：`WQrController()` 构造公开，
  `WQrController.internal` 构造移除，`dispose()` 归调用方；
  `WQrController.scanInvert` → `WQrController.setInvert`，`facing` → `cameraFacing`，新增 `isAttached`。
- 未挂载到 `WQrView` 时相机方法抛 `StateError`（不再静默或空指针）。

### Changed
- `WQrView`：没传 `onScanned` 时不再自动暂停相机，「只监听流必须 `scanOnce: false`」的断言删除。
- `scanInterval` 与 `scanOnce` 解耦：去重窗口在单次 / 连续模式下都生效，`Duration.zero` 关闭去重。
- 单次扫码成功才把边框切成 `successColor` 并保持到 `restart()`；连续模式不再长期保留成功色。
- `onPermissionDenied` 只在「未授权」时上报一次，重新授权后重置。
- `onScanned` 抛异常时回滚单次锁定并恢复相机，不会再静默锁死扫码能力。
- 去重改用单调时钟与固定容量表（最多跟踪 64 个条码）。
- 控制器实例跨平台视图重建保持不变，`scannedDataStream` 也不会被替换。

### Added
- `WQrScanResult`：结构化扫码结果。
- `WQrController.restart()` / `isAttached` / `cameraFacing`。
- `WQrOverlayStyle.isVisible` / `successColor` / `margin`。

### Fixed
- `scanOnce` 切换时边框高亮与去重记录未复位。
- 权限被插件多次上报时回调重复触发。

## 1.1.1

### 修复
- 只监听 `scannedDataStream` / 使用 `onQRViewCreated` 却沿用默认 `scanOnce: true` 时，
  首码后相机会暂停；构造增加 assert，必须显式传 `scanOnce: false`（文档已同步）。
- `flipCamera` / `getCameraInfo` 记录当前方向，平台视图重建后保持翻转结果。

# Changelog

## 1.1.0

### Changed
- `WQrView.onScanned` 改为可选（与 `onQRViewCreated` 至少提供一个，否则断言）。
- `scanInterval` 默认值改为 400ms（连续扫码默认去重）。
- 未传 `onError` 时不再 `FlutterError.reportError`，改为 debug 下 `debugPrint`。
- `WQrViewOverlayShape` 实现 `==` / `hashCode`。

## 1.0.1

### Fixed
- `WQrView` 平台视图在 State 销毁后回调时不再建立新控制器 / 订阅。
- `reassemble` 在应用后台时不再恢复相机。
- `WQrViewOverlayShape` 校验边框与扫描框尺寸必须大于 0。
- `formatsAllowed` 使用不可变快照，支持调用方原地修改列表后触发平台视图重建。

## 1.0.0

首次发布。

- 新增 `WQrView`：二维码 / 条形码扫描组件，支持单次与连续扫描
- 新增 `scanOnce` / `scanInterval`：扫码后暂停、相同内容去重
- 新增 `WQrViewState.restartScan()`：重新开始扫描
- 新增 `WQrController`：广播式扫描流与相机控制（暂停 / 恢复 / 翻转 / 闪光灯等）
- 应用生命周期：后台自动暂停相机，前台恢复
- 新增 `WQrViewOverlayShape`：扫描框颜色、边框、圆角与区域尺寸配置
- 相机与扫描流异常统一通过 `onError` 上报
- 依赖 `qr_code_scanner_plus` 2.1.2
