import 'package:dio/dio.dart';

import '../../utils/logger.dart';
import '../../utils/token.dart';
import '../clients/dio_util.dart';

/// Token 拦截器，用于处理 token 的添加、更新和错误处理
///
/// 功能包括：
/// - 在请求中自动添加 token
/// - 在响应中自动更新 token
/// - 处理未授权错误，清除 token
/// - 处理 token 过期情况
class WTokenInterceptor extends Interceptor {
  /// 认证错误处理回调，返回新的 token
  final Future<String?> Function()? onAuthError;

  /// 请求选项修改回调，用于在添加 token 前修改请求选项
  final void Function(RequestOptions)? onRequestOptions;

  /// 响应处理回调，用于在处理响应后修改响应
  final void Function(Response)? onResponseOptions;

  /// 错误处理回调，用于在处理错误后修改错误
  final void Function(DioException)? onErrorOptions;

  /// 未授权错误状态码，默认为 401
  final int unauthorizedStatusCode;

  /// 认证错误最大重试次数
  final int maxAuthRetries;

  /// 构造函数
  ///
  /// @param onAuthError 认证错误处理回调，返回新的 token
  /// @param onRequestOptions 请求选项修改回调，用于在添加 token 前修改请求选项
  /// @param onResponseOptions 响应处理回调，用于在处理响应后修改响应
  /// @param onErrorOptions 错误处理回调，用于在处理错误后修改错误
  /// @param unauthorizedStatusCode 未授权错误状态码，默认为 401
  /// @param maxAuthRetries 认证错误最大重试次数，默认为 1
  WTokenInterceptor({
    this.onAuthError,
    this.onRequestOptions,
    this.onResponseOptions,
    this.onErrorOptions,
    this.unauthorizedStatusCode = 401,
    this.maxAuthRetries = 1,
  });

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    options.contentType = 'application/json';

    // 调用请求选项修改回调
    onRequestOptions?.call(options);

    // 添加 token
    _addTokenToRequest(options);

    super.onRequest(options, handler);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    // 调用响应处理回调
    onResponseOptions?.call(response);
    
    super.onResponse(response, handler);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 如果提供了错误处理回调，直接调用回调并返回
    if (onErrorOptions != null) {
      onErrorOptions?.call(err);
      super.onError(err, handler);
      return;
    }

    // 处理未授权错误
    if (err.response?.statusCode == unauthorizedStatusCode) {
      await _handleUnauthorizedError(err, handler);
      return;
    }

    super.onError(err, handler);
  }

  /// 添加 token 到请求头
  void _addTokenToRequest(RequestOptions options) {
    final token = WToken.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      // 安全的日志输出：只显示部分 token，避免敏感信息泄露
      final displayLength = token.length >= 10 ? 10 : token.length;
      WLogger.d('Added token to request: ${token.substring(0, displayLength)}...');
    } else {
      WLogger.d('No token found, skipping authorization header');
    }
  }

  /// 处理未授权错误
  Future<void> _handleUnauthorizedError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 获取请求级别的重试计数
    final retryCount = err.requestOptions.extra['_retryCount'] ?? 0;

    if (retryCount < maxAuthRetries) {
      WLogger.d(
        'Handling $unauthorizedStatusCode error, attempt ${retryCount + 1}/$maxAuthRetries',
      );

      // 清除 token
      WToken.clearAllTokens();
      WLogger.e('Unauthorized, token cleared');
      
      // 调用认证错误处理回调
      await _callAuthErrorCallback(err, handler, retryCount);
    } else {
      WLogger.e('Max authentication retry attempts reached');
      super.onError(err, handler);
    }
  }

  /// 调用认证错误处理回调
  Future<void> _callAuthErrorCallback(
    DioException err,
    ErrorInterceptorHandler handler,
    int retryCount,
  ) async {
    if (onAuthError != null) {
      final newToken = await onAuthError!();
      if (newToken != null) {
        await _retryRequestWithNewToken(err, handler, newToken, retryCount);
        return;
      }
    }
    super.onError(err, handler);
  }

  /// 使用新 token 重试请求
  Future<void> _retryRequestWithNewToken(
    DioException err,
    ErrorInterceptorHandler handler,
    String newToken,
    int retryCount,
  ) async {
    // 检查 response 是否为 null（网络连接失败时可能为 null）
    if (err.response == null) {
      WLogger.e('Cannot retry request: response is null');
      super.onError(err, handler);
      return;
    }
    
    final dio = DioUtil.instance(err.response!.requestOptions.baseUrl).dio;
    err.response!.requestOptions.headers['Authorization'] = 'Bearer $newToken';
    err.requestOptions.extra['_retryCount'] = retryCount + 1;
    final responseNew = await dio.fetch(err.response!.requestOptions);
    handler.resolve(responseNew);
  }
}
