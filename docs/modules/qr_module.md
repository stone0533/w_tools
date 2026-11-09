# QR 模块文档

## 概述

QR 模块（`w_tools_qr` 子包）基于 `qr_code_scanner_plus` 封装，提供二维码 / 条形码扫描组件
`WQrView`、调用方持有的相机控制器 `WQrController`、扫描框样式 `WQrOverlayStyle` 与结构化
扫码结果 `WQrScanResult`。

**核心特性**：
- 支持 Android、iOS 与 Web（桌面端插件抛 `UnsupportedError`）
- 默认单次扫描模式（`scanOnce=true`）：首条码后回调一次、边框切成功色并暂停相机
- 不传 `onScanned` 时不会自动暂停相机，可只监听广播流
- 连续扫描模式下按 `scanInterval`（默认 400ms）对相同内容去重
- 应用退后台自动暂停、回前台恢复（单次扫描完成时不恢复）
- `scannedDataStream` 为广播流，可多监听，且跨平台视图重建保持不变
- Android 热重载自动 pause/resume 防黑屏

依赖：`qr_code_scanner_plus`（锁定 `>=2.1.2 <2.2.0`，2.2+ 要求 Flutter 3.44 / iOS 13 / AGP 9，暂不升级）。

## 快速判断

- 扫码 → `WQrView`
- 重扫 / 闪光灯 / 翻转 / 暂停 → `WQrController`
- 扫描框颜色与尺寸 → `WQrOverlayStyle`
- 扫码结果 → `WQrScanResult`
- 不要直接用 `qr_code_scanner_plus` 的 `QRView`
- 可运行示例：[packages/qr/example](../../packages/qr/example/README.md)

- 强制规则：根 [`AGENTS.md`](../../AGENTS.md)

## 模块结构

```
qr/
└── lib/src/
    ├── qr_view.dart          # WQrView + 内部 State
    ├── qr_controller.dart    # WQrController
    ├── qr_overlay_style.dart # WQrOverlayStyle
    └── qr_scan_result.dart   # WQrScanResult
```

---

## 1. WQrOverlayStyle - 扫描框样式

### 功能说明

扫描相关的视觉参数只有这一处：是否显示、边框颜色、成功色、外边距与扫描框几何。

### 配置字段

| 字段 | 默认值 | 说明 |
|------|--------|------|
| `isVisible` | `true` | 是否绘制扫描框；为 false 时全屏扫描，其余字段不生效 |
| `borderColor` | `Colors.red` | 扫描中的边框颜色 |
| `successColor` | `Colors.green` | 单次扫码成功后的边框颜色（保持到 `restart()`） |
| `margin` | `EdgeInsets.zero` | 扫描框外边距 |
| `borderWidth` | `3.0` | 边框宽度（逻辑像素） |
| `overlayColor` | `Color.fromRGBO(0, 0, 0, 0.5)` | 遮罩颜色（半透明黑） |
| `borderRadius` | `0` | 边框圆角（逻辑像素） |
| `borderLength` | `40` | 边框长度（逻辑像素，四角 L 形边的长度） |
| `cutOutWidth` | `250` | 扫描框宽度（逻辑像素） |
| `cutOutHeight` | 同 `cutOutWidth` | 扫描框高度（为 null 时回退到宽度） |
| `cutOutBottomOffset` | `0` | 扫描框底部偏移（逻辑像素），正值向下移动 |

`WQrOverlayStyle` 实现了 `==` / `hashCode`，相同配置可比较。

### 使用示例

```dart
const style = WQrOverlayStyle(
  borderColor: Colors.blue,
  successColor: Colors.greenAccent,
  borderWidth: 4.0,
  borderRadius: 8,
  cutOutWidth: 300,
  cutOutHeight: 300,
  cutOutBottomOffset: 50,
);

WQrView(
  controller: controller,
  style: style,
  onScanned: (result) {},
);
```

---

## 2. WQrController - 相机控制器

### 功能说明

由调用方创建并持有（与 `WMapController` 同模式），传给 `WQrView.controller`：

- `scannedDataStream` 是**广播流**，支持多个监听者；控制器实例与流在平台视图重建后保持不变
- 相机操作方法转发给底层控制器；未挂载时抛 `StateError`（不静默失败）
- 平台视图（重新）创建时挂载、销毁前解除挂载，由 `WQrView` 内部完成
- 传了 `controller` 时由调用方 `dispose()`；不传时 `WQrView` 自己创建并释放

