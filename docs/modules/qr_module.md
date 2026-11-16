# QR 模块文档

## 概述

QR 模块（`w_tools_qr` 子包）基于 `qr_code_scanner_plus` 封装，提供二维码 / 条形码扫描组件
`WQrView`、调用方持有的相机控制器 `WQrController`、扫描框样式 `WQrOverlayStyle` 与结构化
扫码结果 `WQrScanResult`。

**核心特性**：
- 支持 Android、iOS 与 Web（桌面端插件抛 `UnsupportedError`）
- 默认单次扫描（`scanOnce=true`）：首条有效码后暂停相机并只回调一次，再扫走 `restart()`
- 连续扫描按 `scanThrottle` 对连续相同内容节流（只在连续模式生效）
- 应用退后台自动暂停、回前台恢复（单次扫描完成时不恢复；Web 跳过，见平台限制）
- `scannedDataStream` 为广播流，可多监听，且跨平台视图重建保持不变
- `controller` 必传；`style: null` 表示全屏扫描

依赖：`qr_code_scanner_plus`（锁定 `>=2.1.2 <2.2.0`，2.2+ 要求 Flutter 3.44 / iOS 13 / AGP 9，暂不升级）。

## 快速判断

- 扫码 → `WQrView`（`controller` 必传）
- 重扫 / 闪光灯 / 翻转 / 暂停 → `WQrController`
- 扫描框颜色与尺寸 → `WQrOverlayStyle`（`style: null` 全屏）
- 扫码结果 → `WQrScanResult`
- 不要直接用 `qr_code_scanner_plus` 的 `QRView`
- 可运行示例：[packages/qr/example](../../packages/qr/example/README.md)

- 强制规则：根 [`AGENTS.md`](../../AGENTS.md)

## 模块结构

```
qr/
└── lib/src/
    ├── qr_core.dart          # 内部 library：imports + part（接线不进入公开 API）
    ├── qr_view.dart          # WQrView + 内部 State（part of qr_core.dart）
    ├── qr_controller.dart    # WQrController（part of qr_core.dart）
    ├── qr_overlay_style.dart # WQrOverlayStyle
    └── qr_scan_result.dart   # WQrScanResult
```

`WQrController` 与 `WQrView` 互相需要私有接线（挂载平台视图、重扫回调），因此放在同一个
library 里用 `part` 拆分；barrel 只导出 `WQrController` / `WQrView`。

---

## 1. WQrOverlayStyle - 扫描框样式

### 功能说明

扫描框的视觉参数只有这一处。`WQrView.style` 传 `null` 表示不绘制扫描框（全屏扫描）。

### 配置字段

| 字段 | 默认值 | 说明 |
|------|--------|------|
| `borderColor` | `Colors.red` | 边框颜色 |
| `margin` | `EdgeInsets.zero` | 扫描框外边距 |
| `borderWidth` | `3.0` | 边框宽度（逻辑像素） |
| `overlayColor` | `Color.fromRGBO(0, 0, 0, 0.5)` | 遮罩颜色（半透明黑） |
| `borderRadius` | `0` | 边框圆角（逻辑像素） |
| `borderLength` | `40` | 边框长度（逻辑像素，四角 L 形边的长度） |
| `cutOutWidth` | `250` | 扫描框宽度（逻辑像素） |
| `cutOutHeight` | 同 `cutOutWidth` | 扫描框高度（为 null 时回退到宽度） |
| `cutOutBottomOffset` | `0` | 扫描框底部偏移（逻辑像素），正值向下移动 |

`borderWidth` / `borderLength` / 扫描框尺寸必须为正数（本类断言）；`borderLength` 与扫描框
尺寸的比例约束由插件 `QrScannerOverlayShape` 断言。本类不实现 `==` / `hashCode`。

### 使用示例

