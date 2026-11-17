part of 'qr_core.dart';

/// 二维码 / 条形码扫描组件
///
/// 基于 `qr_code_scanner_plus` 封装；[controller] 必传，由调用方创建并持有。
///
/// 两种扫描模式：
/// - [scanOnce] 为 true（默认）：首条有效码后暂停相机、`onScanned` 只回调一次；
///   再扫调用 `WQrController.restart()`。
/// - [scanOnce] 为 false：持续回调，连续相同内容按 [scanThrottle] 节流，不暂停相机。
///
/// 不传 [onScanned] 时组件仍按 [scanOnce] 管理相机（首码后暂停），只是没有回调；
/// 需要多监听时订阅 `WQrController.scannedDataStream`（那一路不做过滤与节流）。
///
/// 自动暂停只在非 Web 平台执行：插件 Web 实现没有 `pauseCamera` / `resumeCamera`。
/// 应用退到后台会自动暂停相机，回到前台恢复（单次扫码已完成时不恢复）。
///
/// 接入前请确保已配置相机权限：Android 的 `CAMERA` 权限、iOS 的
/// `NSCameraUsageDescription`。
class WQrView extends StatefulWidget {
  /// 创建二维码扫描组件
  const WQrView({
    super.key,
    required this.controller,
    this.style = const WQrOverlayStyle(),
    this.onScanned,
    this.onControllerReady,
    this.onPermissionDenied,
    this.onError,
    this.cameraFacing = CameraFacing.back,
    this.formatsAllowed = const <BarcodeFormat>[],
    this.scanOnce = true,
    this.scanThrottle = const Duration(milliseconds: 400),
  });

  /// 相机控制器
  ///
  /// 由调用方创建并持有，平台视图重建后实例不变；页面销毁时由调用方
  /// `dispose()`。
  final WQrController controller;

  /// 扫描框样式；传 null 表示不绘制扫描框（全屏扫描）
  final WQrOverlayStyle? style;

  /// 扫码结果回调
  ///
  /// 仅在 `Barcode.code` 非空时触发；[scanOnce] 为 true 时最多触发一次。
  final void Function(WQrScanResult result)? onScanned;

  /// 相机控制器就绪回调
  ///
  /// 平台视图（重新）创建后触发，参数就是 [controller]；适合做一次初始相机设置。
  final void Function(WQrController controller)? onControllerReady;

  /// 没有相机权限时的回调
  ///
  /// 只在「从未授权 → 未授权」时触发一次；重新授权后会重置。
  final VoidCallback? onPermissionDenied;

  /// 错误回调
  ///
  /// 上报相机操作失败、扫描流错误与 [onScanned] / [onControllerReady] 自身抛出的
  /// 异常；未提供时 debug 下通过 `debugPrint` 输出。
  final void Function(Object error, StackTrace stackTrace)? onError;

  /// 摄像头方向，默认后置
  ///
  /// 运行期修改会重建平台视图（相机重启），并重置扫描状态。
  final CameraFacing cameraFacing;

  /// 允许识别的条码格式；为空表示使用平台默认值
  ///
  /// 运行期修改会重建平台视图（相机重启），并重置扫描状态。请传新列表，
  /// 原地修改同一列表不会被检测到。
  final List<BarcodeFormat> formatsAllowed;

  /// 是否只扫描一次
  ///
  /// 为 true（默认）时，首条有效码后暂停相机且不再触发 [onScanned]；
  /// 为 false 时持续回调，不暂停相机。与是否传 [onScanned] 无关。
  final bool scanOnce;

  /// 连续模式下连续相同内容的最小回调间隔
  ///
  /// 默认 400ms；`Duration.zero` 关闭节流。只在 [scanOnce] 为 false 时生效。
  final Duration scanThrottle;

  @override
  State<WQrView> createState() => _WQrViewState();
}

/// [WQrView] 的状态
class _WQrViewState extends State<WQrView> with WidgetsBindingObserver {
  /// 插件单订阅流的唯一订阅（平台视图重建时更换）
  StreamSubscription<Barcode>? _nativeScanSubscription;

  /// 当前挂载的底层控制器；未挂载时为 null
  QRViewController? _native;

  /// QRView 的全局键（相机方向 / 条码格式变化时会更换以重建视图）
  GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');

  /// 是否已完成一次扫码（仅单次模式生效）
  bool _scanHandled = false;

  /// 是否因单次扫码完成而暂停了相机
  bool _pausedByScan = false;

  /// 单次模式是否已命中并切到 [WQrOverlayStyle.successColor]
  bool _successHighlighted = false;

  /// 是否因应用进入后台而暂停了相机
  bool _pausedByLifecycle = false;

  /// 是否已上报过「无权限」，避免插件多次上报时重复回调
  bool _permissionDeniedReported = false;

