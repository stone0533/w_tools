import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

import '../api_settings.dart';
import '../client/dio_registry.dart';

/// 可选的幂等请求重试拦截器。
///
/// 默认**不会**自动生效：需要显式加入 `DioRegistry.forBaseUrl(interceptors: [...])`。
///
/// 安全边界：
/// - 只重试幂等方法：`GET` / `HEAD` / `PUT` / `DELETE` / `OPTIONS`；
///   `POST` / `PATCH` 永不重试（避免重复提交）；
/// - 只重试网络错误和 `408` / `429` / `5xx`（可用 [retryOnStatusCodes] 覆盖）；
/// - 不重试 `401`（交给 `WTokenInterceptor`）、其他 4xx 和已取消的请求。
///
/// ```dart
/// final registry = DioRegistry.forBaseUrl(
///   'https://api.example.com',
///   interceptors: [
///     WTokenInterceptor(...),
///     WRetryInterceptor(
///       maxRetries: 2,
///       baseDelay: const Duration(milliseconds: 300),
///     ),
///   ],
/// );
/// ```
class WRetryInterceptor extends Interceptor {
  /// 创建重试拦截器。
  ///
  /// [maxRetries] 是重试次数，不含首次请求；0 表示不重试。
  WRetryInterceptor({
    this.maxRetries = 2,
    this.baseDelay = const Duration(milliseconds: 300),
    this.maxDelay = const Duration(seconds: 5),
    Set<String>? retryOnMethods,
    Set<int>? retryOnStatusCodes,
    this.retryOnConnectionErrors = true,
    this.jitter = true,
    this.onRetry,
    this.shouldRetry,
    Dio? dio,
  }) : assert(maxRetries >= 0, 'maxRetries 不能为负'),
       assert(!baseDelay.isNegative, 'baseDelay 不能为负'),
       assert(!maxDelay.isNegative, 'maxDelay 不能为负'),
       retryOnMethods = Set.unmodifiable(
         (retryOnMethods ?? _defaultMethods).map((method) => method.toUpperCase()),
       ),
       retryOnStatusCodes = Set.unmodifiable(
         retryOnStatusCodes ?? _defaultStatusCodes,
       ),
       _dio = dio;

  /// 重试次数（不含首次请求）
  final int maxRetries;

  /// 指数退避的基数
  final Duration baseDelay;

  /// 单次等待上限
  final Duration maxDelay;

  /// 允许重试的方法（已转大写）
  final Set<String> retryOnMethods;

  /// 允许重试的 HTTP 状态码
  final Set<int> retryOnStatusCodes;

  /// 是否重试连接 / 超时错误
  final bool retryOnConnectionErrors;

  /// 是否在延迟上加入 50%–100% 抖动
  final bool jitter;

  /// 每次重试前回调；[attempt] 从 1 开始
  final void Function(int attempt, DioException error)? onRetry;

  /// 完全自定义是否重试；返回 true 仍需满足方法 / 401 / 取消等安全边界
  final bool Function(DioException error)? shouldRetry;

  static const String _retryCountKey = '_w_tools_network_retry_count';

  static const Set<String> _defaultMethods = {
    'GET',
    'HEAD',
    'PUT',
    'DELETE',
    'OPTIONS',
  };

  static const Set<int> _defaultStatusCodes = {408, 429, 500, 502, 503, 504};

  static const Set<DioExceptionType> _networkTypes = {
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
    // dio 5.10 起把「响应体转换超时」单独分类；对调用方来说它是 timeout，
    // 与 WApiException 的 timeout 分类保持一致。
    DioExceptionType.transformTimeout,
    DioExceptionType.connectionError,
    DioExceptionType.unknown,
  };

  final Random _random = Random();
  Dio? _dio;

  /// 绑定所属 Dio（一般不用手动调用；[DioRegistry] 会为传入的拦截器自动绑定）。
  ///
  /// 同一个实例不能绑定到两个 Dio；多个 registry 请各建实例。
  void bindDio(Dio dio) {
    final current = _dio;
    if (current != null && !identical(current, dio)) {
      throw ArgumentError(
        'WRetryInterceptor 已绑定到另一个 Dio；'
        '请为每个 DioRegistry 创建独立的 WRetryInterceptor 实例。',
      );
    }
    _dio = dio;
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = (err.requestOptions.extra[_retryCountKey] as int?) ?? 0;
    if (!_shouldRetry(err, attempt)) {
      super.onError(err, handler);
      return;
    }

    final cancelToken = err.requestOptions.cancelToken;
    if (cancelToken?.isCancelled ?? false) {
      super.onError(err, handler);
      return;
    }

    final delay = _delayFor(attempt);
    WApiSettings.logDebugHandler?.call(
      'Retrying ${err.requestOptions.method} ${err.requestOptions.uri} '
      '(${attempt + 1}/$maxRetries) after ${delay.inMilliseconds}ms',
    );

    try {
      onRetry?.call(attempt + 1, err);
    } catch (error) {
      WApiSettings.logErrorHandler?.call(
        'WRetryInterceptor.onRetry failed: $error',
      );
    }

    if (delay.inMilliseconds > 0) {
      await Future<void>.delayed(delay);
    }

    if (cancelToken?.isCancelled ?? false) {
      super.onError(err, handler);
      return;
    }

    final dio = _dio ?? DioRegistry.maybeForBaseUrl(err.requestOptions.baseUrl);
    if (dio == null) {
      WApiSettings.logErrorHandler?.call(
        'Cannot retry ${err.requestOptions.uri}: WRetryInterceptor 未绑定 Dio。'
        '请用 DioRegistry.forBaseUrl 创建，或构造时传 dio: dio。',
      );
      super.onError(err, handler);
      return;
    }

    err.requestOptions.extra[_retryCountKey] = attempt + 1;
    // FormData 只能 finalize 一次；Stream 已被消费，无法重放。
    final requestData = err.requestOptions.data;
    if (requestData is FormData) {
      err.requestOptions.data = requestData.clone();
    }
    try {
      final response = await dio.fetch(err.requestOptions);
      handler.resolve(response);
    } on DioException catch (error) {
      // 内层链路会按新的 attempt 继续重试 / 结束；这里只交出最终错误。
      super.onError(error, handler);
    } catch (error, stackTrace) {
      WApiSettings.logErrorHandler?.call('Retry failed: $error\n$stackTrace');
      super.onError(err, handler);
    }
  }

  bool _shouldRetry(DioException err, int attempt) {
    if (maxRetries <= 0 || attempt >= maxRetries) return false;
    if (err.type == DioExceptionType.cancel) return false;
    if (err.requestOptions.data is Stream) return false;
    // 401 是 WTokenInterceptor 的职责；在这里重试会绕过刷新流程。
    if (err.response?.statusCode == 401) return false;

    final method = err.requestOptions.method.toUpperCase();
    if (!retryOnMethods.contains(method)) return false;

    final custom = shouldRetry;
    if (custom != null) return custom(err);

    final status = err.response?.statusCode;
    if (status != null) return retryOnStatusCodes.contains(status);
    return retryOnConnectionErrors && _networkTypes.contains(err.type);
  }

  Duration _delayFor(int attempt) {
    final base = baseDelay.inMilliseconds;
    if (base <= 0) return Duration.zero;

    var ms = base * pow(2, attempt).toInt();
    final cap = maxDelay.inMilliseconds;
    if (cap > 0 && ms > cap) ms = cap;
    if (jitter && ms > 0) {
      // 50%–100%，避免多端同时重试。
      ms = (ms * (0.5 + _random.nextDouble() * 0.5)).round();
    }
    return Duration(milliseconds: ms);
  }
}
