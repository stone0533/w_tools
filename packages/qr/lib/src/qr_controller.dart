import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

/// 相机控制器
///
/// 由调用方创建并持有（与 `WMapController` 同模式），传给 `WQrView.controller`：
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
///   [scannedDataStream] 也保持不变，可放心长期持有；
/// - 平台视图（重新）创建时挂载、卸载前解除挂载，由 `WQrView` 内部完成；
/// - 传了 `WQrView.controller` 时由调用方负责 [dispose]；不传时 `WQrView` 自己创建并释放。
///
/// 未挂载时（还没收到 `WQrView.onControllerReady`，或平台视图已销毁）：
/// - 相机操作方法抛 [StateError]（不静默失败）；
/// - [restart] 什么都不做（与 `WMapController.select` 一致，便于在初始化前后统一调用）。
///
/// 相机操作失败时底层抛 `CameraException`，由调用方处理；`WQrView` 内部发起的调用
/// 会转成 `WQrView.onError`。
class WQrController {
  /// 创建控制器
  ///
  /// 创建后由 [WQrView] 在平台视图创建时挂载，无需手动 attach。
  WQrController();

  /// 底层控制器；未挂载时为 null
  QRViewController? _native;

  /// 底层扫描流订阅（插件流是单订阅，本类只订阅一次并转发到广播流）
  StreamSubscription<Barcode>? _nativeSubscription;

  /// 广播版扫描数据流，控制器生命周期内保持不变
  final StreamController<Barcode> _scanController = StreamController<Barcode>.broadcast(sync: true);

  /// 最近一次已知的相机方向（`flipCamera` / `getCameraInfo` 更新）
  CameraFacing? _cameraFacing;

  /// 方向变化通知（由 `WQrView` 注册，用于平台视图重建时沿用方向）
  void Function(CameraFacing facing)? _onFacingChanged;

  /// 重新开始扫描（由 `WQrView` 注册，重置单次锁定 / 成功色 / 去重窗口）
  Future<void> Function()? _onRestart;

  /// 是否已 dispose，避免重复释放
  bool _disposed = false;

  /// 控制器是否已挂载到平台视图
  bool get isAttached => _native != null;

  /// 扫描数据流（广播，可多监听；与 `WQrView.onScanned` 互相独立）
  ///
  /// 这里的 `Barcode` 保留插件原样（`code` 可能为空），过滤与去重只在
  /// `WQrView.onScanned` 上做。
  Stream<Barcode> get scannedDataStream => _scanController.stream;

  /// 相机是否已获得权限（未挂载时为 false）
  bool get hasPermissions => _native?.hasPermissions ?? false;

  /// 最近一次已知的相机方向（可能为 null，尚未查询）
  CameraFacing? get cameraFacing => _cameraFacing;

  /// 重新开始扫描
  ///
  /// 重置单次扫码锁定、成功色与去重窗口；应用在前台时恢复相机，在后台时
  /// 等到回到前台再恢复。未挂载时什么都不做。
  Future<void> restart() async {
    final handler = _onRestart;
    if (handler == null) return;
    await handler();
  }

  /// 暂停相机
  Future<void> pauseCamera() => _requireNative().pauseCamera();

  /// 恢复相机
  ///
  /// 只恢复相机运行态，不重置单次扫码锁定；需要重新扫描请用 [restart]。
  Future<void> resumeCamera() => _requireNative().resumeCamera();

  /// 停止相机
  Future<void> stopCamera() => _requireNative().stopCamera();

  /// 翻转前后摄像头，返回翻转后的方向
  Future<CameraFacing> flipCamera() async {
    final facing = await _requireNative().flipCamera();
    _updateFacing(facing);
    return facing;
  }

  /// 获取当前摄像头方向
  Future<CameraFacing> getCameraInfo() async {
    final facing = await _requireNative().getCameraInfo();
    _updateFacing(facing);
    return facing;
  }

  /// 获取闪光灯状态
  Future<bool?> getFlashStatus() => _requireNative().getFlashStatus();

  /// 切换闪光灯
  Future<void> toggleFlash() => _requireNative().toggleFlash();

  /// 获取设备可用能力
  Future<SystemFeatures> getSystemFeatures() => _requireNative().getSystemFeatures();

  /// 开关反色扫描（仅 Android 生效）
  Future<void> setInvert(bool enabled) => _requireNative().scanInvert(enabled);

  /// 释放广播流与底层订阅
  ///
  /// 只有「调用方自己创建并传给 `WQrView`」的控制器才需要调用；不传 controller
  /// 时由 `WQrView` 负责释放。重复调用无效。
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    detach();
    await _scanController.close();
  }

  /// 挂载底层控制器（由 `WQrView` 调用）
  @internal
  void attach(
    QRViewController native, {
    CameraFacing? initialFacing,
    void Function(CameraFacing facing)? onFacingChanged,
    Future<void> Function()? onRestart,
  }) {
    if (_disposed) return;
    detach();
    _native = native;
    _cameraFacing = initialFacing ?? _cameraFacing;
    _onFacingChanged = onFacingChanged;
    _onRestart = onRestart;
    _nativeSubscription = native.scannedDataStream.listen(
      _scanController.add,
      onError: _scanController.addError,
    );
  }

  /// 解除挂载（由 `WQrView` 在平台视图销毁 / 重建前调用）
  @internal
  void detach() {
    final subscription = _nativeSubscription;
    _nativeSubscription = null;
    _native = null;
    _onFacingChanged = null;
    _onRestart = null;
    if (subscription != null) unawaited(subscription.cancel());
  }

  /// 更新方向并通知 `WQrView`
  void _updateFacing(CameraFacing facing) {
    _cameraFacing = facing;
    _onFacingChanged?.call(facing);
  }

  /// 取底层控制器；未挂载时抛 [StateError] 而不是静默失败
  QRViewController _requireNative() {
    final native = _native;
    if (native == null) {
      throw StateError(
        'WQrController 尚未挂载到 WQrView：请在 onControllerReady 之后调用相机方法',
      );
    }
    return native;
  }
}
