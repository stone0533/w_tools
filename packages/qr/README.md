# w_tools_qr

[![pub package](https://img.shields.io/pub/v/w_tools_qr.svg)](https://pub.dev/packages/w_tools_qr)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

`w_tools_qr` 是 w_tools 的二维码 / 条形码扫描组件层，基于 `qr_code_scanner_plus` 封装。

## 特性

- **单次 / 连续扫描**：`scanOnce` 控制扫码后是否暂停相机；不传 `onScanned` 时不会自动暂停
- **控制器归调用方**：`WQrController` 由页面创建并持有，重扫 / 闪光灯 / 翻转 / 暂停都走它
- **结构化结果**：`onScanned` 回调 `WQrScanResult`（`code` / `format` / `rawBytes` / `timestamp`）
- **生命周期管理**：进入后台自动暂停相机，回到前台恢复
- **广播扫描流**：`WQrController.scannedDataStream` 支持多监听，跨平台视图重建不变
- **可定制扫描框**：`WQrOverlayStyle` 统一颜色、是否显示、外边距与扫描区域尺寸
- **错误隔离**：相机与流异常统一通过 `onError` 上报

## 平台支持

- Android、iOS、Web（Web 上 `pause/resume/flip` 经 `WQrView` 内部调用时会走 `onError`；直接调用 `WQrController` 的 `hasPermissions` / `stopCamera` / `setInvert` / `getSystemFeatures` 会同步抛 `UnimplementedError`）
- 桌面端由 `qr_code_scanner_plus` 抛出 `UnsupportedError`
- iOS 最低部署版本 12.0（插件 2.1.2）
- Android 需声明 `CAMERA` 权限；iOS 需配置 `NSCameraUsageDescription`
- 本包最低要求 Flutter 3.38.0

## 安装

```yaml
dependencies:
  w_tools_qr: ^2.0.0
```

## 快速开始

```dart
import 'package:flutter/material.dart';
import 'package:w_tools_qr/w_tools_qr.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final WQrController _controller = WQrController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WQrView(
        controller: _controller,
        onScanned: (result) {
          debugPrint('扫码结果: ${result.code}');
        },
      ),
    );
  }
}
```

单次扫码完成后需要再扫：

```dart
await _controller.restart();
```

`WQrController.restart()` 会重置单次扫码锁定、成功色与去重窗口，并恢复相机；
应用在后台时不会恢复，等回到前台再恢复。

## 连续扫描

```dart
WQrView(
  controller: _controller,
  scanOnce: false,
  scanInterval: const Duration(milliseconds: 800),
  onScanned: (result) {
    debugPrint(result.code);
  },
)
```

`scanInterval` 是相同内容的最小回调间隔（默认 400ms），`Duration.zero` 关闭去重。

## 只监听扫描流

不传 `onScanned` 时组件不会自动暂停相机，可以只订阅广播流：

```dart
final controller = WQrController();
controller.scannedDataStream.listen((barcode) {
  debugPrint(barcode.code);
});

WQrView(controller: controller);
```

流里的 `Barcode` 是插件原样对象（`code` 可能为空），过滤与去重只发生在 `onScanned` 上。

## 自定义扫描框

```dart
WQrView(
  controller: _controller,
  style: const WQrOverlayStyle(
    borderColor: Colors.blue,
    successColor: Colors.greenAccent,
    borderWidth: 4,
    cutOutWidth: 240,
    cutOutHeight: 240,
  ),
  onScanned: (result) {},
)
```

`WQrOverlayStyle.isVisible: false` 时全屏扫描，其余字段不生效。

## 权限

- Android：`AndroidManifest.xml` 加 `CAMERA` 权限；
- iOS：`Info.plist` 加 `NSCameraUsageDescription`；
- 没授权时 `onPermissionDenied` 会回调一次（重新授权后可再次上报），可据此展示自己的权限页。

## 主要 API

| 能力 | 入口 |
|---|---|
| 扫描组件 | `WQrView` |
| 相机控制 / 重扫 | `WQrController`（`restart()` / `flipCamera()` / `toggleFlash()` / `pauseCamera()` 等） |
| 扫描框样式 | `WQrOverlayStyle` |
| 扫码结果 | `WQrScanResult` |
| 原始扫描数据 | `WQrController.scannedDataStream`（`Barcode`，已由本包转出） |

## 完整示例

见 [`example/`](example/)：单次扫码、结果展示、继续扫描、闪光灯与摄像头翻转、连续扫描 / 扫描框 /
仅二维码开关、无权限提示。

## 从 1.x 升级

2.0 是 breaking 版本：`WQrViewState` 已移除（重扫改用 `WQrController.restart()`），
`onScanned` 改为回调 `WQrScanResult`，扫描框样式统一到 `WQrOverlayStyle`。逐条对照见
[`qr 2.0 迁移`](https://github.com/stone0533/w_tools/blob/main/docs/migrations/qr-2.0.md)。

## License

MIT
