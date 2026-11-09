import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

import 'qr_controller.dart';
import 'qr_overlay_style.dart';
import 'qr_scan_result.dart';

/// 二维码 / 条形码扫描组件
///
/// 基于 `qr_code_scanner_plus` 封装，支持 Android、iOS 与 Web；桌面端会由
/// 插件抛出 `UnsupportedError`。
///
/// 两种用法：
/// - **单次扫码（默认）**：传 [onScanned]，首条码后回调一次、边框切
///   [WQrOverlayStyle.successColor] 并暂停相机；再扫调用
///   `WQrController.restart()`。
/// - **连续扫码**：`scanOnce: false`，按 [scanInterval] 对相同内容去重后持续回调。
///
/// [onScanned] 与 [onControllerReady] 都可省略，也不存在「必须配 scanOnce」的约束：
/// 不传 [onScanned] 时组件不会自动暂停相机，只监听
/// `WQrController.scannedDataStream` 即可。
///
/// 命令式控制（重扫 / 闪光灯 / 翻转 / 暂停）统一走 [controller]：
///
/// ```dart
/// final controller = WQrController();
/// WQrView(
///   controller: controller,
///   onScanned: (result) => debugPrint(result.code),
/// );
/// // 再扫
/// await controller.restart();
/// ```
///
/// 应用退到后台会自动暂停相机，回到前台恢复（单次扫码已完成时不恢复）。
/// 接入前请确保已配置相机权限：Android 的 `CAMERA` 权限、iOS 的
/// `NSCameraUsageDescription`。
class WQrView extends StatefulWidget {
  /// 创建二维码扫描组件
  ///
  /// 所有参数都有默认值，回调都可省略。
  const WQrView({
    super.key,
    this.controller,
    this.style = const WQrOverlayStyle(),
    this.onScanned,
    this.onControllerReady,
    this.onPermissionDenied,
    this.onError,
    this.cameraFacing = CameraFacing.back,
    this.formatsAllowed = const <BarcodeFormat>[],
    this.scanOnce = true,
    this.scanInterval = const Duration(milliseconds: 400),
  });

  /// 相机控制器
  ///
  /// 由调用方创建并持有，用于重扫与相机操作；省略时组件内部创建并在销毁时释放
  /// （此时通过 [onControllerReady] 拿到实例也能用，但不要长期持有）。
  /// 控制器实例在平台视图重建后保持不变。
  final WQrController? controller;

  /// 扫描框样式（颜色、是否显示、外边距与扫描框几何）
  final WQrOverlayStyle style;

  /// 扫码结果回调
  ///
  /// 仅在 `Barcode.code` 非空时触发；[scanOnce] 为 true 时最多触发一次。
  /// 省略时组件不会自动暂停相机（可只监听 `scannedDataStream`）。
  final void Function(WQrScanResult result)? onScanned;

  /// 相机控制器就绪回调
  ///
  /// 平台视图（重新）创建后触发，传入的就是 [controller]（或组件内部创建的实例），
  /// 可在这里读取 `hasPermissions` / `cameraFacing` 或做一次初始化。
  final void Function(WQrController controller)? onControllerReady;

  /// 没有相机权限时的回调
  ///
  /// 只在「从未授权 → 未授权」这一次触发；重新授权后会重置。
  final VoidCallback? onPermissionDenied;

  /// 错误回调
  ///
  /// 用于上报相机操作失败、扫描流错误与 [onScanned] / [onControllerReady]
  /// 自身抛出的异常；未提供时 debug 下通过 `debugPrint` 输出。
  final void Function(Object error, StackTrace stackTrace)? onError;

  /// 摄像头方向，默认后置
  ///
  /// 运行期修改会重建平台视图（相机重启），并重置扫描状态。
  final CameraFacing cameraFacing;

  /// 允许识别的条码格式；为空表示使用平台默认值
  ///
  /// 运行期修改（包括原地修改列表内容）会重建平台视图（相机重启），并重置扫描状态。
  /// 为避免原地修改导致比较失效，内部会保存一份不可变快照。
  final List<BarcodeFormat> formatsAllowed;

  /// 是否只扫描一次
  ///
  /// 为 true（默认）时，首次成功扫码后调用 [onScanned] 并暂停相机；
  /// 为 false 时持续回调，不暂停相机。
  /// 只有同时传了 [onScanned] 才生效：没有 [onScanned] 时不会暂停相机。
  final bool scanOnce;

  /// 相同内容的最小回调间隔（去重窗口）
  ///
  /// 默认 400ms；`Duration.zero` 关闭去重。单次与连续模式都生效，
  /// 由组件内部用单调时钟计时。
  final Duration scanInterval;

  @override
  State<WQrView> createState() => _WQrViewState();
}

/// [WQrView] 的状态
class _WQrViewState extends State<WQrView> with WidgetsBindingObserver {
  /// 去重表最多跟踪的条码数；超过后淘汰最旧的一条
  static const _maxTrackedCodes = 64;

  /// 当前控制器（调用方传入或内部创建）
  late WQrController _controller;

