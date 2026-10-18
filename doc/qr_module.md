# QR 模块文档

## 概述

QR 模块（`w_tools_qr` 子包）基于 `qr_code_scanner_plus` 封装，提供二维码 / 条形码扫描组件 `WQrView`、相机控制器 `WQrController` 和扫描框样式 `WQrViewOverlayShape`。

**核心特性**：
- 支持 Android、iOS 与 Web（桌面端插件抛 `UnsupportedError`）
- 默认单次扫描模式（`scanOnce=true`），首次成功扫码后自动暂停相机
- 连续扫描模式下可配置 `scanInterval` 按内容+时间窗去重
- 应用退后台自动暂停、回前台恢复（单次扫描完成时不恢复）
- `scannedDataStream` 为广播流，可多监听（与 `onScanned` 同时使用）
- Android 热重载自动 pause/resume 防黑屏

依赖：`qr_code_scanner_plus`（锁定 `>=2.1.2 <2.2.0`，2.2+ 要求 Flutter 3.44 / iOS 13 / AGP 9，暂不升级）。

## 模块结构

```
qr/
└── lib/src/
    ├── qr_view.dart           # WQrView / WQrViewState
    ├── qr_controller.dart    # WQrController
    └── qr_overlay_shape.dart  # WQrViewOverlayShape
```

---

## 1. WQrViewOverlayShape - 扫描框样式

### 功能说明

纯数据类，配置扫描框的边框、遮罩、圆角和尺寸。

### 配置字段

| 字段 | 默认值 | 说明 |
|------|--------|------|
| `borderWidth` | `3.0` | 边框宽度（逻辑像素） |
| `overlayColor` | `Color.fromRGBO(0, 0, 0, 0.5)` | 遮罩颜色（半透明黑） |
| `borderRadius` | `0` | 边框圆角（逻辑像素） |
| `borderLength` | `40` | 边框长度（逻辑像素，四角 L 形边的长度） |
| `cutOutWidth` | `250` | 扫描框宽度（逻辑像素） |
| `cutOutHeight` | 同 `cutOutWidth` | 扫描框高度（为 null 时回退到宽度） |
| `cutOutBottomOffset` | `0` | 扫描框底部偏移（逻辑像素），正值向下移动 |

### 使用示例

```dart
const overlay = WQrViewOverlayShape(
  borderWidth: 4.0,
  borderColor: Colors.blue, // 实际颜色由 WQrView.borderColor 控制
  borderRadius: 8,
  cutOutWidth: 300,
  cutOutHeight: 300,
  cutOutBottomOffset: 50,
);
```

---

## 2. WQrController - 相机控制器

### 功能说明

对底层 `QRViewController` 的轻量包装：

- `scannedDataStream` 是**广播流**，支持多个监听者（底层是单订阅流，包装层只订阅一次并转发到广播流）
- 相机操作方法直接转发给底层控制器
- 与平台视图**同生命周期**：视图重建后会创建新实例，旧的 controller 不再可用

### 核心属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `scannedDataStream` | `Stream<Barcode>` | 扫描数据流（广播，可多监听，不关心空 code） |
| `hasPermissions` | `bool` | 相机权限是否已获取 |

### 核心方法

| 方法 | 返回类型 | 说明 |
|------|----------|------|
| `pauseCamera()` | `Future<void>` | 暂停相机 |
| `resumeCamera()` | `Future<void>` | 恢复相机。**只恢复相机，不重置 `scanOnce` 锁定**，需重置请用 `WQrViewState.restartScan()` |
| `stopCamera()` | `Future<void>` | 停止相机 |
| `flipCamera()` | `Future<CameraFacing>` | 翻转前后摄像头，返回翻转后的方向 |
| `getFlashStatus()` | `Future<bool?>` | 获取闪光灯状态 |
| `toggleFlash()` | `Future<void>` | 切换闪光灯 |
| `getCameraInfo()` | `Future<CameraFacing>` | 获取当前摄像头方向 |
| `getSystemFeatures()` | `Future<SystemFeatures>` | 获取设备可用能力 |
| `scanInvert(bool)` | `Future<void>` | 开关反色扫描（**仅 Android 生效**） |
| `dispose()` | `Future<void>` | 释放广播流与底层订阅，`@internal`，由框架内部调用 |