### 核心属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `isAttached` | `bool` | 是否已挂载到平台视图 |
| `scannedDataStream` | `Stream<Barcode>` | 扫描数据流（广播，可多监听，不关心空 code） |
| `hasPermissions` | `bool` | 相机权限是否已获取（未挂载时 false） |
| `cameraFacing` | `CameraFacing?` | 最近一次已知的相机方向（尚未查询时为 null） |

### 核心方法

| 方法 | 返回类型 | 说明 |
|------|----------|------|
| `restart()` | `Future<void>` | 重扫：重置单次锁定 / 成功色 / 去重窗口并恢复相机；未挂载时 no-op |
| `pauseCamera()` | `Future<void>` | 暂停相机 |
| `resumeCamera()` | `Future<void>` | 恢复相机。**只恢复相机，不重置单次锁定**，需重置请用 `restart()` |
| `stopCamera()` | `Future<void>` | 停止相机（插件只在 iOS 生效，其他平台 no-op） |
| `flipCamera()` | `Future<CameraFacing>` | 翻转前后摄像头，返回翻转后的方向 |
| `getCameraInfo()` | `Future<CameraFacing>` | 获取当前摄像头方向 |
| `getFlashStatus()` | `Future<bool?>` | 获取闪光灯状态 |
| `toggleFlash()` | `Future<void>` | 切换闪光灯 |
| `getSystemFeatures()` | `Future<SystemFeatures>` | 获取设备可用能力 |
| `setInvert(bool enabled)` | `Future<void>` | 开关反色扫描（**仅 Android 生效**） |
| `dispose()` | `Future<void>` | 释放广播流与底层订阅；调用方持有控制器时才需要 |

### 注意事项

- `resumeCamera` 只恢复相机运行态，不会重置单次扫码锁定；若 `scanOnce=true` 且已扫码一次，
  调用后相机恢复但不会再触发 `onScanned`，需要重新扫描请用 `restart()`。
- `WQrView` 内部发出的相机调用失败会走 `onError`；直接调用 `WQrController` 成员
  （含 Web 上同步抛 `UnimplementedError` 的 `hasPermissions` / `stopCamera` / `setInvert` /
  `getSystemFeatures`）会抛给调用方，请自行 `try/catch`。
- 未挂载时调用相机方法抛 `StateError`；`restart()` 是 no-op，便于在初始化前后统一调用。

### 使用示例

```dart
final controller = WQrController();

@override
void dispose() {
  controller.dispose();
  super.dispose();
}

WQrView(
  controller: controller,
  onScanned: (result) => debugPrint(result.code),
);

// 外部控制
await controller.toggleFlash();
final facing = await controller.flipCamera();
await controller.restart();
```

---

## 3. WQrView - 二维码扫描组件

### 功能说明

基于 `qr_code_scanner_plus` 的 `StatefulWidget`，封装扫描框 UI、相机生命周期管理、扫码逻辑与错误处理。

**交互行为**：
- 单次扫码（`scanOnce=true` 且传了 `onScanned`）：边框切 `successColor` → 暂停相机 → 回调
- 连续扫码（`scanOnce=false`）：持续回调，按 `scanInterval` 去重，不切换成功色
- 不传 `onScanned`：不暂停相机，只把数据送进 `scannedDataStream`
- 退后台自动暂停，回前台恢复（单次扫描完成时不恢复）
- Android 热重载自动 pause → resume 防黑屏
- `cameraFacing` / `formatsAllowed` 变化时重建平台视图并重置扫描状态

