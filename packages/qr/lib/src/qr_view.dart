import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

import 'qr_controller.dart';
import 'qr_overlay_shape.dart';

/// 二维码 / 条形码扫描组件
///
/// 基于 `qr_code_scanner_plus` 封装，支持 Android、iOS 与 Web；桌面端会由
/// 插件抛出 `UnsupportedError`。
/// 默认在首次成功扫码后回调 [onScanned] 并暂停相机（[scanOnce] 为 true）；
/// 需要连续扫描时请将 [scanOnce] 设为 false。
/// 应用退到后台时会自动暂停相机，回到前台时恢复（单次扫描已完成时不恢复）。
/// 需要重新开始扫描时，可通过 `GlobalKey<WQrViewState>` 调用
/// [WQrViewState.restartScan]。
///
/// 接入前请确保已配置相机权限：Android 的 `CAMERA` 权限、iOS 的
/// `NSCameraUsageDescription`。
class WQrView extends StatefulWidget {
  /// 扫描框边框颜色
  final Color borderColor;

  /// 扫描成功后的边框颜色
  final Color checkedBorderColor;

  /// 是否绘制扫描框
  ///
  /// 为 false 时全屏扫描，[borderColor] / [checkedBorderColor] / [overlay]
  /// 均不生效。
  final bool showOverlay;

  /// 扫描框样式；为空时使用 [WQrViewOverlayShape] 的默认值
  final WQrViewOverlayShape? overlay;

  /// 扫描框外边距
  final EdgeInsetsGeometry overlayMargin;

  /// 无相机权限回调
  ///
  /// 权限状态可能被多次上报，因此回调也可能被多次触发。
  final VoidCallback? noPermissionCallback;

  /// 扫描到有效内容时的回调
  ///
  /// 仅在 `Barcode.code` 非空时触发；[scanOnce] 为 true 时最多触发一次。
  final void Function(Barcode scanData) onScanned;

  /// 相机控制器创建回调
  ///
  /// 通过 [WQrController] 控制相机（暂停 / 恢复 / 翻转 / 闪光灯等）；
  /// [WQrController.scannedDataStream] 为广播流，可与 [onScanned] 同时监听。
  /// 平台视图重建后会回调新的控制器，旧控制器不再可用。
  final void Function(WQrController)? onQRViewCreated;

  /// 摄像头方向，默认后置
  ///
  /// 运行期修改会重建平台视图，并重置扫描状态。
  final CameraFacing cameraFacing;

  /// 允许识别的条码格式；为空表示使用平台默认值
  ///
  /// 运行期修改会重建平台视图，并重置扫描状态。
  final List<BarcodeFormat> formatsAllowed;

  /// 是否只扫描一次
  ///
  /// 为 true（默认）时，首次成功扫码后调用 [onScanned] 并暂停相机；
  /// 为 false 时持续回调，不暂停相机。
  final bool scanOnce;

  /// 连续扫描模式下相同内容的最小回调间隔
  ///
  /// 默认 [Duration.zero]，表示不去重；仅在 [scanOnce] 为 false 时生效。
  final Duration scanInterval;

  /// 错误回调
  ///
  /// 用于上报相机操作失败、扫描流错误与 [onScanned] 自身抛出的异常；
  /// 未提供时会通过 [FlutterError.reportError] 上报。
  final void Function(Object error, StackTrace stackTrace)? onError;

  /// 创建二维码扫描组件
  ///
  /// [onScanned] 为必填项，其余参数均有默认值。
  const WQrView({
    super.key,
    this.borderColor = Colors.red,
    this.checkedBorderColor = Colors.green,
    this.showOverlay = true,
    this.overlay,
    this.overlayMargin = EdgeInsets.zero,
    this.noPermissionCallback,
    required this.onScanned,
    this.onQRViewCreated,
    this.cameraFacing = CameraFacing.back,
    this.formatsAllowed = const <BarcodeFormat>[],
    this.scanOnce = true,
    this.scanInterval = Duration.zero,
    this.onError,
  });

  @override
  State<WQrView> createState() => WQrViewState();
}

// ============== 组件状态 ==============

/// [WQrView] 的状态
///
/// 可通过 `GlobalKey<WQrViewState>` 调用 [restartScan] 重新开始扫描。
class WQrViewState extends State<WQrView> with WidgetsBindingObserver {
  /// 扫描数据流订阅（订阅 [WQrController] 的广播流）
  StreamSubscription<Barcode>? _scanSubscription;