### 注意事项

- `resumeCamera` 只恢复相机运行态，不会重置 `scanOnce` 的已扫码锁定；若 `scanOnce=true` 且已扫码一次，调用 `resumeCamera` 后相机恢复但不会再触发 `onScanned`。
- 底层控制器抛出的 `CameraException` 由调用方处理，本类不捕获。
- 控制器通过 `WQrView.onQRViewCreated` 回调获得，**每次回调都是新实例**；平台视图重建（`cameraFacing` / `formatsAllowed` 变化）后旧 controller 会被 `dispose()`。

### 使用示例

```dart
// 在 onQRViewCreated 中持有 controller
WQrController? _cameraController;

WQrView(
  onQRViewCreated: (controller) {
    _cameraController = controller;
    // 广播流可多监听
    controller.scannedDataStream.listen((barcode) {
      debugPrint('广播流收到: ${barcode.code}');
    });
  },
  // ...
);

// 外部控制
await _cameraController?.toggleFlash();
final facing = await _cameraController?.flipCamera();
await _cameraController?.pauseCamera();
```

---

## 3. WQrView - 二维码扫描组件

### 功能说明

基于 `qr_code_scanner_plus` 的 `StatefulWidget`，封装扫描框 UI、相机生命周期管理、扫码逻辑与错误处理。

**交互行为**：
- 首次成功扫码（`scanOnce=true`）：边框切 `checkedBorderColor` → 暂停相机 → 触发 `onScanned`
- 连续扫码（`scanOnce=false`）：持续回调，按 `scanInterval` 去重
- 退后台自动暂停，回前台恢复（单次扫描完成时不恢复）
- Android 热重载自动 pause → resume 防黑屏
- `cameraFacing` / `formatsAllowed` 变化时重建平台视图并重置扫描状态

### 构造参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `borderColor` | `Color` | `Colors.red` | 扫描框边框颜色 |
| `checkedBorderColor` | `Color` | `Colors.green` | 扫描成功后的边框颜色 |
| `showOverlay` | `bool` | `true` | 是否绘制扫描框。为 false 时全屏扫描，边框颜色和 overlay 均不生效 |
| `overlay` | `WQrViewOverlayShape?` | `null` | 扫描框样式；为 null 时使用 `WQrViewOverlayShape` 默认值 |
| `overlayMargin` | `EdgeInsetsGeometry` | `EdgeInsets.zero` | 扫描框外边距 |
| `noPermissionCallback` | `VoidCallback?` | `null` | 无相机权限回调。权限状态可能被插件多次上报，因此回调也可能多次触发 |
| `onScanned` | `void Function(Barcode)` | **必填** | 扫描到有效内容时的回调。仅在 `Barcode.code` 非空时触发；`scanOnce=true` 时最多触发一次 |
| `onQRViewCreated` | `void Function(WQrController)?` | `null` | 相机控制器创建回调。平台视图重建后再次回调新 controller，旧的不再可用 |
| `cameraFacing` | `CameraFacing` | `CameraFacing.back` | 摄像头方向。运行期修改会**重建平台视图**并重置扫描状态 |
| `formatsAllowed` | `List<BarcodeFormat>` | `[]` | 允许识别的条码格式；为空表示使用平台默认值。运行期修改会重建平台视图 |
| `scanOnce` | `bool` | `true` | 是否只扫描一次。为 true 时首次成功后暂停相机；为 false 时持续回调 |
| `scanInterval` | `Duration` | `Duration.zero` | 连续扫描模式下相同内容的最小回调间隔；仅在 `scanOnce=false` 时生效 |
| `onError` | `void Function(Object, StackTrace)?` | `null` | 错误回调，用于上报相机操作失败、扫描流错误与 `onScanned` 自身抛出的异常；未提供时通过 `FlutterError.reportError` 上报 |

