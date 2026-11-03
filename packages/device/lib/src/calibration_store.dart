import 'dart:convert';
import 'dart:io';

import 'calibration.dart';
import 'device_hub.dart';

/// 标定结果缓存：`~/.cache/w_tools_device/<udid>.json`。
///
/// 命中条件：窗口位置/大小没变。变了就重算（DeviceHub 被移动/缩放时）。
class CalibrationStore {
  CalibrationStore({String? home})
      : _home = home ?? Platform.environment['HOME'] ?? Directory.systemTemp.path;

  final String _home;

  Directory get dir => Directory('$_home/.cache/w_tools_device');

  File fileFor(String udid) => File('${dir.path}/$udid.json');

  Calibration? load(String udid) {
    final f = fileFor(udid);
    if (!f.existsSync()) return null;
    try {
      final json = jsonDecode(f.readAsStringSync());
      if (json is! Map<String, dynamic>) return null;
      return Calibration.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  void save(String udid, Calibration c) {
    dir.createSync(recursive: true);
    fileFor(udid).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(c.toJson()),
    );
  }

  /// 当前窗口与缓存是否仍然匹配。
  ///
  /// 设备尺寸 / 方向变化（竖屏转横屏、--scale 改变）时也必须失效，
  /// 否则旧的 deviceRect 会把点击换算到错误位置。
  bool isFresh(
    String udid,
    HubWindow window, {
    int? deviceWidth,
    int? deviceHeight,
    double? scale,
  }) {
    return isFreshCalibration(
      load(udid),
      window,
      deviceWidth: deviceWidth,
      deviceHeight: deviceHeight,
      scale: scale,
    );
  }

  /// 不重复读文件的缓存判断；CLI 已经 load 过缓存时使用。
  static bool isFreshCalibration(
    Calibration? cached,
    HubWindow window, {
    int? deviceWidth,
    int? deviceHeight,
    double? scale,
  }) {
    if (cached == null || !cached.matches(window)) return false;
    if (deviceWidth != null && cached.deviceWidth != deviceWidth) return false;
    if (deviceHeight != null && cached.deviceHeight != deviceHeight) return false;
    if (scale != null && cached.scale != scale) return false;
    return true;
  }
}
