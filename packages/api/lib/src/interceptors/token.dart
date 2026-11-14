import 'dart:async';

import 'package:dio/dio.dart';

import '../client/dio_registry.dart';
import 'log_support.dart' as log_support;

/// 标记「当前异步链是 tokenRefresher 发起的刷新请求」
final Object _refreshZoneKey = Object();

/// Token 拦截器，用于处理 token 的添加与 401 刷新。
///
/// 功能：
/// - 请求前自动添加 `Authorization: Bearer <token>`；请求已显式带 `Authorization`
///   时不覆盖（大小写不敏感），因此登录 / 公开接口可以自己控制该头；
/// - 收到未授权状态码（默认 401）时：清除 token → 调用 [tokenRefresher] 获取新 token → 重试。
///
/// 说明：
/// - 本类不负责 token 的存储，读写/清除均通过 [tokenGetter] / [tokenClearer] 注入。
/// - 并发 401：刷新是 single-flight 的；晚到的 401 若发现当前 token 已与本次请求带出去的
///   不同，会直接用新 token 重试，既不清理也不二次刷新（否则可能把新 token 清掉）。
/// - 刷新契约：[tokenRefresher] 取得新 token 后应自行持久化，使 [tokenGetter] 随后返回新 token；
///   若提供 [tokenClearer]，须保证清除后 [tokenGetter] 不再返回旧 token（返回 null 亦可，
///   此时重试会使用本拦截器显式写入的新 token）。任一处仍返回旧 token，都会导致重试再次 401。
/// - 重试必须知道「当前 Dio」：经 [DioRegistry.forBaseUrl] 创建的实例会自动绑定；
///   自行 `Dio()` 创建时请构造传 `dio: dio`，否则 401 刷新后无法重试（不会隐式注册新实例）。
/// - `DioRegistry.dispose` 后不要复用同一个拦截器实例：它仍持有已关闭的 Dio，
///   重新创建 registry 时会触发 [bindDio] 的二次绑定异常。
/// - [onAuthFailure] 收到底层 [DioException]；`WApiClient.onAuthFailure` 收到的是
///   `WApiException`，两者不要混接。
class WTokenInterceptor extends Interceptor {
  /// Token 获取回调
  final String? Function()? tokenGetter;

  /// Token 清除回调（提供时须保证清除后 [tokenGetter] 不再返回旧 token）
  final Future<void> Function()? tokenClearer;

  /// 刷新 token 回调：返回新 token（返回 null 表示刷新失败）。
  /// 建议在此持久化新 token，使 [tokenGetter] 之后返回最新值
  final Future<String?> Function()? tokenRefresher;

  /// 认证无法恢复时的回调：刷新失败、未配置刷新、或达到重试上限
  ///
  /// 适合跳登录 / 清会话。回调抛出的异常会被记录，不会替换原始 [DioException]。
  final void Function(DioException)? onAuthFailure;

  /// 每次未授权时是否允许自动刷新。
  ///
  /// 返回 `false` 时不会清除 token、不会刷新、也不会重试，直接把原始 401
  /// 交给调用方；适合登录 / 刷新 / 公开接口等需要自己处理 401 的请求。
  final bool Function(RequestOptions options)? shouldRefresh;

  /// 未授权错误状态码，默认为 401
  final int unauthorizedStatusCode;

  /// 认证错误最大重试次数
  final int maxAuthRetries;

  /// 进行中的刷新任务：并发 401 共享同一次刷新，避免重复请求
  Future<String?>? _refreshFuture;

  /// 请求级认证重试计数键；带命名空间，避免覆盖业务自己的 extra
  static const String _retryCountKey = '_w_tools_auth_retry_count';

  /// 所属 Dio（registry 创建时自动绑定；裸 Dio 请构造时传 `dio:`）
  Dio? _dio;