```dart
const style = WQrOverlayStyle(
  borderColor: Colors.blue,
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

由调用方创建并持有，传给 `WQrView.controller`（必传）：

- `scannedDataStream` 是**广播流**，支持多个监听者；控制器实例与流在平台视图重建后保持不变
- 相机操作方法转发给底层控制器；未挂载时抛 `StateError`（不静默失败）
- 平台视图（重新）创建时挂载、组件销毁时解除挂载，由 `WQrView` 内部完成
- 页面 `dispose()` 时调用 `dispose()` 释放

### 核心属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `isAttached` | `bool` | 是否已挂载到平台视图 |
| `scannedDataStream` | `Stream<Barcode>` | 扫描数据流（广播，可多监听，不做空 code 过滤） |
| `cameraFacing` | `CameraFacing?` | 最近一次已知的相机方向（挂载后即初始方向） |

### 核心方法

| 方法 | 返回类型 | 说明 |
|------|----------|------|
| `restart()` | `Future<void>` | 重扫：重置单次锁定 / 节流窗口并恢复相机；未挂载时抛 `StateError` |
| `pauseCamera()` | `Future<void>` | 暂停相机（Web 上插件未实现） |
| `resumeCamera()` | `Future<void>` | 恢复相机。**只恢复相机，不重置单次锁定**，需重置请用 `restart()` |
| `flipCamera()` | `Future<CameraFacing>` | 翻转前后摄像头，返回翻转后的方向 |
| `getFlashStatus()` | `Future<bool?>` | 获取闪光灯状态 |
| `toggleFlash()` | `Future<void>` | 切换闪光灯 |
| `dispose()` | `Future<void>` | 释放广播流并解除挂载 |

### 注意事项

- `resumeCamera` 只恢复相机运行态，不会重置单次扫码锁定；若 `scanOnce=true` 且已扫码一次，
  调用后相机恢复但不会再触发 `onScanned`，需要重新扫描请用 `restart()`。
- `WQrView` 内部发出的相机调用失败会走 `onError`；直接调用 `WQrController` 成员
  （含 Web 上同步抛 `UnimplementedError` 的 `pauseCamera` / `resumeCamera`）会抛给调用方，
  请自行 `try/catch`。
- 未挂载时相机方法与 `restart()` 都抛 `StateError`；`isAttached` 可用于判断。

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
- 单次模式（`scanOnce=true`，默认）：首条有效码 → 暂停相机 → 回调一次
- 连续模式（`scanOnce=false`）：持续回调，连续相同内容按 `scanThrottle` 节流，不暂停相机
- `onScanned` 可省略；省略时仍按 `scanOnce` 管理相机，只是没有回调
- 退后台自动暂停，回前台恢复（单次扫描完成时不恢复；Web 跳过）
- `cameraFacing` / `formatsAllowed` 变化时重建平台视图并重置扫描状态

### 构造参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `controller` | `WQrController` | 必填 | 相机控制器；由调用方创建并持有 |
| `style` | `WQrOverlayStyle?` | `WQrOverlayStyle()` | 扫描框样式；传 `null` 全屏扫描（见 §1） |
| `onScanned` | `void Function(WQrScanResult)?` | `null` | 扫码结果回调；仅在 `Barcode.code` 非空时触发；单次模式最多一次 |
| `onControllerReady` | `void Function(WQrController)?` | `null` | 相机就绪回调；平台视图（重新）创建后触发，参数就是 `controller` |
| `onPermissionDenied` | `VoidCallback?` | `null` | 无相机权限回调；只在「未授权」首次触发，重新授权后重置 |
| `onError` | `void Function(Object, StackTrace)?` | `null` | 错误回调（相机操作失败、流错误、回调自身异常）；未提供时 debug 下 `debugPrint` |
| `cameraFacing` | `CameraFacing` | `CameraFacing.back` | 摄像头方向。运行期修改会**重建平台视图**并重置扫描状态 |
| `formatsAllowed` | `List<BarcodeFormat>` | `[]` | 允许识别的条码格式；为空表示平台默认。运行期修改会重建平台视图 |
| `scanOnce` | `bool` | `true` | 首码后暂停且只回调一次；为 false 时连续回调 |
| `scanThrottle` | `Duration` | `400ms` | 连续模式下连续相同内容的最小回调间隔；`Duration.zero` 关闭；单次模式不生效 |

`onScanned` 与 `onControllerReady` 都可省略；`scanOnce` 与是否传 `onScanned` 无关。

### WQrScanResult

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | `String` | 扫码内容，保证非空 |
| `format` | `BarcodeFormat` | 条码格式 |
| `rawBytes` | `List<int>?` | 原始字节，仅 Android / iOS 提供 |

需要插件原始对象（例如自己过滤）时监听 `WQrController.scannedDataStream`。

### 行为说明

#### 扫码流程（scanOnce=true）

```
相机捕获 → 解析 Barcode
  ├─ code 为空 → 忽略
  ├─ 已扫码 → 忽略
  └─ 有效扫码
       ├─ 暂停相机（Web 跳过）
       └─ 回调 onScanned(WQrScanResult)
            └─ 回调抛异常时：回滚锁定、恢复相机、走 onError
```

#### 扫码流程（scanOnce=false）

```
相机捕获 → 解析 Barcode
  ├─ code 为空 → 忽略
  ├─ 节流窗口内连续相同内容 → 忽略
  └─ 有效扫码 → 回调 onScanned（若有），不暂停
