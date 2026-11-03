/// 基础配置
///
/// token 键名已迁到 [WToken]，这里的同名字段只作弃用代理；`assetImagePath` 仅为
/// 源码兼容保留，不再有任何效果。
library;

import 'utils/token.dart';

class WConfig {
  /// 资产图片路径（以 `/` 结尾）
  ///
  /// **已失效**：本字段不再被任何代码读取。资源前缀的实际开关是
  /// `w_tools_ui` 的 `WAssets.imagePath`；聚合包里的 `WConfig.assetImagePath`
  /// 代理的也是后者。字段仅为源码兼容保留。
  ///
  /// remove-in: 3.0.0
  @Deprecated(
    '该字段没有任何效果；请改用 w_tools_ui 的 WAssets.imagePath'
    '（聚合包的 WConfig.assetImagePath 已是它的代理）。',
  )
  static String assetImagePath = 'assets/images/';

  /// token 存储键名（代理到 [WToken.tokenKey]）
  @Deprecated('用 WToken.tokenKey；3.0 移除')
  static String get tokenKey => WToken.tokenKey;

  /// token 存储键名（代理到 [WToken.tokenKey]）
  /// remove-in: 3.0.0
  @Deprecated('用 WToken.tokenKey；3.0 移除')
  static set tokenKey(String value) => WToken.tokenKey = value;

  /// refresh token 存储键名（代理到 [WToken.refreshTokenKey]）
  /// remove-in: 3.0.0
  @Deprecated('用 WToken.refreshTokenKey；3.0 移除')
  static String get refreshTokenKey => WToken.refreshTokenKey;

  /// refresh token 存储键名（代理到 [WToken.refreshTokenKey]）
  /// remove-in: 3.0.0
  @Deprecated('用 WToken.refreshTokenKey；3.0 移除')
  static set refreshTokenKey(String value) => WToken.refreshTokenKey = value;

  /// token 过期时间存储键名（代理到 [WToken.tokenExpiryKey]）
  /// remove-in: 3.0.0
  @Deprecated('用 WToken.tokenExpiryKey；3.0 移除')
  static String get tokenExpiryKey => WToken.tokenExpiryKey;

  /// token 过期时间存储键名（代理到 [WToken.tokenExpiryKey]）
  /// remove-in: 3.0.0
  @Deprecated('用 WToken.tokenExpiryKey；3.0 移除')
  static set tokenExpiryKey(String value) => WToken.tokenExpiryKey = value;

  // 纯静态配置类，禁止实例化
  WConfig._();
}
