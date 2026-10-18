import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

/// 相机控制器封装
///
/// 对 `QRViewController` 的轻量包装：
/// - `scannedDataStream` 为广播流，支持多个监听者；
/// - 相机操作直接转发给底层控制器。
///
/// 底层控制器的扫描流是单订阅流，本类在创建时只订阅一次，因此调用方可以
/// 同时监听 `scannedDataStream` 与使用 `WQrView.onScanned`。
///
/// 控制器与当前平台视图的生命周期一致：视图重建后会创建新实例，
/// 请以最新一次 `WQrView.onQRViewCreated` 回调为准。
/// `resumeCamera` 只恢复相机，不会重置 `scanOnce` 的已扫码锁定；
/// 需要重新扫码请调用 `WQrViewState.restartScan`。
/// 相机操作失败时底层会抛出 `CameraException`，由调用方处理。
class WQrController {
  /// 包装底层控制器，订阅其单订阅流并转发到广播流
  @internal
  WQrController.internal(this._controller) {
    _scanSubscription = _controller.scannedDataStream.listen(
      _scanController.add,
      onError: _scanController.addError,
    );
  }

  /// 底层控制器
  final QRViewController _controller;

  /// 广播版扫描数据流
  final StreamController<Barcode> _scanController = StreamController<Barcode>.broadcast();

  /// 底层扫描流的订阅
  late final StreamSubscription<Barcode> _scanSubscription;

  /// 扫描数据流（广播，可多监听）
  Stream<Barcode> get scannedDataStream => _scanController.stream;

  /// 相机是否已获得权限
  bool get hasPermissions => _controller.hasPermissions;

  /// 暂停相机
  Future<void> pauseCamera() => _controller.pauseCamera();

  /// 恢复相机
  Future<void> resumeCamera() => _controller.resumeCamera();

  /// 停止相机
  Future<void> stopCamera() => _controller.stopCamera();

  /// 翻转前后摄像头，返回翻转后的方向
  Future<CameraFacing> flipCamera() => _controller.flipCamera();

  /// 获取闪光灯状态
  Future<bool?> getFlashStatus() => _controller.getFlashStatus();

  /// 切换闪光灯
  Future<void> toggleFlash() => _controller.toggleFlash();

  /// 获取当前摄像头方向
  Future<CameraFacing> getCameraInfo() => _controller.getCameraInfo();

  /// 获取设备可用能力
  Future<SystemFeatures> getSystemFeatures() => _controller.getSystemFeatures();

  /// 开关反色扫描（仅 Android 生效）
  Future<void> scanInvert(bool isScanInvert) => _controller.scanInvert(isScanInvert);

  /// 释放广播流与底层订阅
  @internal
  Future<void> dispose() async {
    await _scanSubscription.cancel();
    await _scanController.close();
  }
}