```

#### 生命周期

```
应用进入后台 → pauseCamera() + 标记 _pausedByLifecycle = true（Web 跳过）
应用回到前台（_pausedByLifecycle = true）
  ├─ 单次模式且已扫码 → 不恢复（保持暂停）
  └─ 其他 → resumeCamera() + 清除 _pausedByLifecycle
```

#### didUpdateWidget 触发重建

| 参数变化 | 影响 |
|----------|------|
| `cameraFacing` 或 `formatsAllowed` | 重建平台视图（更换 `_qrKey`），重置所有扫描状态 |
| `controller` | 解绑旧控制器并挂到新控制器（旧控制器不再收到数据） |
| `style` | 即时更新样式（不重建视图） |
| `scanOnce` | 重置单次锁定与节流记录；true → false 时恢复相机 |

### 使用示例

```dart
// 单次扫码
final controller = WQrController();
WQrView(
  controller: controller,
  onScanned: (result) => debugPrint(result.code),
);
await controller.restart(); // 继续扫描

// 连续扫描 + 节流
WQrView(
  controller: controller,
  scanOnce: false,
  scanThrottle: const Duration(milliseconds: 500),
  onScanned: (result) => debugPrint(result.code),
);

// 只订阅广播流（默认单次仍会暂停，持续接收要显式 scanOnce: false）
controller.scannedDataStream.listen((barcode) => debugPrint(barcode.code));
WQrView(controller: controller, scanOnce: false);
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
     │          - scanOnce 切换 → 重置锁定 / 节流
     │
     └──► 扫码成功
            ├─ 单次模式 → 暂停相机 + 回调（异常则回滚）
            └─ 连续模式 → 回调（按 scanThrottle 节流），不暂停
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
- 插件会在平台视图创建时自行发起相机权限请求；被拒绝后 `onPermissionDenied` 只回调一次，
  引导用户去系统设置需要业务自行实现（例如 `permission_handler` 的 `openAppSettings`）。

### 平台限制

| 平台 | 支持情况 |
|------|----------|
| Android | ✅ 完整支持 |
| iOS | ✅ 完整支持 |
| Web | ⚠️ 扫码可用；插件没有实现 `pauseCamera` / `resumeCamera`，`WQrView` 在 Web 上跳过自动暂停 / 恢复 |
| Windows / macOS / Linux | ❌ 插件抛 `UnsupportedError` |

### 版本锁定

`qr_code_scanner_plus` 锁定 `>=2.1.2 <2.2.0`。2.2.0+ 要求 Flutter 3.44 / iOS 13 / AGP 9，贸然升级可能破坏现有项目的构建环境。

### 生命周期

- `WQrController` 由调用方持有，跨平台视图重建保持不变；`scannedDataStream` 也不会被替换。
- `cameraFacing` / `formatsAllowed` 变化会触发平台视图重建：控制器先 detach，新视图创建后重新 attach，
  并再次触发 `onControllerReady`。
- `resumeCamera()` 只恢复相机运行态，**不会重置单次锁定**；需显式调用 `restart()`。
- 单次扫描完成后应用退后台再回前台，**不会自动恢复相机**（避免意外重复扫码）；如需重新扫描请调用 `restart()`。
- 页面销毁时由调用方 `dispose()` 控制器。

### 错误处理

- `onScanned` 自身抛出的异常会被捕获并通过 `onError` 上报，同时回滚单次锁定、恢复相机。
- 底层控制器抛出的 `CameraException` 会通过 `onError` 上报，由调用方决定如何处理。
- `onError` 自身抛出的异常会被忽略，避免形成未处理异常。

### 其他

- `scanThrottle` 默认 `400ms`：连续模式对「连续相同内容」节流；持续对着同一码会按窗口重复回调，
  需要「一码一次」请用单次模式或自行去重。
- `style` 为 `null` 时全屏扫描，颜色与几何都不生效。
- `formatsAllowed` 为空列表时使用平台默认识别格式，显式指定可提升识别速度；请传新列表，
  原地修改同一列表不会被检测到。
- 桌面端（Windows/macOS/Linux）运行会在插件层抛 `UnsupportedError`，请在使用前做平台判断。
- Web 上 `WQrController.pauseCamera()` / `resumeCamera()` 会同步抛 `UnimplementedError`。

### 从 2.x 升级

3.0 是 breaking 版本：`controller` 必传、扫描模式由 `scanOnce` 决定、连续模式节流改为
`scanThrottle`、控制器删掉平台残缺与纯转发能力、扫码结果去掉合成字段。逐条对照见
[qr 3.0 迁移](../migrations/qr-3.0.md)。

---

相关文档：[模块索引](README.md) · [组件目录](components.md) · [接入约定](../conventions.md)
