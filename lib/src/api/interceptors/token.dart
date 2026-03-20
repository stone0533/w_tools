import 'package:dio/dio.dart';

import '../../utils/logger.dart';
import '../../utils/storage.dart';

/// Token 拦截器，用于处理 token 的添加、更新和错误处理
///
/// 功能包括：
/// - 在请求中自动添加 token
/// - 在响应中自动更新 token
/// - 处理 401 未授权错误，清除 token
/// - 处理 token 过期情况
class WTokenInterceptor extends Interceptor {
  /// token 存储键名，默认为 'token'
  final String tokenKey;

  /// token 过期时间存储键名
  final String tokenExpiryKey;

  /// 401 错误处理回调
  final void Function()? onUnauthorized;

  /// 构造函数
  ///
  /// @param tokenKey token 存储键名
  /// @param tokenExpiryKey token 过期时间存储键名
  /// @param onUnauthorized 401 错误处理回调
  WTokenInterceptor({
    this.tokenKey = 'token',
    this.tokenExpiryKey = 'token_expiry',
    this.onUnauthorized,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.contentType = "application/json";

    // 检查 token 是否过期
    if (_isTokenExpired()) {
      WStorage.remove(tokenKey);
      WStorage.remove(tokenExpiryKey);
      WLogger.d('Token expired, cleared');
    }

    // 添加 token
    final token = WStorage.getString(tokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
      WLogger.d('Added token to request: ${token.substring(0, 10)}...');
    } else {
      WLogger.d('No token found, skipping authorization header');
    }

    super.onRequest(options, handler);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    // 处理响应中的 token
    final token = response.data?['token'];
    if (token != null && token is String) {
      try {
        await WStorage.setString(tokenKey, token);
        // 存储 token 过期时间（假设 token 有效期为 24 小时）
        final expiryTime = DateTime.now().add(const Duration(hours: 24));
        await WStorage.setString(tokenExpiryKey, expiryTime.toIso8601String());
        WLogger.d('Updated token successfully');
      } catch (e) {
        WLogger.e('Failed to update token: $e');
      }
    }

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 处理 401 错误（未授权）
    if (err.response?.statusCode == 401) {
      // 清除 token
      WStorage.remove(tokenKey);
      WStorage.remove(tokenExpiryKey);
      WLogger.e('Unauthorized, token cleared');
      // 调用 401 错误处理回调
      onUnauthorized?.call();
    }

    super.onError(err, handler);
  }

  /// 检查 token 是否过期
  bool _isTokenExpired() {
    final expiryStr = WStorage.getString(tokenExpiryKey);
    if (expiryStr == null) return false;

    try {
      final expiryTime = DateTime.parse(expiryStr);
      return DateTime.now().isAfter(expiryTime);
    } catch (e) {
      WLogger.e('Failed to parse token expiry time: $e');
      return false;
    }
  }
}