### WQrViewState 公开方法

| 方法 | 说明 |
|------|------|
| `restartScan()` | 重置边框颜色、清空去重记录、恢复相机。在 `scanOnce=false` 时可用于恢复边框颜色；若应用仍在后台则等到回前台后再恢复 |

通过 `GlobalKey<WQrViewState>` 调用：

```dart
final key = GlobalKey<WQrViewState>();
WQrView(key: key, ...);
key.currentState?.restartScan();
```

### 行为说明

#### 扫码流程（scanOnce=true）

```
相机捕获 → 解析 Barcode
  ├─ code 为空 → 忽略
  ├─ 已扫码 → 忽略
  └─ 有效扫码
       ├─ 边框切换为 checkedBorderColor
       ├─ 暂停相机
       └─ 回调 onScanned(barcode)
```

#### 扫码流程（scanOnce=false）

```
相机捕获 → 解析 Barcode
  ├─ code 为空 → 忽略
  ├─ scanInterval 内相同内容 → 忽略（去重）
  └─ 有效扫码
       ├─ 边框切换为 checkedBorderColor（仅首次）
       └─ 回调 onScanned(barcode)
```

#### 生命周期

```
应用进入后台 → pauseCamera() + 标记 _pausedByLifecycle = true
应用回到前台（_pausedByLifecycle = true）
  ├─ scanOnce=true 且已扫码 → 不恢复（保持暂停）
  └─ 其他 → resumeCamera() + 清除 _pausedByLifecycle
```

#### didUpdateWidget 触发重建

| 参数变化 | 影响 |
|----------|------|
| `cameraFacing` 或 `formatsAllowed` | 重建平台视图（更换 `_qrKey`），重置所有扫描状态 |
| `overlay` | 即时更新样式（不重建视图） |
| `borderColor` | 更新边框颜色 |
| `scanOnce` | 重置 `_scanHandled` 和去重记录 |

#### reassemble（热重载）

Android 上热重载后相机可能黑屏，框架自动执行 `pauseCamera()` → `resumeCamera()` 恢复；Web 跳过此步骤。

### 使用示例

```dart
// 基础单次扫描
WQrView(
  onScanned: (barcode) {
    debugPrint('扫码结果: ${barcode.code}');
    // 页面跳转等后续处理
  },
);

// 连续扫描 + 去重
WQrView(
  scanOnce: false,
  scanInterval: const Duration(milliseconds: 500),
  onScanned: (barcode) {
    debugPrint('连续扫码: ${barcode.code}');
  },
);

// 外部控制相机
final qrKey = GlobalKey<WQrViewState>();
WQrView(
  key: qrKey,
  scanOnce: true,
  onScanned: (barcode) {
    // 处理完后手动重启扫描
    Future.delayed(const Duration(seconds: 2), () {
      qrKey.currentState?.restartScan();
    });
  },
  onQRViewCreated: (controller) {
    // 通过 controller 操作闪光灯
    controller.toggleFlash();
  },
);

// 自定义扫描框样式
WQrView(
  overlay: const WQrViewOverlayShape(
    borderWidth: 4,
    borderRadius: 8,
    cutOutWidth: 280,
    cutOutHeight: 280,
    cutOutBottomOffset: 60,
  ),
  borderColor: Colors.blue,
  checkedBorderColor: Colors.greenAccent,
  onScanned: (barcode) {},
);
```

---

## 完整使用示例

