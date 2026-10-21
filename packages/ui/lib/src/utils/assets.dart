/// 全局资产配置
///
/// 资源前缀的唯一开关：`'logo.png'.assetImagePath` 读这里；聚合包的
/// `WConfig.assetImagePath` 也是它的转发。在应用启动时配置一次：
/// ```dart
/// WAssets.imagePath = 'images/icons/';
/// ```
class WAssets {
  /// 图片资产前置路径，默认 `assets/images/`
  static String imagePath = 'assets/images/';

  WAssets._();
}
