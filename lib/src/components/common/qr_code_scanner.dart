import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

/// 二维码扫描组件，用于扫描和识别二维码
class WQrView extends StatefulWidget {
  /// 边框颜色
  final Color borderColor;

  /// 扫描成功时的边框颜色
  final Color checkedBorderColor;

  /// 扫描框样式
  final WQrViewOverlayShape? overlay;

  /// 无相机权限回调
  final VoidCallback? noPermissionCallback;

  /// 扫描成功回调
  final void Function(Barcode scanData) onScanned;

  /// QRView 创建回调
  final void Function(QRViewController)? onQRViewCreated;

  /// 构造函数
  ///
  /// @param key 组件键
  /// @param borderColor 边框颜色，默认红色
  /// @param checkedBorderColor 扫描成功时的边框颜色，默认红色
  /// @param overlay 扫描框样式
  /// @param noPermissionCallback 无相机权限回调
  /// @param onScanned 扫描成功回调
  /// @param onQRViewCreated QRView 创建回调
  const WQrView({
    super.key,
    this.borderColor = Colors.red,
    this.checkedBorderColor = Colors.red,
    this.overlay,
    this.noPermissionCallback,
    required this.onScanned,
    this.onQRViewCreated,
  });

  @override
  State<WQrView> createState() => _WQrViewState();
}

/// WQrView 的状态类
class _WQrViewState extends State<WQrView> {
  /// 扫描结果
  Barcode? result;

  /// QR 控制器
  QRViewController? controller;

  /// QR 视图的全局键
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  /// 边框颜色
  late Color borderColor;

  /// 扫描是否结束
  bool isOver = false;

  /// 扫描框样式
  late WQrViewOverlayShape overlay;

  @override
  void initState() {
    borderColor = widget.borderColor;
    overlay = widget.overlay ?? WQrViewOverlayShape();
    super.initState();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderColor: borderColor,
        borderWidth: overlay.borderWidth,
        overlayColor: overlay.overlayColor,
        borderRadius: overlay.borderRadius,
        borderLength: overlay.borderLength,
        cutOutWidth: overlay.cutOutWidth,
        cutOutHeight: overlay.cutOutHeight,
        cutOutBottomOffset: overlay.cutOutBottomOffset,
      ),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  /// QRView 创建回调
  ///
  /// @param controller QR 控制器
  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    widget.onQRViewCreated?.call(controller);
    controller.scannedDataStream.listen((scanData) {
      result = scanData;
      if (result != null) {
        final String code = result!.code ?? '';
        if (code.isNotEmpty && borderColor != widget.checkedBorderColor) {
          setState(() {
            borderColor = widget.checkedBorderColor;
          });
          widget.onScanned.call(scanData);
        }
      }
      if (borderColor == widget.checkedBorderColor && !isOver) {
        isOver = true;
        this.controller?.pauseCamera();
      }
    });
  }

  /// 权限设置回调
  ///
  /// @param context 上下文
  /// @param ctrl QR 控制器
  /// @param p 是否有相机权限
  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p) {
      widget.noPermissionCallback?.call();
    }
  }
}

/// 二维码扫描框样式配置类
class WQrViewOverlayShape {
  /// 边框宽度
  final double borderWidth;

  /// 遮罩颜色
  final Color overlayColor;

  /// 边框圆角
  final double borderRadius;

  /// 边框长度
  final double borderLength;

  /// 扫描框宽度
  final double cutOutWidth;

  /// 扫描框高度
  final double cutOutHeight;

  /// 扫描框底部偏移
  final double cutOutBottomOffset;

  /// 构造函数
  ///
  /// @param borderWidth 边框宽度，默认 3.0
  /// @param overlayColor 遮罩颜色，默认半透明黑色
  /// @param borderRadius 边框圆角，默认 0
  /// @param borderLength 边框长度，默认 40
  /// @param cutOutWidth 扫描框宽度，默认 250
  /// @param cutOutHeight 扫描框高度，默认等于扫描框宽度
  /// @param cutOutBottomOffset 扫描框底部偏移，默认 0
  WQrViewOverlayShape({
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 0.5),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutWidth = 250,
    double? cutOutHeight,
    this.cutOutBottomOffset = 0,
  }) : cutOutHeight = cutOutHeight ?? cutOutWidth;
}
