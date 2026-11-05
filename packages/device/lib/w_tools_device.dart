/// 设备验证小工具：iOS/Android 模拟器可交互；Android 真机经 adb；iOS 真机仅 list/shot。
///
/// 本包定位是 CLI（`bin/device.dart`）。下面的 `src/` 导出只供仓库内示例/测试使用，
/// **不承诺库 API 稳定性**；消费方请用 `dart run w_tools_device:device ...`。
library;

export 'src/android.dart';
export 'src/calibration.dart';
export 'src/calibration_store.dart';
export 'src/device_hub.dart';
export 'src/geometry.dart';
export 'src/input.dart';
export 'src/options.dart';
export 'src/real_device.dart';
export 'src/shell.dart';
export 'src/simctl.dart';
export 'src/stability.dart';