### 构造参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `controller` | `WQrController?` | `null` | 相机控制器；省略时组件内部创建并在销毁时释放 |
| `style` | `WQrOverlayStyle` | `WQrOverlayStyle()` | 扫描框样式（见 §1） |
| `onScanned` | `void Function(WQrScanResult)?` | `null` | 扫码结果回调；仅在 `Barcode.code` 非空时触发；单次模式最多一次 |
| `onControllerReady` | `void Function(WQrController)?` | `null` | 相机就绪回调；平台视图（重新）创建后触发，传入的就是 `controller` |
| `onPermissionDenied` | `VoidCallback?` | `null` | 无相机权限回调；只在「未授权」首次触发，重新授权后重置 |
| `onError` | `void Function(Object, StackTrace)?` | `null` | 错误回调（相机操作失败、流错误、回调自身异常）；未提供时 debug 下 `debugPrint` |
| `cameraFacing` | `CameraFacing` | `CameraFacing.back` | 摄像头方向。运行期修改会**重建平台视图**并重置扫描状态 |
| `formatsAllowed` | `List<BarcodeFormat>` | `[]` | 允许识别的条码格式；为空表示平台默认。运行期修改会重建平台视图 |
| `scanOnce` | `bool` | `true` | 是否只扫描一次；只有传了 `onScanned` 才生效 |
| `scanInterval` | `Duration` | `400ms` | 相同内容的最小回调间隔；`Duration.zero` 关闭去重；单次 / 连续模式都生效 |

`onScanned` 与 `onControllerReady` 都可省略，也不存在「只监听流必须传 `scanOnce: false`」的约束：
不传 `onScanned` 时组件根本不会自动暂停。

### WQrScanResult

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | `String` | 扫码内容，保证非空 |
| `format` | `BarcodeFormat` | 条码格式 |
| `rawBytes` | `List<int>?` | 原始字节，仅 Android / iOS 提供 |
| `timestamp` | `DateTime` | 包内收到结果的时间 |

### 行为说明

#### 扫码流程（scanOnce=true 且传了 onScanned）

```
相机捕获 → 解析 Barcode
  ├─ code 为空 → 忽略
  ├─ 已扫码 → 忽略
  ├─ 去重窗口内相同内容 → 忽略
  └─ 有效扫码
       ├─ 边框切换为 successColor
       ├─ 暂停相机
       └─ 回调 onScanned(WQrScanResult)
            └─ 回调抛异常时：回滚锁定、恢复相机、走 onError
```

#### 扫码流程（scanOnce=false 或未传 onScanned）

```
相机捕获 → 解析 Barcode
  ├─ code 为空 → 忽略
  ├─ 去重窗口内相同内容 → 忽略
  └─ 有效扫码
       └─ 回调 onScanned（若有），不暂停、不切换成功色
```

#### 生命周期

```
应用进入后台 → pauseCamera() + 标记 _pausedByLifecycle = true
应用回到前台（_pausedByLifecycle = true）
  ├─ 单次模式且已扫码 → 不恢复（保持暂停）
  └─ 其他 → resumeCamera() + 清除 _pausedByLifecycle
```

#### didUpdateWidget 触发重建

| 参数变化 | 影响 |
|----------|------|
| `cameraFacing` 或 `formatsAllowed` | 重建平台视图（更换 `_qrKey`），重置所有扫描状态 |
| `controller` | 解绑旧控制器（内部创建的会释放）并挂到新控制器 |
| `style` | 即时更新样式（不重建视图） |
| `scanOnce` / `onScanned` 是否为空 | 重置单次锁定、成功色与去重记录 |

#### reassemble（热重载）

Android 上热重载后相机可能黑屏，框架自动执行 `pauseCamera()` → `resumeCamera()` 恢复；Web 跳过此步骤。

### 使用示例

```dart
// 基础单次扫描
final controller = WQrController();
WQrView(
  controller: controller,
  onScanned: (result) {
    debugPrint('扫码结果: ${result.code}');
  },
);

// 连续扫描 + 去重
WQrView(
  controller: controller,
  scanOnce: false,
  scanInterval: const Duration(milliseconds: 500),
  onScanned: (result) => debugPrint('连续扫码: ${result.code}'),
);

// 只监听广播流
controller.scannedDataStream.listen((barcode) {
  debugPrint('广播流收到: ${barcode.code}');
});
WQrView(controller: controller);

// 自定义扫描框样式
WQrView(
  controller: controller,
  style: const WQrOverlayStyle(
    borderWidth: 4,
    borderRadius: 8,
    cutOutWidth: 280,
    cutOutHeight: 280,
    cutOutBottomOffset: 60,
  ),
  onScanned: (result) {},
);
```

---

## 交互流程（状态机）

