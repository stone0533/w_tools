import '../config.dart';
import 'storage.dart';

/// Token 管理类，用于管理 token 及过期时间
class WToken {
  /// 存储 token 的键名
  static const String tokenKey = WConfig.tokenKey;

  /// 存储 refresh token 的键名
  static const String refreshTokenKey = WConfig.refreshTokenKey;

  /// 存储 token 过期时间的键名
  static const String tokenExpiryKey = WConfig.tokenExpiryKey;
  
  /// 内存缓存的 token
  static String? _cachedToken;
  
  /// 内存缓存的 refresh token
  static String? _cachedRefreshToken;

  /// 私有构造函数，禁用实例化
  WToken._();

  /// 保存 token
  /// @param token 要保存的 token
  /// @param expiry 过期时间（可选）
  static Future<void> saveToken(String token, [DateTime? expiry]) async {
    // 更新内存缓存
    _cachedToken = token;
    // 保存到磁盘
    await WStorage.setString(tokenKey, token);
    if (expiry != null) {
      await WStorage.setString(tokenExpiryKey, expiry.toIso8601String());
    }
  }

  /// 保存 refresh token
  /// @param refreshToken 要保存的 refresh token
  static Future<void> saveRefreshToken(String refreshToken) async {
    // 更新内存缓存
    _cachedRefreshToken = refreshToken;
    // 保存到磁盘
    await WStorage.setString(refreshTokenKey, refreshToken);
  }

  /// 保存 token 和 refresh token
  /// @param token 要保存的 token
  /// @param refreshToken 要保存的 refresh token
  /// @param expiry token 过期时间（可选）
  static Future<void> saveTokens(String token, String refreshToken, [DateTime? expiry]) async {
    await saveToken(token, expiry);
    await saveRefreshToken(refreshToken);
  }

  /// 获取 token
  static String? getToken() {
    // 优先返回内存缓存
    if (_cachedToken != null) {
      return _cachedToken;
    }
    // 缓存未命中，从磁盘读取并更新缓存
    final token = WStorage.getString(tokenKey);
    _cachedToken = token;
    return token;
  }

  /// 获取 refresh token
  static String? getRefreshToken() {
    // 优先返回内存缓存
    if (_cachedRefreshToken != null) {
      return _cachedRefreshToken;
    }
    // 缓存未命中，从磁盘读取并更新缓存
    final refreshToken = WStorage.getString(refreshTokenKey);
    _cachedRefreshToken = refreshToken;
    return refreshToken;
  }

  /// 清除 token
  static Future<void> clearToken() async {
    // 清除内存缓存
    _cachedToken = null;
    // 从磁盘删除
    await WStorage.remove(tokenKey);
    await WStorage.remove(tokenExpiryKey);
  }

  /// 清除 refresh token
  static Future<void> clearRefreshToken() async {
    // 清除内存缓存
    _cachedRefreshToken = null;
    // 从磁盘删除
    await WStorage.remove(refreshTokenKey);
  }

  /// 清除所有 token 相关数据
  static Future<void> clearAllTokens() async {
    await clearToken();
    await clearRefreshToken();
  }

  /// 检查 token 是否过期
  static bool isTokenExpired() {
    final expiryStr = WStorage.getString(tokenExpiryKey);
    if (expiryStr == null) {
      return false; // 如果没有存储过期时间，则认为 token 不过期
    }
    try {
      final expiry = DateTime.parse(expiryStr);
      return DateTime.now().isAfter(expiry);
    } catch (e) {
      return false; // 如果解析失败，则认为 token 不过期
    }
  }

  /// 检查 token 是否有效（存在且未过期）
  static bool isTokenValid() {
    final token = getToken();
    if (token == null || token.isEmpty) {
      return false;
    }
    return !isTokenExpired();
  }

  /// 检查是否存在 refresh token
  static bool hasRefreshToken() {
    final refreshToken = getRefreshToken();
    return refreshToken != null && refreshToken.isNotEmpty;
  }

  /// 获取 token 过期时间
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