  /// 相机控制器
  WQrController? _controller;

  /// QRView 的全局键（相机方向 / 条码格式变化时会更换以重建视图）
  GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');

  /// 当前显示的边框颜色
  late Color _borderColor;

  /// 当前扫描框样式
  late WQrViewOverlayShape _overlay;

  /// 是否已完成一次扫码（仅 [WQrView.scanOnce] 为 true 时生效）
  bool _scanHandled = false;

  /// 是否已把边框切换为 [WQrView.checkedBorderColor]
  bool _borderHighlighted = false;

  /// 是否因应用进入后台而暂停了相机
  bool _pausedByLifecycle = false;

  /// 上一次回调的条码内容（用于 [WQrView.scanInterval] 去重）
  String? _lastScannedCode;

  /// 上一次回调的时间（用于 [WQrView.scanInterval] 去重）
  DateTime? _lastScannedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _borderColor = widget.borderColor;
    _overlay = widget.overlay ?? const WQrViewOverlayShape();
  }

  /// 同步父组件更新：相机配置、扫描框样式、边框颜色与扫描模式
  @override
  void didUpdateWidget(covariant WQrView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cameraFacing != widget.cameraFacing ||
        !listEquals(oldWidget.formatsAllowed, widget.formatsAllowed)) {
      _recreatePlatformView();
    }
    if (oldWidget.overlay != widget.overlay) {
      _overlay = widget.overlay ?? const WQrViewOverlayShape();
    }
    if (_borderHighlighted) {
      if (oldWidget.checkedBorderColor != widget.checkedBorderColor) {
        _borderColor = widget.checkedBorderColor;
      }
    } else if (oldWidget.borderColor != widget.borderColor) {
      _borderColor = widget.borderColor;
    }
    // 扫描模式切换时重置一次状态，避免沿用上一次的锁定 / 去重记录
    if (oldWidget.scanOnce != widget.scanOnce) {
      _scanHandled = false;
      _lastScannedCode = null;
      _lastScannedAt = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 底层 QRViewController 由插件在 QRView 卸载时自行释放，这里只释放包装层
    unawaited(_scanSubscription?.cancel());
    _scanSubscription = null;
    unawaited(_controller?.dispose());
    _controller = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resumeFromLifecycle();
    } else {
      _pauseForLifecycle();
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    // Android 热重载后相机可能黑屏，先暂停再恢复
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _runCameraAction(_controller?.pauseCamera());
    }
    _runCameraAction(_controller?.resumeCamera());
  }

  @override
  Widget build(BuildContext context) {
    return QRView(
      key: _qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: widget.showOverlay
          ? QrScannerOverlayShape(
              borderColor: _borderColor,
              borderWidth: _overlay.borderWidth,
              overlayColor: _overlay.overlayColor,
              borderRadius: _overlay.borderRadius,
              borderLength: _overlay.borderLength,
              cutOutWidth: _overlay.cutOutWidth,
              cutOutHeight: _overlay.cutOutHeight,
              cutOutBottomOffset: _overlay.cutOutBottomOffset,
            )
          : null,
      overlayMargin: widget.overlayMargin,
      cameraFacing: widget.cameraFacing,
      formatsAllowed: widget.formatsAllowed,
      onPermissionSet: _onPermissionSet,
    );
  }

  /// 重新开始扫描
  ///
  /// 重置边框与「已扫码」状态，并恢复相机。
  /// 在 [WQrView.scanOnce] 为 false 时可用于恢复边框颜色；
  /// 若应用仍在后台，则等到回到前台后再恢复相机。
  Future<void> restartScan() async {
    if (!mounted) return;
    setState(() {
      _scanHandled = false;
      _borderHighlighted = false;
      _borderColor = widget.borderColor;
      _lastScannedCode = null;
      _lastScannedAt = null;
    });
    if (!_pausedByLifecycle) {
      await _controller?.resumeCamera();
    }
  }

  /// 重建平台视图（相机方向 / 条码格式变化时）
  void _recreatePlatformView() {
    unawaited(_scanSubscription?.cancel());
    _scanSubscription = null;
    unawaited(_controller?.dispose());
    _controller = null;
    _qrKey = GlobalKey(debugLabel: 'QR');
    _scanHandled = false;
    _borderHighlighted = false;
    _borderColor = widget.borderColor;
    _lastScannedCode = null;
    _lastScannedAt = null;
  }

  /// 包装底层控制器，并把扫描流转换为广播流
  void _onQRViewCreated(QRViewController controller) {
    // 平台视图重建时，先释放旧的包装控制器与订阅
    unawaited(_scanSubscription?.cancel());
    unawaited(_controller?.dispose());

    final wrapper = WQrController.internal(controller);
    _controller = wrapper;
    _scanSubscription = wrapper.scannedDataStream.listen(
      _handleBarcode,
      onError: _reportError,
    );

    // 若创建时应用不在前台，先暂停相机，等回到前台再恢复
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    if (lifecycleState != null && lifecycleState != AppLifecycleState.resumed) {
      _pausedByLifecycle = true;
      _runCameraAction(wrapper.pauseCamera());
    }

    final callback = widget.onQRViewCreated;
    if (callback != null) {
      try {
        callback(wrapper);
      } catch (error, stackTrace) {
        _reportError(error, stackTrace);
      }
    }
  }

  /// 处理扫描结果
  ///
  /// 忽略空内容；[WQrView.scanOnce] 为 true 时只处理第一次扫码。
  void _handleBarcode(Barcode scanData) {
    if (!mounted) return;

    final code = scanData.code;
    if (code == null || code.isEmpty) return;
    if (widget.scanOnce && _scanHandled) return;
    if (_isDuplicateScan(code)) return;

    if (!_borderHighlighted) {
      _borderHighlighted = true;
      if (_borderColor != widget.checkedBorderColor) {
        setState(() {
          _borderColor = widget.checkedBorderColor;
        });
      }
    }

    if (widget.scanOnce) {
      _scanHandled = true;
      // 先暂停再回调：调用方在 onScanned 内调用 restartScan 时，
      // resume 会排在 pause 之后，最终状态正确
      _runCameraAction(_controller?.pauseCamera());
    }

    try {
      widget.onScanned(scanData);
    } catch (error, stackTrace) {
      _reportError(error, stackTrace);
    }
  }

  /// 连续扫描模式下按内容与时间窗去重
  bool _isDuplicateScan(String code) {
    if (widget.scanOnce || widget.scanInterval <= Duration.zero) {
      return false;
    }
    final now = DateTime.now();
    final lastAt = _lastScannedAt;
    if (code == _lastScannedCode &&
        lastAt != null &&
        now.difference(lastAt) < widget.scanInterval) {
      return true;
    }
    _lastScannedCode = code;
    _lastScannedAt = now;
    return false;
  }

  /// 权限设置回调
  ///
  /// 插件可能多次上报权限状态，因此回调也可能多次触发。
  void _onPermissionSet(QRViewController _, bool granted) {
    if (!granted) {
      widget.noPermissionCallback?.call();
    }
  }

  /// 应用进入后台时暂停相机
  void _pauseForLifecycle() {
    if (_controller == null || _pausedByLifecycle) return;
    _pausedByLifecycle = true;
    _runCameraAction(_controller?.pauseCamera());
  }

  /// 应用回到前台时恢复相机（单次扫描已完成时不恢复）
  void _resumeFromLifecycle() {
    if (!_pausedByLifecycle) return;
    _pausedByLifecycle = false;
    if (widget.scanOnce && _scanHandled) return;
    _runCameraAction(_controller?.resumeCamera());
  }

  /// 执行相机操作并上报异步异常
  void _runCameraAction(Future<void>? action) {
    if (action == null) return;
    unawaited(
      action.catchError((Object error, StackTrace stackTrace) {
        _reportError(error, stackTrace);
      }),
    );
  }

  /// 上报错误
  ///
  /// [WQrView.onError] 自身抛出的异常会被忽略，避免再次形成未处理异常；
  /// Widget 已销毁时直接丢弃（此时调用方通常已不再关心结果）。
  void _reportError(Object error, StackTrace stackTrace) {
    if (!mounted) return;

    final handler = widget.onError;
    if (handler != null) {
      try {
        handler(error, stackTrace);
      } catch (_) {
        // 忽略错误回调自身的异常
      }
      return;
    }
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'w_tools_qr',
      ),
    );
  }
}
