/// 基础配置
///
/// 通过静态字段统一配置资源路径与 token 存储键名，修改后对所有使用方立即生效。
class WConfig {
  /// 资产图片路径（以 `/` 结尾）
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
