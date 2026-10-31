/// 全局资产配置
///
/// 资源前缀的唯一开关：`'logo.png'.assetImagePath` 读这里；聚合包的
/// `WConfig.assetImagePath` 也是它的转发。在应用启动时配置一次：
/// ```dart
/// WAssets.imagePath = 'images/icons/';
/// ```
class WAssets {
  static String _imagePath = 'assets/images/';

  /// 图片资产前置路径，默认 `assets/images/`
  ///
  /// 写入时会自动补齐末尾 `/`；空字符串表示不添加前缀。
  static String get imagePath => _imagePath;

  static set imagePath(String value) {
    final trimmed = value.trim();
    _imagePath = trimmed.isEmpty || trimmed.endsWith('/') ? trimmed : '$trimmed/';
  }

  WAssets._();
}