  /// 构造函数
  ///
  /// @param tokenGetter Token 获取回调（不依赖外部存储库，由调用方决定 token 存在哪）
  /// @param tokenClearer Token 清除回调
  /// @param tokenRefresher 刷新 token 回调，返回新 token（返回 null 表示刷新失败）
  /// @param onAuthFailure 认证无法恢复时的回调
  /// @param unauthorizedStatusCode 未授权错误状态码，默认为 401
  /// @param dio 所属 Dio（裸 Dio 创建时传入；registry 会自动绑定）
  /// @param maxAuthRetries 认证错误最大重试次数，默认为 1
  /// @param shouldRefresh 每次 401 是否允许自动刷新；返回 false 时直接交出 401
  WTokenInterceptor({
    this.tokenGetter,
    this.tokenClearer,
    this.tokenRefresher,
    this.onAuthFailure,
    this.shouldRefresh,
    this.unauthorizedStatusCode = 401,
    this.maxAuthRetries = 1,
    Dio? dio,
  }) : assert(maxAuthRetries >= 0, 'maxAuthRetries 不能为负'),
       _dio = dio;

  /// 绑定所属 Dio（一般不用手动调用；[DioRegistry] 会为传入的拦截器自动绑定）
  ///
  /// 同一个实例不能绑定到两个 Dio；共享实例请为每个 registry 创建独立拦截器。
  void bindDio(Dio dio) {
    final current = _dio;
    if (current != null && !identical(current, dio)) {
      throw ArgumentError(
        'WTokenInterceptor 已绑定到另一个 Dio；'
        '请为每个 DioRegistry 创建独立的 WTokenInterceptor 实例。',
      );
    }
    _dio = dio;
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    _addTokenToRequest(options);
    super.onRequest(options, handler);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 刷新请求自身返回 401：不能再走刷新（会 await 自己的 single-flight future）
    if (Zone.current[_refreshZoneKey] == true) {
      log_support.logError(
        'Token refresh request failed; skip auto-refresh',
      );
      super.onError(err, handler);
      return;
    }

    // 处理未授权错误
    if (err.response?.statusCode == unauthorizedStatusCode) {
      final allowRefresh = _shouldRefresh(err);
      if (!allowRefresh) {
        log_support.logDebug('Unauthorized, refresh skipped by shouldRefresh');
        super.onError(err, handler);
        return;
      }
      await _handleUnauthorizedError(err, handler);
      return;
    }

    super.onError(err, handler);
  }

