/// 基础配置
///
/// 通过静态字段统一配置资源路径与 token 存储键名，修改后对所有使用方立即生效。
class WConfig {
  /// 资产图片路径（以 `/` 结尾）
  ///
  /// **已失效**：本字段不再被任何代码读取。资源前缀的实际开关是
  /// `w_tools_ui` 的 `WAssets.imagePath`；聚合包里的 `WConfig.assetImagePath`
  /// 代理的也是后者。字段仅为源码兼容保留，将在下个大版本移除。
  @Deprecated(
    '该字段没有任何效果；请改用 w_tools_ui 的 WAssets.imagePath'
    '（聚合包的 WConfig.assetImagePath 已是它的代理）。',
  )
  static String assetImagePath = 'assets/images/';

  /// token 存储键名（由 WToken 使用）
  static String tokenKey = 'token';

  /// refresh token 存储键名（由 WToken 使用）
  static String refreshTokenKey = 'refresh_token';

  /// token 过期时间存储键名（由 WToken 使用）
  static String tokenExpiryKey = 'token_expiry';

  // 纯静态配置类，禁止实例化
  WConfig._();
}