  /// 节流用的单调时钟（避免系统时间跳变）
  final Stopwatch _clock = Stopwatch();

  /// 上一次通过节流的内容与时间（微秒，来自 [_clock]）
  ({String code, int atUs})? _lastScan;

  /// 插件 Web 实现没有 pauseCamera / resumeCamera，组件内不做这两个调用
  bool get _canPauseCamera => !kIsWeb;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clock.start();
  }

  @override
  void didUpdateWidget(covariant WQrView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._detach();
      final native = _native;
      if (native != null) _attachController(native);
    }
    if (oldWidget.cameraFacing != widget.cameraFacing) {
      widget.controller._setFacing(widget.cameraFacing);
    }
    if (oldWidget.cameraFacing != widget.cameraFacing ||
        !listEquals(oldWidget.formatsAllowed, widget.formatsAllowed)) {
      _recreatePlatformView();
    }
    if (oldWidget.scanOnce != widget.scanOnce) {
      final wasHandled = _scanHandled;
      _resetScanState();
      // true → false：单次扫码已把相机 pause 了，必须恢复，否则连续扫描静默失效
      if (wasHandled && !widget.scanOnce) {
        _resumeCamera();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_nativeScanSubscription?.cancel());
    _nativeScanSubscription = null;
    widget.controller._detach();
    _native = null;
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
  Widget build(BuildContext context) {
    final style = widget.style;
    return QRView(
      key: _qrKey,
      onQRViewCreated: _onNativeCreated,
      overlay: style == null
          ? null
          : QrScannerOverlayShape(
              borderColor: _successHighlighted && style.successColor != null
                  ? style.successColor!
                  : style.borderColor,
              borderWidth: style.borderWidth,
              overlayColor: style.overlayColor,
              borderRadius: style.borderRadius,
              borderLength: style.borderLength,
              cutOutWidth: style.cutOutWidth,
              cutOutHeight: style.cutOutHeight,
              cutOutBottomOffset: style.cutOutBottomOffset,
            ),
      overlayMargin: style?.margin ?? EdgeInsets.zero,
      cameraFacing: widget.controller.cameraFacing ?? widget.cameraFacing,
      formatsAllowed: widget.formatsAllowed,
      onPermissionSet: _onPermissionSet,
    );
  }

  /// 重置单次锁定、节流窗口与「因扫码暂停」标记
  void _resetScanState() {
    _scanHandled = false;
    _pausedByScan = false;
    _successHighlighted = false;
    _lastScan = null;
    _clock.reset();
  }

  /// 重建平台视图（相机方向 / 条码格式变化时）
  void _recreatePlatformView() {
    widget.controller._detach();
    unawaited(_nativeScanSubscription?.cancel());
    _nativeScanSubscription = null;
    _native = null;
    _qrKey = GlobalKey(debugLabel: 'QR');
    _resetScanState();
  }

  /// 平台视图创建：把底层控制器挂到 [WQrController] 上
  void _onNativeCreated(QRViewController native) {
    // State 已销毁时不再建立新的订阅；底层控制器由 QRView 释放。
    if (!mounted) return;
    _attachController(native);

    // 若创建时应用不在前台，先暂停相机，等回到前台再恢复
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    if (_canPauseCamera && lifecycleState != null && lifecycleState != AppLifecycleState.resumed) {
      _pausedByLifecycle = true;
      unawaited(_runCameraAction(widget.controller.pauseCamera));
    }

    final callback = widget.onControllerReady;
    if (callback != null) {
      try {
        callback(widget.controller);
      } catch (error, stackTrace) {
        _reportError(error, stackTrace);
      }
    }
  }

  /// 把当前底层控制器挂到 [widget.controller]（平台视图重建后也走这里）
  ///
  /// 插件 `scannedDataStream` 是单订阅流：整个平台视图生命周期只由本组件订阅一次，
  /// 事件同时转发给控制器的广播流与 `onScanned` 管道。这样替换 controller 不需要
  /// 重新 listen。
  void _attachController(QRViewController native) {
    if (!identical(_native, native) || _nativeScanSubscription == null) {
      unawaited(_nativeScanSubscription?.cancel());
      _native = native;
      _nativeScanSubscription = native.scannedDataStream.listen(
        _handleNativeBarcode,
        onError: _handleNativeError,
      );
    }
    widget.controller._attach(
      native,
      initialFacing: widget.cameraFacing,
      onRestart: _restartScan,
    );
  }

  /// 插件条码：先走 `onScanned` 管道，再转发给当前控制器的广播流
  ///
  /// 顺序有意保持「扫描门闩 → 广播」：监听方在广播回调里调用 `restart()` 时，
  /// 不会先 resume 再被单次扫码的 pause 覆盖。
  void _handleNativeBarcode(Barcode barcode) {
    _handleBarcode(barcode);
    widget.controller._emit(barcode);
  }

  /// 插件流错误：转发给广播流并上报
  void _handleNativeError(Object error, StackTrace stackTrace) {
    widget.controller._emitError(error, stackTrace);
    _reportError(error, stackTrace);
  }

  /// 处理扫描结果
  ///
  /// 忽略空内容；单次模式只处理第一次扫码，连续模式按 [WQrView.scanThrottle]
  /// 节流连续相同内容。
  void _handleBarcode(Barcode barcode) {
    if (!mounted) return;

    final code = barcode.code;
    if (code == null || code.isEmpty) return;
    if (widget.scanOnce && _scanHandled) return;
    if (!widget.scanOnce && _isThrottled(code)) return;

    if (widget.scanOnce) {
      _scanHandled = true;
      if (widget.style?.successColor != null) {
        _successHighlighted = true;
        setState(() {});
      }
      // 先暂停再回调：调用方在 onScanned 内调用 restart() 时，
      // resume 会排在 pause 之后，最终状态正确
      _pauseAfterScan();
    }

    final callback = widget.onScanned;
    if (callback == null) return;

    final result = WQrScanResult(
      code: code,
      format: barcode.format,
      rawBytes: barcode.rawBytes,
    );

    try {
      callback(result);
    } catch (error, stackTrace) {
      // 回调失败时回滚单次锁定并恢复相机，避免扫码能力被静默锁死
      if (widget.scanOnce) {
        _scanHandled = false;
        _successHighlighted = false;
        _resumeCamera();
        if (mounted) setState(() {});
      }
      _reportError(error, stackTrace);
    }
  }

  /// 连续模式节流：连续相同内容在窗口内只放行一次
  bool _isThrottled(String code) {
    final window = widget.scanThrottle;
    if (window <= Duration.zero) return false;
    final now = _clock.elapsedMicroseconds;
    final lastScan = _lastScan;
    if (lastScan != null && code == lastScan.code && now - lastScan.atUs < window.inMicroseconds) {
      return true;
    }
    _lastScan = (code: code, atUs: now);
    return false;
  }

  /// 权限设置回调
  ///
  /// 插件可能多次上报未授权，这里只上报一次；重新授权后重置。
  void _onPermissionSet(QRViewController _, bool granted) {
    if (granted) {
      _permissionDeniedReported = false;
      return;
    }
    if (_permissionDeniedReported) return;
    _permissionDeniedReported = true;
    widget.onPermissionDenied?.call();
  }

  /// 单次扫码完成后暂停相机
  void _pauseAfterScan() {
    if (!_canPauseCamera || !widget.controller.isAttached) return;
    _pausedByScan = true;
    unawaited(_runCameraAction(widget.controller.pauseCamera));
  }

  /// 恢复相机（单次锁定已复位或切换模式时）
  void _resumeCamera() {
    _pausedByScan = false;
    if (_pausedByLifecycle || !_canPauseCamera || !widget.controller.isAttached) return;
    unawaited(_runCameraAction(widget.controller.resumeCamera));
  }

  /// 应用进入后台时暂停相机
  void _pauseForLifecycle() {
    if (_native == null || _pausedByLifecycle || !_canPauseCamera) return;
    _pausedByLifecycle = true;
    unawaited(_runCameraAction(widget.controller.pauseCamera));
  }

  /// 应用回到前台时恢复相机（单次扫描已完成时不恢复）
  void _resumeFromLifecycle() {
    if (!_pausedByLifecycle) return;
    _pausedByLifecycle = false;
    if (_pausedByScan || (widget.scanOnce && _scanHandled)) return;
    _resumeCamera();
  }

  /// 重新开始扫描（由 `WQrController.restart()` 调用）
  ///
  /// 重置「已扫码」状态与节流窗口；应用在前台时恢复相机，仍在后台则等到
  /// 回到前台再恢复。
  Future<void> _restartScan() async {
    if (!mounted) return;
    final bool wasHighlighted = _successHighlighted;
    _resetScanState();
    if (wasHighlighted) setState(() {});
    if (_pausedByLifecycle || !_canPauseCamera || !widget.controller.isAttached) {
      return;
    }
    await _runCameraAction(widget.controller.resumeCamera);
  }

  /// 执行相机操作并上报异常（同步 throw 与 Future 失败都走 onError）
  ///
  /// [action] 在 try 内调用，插件同步抛出的异常也能被捕获。
  Future<void> _runCameraAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      _reportError(error, stackTrace);
    }
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
    if (kDebugMode) {
      debugPrint('WQrView error: $error\n$stackTrace');
    }
  }
}
