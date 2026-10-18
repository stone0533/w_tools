/// 全局资产配置
///
/// 在应用启动时配置一次，之后所有相关方法自动生效：
/// ```dart
/// WAssets.imagePath = 'images/icons/';
/// ```
class WAssets {
  /// 图片资产前置路径，默认 `assets/images/`
  static String imagePath = 'assets/images/';

  WAssets._();
}
