> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

# qr 2.0 迁移：控制器归调用方 / 样式收口 / 结构化结果

2.0 的核心变化：命令式入口从 widget State 换成 `WQrController`，扫描框视觉参数收进
`WQrOverlayStyle`，`onScanned` 回调结构化结果。旧名一律不保留。

## 1. 类型对照

| 旧 | 新 | 说明 |
| --- | --- | --- |
| `WQrViewOverlayShape` | `WQrOverlayStyle` | 扫描框样式；新增 `isVisible` / `successColor` / `margin` 字段 |
| `WQrView(borderColor: …)` | `WQrOverlayStyle(borderColor: …)` | 字段同名，搬到 `style` 里 |
| `WQrView(checkedBorderColor: …)` | `WQrOverlayStyle(successColor: …)` | 语义从「勾选」改为「扫码成功」 |
| `WQrView(showOverlay: …)` | `WQrOverlayStyle(isVisible: …)` | 取反无关，直接搬 |
| `WQrView(overlay: …)` | `WQrView(style: …)` | 原 `overlay` 的字段就是现在的 `style` |
| `WQrView(overlayMargin: …)` | `WQrOverlayStyle(margin: …)` | 外边距属于样式 |
| `onQRViewCreated:` | `onControllerReady:` | 不再泄漏插件名词；每次平台视图（重新）创建后触发 |
| `noPermissionCallback:` | `onPermissionDenied:` | 回调字段统一 `onXxx` |
| `void Function(Barcode)` | `void Function(WQrScanResult)` | 结果含 `code` / `format` / `rawBytes` / `timestamp` |
| `WQrController.internal` | `WQrController()` | 调用方自己创建控制器 |
| `scanInvert(bool)` | `setInvert(bool enabled)` | 动词 + 布尔参数规范 |
| `WQrController.facing` | `WQrController.cameraFacing` | 与 `WQrView.cameraFacing` 同名 |
| `@internal WQrController.dispose()` | 公开 `dispose()` | 传了 `controller` 就由调用方释放 |
| `WQrViewState` + `GlobalKey` | `WQrController.restart()` | `WQrViewState` 不再公开 |

## 2. 迁移步骤

1. 依赖改为 `w_tools_qr: ^2.0.0`，跑一次 `dart pub get`。
2. 把五个视觉参数搬进 `WQrOverlayStyle`，传给 `WQrView(style: …)`。
3. `onQRViewCreated` → `onControllerReady`；`noPermissionCallback` → `onPermissionDenied`。
4. `onScanned` 回调签名从 `(Barcode barcode)` 改为 `(WQrScanResult result)`：
   - `barcode.code` → `result.code`（不再需要判空）；
   - 需要原始 `Barcode`（例如 `rawBytes`）时读 `result.rawBytes`，或监听
     `WQrController.scannedDataStream`。
5. 重扫：删掉 `GlobalKey<WQrViewState>`，改成页面持有 `WQrController`，
   `key.currentState?.restartScan()` → `controller.restart()`。
6. 页面 `dispose()` 里加 `controller.dispose()`（只有自己创建控制器时才需要）。
7. 如果只是拿控制器做相机操作，可继续用 `onControllerReady` 拿到实例；但推荐在页面里
   自己创建并传 `WQrView(controller: …)`，这样控制器在平台视图重建后依然可用。

## 3. 行为变化（升级后要留意）

| 场景 | 1.x | 2.0 |
| --- | --- | --- |
| 只监听 `scannedDataStream`、不传 `onScanned` | 必须显式 `scanOnce: false`，否则 debug 断言失败 | 不再暂停相机，`scanOnce` 不生效 |
| `scanInterval` | 只在 `scanOnce: false` 生效 | 单次 / 连续模式都生效；`Duration.zero` 关闭 |
| 单次扫码成功后的边框 | 切成功色后一直保持 | 只在单次模式切成功色，`restart()` 复位 |
| 连续模式扫码 | 首次成功后边框长期变绿 | 不再切换成功色 |
| 权限被插件多次上报 | 每次未授权都回调 | 只回调一次，重新授权后重置 |
| `onScanned` 抛异常 | 单次锁定已置位，扫码能力被锁死 | 回滚锁定并恢复相机，同时走 `onError` |
| 控制器生命周期 | 平台视图重建后旧控制器失效 | 控制器实例与 `scannedDataStream` 保持不变 |
| 未挂载时调相机方法 | 不会发生（控制器总是已挂载） | 抛 `StateError`；`restart()` 是 no-op |
| `stopCamera()` | 转发给插件 | 插件只在 iOS 生效，其他平台 no-op |
