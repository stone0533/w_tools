# w_tools_qr

[![pub package](https://img.shields.io/pub/v/w_tools_qr.svg)](https://pub.dev/packages/w_tools_qr)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

`w_tools_qr` 是 w_tools 的二维码 / 条形码扫描组件层，基于 `qr_code_scanner_plus` 封装。

## 特性

- **单次 / 连续扫描**：`scanOnce` 控制扫码后是否暂停相机
- **生命周期管理**：进入后台自动暂停相机，回到前台恢复
- **广播扫描流**：`WQrController.scannedDataStream` 支持多监听
- **相机控制**：暂停 / 恢复 / 翻转 / 闪光灯 / 反色扫描
- **可定制扫描框**：颜色、边框、圆角、扫描区域尺寸
- **错误隔离**：相机与流异常统一通过 `onError` 上报

## 平台支持

- Android、iOS、Web
- 桌面端由 `qr_code_scanner_plus` 抛出 `UnsupportedError`
- iOS 最低部署版本 12.0（插件 2.1.2）
- Android 需声明 `CAMERA` 权限；iOS 需配置 `NSCameraUsageDescription`
- 本包最低要求 Flutter 3.27.0

## 安装

```yaml
dependencies:
  w_tools_qr: ^1.0.0
```

## 快速开始

```dart
import 'package:flutter/material.dart';
import 'package:w_tools_qr/w_tools_qr.dart';

class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WQrView(
        onScanned: (Barcode barcode) {
          debugPrint('扫码结果: ${barcode.code}');
        },
      ),
    );
  }
}
```

连续扫描：

```dart
WQrView(
  scanOnce: false,
  scanInterval: const Duration(milliseconds: 800),
  onScanned: (barcode) {
    debugPrint(barcode.code);
  },
)
```

重新扫描：

```dart
final key = GlobalKey<WQrViewState>();

WQrView(key: key, onScanned: (_) {});

// 扫码完成后重新开始
await key.currentState?.restartScan();
```

## 主要 API

| 能力 | 入口 |
|---|---|
| 扫描组件 | `WQrView` |
| 状态控制 | `WQrViewState.restartScan` |
| 相机控制器 | `WQrController` |
| 扫描框样式 | `WQrViewOverlayShape` |
| 扫码结果 | `Barcode`（已由本包转出） |

## License

MIT
