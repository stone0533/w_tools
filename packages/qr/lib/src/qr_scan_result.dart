import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart' show BarcodeFormat;

/// 一次成功扫码的结果
///
/// 由 `WQrView.onScanned` 回调；包内已完成「`code` 非空」过滤，因此 [code]
/// 一定非空。需要原始平台对象时仍可监听 `WQrController.scannedDataStream` 读取 `Barcode`。
///
/// - [code]：扫码内容（已保证非空）
/// - [format]：条码格式
/// - [rawBytes]：原始字节，仅 Android / iOS 提供
/// - [timestamp]：包内收到该结果的时间
class WQrScanResult {
  /// 创建扫码结果
  const WQrScanResult({
    required this.code,
    required this.format,
    required this.timestamp,
    this.rawBytes,
  });

  /// 扫码内容，保证非空
  final String code;

  /// 条码格式
  final BarcodeFormat format;

  /// 原始字节（仅 Android / iOS 提供，其他平台为 null）
  final List<int>? rawBytes;

  /// 包内收到该结果的时间
  final DateTime timestamp;

  @override
  String toString() => 'WQrScanResult(code: $code, format: $format)';
}