```
  ┌──────────────┐
  │   初始化     │
  │ WQrView 创建 │
  └──────┬───────┘
         │
         ▼
  ┌──────────────┐      cameraFacing /
  │  扫描中      │◄───── formatsAllowed 变化
  │ (camera 运行)│            │
  └──┬──┬──┬──┬──┘            │
     │  │  │  │               ▼
     │  │  │  └────────► 重建平台视图 + 重置状态
     │  │  │
     │  │  └──► 退后台 → 暂停 → 回前台恢复
     │  │
     │  └──► didUpdateWidget:
     │          - style 变化 → 即时更新
     │          - scanOnce 切换 → 重置锁定 / 去重
     │
     └──► 扫码成功
            ├─ 单次模式 → 成功色 + 暂停相机 + 回调（异常则回滚）
            └─ 连续模式 → 回调（scanInterval 去重），不暂停
                           │
                           ▼
                    业务方处理完 → controller.restart()
                           │
                           ▼
                    回到「扫描中」
```

---

## 注意事项

### 权限

- **Android**：在 `AndroidManifest.xml` 添加 `CAMERA` 权限：
  ```xml
  <uses-permission android:name="android.permission.CAMERA" />
  ```
- **iOS**：在 `Info.plist` 添加 `NSCameraUsageDescription`：
  ```xml
  <key>NSCameraUsageDescription</key>
  <string>需要相机权限以扫描二维码</string>
  ```
- 运行时需先申请权限（例如使用 `permission_handler` 包），否则 `onPermissionDenied` 会被触发。

### 平台限制

| 平台 | 支持情况 |
|------|----------|
| Android | ✅ 完整支持 |
| iOS | ✅ 完整支持 |
| Web | ⚠️ 扫码可用；`pause/resume/flip` 经 WQrView 调用会走 `onError`，直接调用 controller 的 4 个成员同步抛 `UnimplementedError` |
| Windows / macOS / Linux | ❌ 插件抛 `UnsupportedError` |

### 版本锁定

`qr_code_scanner_plus` 锁定 `>=2.1.2 <2.2.0`。2.2.0+ 要求 Flutter 3.44 / iOS 13 / AGP 9，贸然升级可能破坏现有项目的构建环境。

### 生命周期

- `WQrController` 由调用方持有，跨平台视图重建保持不变；`scannedDataStream` 也不会被替换。
- `cameraFacing` / `formatsAllowed` 变化会触发平台视图重建：控制器先 detach，新视图创建后重新 attach，
  并再次触发 `onControllerReady`。
- `resumeCamera()` 只恢复相机运行态，**不会重置单次锁定**；需显式调用 `restart()`。
- 单次扫描完成后应用退后台再回前台，**不会自动恢复相机**（避免意外重复扫码）；如需重新扫描请调用 `restart()`。
- 传了 `controller` 时框架不会释放它，页面销毁时要自己 `dispose()`。

### 错误处理

- `onScanned` 自身抛出的异常会被捕获并通过 `onError` 上报，同时回滚单次锁定、恢复相机。
- 底层控制器抛出的 `CameraException` 会通过 `onError` 上报，由调用方决定如何处理。
- `onError` 自身抛出的异常会被忽略，避免形成未处理异常。

### 其他

- `borderLength` 需 `<= min(cutOutWidth, cutOutHeight) / 2 + borderWidth * 2`，否则构造时断言失败。
- `scanInterval` 默认 `400ms`：同一内容最快每 400ms 回调一次；持续对着同一码会持续回调，
  需要「一码一次」请自行去重或改用单次模式。
- `style.isVisible = false` 时全屏扫描，颜色与扫描框几何均不生效。
- `formatsAllowed` 为空列表时使用平台默认识别格式，显式指定可提升识别速度。
- 桌面端（Windows/macOS/Linux）运行会在插件层抛 `UnsupportedError`，请在使用前做平台判断。

### 从 1.x 升级

2.0 是 breaking 版本：`WQrViewState` 已移除，命令式入口改为 `WQrController.restart()`；
`onScanned` 改为回调 `WQrScanResult`；扫描框样式统一到 `WQrOverlayStyle`。
逐条对照见 [qr 2.0 迁移](../migrations/qr-2.0.md)。

---

相关文档：[模块索引](README.md) · [组件目录](components.md) · [接入约定](../conventions.md)