```dart
import 'package:flutter/material.dart';
import 'package:w_tools_qr/w_tools_qr.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});
  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  final GlobalKey<WQrViewState> _qrKey = GlobalKey();
  WQrController? _controller;
  bool _flashOn = false;

  Future<void> _toggleFlash() async {
    await _controller?.toggleFlash();
    final status = await _controller?.getFlashStatus();
    setState(() => _flashOn = status ?? false);
  }

  void _onScanned(Barcode barcode) {
    final code = barcode.code;
    if (code == null || code.isEmpty) return;

    // 扫码成功 → 展示结果 → 延迟重启扫描
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('扫码成功: $code')),
    );
    Future.delayed(const Duration(seconds: 2), () {
      _qrKey.currentState?.restartScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          WQrView(
            key: _qrKey,
            onScanned: _onScanned,
            onQRViewCreated: (controller) => _controller = controller,
            noPermissionCallback: () {
              debugPrint('无相机权限');
            },
            onError: (error, stack) {
              debugPrint('扫码错误: $error\n$stack');
            },
          ),
          Positioned(
            right: 16,
            bottom: 32,
            child: FloatingActionButton(
              onPressed: _toggleFlash,
              child: Icon(_flashOn ? Icons.flash_on : Icons.flash_off),
            ),
          ),
        ],
      ),
    );
  }
}
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
     │          - overlay 变化 → 即时更新
     │          - scanOnce 切换 → 重置去重记录
     │
     └──► 扫码成功
            ├─ scanOnce=true → 边框变色 + 暂停相机 + 回调
            └─ scanOnce=false → 边框变色(仅首次) + 回调(scanInterval 去重)
                                   │
                                   ▼
                            业务方处理完 → restartScan()
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
- 运行时需先申请权限（例如使用 `permission_handler` 包），否则 `noPermissionCallback` 会被触发。

### 平台限制

| 平台 | 支持情况 |
|------|----------|
| Android | ✅ 完整支持 |
| iOS | ✅ 完整支持 |
| Web | ✅ 支持 |
| Windows / macOS / Linux | ❌ 插件抛 `UnsupportedError` |

### 版本锁定

`qr_code_scanner_plus` 锁定 `>=2.1.2 <2.2.0`。2.2.0+ 要求 Flutter 3.44 / iOS 13 / AGP 9，贸然升级可能破坏现有项目的构建环境。

### 生命周期

- `WQrController` 与平台视图同生命周期：`cameraFacing` / `formatsAllowed` 变化会触发平台视图重建，此时旧 controller 会被 `dispose()`，新 controller 通过 `onQRViewCreated` 回调传入。
- `resumeCamera()` 只恢复相机运行态，**不会重置 `scanOnce` 锁定**；若 `scanOnce=true` 且已扫码一次，调用 `resumeCamera` 后相机恢复但不会再触发 `onScanned`，需显式调用 `WQrViewState.restartScan()`。
- 单次扫描完成后应用退后台再回前台，**不会自动恢复相机**（避免意外重复扫码）；如需重新扫描请调用 `restartScan()`。
- `dispose()` 时框架内部会释放扫描流订阅和 `WQrController`，调用方无需自行管理。

### 错误处理

- `onScanned` 自身抛出的异常会被捕获并通过 `onError`（或 `FlutterError.reportError`）上报，不会导致组件崩溃。
- 底层控制器抛出的 `CameraException` 会通过 `onError` 上报，由调用方决定如何处理。
- `onError` 自身抛出的异常会被忽略，避免形成未处理异常。

### 其他

- `scanInterval` 仅在 `scanOnce=false` 时生效，默认 `Duration.zero` 表示不去重。
- `showOverlay=false` 时 `borderColor` / `checkedBorderColor` / `overlay` 均不生效，组件进入全屏扫描模式。
- `formatsAllowed` 为空列表时使用平台默认识别格式，显式指定可提升识别速度。
- 桌面端（Windows/macOS/Linux）运行会在插件层抛 `UnsupportedError`，请在使用前做平台判断。
