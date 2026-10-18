import '../config.dart';
import 'storage.dart';

/// Token 管理
///
/// 键名来自 [WConfig]；读写直接走 [WStorage]（SharedPreferences 自身已有内存
/// 缓存），因此调用 [WStorage.clear] 后 token 状态会同步清空。
class WToken {
  /// token 存储键名（来自 [WConfig.tokenKey]）
  static String get tokenKey => WConfig.tokenKey;

  /// refresh token 存储键名（来自 [WConfig.refreshTokenKey]）
  static String get refreshTokenKey => WConfig.refreshTokenKey;

  /// token 过期时间存储键名（来自 [WConfig.tokenExpiryKey]）
  static String get tokenExpiryKey => WConfig.tokenExpiryKey;

  // 纯静态工具类，禁止实例化
  WToken._();

  /// 保存 token
  ///
  /// [expiry] 为 null 时会清除旧的过期时间，避免新 token 沿用旧值。
  static Future<void> saveToken(String token, [DateTime? expiry]) async {
    await WStorage.setString(tokenKey, token);
    if (expiry != null) {
      await WStorage.setString(tokenExpiryKey, expiry.toIso8601String());
    } else {
      await WStorage.remove(tokenExpiryKey);
    }
  }

  /// 保存 refresh token
  static Future<void> saveRefreshToken(String refreshToken) async {
    await WStorage.setString(refreshTokenKey, refreshToken);
  }

  /// 同时保存 token 与 refresh token
  ///
  /// [expiry] 为 null 时会清除旧的过期时间（同 [saveToken]）。
  static Future<void> saveTokens(String token, String refreshToken, [DateTime? expiry]) async {
    await saveToken(token, expiry);
    await saveRefreshToken(refreshToken);
  }

  /// 读取 token
  static String? getToken() {
    return WStorage.getString(tokenKey);
  }

  /// 读取 refresh token
  static String? getRefreshToken() {
    return WStorage.getString(refreshTokenKey);
  }

  /// 清除 token 及其过期时间
  static Future<void> clearToken() async {
    await WStorage.remove(tokenKey);
    await WStorage.remove(tokenExpiryKey);
  }

  /// 清除 refresh token
  static Future<void> clearRefreshToken() async {
    await WStorage.remove(refreshTokenKey);
  }

  /// 清除全部 token 相关数据
  static Future<void> clearAllTokens() async {
    await clearToken();
    await clearRefreshToken();
  }

  /// token 是否已过期
  ///
  /// 未存过期时间或过期时间解析失败时返回 false（视为未过期）。
  static bool isTokenExpired() {
    final expiryStr = WStorage.getString(tokenExpiryKey);
    if (expiryStr == null) {
      return false;
    }
    try {
      final expiry = DateTime.parse(expiryStr);
      return DateTime.now().isAfter(expiry);
    } catch (e) {
      return false;
    }
  }

  /// token 是否有效（存在且未过期）
  static bool isTokenValid() {
    final token = getToken();
    if (token == null || token.isEmpty) {
      return false;
    }
    return !isTokenExpired();
  }

  /// 是否存在 refresh token
  static bool hasRefreshToken() {
    final refreshToken = getRefreshToken();
    return refreshToken != null && refreshToken.isNotEmpty;
  }

  /// 读取 token 过期时间，未设置或解析失败时返回 null
  static DateTime? getTokenExpiry() {
    final expiryStr = WStorage.getString(tokenExpiryKey);
    if (expiryStr == null) {
      return null;
    }
    try {
      return DateTime.parse(expiryStr);
    } catch (e) {
      return null;
    }
  }

  /// 更新 token 过期时间
  static Future<void> updateTokenExpiry(DateTime expiry) async {
    await WStorage.setString(tokenExpiryKey, expiry.toIso8601String());
  }
}
