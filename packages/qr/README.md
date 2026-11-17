# w_tools_qr

[![pub package](https://img.shields.io/pub/v/w_tools_qr.svg)](https://pub.dev/packages/w_tools_qr)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

`w_tools_qr` 是 w_tools 的二维码 / 条形码扫描组件层，基于 `qr_code_scanner_plus` 封装。

## 特性

- **单次 / 连续扫描**：`scanOnce` 控制首码后是否暂停相机；连续模式按 `scanThrottle` 节流连续相同内容
- **控制器归调用方**：`WQrController` 由页面创建并持有，`controller` 必传；重扫 / 闪光灯 / 翻转 / 暂停都走它
- **结构化结果**：`onScanned` 回调 `WQrScanResult`（`code` / `format` / `rawBytes`）
- **生命周期管理**：进入后台自动暂停相机，回到前台恢复
- **广播扫描流**：`WQrController.scannedDataStream` 支持多监听，跨平台视图重建不变
- **可定制扫描框**：`WQrOverlayStyle` 配置颜色、外边距与扫描区域尺寸；`style: null` 全屏扫描
- **错误隔离**：相机与流异常统一通过 `onError` 上报

## 平台支持

- Android、iOS：完整支持
- Web：扫码可用；插件没有实现 `pauseCamera` / `resumeCamera`，组件在 Web 上跳过自动暂停 /
  恢复，直接调用 `WQrController.pauseCamera()` / `resumeCamera()` 会抛 `UnimplementedError`
- 桌面端由 `qr_code_scanner_plus` 抛出 `UnsupportedError`
- iOS 最低部署版本 12.0（插件 2.1.2）
- Android 需声明 `CAMERA` 权限；iOS 需配置 `NSCameraUsageDescription`
- 本包最低要求 Flutter 3.38.0

## 安装

```yaml
dependencies:
  w_tools_qr: ^3.1.0
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

`WQrController.restart()` 会重置单次扫码锁定与节流窗口，并恢复相机；
应用在后台时不会恢复，等回到前台再恢复。

## 连续扫描

```dart
WQrView(
  controller: _controller,
  scanOnce: false,
  scanThrottle: const Duration(milliseconds: 800),
  onScanned: (result) {
    debugPrint(result.code);
  },
)
```

`scanThrottle` 是连续模式下连续相同内容的最小回调间隔（默认 400ms），`Duration.zero` 关闭节流；
单次模式不受它影响。

## 只监听扫描流

`onScanned` 可省略，订阅广播流即可拿到插件的原始 `Barcode`：

```dart
final controller = WQrController();
controller.scannedDataStream.listen((barcode) => debugPrint(barcode.code));

WQrView(controller: controller, scanOnce: false);
```

`scanOnce` 与是否传 `onScanned` 无关：默认单次模式下首条有效码后相机仍会暂停，所以上例
显式传了 `scanOnce: false`；只关心首码时省略即可。流里的 `Barcode` 保留插件原样
（`code` 可能为空），过滤与节流只发生在 `onScanned` 上。

## 自定义扫描框

```dart
WQrView(
  controller: _controller,
  style: const WQrOverlayStyle(
    borderColor: Colors.blue,
    successColor: Colors.greenAccent, // 单次命中后变绿
    borderWidth: 4,
    cutOutWidth: 240,
    cutOutHeight: 240,
  ),
  onScanned: (result) {},
)
```

传 `style: null` 表示全屏扫描，不绘制扫描框。

`successColor` 是 opt-in：不传（默认 `null`）时边框保持 `borderColor`；传了之后，单次模式
命中有效码时边框切到该颜色，并保持到 `WQrController.restart()`。连续模式不生效。

## 权限

- Android：`AndroidManifest.xml` 加 `CAMERA` 权限；
- iOS：`Info.plist` 加 `NSCameraUsageDescription`；
- 没授权时 `onPermissionDenied` 会回调一次（重新授权后可再次上报），可据此展示自己的权限页。

## 主要 API

| 能力 | 入口 |
|---|---|
| 扫描组件 | `WQrView`（`controller` 必传） |
| 相机控制 / 重扫 | `WQrController`（`restart()` / `flipCamera()` / `toggleFlash()` / `pauseCamera()` 等） |
| 扫描框样式 | `WQrOverlayStyle`（`style: null` 全屏） |
| 扫码结果 | `WQrScanResult` |
| 原始扫描数据 | `WQrController.scannedDataStream`（`Barcode`，已由本包转出） |

## 完整示例

见 [`example/`](example/)：单次扫码、结果展示、继续扫描、闪光灯与摄像头翻转、连续扫描 / 扫描框 /
仅二维码开关、无权限提示。

## 从 2.x 升级

3.0 是 breaking 版本：`controller` 必传；删除 `scanInterval`，改用 `scanThrottle`；
`WQrController` 删除平台残缺与纯转发能力；`WQrScanResult` 删除 `timestamp`。逐条对照见
[`qr 3.0 迁移`](https://github.com/stone0533/w_tools/blob/main/docs/migrations/qr-3.0.md)。

## License

MIT
