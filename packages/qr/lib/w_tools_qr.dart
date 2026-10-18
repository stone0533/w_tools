/// w_tools 二维码扫描组件
library w_tools_qr;

// 公开签名中出现的第三方类型，统一由本包转出，调用方无需额外依赖插件
export 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart'
    show Barcode, BarcodeFormat, CameraException, CameraFacing, SystemFeatures;

export 'src/qr_controller.dart';
export 'src/qr_overlay_shape.dart';
export 'src/qr_view.dart';
