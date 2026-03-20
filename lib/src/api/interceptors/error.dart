import 'package:dio/dio.dart';
import '../../../w.dart';

/// 错误处理拦截器，用于处理 401 未授权错误和令牌刷新
class WErrorInterceptor extends Interceptor {
  /// 刷新令牌存储键名
  final String refreshTokenKey;

  /// 访问令牌存储键名
  final String accessTokenKey;

  /// 获取新令牌的回调函数
  final Future<String?> Function(String refreshToken)? onRefreshToken;

  /// 最大重试次数
  final int maxRetries;

  /// 构造函数
  ///
  /// @param refreshTokenKey 刷新令牌存储键名
  /// @param accessTokenKey 访问令牌存储键名
  /// @param onRefreshToken 获取新令牌的回调函数
  /// @param maxRetries 最大重试次数
  WErrorInterceptor({
    this.refreshTokenKey = 'refreshToken',
    this.accessTokenKey = 'token',
    this.onRefreshToken,
    this.maxRetries = 1,
  });

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // 处理 401 错误（未授权）
    if (err.response?.statusCode == 401) {
      // 获取请求级别的重试计数
      int retryCount = err.requestOptions.extra['_retryCount'] ?? 0;

      if (retryCount < maxRetries) {
        WLogger.d('Handling 401 error, attempt ${retryCount + 1}/$maxRetries');

        // 获取刷新令牌
        String? refreshToken = WStorage.getString(refreshTokenKey);
        if (refreshToken?.isNotEmpty ?? false) {
          try {
            // 获取新令牌
            String? newToken;
            if (onRefreshToken != null) {
              newToken = await onRefreshToken!(refreshToken!);
            } else {
              // 默认实现，实际项目中应该替换为真实的令牌刷新逻辑
              WLogger.w('No onRefreshToken callback provided, using default implementation');
              // 这里应该调用真实的令牌刷新 API
              newToken = 'new_token';
            }

            if (newToken?.isNotEmpty ?? false) {
              // 存储新令牌
              await WStorage.setString(accessTokenKey, newToken!);
              WLogger.d('Token refreshed successfully');

              // 更新请求头并重试
              err.response!.requestOptions.headers['Authorization'] = "Bearer $newToken";

              // 增加重试计数
              err.requestOptions.extra['_retryCount'] = retryCount + 1;

              // 创建新的 Dio 实例进行重试
              Dio dio = DioUtil.instance(err.response!.requestOptions.baseUrl).dio;
              var responseNew = await dio.fetch(err.response!.requestOptions);
              WLogger.d('Request retried successfully');
              return handler.resolve(responseNew);
            } else {
              WLogger.e('Failed to get new token: token is empty');
            }
          } catch (e) {
            WLogger.e('Error refreshing token: $e');
          }
        } else {
          WLogger.e('No refresh token found');
        }
      } else {
        WLogger.e('Max retry attempts reached');
      }
    }

    super.onError(err, handler);
  }
}
