import 'dart:async';

import 'package:dio/dio.dart';

import '../api_config.dart';
import '../clients/dio_registry.dart';

/// Token 拦截器，用于处理 token 的添加、更新和错误处理
///
/// 功能：
/// - 请求前自动添加 `Authorization: Bearer <token>`
/// - 收到未授权状态码（默认 401）时：清除 token → 调用 [tokenRefresher] 获取新 token → 重试
///
/// 说明：
/// - 本类不负责 token 的存储，读写/清除均通过 [tokenGetter] / [tokenClearer] 注入。
/// - 刷新契约：[tokenRefresher] 取得新 token 后应自行持久化，使 [tokenGetter] 随后返回新 token；
///   若提供 [tokenClearer]，须保证清除后 [tokenGetter] 不再返回旧 token（返回 null 亦可，
///   此时重试会使用本拦截器显式写入的新 token）。任一处仍返回旧 token，都会导致重试再次 401。
/// - [observeError] 与 401 刷新逻辑相互独立、可同时使用（前者仅用于观测/埋点）。
/// - 重试依赖 **经 [DioRegistry.forBaseUrl] 创建的 Dio**；若自行 `Dio()` 创建实例，
///   重试会走 `DioRegistry` 中的另一实例，可能导致配置不一致。
class WTokenInterceptor extends Interceptor {
  /// Token 获取回调
  final String? Function()? tokenGetter;

  /// Token 清除回调（提供时须保证清除后 [tokenGetter] 不再返回旧 token）
  final Future<void> Function()? tokenClearer;

  /// 刷新 token 回调：返回新 token（返回 null 表示刷新失败）。
  /// 建议在此持久化新 token，使 [tokenGetter] 之后返回最新值
  final Future<String?> Function()? tokenRefresher;

  /// 配置请求回调（**可修改**）：在添加 token 前调整请求，如注入公共 header、调整超时
  final void Function(RequestOptions)? configureRequest;

  /// 配置响应回调（**可修改**）：调整业务层最终拿到的响应，如统一解包
  final void Function(Response)? configureResponse;

  /// 错误观测回调（**仅观测**，不能修改或阻止错误）：日志、埋点、提示；与 401 刷新相互独立
  final void Function(DioException)? observeError;

  /// 未授权错误状态码，默认为 401
  final int unauthorizedStatusCode;

  /// 认证错误最大重试次数
  final int maxAuthRetries;

  /// 进行中的刷新任务：并发 401 共享同一次刷新，避免重复请求
  Future<String?>? _refreshFuture;

  /// 构造函数
  ///
  /// @param tokenGetter Token 获取回调（不依赖外部存储库，由调用方决定 token 存在哪）
  /// @param tokenClearer Token 清除回调
  /// @param tokenRefresher 刷新 token 回调，返回新 token（返回 null 表示刷新失败）
  /// @param configureRequest 配置请求回调
  /// @param configureResponse 配置响应回调
  /// @param observeError 错误观测回调
  /// @param unauthorizedStatusCode 未授权错误状态码，默认为 401
  /// @param maxAuthRetries 认证错误最大重试次数，默认为 1
  WTokenInterceptor({
    this.tokenGetter,
    this.tokenClearer,
    this.tokenRefresher,
    this.configureRequest,
    this.configureResponse,
    this.observeError,
    this.unauthorizedStatusCode = 401,
    this.maxAuthRetries = 1,
  });

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    options.contentType ??= 'application/json';

    // 配置请求
    configureRequest?.call(options);

    // 添加 token
    _addTokenToRequest(options);

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // 配置响应
    configureResponse?.call(response);

    super.onResponse(response, handler);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 错误观测：与 401 刷新相互独立，先无条件执行
    observeError?.call(err);

    // 处理未授权错误
    if (err.response?.statusCode == unauthorizedStatusCode) {
      await _handleUnauthorizedError(err, handler);
      return;
    }

    super.onError(err, handler);
  }

  /// 添加 token 到请求头
  void _addTokenToRequest(RequestOptions options) {
    final token = tokenGetter?.call();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      // 安全的日志输出：仅显示前缀；过短的 token 全量遮蔽，避免敏感信息泄露
      final masked = token.length >= 10 ? '${token.substring(0, 10)}...' : '***';
      WApiConfig.logDebugHandler?.call('Added token to request: $masked');
    } else {
      WApiConfig.logDebugHandler?.call('No token found, skipping authorization header');
    }
  }

  /// 处理未授权错误
  Future<void> _handleUnauthorizedError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 获取请求级别的重试计数
    final retryCount = (err.requestOptions.extra['_retryCount'] as int?) ?? 0;

    if (retryCount >= maxAuthRetries) {
      WApiConfig.logErrorHandler?.call('Max authentication retry attempts reached');
      super.onError(err, handler);
      return;
    }

    // 清除失效 token
    await tokenClearer?.call();
    WApiConfig.logDebugHandler?.call('Unauthorized, token cleared');

    await _callAuthErrorCallback(err, handler, retryCount);
  }

  /// 调用认证错误处理回调
  Future<void> _callAuthErrorCallback(
    DioException err,
    ErrorInterceptorHandler handler,
    int retryCount,
  ) async {
    if (tokenRefresher == null) {
      super.onError(err, handler);
      return;
    }

    WApiConfig.logDebugHandler?.call(
      'Handling $unauthorizedStatusCode error, attempt ${retryCount + 1}/$maxAuthRetries',
    );

    try {
      final newToken = await _refreshToken();
      if (newToken != null) {
        await _retryRequestWithNewToken(err, handler, newToken, retryCount);
        return;
      }
    } catch (e) {
      // 刷新失败不应让异常逃逸出拦截器链，按原错误结束
      WApiConfig.logErrorHandler?.call('Token refresh failed: $e');
    }

    super.onError(err, handler);
  }

  /// 触发一次 token 刷新；并发调用共享同一 Future（single-flight）
  Future<String?> _refreshToken() {
    final pending = _refreshFuture;
    if (pending != null) return pending;

    final future = tokenRefresher!().whenComplete(() {
      _refreshFuture = null;
    });
    _refreshFuture = future;
    return future;
  }

  /// 使用新 token 重试请求
  Future<void> _retryRequestWithNewToken(
    DioException err,
    ErrorInterceptorHandler handler,
    String newToken,
    int retryCount,
  ) async {
    final requestOptions = err.requestOptions;

    // 检查 response 是否为 null（网络连接失败时可能为 null）
    if (err.response == null) {
      WApiConfig.logErrorHandler?.call('Cannot retry request: response is null');
      super.onError(err, handler);
      return;
    }

    // 不可重放的请求体处理：
    // - FormData 只能 finalize 一次，重放前必须克隆（否则 dio 抛 StateError）
    // - Stream 已被消费，无法重放，直接放弃重试
    final data = requestOptions.data;
    if (data is FormData) {
      requestOptions.data = data.clone();
    } else if (data is Stream) {
      WApiConfig.logErrorHandler?.call(
        'Cannot retry request: request body is a Stream and cannot be replayed',
      );
      super.onError(err, handler);
      return;
    }

    // 见类文档：重试依赖经 DioRegistry 创建的 Dio
    final dio = DioRegistry.forBaseUrl(requestOptions.baseUrl).dio;
    requestOptions.headers['Authorization'] = 'Bearer $newToken';
    requestOptions.extra['_retryCount'] = retryCount + 1;
    final responseNew = await dio.fetch(requestOptions);
    handler.resolve(responseNew);
  }
}