  /// 控制器是否由本组件创建（决定 dispose 时是否释放）
  late bool _ownsController;

  /// 扫描数据流订阅
  StreamSubscription<Barcode>? _scanSubscription;

  /// 当前挂载的底层控制器；未挂载时为 null
  QRViewController? _native;

  /// QRView 的全局键（相机方向 / 条码格式变化时会更换以重建视图）
  GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');

  /// 是否已完成一次扫码（仅单次模式生效）
  bool _scanHandled = false;

  /// 是否已切换为成功色
  bool _borderHighlighted = false;

  /// 是否因应用进入后台而暂停了相机
  bool _pausedByLifecycle = false;

  /// 是否已上报过「无权限」，避免插件多次上报时重复回调
  bool _permissionDeniedReported = false;

  /// 去重用的单调时钟（避免系统时间跳变）
  final Stopwatch _clock = Stopwatch();

  /// 每个条码内容上次通过的时间（微秒，来自 [_clock]）
  final Map<String, int> _lastScanAtUs = {};

  /// 当前实际相机方向（flip / getCameraInfo 会更新，重建时沿用）
  late CameraFacing _effectiveFacing = widget.cameraFacing;

  /// 条码格式的不可变快照，用于检测原地修改
  late List<BarcodeFormat> _formatsAllowed;

