> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

# qr 3.0 迁移：控制器必传 / 控制器收口 / 样式与结果瘦身

3.0 的核心变化：`WQrView` 不再自己创建控制器，`WQrController` 只保留真正用得到的相机能力，
扫描框样式与扫码结果去掉「包内自造」的字段。旧名一律不保留。

## 1. 类型对照

| 旧 | 新 | 说明 |
| --- | --- | --- |
| `WQrView(controller: null)` / 不传 `controller` | `WQrView(controller: controller)` | `controller` 改为必传；组件不再内部创建与释放 |
| `WQrOverlayStyle.isVisible: false` | `WQrView(style: null)` | 全屏扫描由 style 是否为 null 表达 |
| `WQrView(style: WQrOverlayStyle(successColor: …))` | 删除 | 单次成功后的边框高亮已移除，成功反馈由业务在 `onScanned` 里自绘 |
| `WQrView.scanInterval` | `WQrView.scanThrottle` | 只作用于连续模式；`Duration.zero` 关闭 |
| `WQrScanResult.timestamp` | 删除 | 回调时刻的 `DateTime.now()`，没有业务含义 |
| `WQrView.scanOnce`（依赖 `onScanned` 才生效） | `WQrView.scanOnce` | 不再看 `onScanned`：首码后一律暂停 |
| `WQrController.hasPermissions` | 删除 | Web 上会同步抛 `UnimplementedError`；用 `onPermissionDenied` 做权限 UI |
| `WQrController.getCameraInfo()` | `WQrController.cameraFacing` | 方向由 `flipCamera()` 与挂载时的初始值维护 |
| `WQrController.stopCamera()` | 删除 | 只有 iOS 生效，与 `pauseCamera` / 生命周期重叠 |
| `WQrController.getSystemFeatures()` | 删除 | 平台残缺且无消费场景 |
| `WQrController.setInvert(bool)` | 删除 | 反色扫描属长尾能力，仅 Android 生效 |
| `WQrController.attach` / `detach` | 删除 | 内部接线改为私有；调用方不需要也不应该手动挂载 |
| `WQrController.restart()`（未挂载 no-op） | 未挂载抛 `StateError` | 与其他相机方法一致，不再静默 |

## 2. 迁移步骤

1. 依赖改为 `w_tools_qr: ^3.0.0`，跑一次 `flutter pub get`。
2. 页面里创建控制器并传给 `WQrView(controller: …)`；不再依赖组件内部创建。
3. `controller` 的释放留在页面 `dispose()`：`controller.dispose()`。
4. 全屏扫描由 `style: null` 表达，删掉 `isVisible`；删掉 `successColor`，成功态自己画。
5. `scanInterval` 改名 `scanThrottle`；如果只是单次扫码，直接删掉即可（单次模式不节流）。
6. `WQrScanResult.timestamp` 的消费点删除；需要时间戳时在 `onScanned` 里自己取。
7. 如果用了 `hasPermissions` / `getCameraInfo` / `stopCamera` / `getSystemFeatures` / `setInvert`，
   按上表替换或删除；`cameraFacing` 可读当前方向。
8. 如果只监听 `scannedDataStream`：默认 `scanOnce: true` 会在首码后暂停相机，
   需要持续接收时显式传 `scanOnce: false`。

## 3. 行为变化（升级后要留意）

| 场景 | 2.x | 3.0 |
| --- | --- | --- |
| 不传 `onScanned`、只监听流 | 不暂停相机，`scanOnce` 不生效 | 仍按 `scanOnce` 管理相机：首码后暂停 |
| 单次扫码成功 | 边框切 `successColor` | 不再有边框成功态 |
| 单次模式下相同内容 | 走 400ms 去重表 | 单次模式不节流（只回调一次） |
| 连续模式节流 | 每个 code 独立 400ms 窗口，最多跟踪 64 个 | 只比较「上一次内容 + 单调时钟」 |
| `WQrOverlayStyle` 相等性 | 实现 `==` / `hashCode`（值相等） | 不再实现，按标识比较 |
| Web 上单次扫码 | 暂停失败 → `onError` 收到 `UnimplementedError` | 组件跳过自动暂停，不再产生假错误 |
| 未挂载时 `restart()` | 静默 no-op | 抛 `StateError` |
| `formatsAllowed` 原地修改 | 组件检测到并重建平台视图 | 不检测；请传新列表 |
| Android 热重载后相机黑屏 | `reassemble` 自动 pause → resume | 补丁删除，由调用方自行处理 |
