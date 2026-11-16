part of 'qr_core.dart';

/// 相机控制器
///
/// 由调用方创建并持有，传给 `WQrView.controller`：
///
/// ```dart
/// final controller = WQrController();
/// WQrView(controller: controller, onScanned: (result) => ...);
/// // 需要再扫
/// await controller.restart();
/// ```
///
/// 生命周期：
/// - 控制器实例跨「平台视图重建」（`cameraFacing` / `formatsAllowed` 变化）保持不变，
///   [scannedDataStream] 也保持不变，可长期持有；
/// - 平台视图（重新）创建时挂载、组件销毁时解除挂载，由 `WQrView` 完成；
/// - 页面 `dispose()` 里由调用方 [dispose]。
///
/// 未挂载时（平台视图还没创建或已销毁）相机方法与 [restart] 都抛 [StateError]，
/// 不静默失败；Web 上插件没有实现 `pauseCamera` / `resumeCamera`，直接调用会抛
/// `UnimplementedError`（`WQrView` 内部已跳过这两个调用）。
class WQrController {
  /// 创建控制器
  WQrController();

  /// 底层控制器；未挂载时为 null
  QRViewController? _native;

  /// 广播版扫描数据流，控制器生命周期内保持不变
  final StreamController<Barcode> _scanController = StreamController<Barcode>.broadcast(sync: true);

  /// 最近一次已知的相机方向（挂载时的初始方向或 `flipCamera` 的结果）
  CameraFacing? _cameraFacing;

  /// 重扫回调（由 `WQrView` 注册，重置单次锁定 / 节流窗口）
  Future<void> Function()? _onRestart;

  /// 是否已 dispose，避免重复释放
  bool _disposed = false;

  /// 控制器是否已挂载到平台视图
  bool get isAttached => _native != null;

  /// 扫描数据流（广播，可多监听）
  ///
  /// 这里是插件原样的 `Barcode`（`code` 可能为空）；过滤与节流只发生在
  /// `WQrView.onScanned` 上。
  Stream<Barcode> get scannedDataStream => _scanController.stream;

  /// 最近一次已知的相机方向；尚未挂载时为 null
  CameraFacing? get cameraFacing => _cameraFacing;

  /// 重新开始扫描
  ///
  /// 重置单次扫码锁定与节流窗口；应用在前台时恢复相机，在后台时等到回到前台
  /// 再恢复。未挂载时抛 [StateError]。
  Future<void> restart() async {
    final handler = _onRestart;
    if (handler == null) {
      throw StateError('WQrController 尚未挂载到 WQrView：请在相机就绪后调用 restart()');
    }
    await handler();
  }

  /// 暂停相机
  Future<void> pauseCamera() => _requireNative().pauseCamera();

  /// 恢复相机
  ///
  /// 只恢复相机运行态，不重置单次扫码锁定；需要重新扫描请用 [restart]。
  Future<void> resumeCamera() => _requireNative().resumeCamera();

  /// 翻转前后摄像头，返回翻转后的方向
  Future<CameraFacing> flipCamera() async {
    final facing = await _requireNative().flipCamera();
    _cameraFacing = facing;
    return facing;
  }

  /// 获取闪光灯状态
  Future<bool?> getFlashStatus() => _requireNative().getFlashStatus();

  /// 切换闪光灯
  Future<void> toggleFlash() => _requireNative().toggleFlash();

  /// 释放广播流并解除挂载
  ///
  /// 由调用方在页面销毁时调用；重复调用无效。
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _detach();
    await _scanController.close();
  }

  /// 挂载底层控制器（由 `WQrView` 调用）
  void _attach(
    QRViewController native, {
    required CameraFacing initialFacing,
    required Future<void> Function() onRestart,
  }) {
    if (_disposed) return;
    _detach();
    _native = native;
    _cameraFacing ??= initialFacing;
    _onRestart = onRestart;
  }

  /// 解除挂载（由 `WQrView` 在平台视图销毁 / 重建前调用）
  void _detach() {
    _native = null;
    _onRestart = null;
  }

  /// 把插件原样的条码转发到广播流（由 `WQrView` 调用）
  ///
  /// 插件流是单订阅，订阅由 `WQrView` 独占；控制器只负责广播，这样控制器
  /// 替换 / 平台视图重建都不会再碰底层流。
  void _emit(Barcode barcode) {
    if (!_scanController.isClosed) _scanController.add(barcode);
  }

  /// 把底层流错误转发到广播流
  void _emitError(Object error, StackTrace stackTrace) {
    if (!_scanController.isClosed) _scanController.addError(error, stackTrace);
  }

  /// 记录方向（`WQrView.cameraFacing` 变化时由组件写入）
  void _setFacing(CameraFacing facing) => _cameraFacing = facing;

  /// 取底层控制器；未挂载时抛 [StateError] 而不是静默失败
  QRViewController _requireNative() {
    final native = _native;
    if (native == null) {
      throw StateError('WQrController 尚未挂载到 WQrView：请在相机就绪后调用相机方法');
    }
    return native;
  }
}