  /// 单次模式：传了 onScanned 且 scanOnce 为 true
  bool get _singleShot => widget.scanOnce && widget.onScanned != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clock.start();
    _formatsAllowed = List<BarcodeFormat>.unmodifiable(widget.formatsAllowed);
    _bindController(widget.controller);
  }

  /// 绑定控制器并订阅扫描流
  void _bindController(WQrController? controller) {
    _controller = controller ?? WQrController();
    _ownsController = controller == null;
    _native = null;
    _scanSubscription = _controller.scannedDataStream.listen(
      _handleBarcode,
      onError: _reportError,
    );
  }

  @override
  void didUpdateWidget(covariant WQrView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _swapController(widget.controller);
    }
    if (oldWidget.cameraFacing != widget.cameraFacing) {
      _effectiveFacing = widget.cameraFacing;
    }
    if (oldWidget.cameraFacing != widget.cameraFacing ||
        !listEquals(_formatsAllowed, widget.formatsAllowed)) {
      _formatsAllowed = List<BarcodeFormat>.unmodifiable(widget.formatsAllowed);
      _recreatePlatformView();
    }
    // 扫描模式切换时重置一次状态，避免沿用上一次的锁定 / 高亮 / 去重记录
    if (oldWidget.scanOnce != widget.scanOnce ||
        (oldWidget.onScanned == null) != (widget.onScanned == null)) {
      final wasHandled = _scanHandled;
      _scanHandled = false;
      _borderHighlighted = false;
      _lastScanAtUs.clear();
      _clock.reset();
      // true → false：单次扫码已把相机 pause 了，必须恢复，否则连续扫描静默失效
      if (wasHandled && !_singleShot && !_pausedByLifecycle && _controller.isAttached) {
        _runCameraAction(() => _controller.resumeCamera());
      }
    }
  }

  /// 切换控制器：解除旧绑定，必要时释放旧的内部控制器
  void _swapController(WQrController? next) {
    final native = _native;
    unawaited(_scanSubscription?.cancel());
    _scanSubscription = null;
    _controller.detach();
    if (_ownsController) unawaited(_controller.dispose());
    _bindController(next);
    if (native != null) {
      _native = native;
      _attachController(native);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_scanSubscription?.cancel());
    _scanSubscription = null;
    _controller.detach();
    if (_ownsController) unawaited(_controller.dispose());
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
  void reassemble() {
    super.reassemble();
    if (_native == null) return;
    // Android 热重载后相机可能黑屏，先暂停再恢复
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _runCameraAction(() => _controller.pauseCamera());
    }
    if (!_pausedByLifecycle && !(_singleShot && _scanHandled)) {
      _runCameraAction(() => _controller.resumeCamera());
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    return QRView(
      key: _qrKey,
      onQRViewCreated: _onNativeCreated,
      overlay: style.isVisible
          ? QrScannerOverlayShape(
              borderColor: _borderHighlighted ? style.successColor : style.borderColor,
              borderWidth: style.borderWidth,
              overlayColor: style.overlayColor,
              borderRadius: style.borderRadius,
              borderLength: style.borderLength,
              cutOutWidth: style.cutOutWidth,
              cutOutHeight: style.cutOutHeight,
              cutOutBottomOffset: style.cutOutBottomOffset,
            )
          : null,
      overlayMargin: style.margin,
      cameraFacing: _effectiveFacing,
      formatsAllowed: _formatsAllowed,
      onPermissionSet: _onPermissionSet,
    );
  }

  /// 重建平台视图（相机方向 / 条码格式变化时）
  void _recreatePlatformView() {
    _controller.detach();
    _native = null;
    _qrKey = GlobalKey(debugLabel: 'QR');
    _scanHandled = false;
    _borderHighlighted = false;
    _lastScanAtUs.clear();
    _clock.reset();
  }

  /// 平台视图创建：把底层控制器挂到 [WQrController] 上
  void _onNativeCreated(QRViewController native) {
    // State 已销毁时不再建立新的包装控制器 / 订阅；底层控制器由 QRView 释放。
    if (!mounted) return;
    _native = native;
    _attachController(native);

    // 若创建时应用不在前台，先暂停相机，等回到前台再恢复
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    if (lifecycleState != null && lifecycleState != AppLifecycleState.resumed) {
      _pausedByLifecycle = true;
      _runCameraAction(() => _controller.pauseCamera());
    }

    final callback = widget.onControllerReady;
    if (callback != null) {
      try {
        callback(_controller);
      } catch (error, stackTrace) {
        _reportError(error, stackTrace);
      }
    }
  }

  /// 把当前底层控制器挂到 [_controller]（平台视图重建后也走这里）
  void _attachController(QRViewController native) {
    _controller.attach(
      native,
      initialFacing: _effectiveFacing,
      onFacingChanged: (facing) => _effectiveFacing = facing,
      onRestart: _restartScan,
    );
  }

  /// 处理扫描结果
  ///
  /// 忽略空内容；单次模式下只处理第一次扫码。
  void _handleBarcode(Barcode barcode) {
    if (!mounted) return;

    final code = barcode.code;
    if (code == null || code.isEmpty) return;
    if (_singleShot && _scanHandled) return;
    if (_isDuplicateScan(code)) return;

    if (_singleShot) {
      _borderHighlighted = true;
      _scanHandled = true;
      // 先暂停再回调：调用方在 onScanned 内调用 restart() 时，
      // resume 会排在 pause 之后，最终状态正确
      _runCameraAction(() => _controller.pauseCamera());
      setState(() {});
    }

    final callback = widget.onScanned;
    if (callback == null) return;

    final result = WQrScanResult(
      code: code,
      format: barcode.format,
      rawBytes: barcode.rawBytes,
      timestamp: DateTime.now(),
    );

    try {
      callback(result);
    } catch (error, stackTrace) {
      // 回调失败时回滚单次锁定并恢复相机，避免扫码能力被静默锁死
      if (_singleShot) {
        _scanHandled = false;
        _borderHighlighted = false;
        _runCameraAction(() => _controller.resumeCamera());
        if (mounted) setState(() {});
      }
      _reportError(error, stackTrace);
    }
  }

  /// 按内容与时间窗去重（每个 code 独立窗口，表容量有上限）
  bool _isDuplicateScan(String code) {
    final window = widget.scanInterval;
    if (window <= Duration.zero) return false;
    final now = _clock.elapsedMicroseconds;
    final lastAt = _lastScanAtUs[code];
    if (lastAt != null && now - lastAt < window.inMicroseconds) {
      return true;
    }
    _lastScanAtUs[code] = now;
    if (_lastScanAtUs.length > _maxTrackedCodes) {
      // 淘汰最旧的一条，保证表容量有硬上限
      String? oldestCode;
      var oldestAt = now;
      for (final entry in _lastScanAtUs.entries) {
        if (entry.value <= oldestAt) {
          oldestAt = entry.value;
          oldestCode = entry.key;
        }
      }
      if (oldestCode != null) _lastScanAtUs.remove(oldestCode);
    }
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

  /// 应用进入后台时暂停相机
  void _pauseForLifecycle() {
    if (_native == null || _pausedByLifecycle) return;
    _pausedByLifecycle = true;
    _runCameraAction(() => _controller.pauseCamera());
  }

  /// 应用回到前台时恢复相机（单次扫描已完成时不恢复）
  void _resumeFromLifecycle() {
    if (!_pausedByLifecycle) return;
    _pausedByLifecycle = false;
    if (_singleShot && _scanHandled) return;
    _runCameraAction(() => _controller.resumeCamera());
  }

  /// 重新开始扫描（由 `WQrController.restart()` 调用）
  ///
  /// 重置边框与「已扫码」状态、去重窗口，并恢复相机。
  /// 若应用仍在后台，则等到回到前台后再恢复相机。
  Future<void> _restartScan() async {
    if (!mounted) return;
    setState(() {
      _scanHandled = false;
      _borderHighlighted = false;
      _lastScanAtUs.clear();
      _clock.reset();
    });
    if (!_pausedByLifecycle && _controller.isAttached) {
      await _runCameraActionAsync(() => _controller.resumeCamera());
    }
  }

  /// 执行相机操作并上报异常（同步 throw 与 Future 失败都走 onError）
  ///
  /// 传闭包而不是已求值的 Future：Web 端插件的 `pauseCamera` 是同步抛
  /// `UnimplementedError`，先求值会绕过这里的护栏。
  void _runCameraAction(Future<void>? Function()? action) {
    if (action == null) return;
    unawaited(_runCameraActionAsync(action));
  }

  /// 可等待版本：供 restart 等需要「完成语义」的调用点使用
  Future<void> _runCameraActionAsync(Future<void>? Function()? action) async {
    if (action == null) return;
    try {
      final future = action();
      if (future != null) await future;
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