  /// 添加 token 到请求头；已显式设置的 Authorization 不覆盖。
  void _addTokenToRequest(RequestOptions options) {
    if (_hasHeader(options.headers, 'Authorization')) {
      log_support.logDebug(
        'Authorization already set, skipping token injection',
      );
      return;
    }

    final token = tokenGetter?.call();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      // 不输出 token 的任何片段；只记录“已注入”。
      log_support.logDebug('Added token to request: ***');
    } else {
      log_support.logDebug(
        'No token found, skipping authorization header',
      );
    }
  }

  static bool _hasHeader(Map<String, dynamic> headers, String name) {
    final lowered = name.toLowerCase();
    return headers.keys.any((key) => key.toLowerCase() == lowered);
  }

  /// 读取 [shouldRefresh]；回调抛错时按“不刷新”处理，避免把内部异常带进请求链。
  bool _shouldRefresh(DioException err) {
    final callback = shouldRefresh;
    if (callback == null) return true;
    try {
      return callback(err.requestOptions);
    } catch (error) {
      log_support.logError('WTokenInterceptor.shouldRefresh failed: $error');
      return false;
    }
  }

  /// 处理未授权错误
  Future<void> _handleUnauthorizedError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 获取请求级别的重试计数（使用带命名空间的键）
    final retryCount = (err.requestOptions.extra[_retryCountKey] as int?) ?? 0;

    // 本次请求带出去的是哪个 token：晚到的 401 可能发生在别的请求已经刷新之后。
    final usedToken = _bearerTokenOf(err.requestOptions);
    final currentToken = tokenGetter?.call();
    final refreshedByOthers =
        currentToken != null && currentToken.isNotEmpty && currentToken != usedToken;

    if (!refreshedByOthers) {
      // 清除失效 token；即使不重试，也不应把旧 token 留在存储里。
      // 已经在别处刷新成功时不能清 —— 那会把刚写入的新 token 抹掉。
      // 清除失败也不能替换原始 401，否则业务无法按未授权处理。
      try {
        await tokenClearer?.call();
      } catch (e) {
        log_support.logError('tokenClearer failed: $e');
      }
    }

    if (retryCount >= maxAuthRetries) {
      log_support.logError('Max authentication retry attempts reached');
      _notifyAuthFailure(err);
      super.onError(err, handler);
      return;
    }

    if (refreshedByOthers) {
      // 直接拿当前（新）token 重试，不再刷新，避免二次刷新把用户登出。
      log_support.logDebug(
        'Unauthorized, token already refreshed by another request',
      );
      try {
        await _retryRequestWithNewToken(err, handler, currentToken, retryCount);
      } on DioException catch (retryError) {
        // 重试请求自身失败（例如 5xx）：把真实错误交给调用方，而不是原始 401。
        super.onError(retryError, handler);
      } catch (e) {
        log_support.logError('Retry with refreshed token failed: $e');
        super.onError(err, handler);
      }
      return;
    }

    log_support.logDebug('Unauthorized, token cleared');

    await _callAuthErrorCallback(err, handler, retryCount);
  }

  /// 取请求头里的 bearer token（没有则返回 null）
  static String? _bearerTokenOf(RequestOptions options) {
    for (final entry in options.headers.entries) {
      if (entry.key.toLowerCase() != 'authorization') continue;
      final header = entry.value;
      if (header is! String) return null;
      const prefix = 'Bearer ';
      return header.startsWith(prefix) ? header.substring(prefix.length) : null;
    }
    return null;
  }

  /// 调用认证错误处理回调
  Future<void> _callAuthErrorCallback(
    DioException err,
    ErrorInterceptorHandler handler,
    int retryCount,
  ) async {
    if (tokenRefresher == null) {
      _notifyAuthFailure(err);
      super.onError(err, handler);
      return;
    }

    log_support.logDebug(
      'Handling $unauthorizedStatusCode error, attempt ${retryCount + 1}/$maxAuthRetries',
    );

    final String? newToken;
    try {
      newToken = await _refreshToken();
    } catch (e) {
      // 刷新失败不应让异常逃逸出拦截器链，按原错误结束。
      log_support.logError('Token refresh failed: $e');
      _notifyAuthFailure(err);
      super.onError(err, handler);
      return;
    }

    if (newToken == null) {
      _notifyAuthFailure(err);
      super.onError(err, handler);
      return;
    }

    try {
      await _retryRequestWithNewToken(err, handler, newToken, retryCount);
    } on DioException catch (retryError) {
      // 刷新成功、重试失败：保留重试的真实错误（例如 500），并把它交给调用方。
      // 不能在这里调用 onAuthFailure —— 认证本身已经恢复。
      super.onError(retryError, handler);
    } catch (e) {
      log_support.logError('Retry with refreshed token failed: $e');
      super.onError(err, handler);
    }
  }

  void _notifyAuthFailure(DioException err) {
    try {
      onAuthFailure?.call(err);
    } catch (e) {
      log_support.logError('onAuthFailure failed: $e');
    }
  }

  /// 触发一次 token 刷新；并发调用共享同一 Future（single-flight）
  Future<String?> _refreshToken() {
    final pending = _refreshFuture;
    if (pending != null) return pending;

    final future =
        runZoned(
          tokenRefresher!,
          zoneValues: {_refreshZoneKey: true},
        ).whenComplete(() {
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
      log_support.logError('Cannot retry request: response is null');
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
      log_support.logError(
        'Cannot retry request: request body is a Stream and cannot be replayed',
      );
      super.onError(err, handler);
      return;
    }

    // 只用已知的 Dio 重试：绑定实例 > 已注册的 registry；绝不隐式创建新实例
    final dio = _dio ?? DioRegistry.maybeForBaseUrl(requestOptions.baseUrl);
    if (dio == null) {
      log_support.logError(
        'Cannot retry ${log_support.redactUri(requestOptions.uri, log_support.defaultSensitiveQueryKeys)}: WTokenInterceptor 未绑定 Dio。'
        '请用 DioRegistry.forBaseUrl 创建，或构造时传 dio: dio。',
      );
      super.onError(err, handler);
      return;
    }
    requestOptions.headers['Authorization'] = 'Bearer $newToken';
    requestOptions.extra[_retryCountKey] = retryCount + 1;
    final responseNew = await dio.fetch(requestOptions);
    handler.resolve(responseNew);
  }
}
