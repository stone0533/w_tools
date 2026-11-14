import 'dart:math';

import 'package:dio/dio.dart';

/// 一次请求的指标快照。
///
/// 只描述这次请求，不包含用户 / 业务信息；[uri] 可能带 query，
/// 上报前请自己过滤敏感参数，或改用 [path]。
class WMetric {
  /// 创建指标。
  const WMetric({
    required this.method,
    required this.uri,
    required this.duration,
    this.statusCode,
    this.failed = false,
    this.error,
    this.attempt = 1,
  });

  /// HTTP 方法（大写）
  final String method;

  /// 请求 URI（可能包含 query）
  final Uri uri;

  /// 从请求开始到响应 / 错误的时间
  final Duration duration;

  /// HTTP 状态码；网络错误时为 null
  final int? statusCode;

  /// 是否失败（网络错误或 4xx / 5xx）
  final bool failed;

  /// 原始错误（失败时）
  final Object? error;

  /// 第几次尝试（首次为 1；重试 / 401 刷新会递增）
  final int attempt;

  /// 不含 query 的路径，适合直接上报
  String get path => uri.path;

  @override
  String toString() =>
      'WMetric($method ${uri.path}, status: $statusCode, '
      'duration: ${duration.inMilliseconds}ms, failed: $failed, '
      'attempt: $attempt)';
}

/// 可选的请求指标拦截器。
///
/// 默认不启用；只负责产出 [WMetric]，不写日志、不上报、不弹提示。
/// 需要接入埋点 / Prometheus / Sentry 时，在 [onMetric] 里自己决定。
///
/// ```dart
/// final metrics = WMetricsInterceptor(
///   onMetric: (metric) => analytics.track('http', {
///     'method': metric.method,
///     'path': metric.path,
///     'status': metric.statusCode,
///     'ms': metric.duration.inMilliseconds,
///   }),
/// );
/// ```
///
/// 注意：
/// - 401 刷新 / 重试会重新走请求链路，每次尝试都会产生一条指标；
///   该结论依赖拦截器顺序：如果重试 / token 拦截器先 `resolve`，更早的
///   `onError` 可能不会执行；需要严格每次尝试都上报时，把 metrics 放在
///   重试 / token 拦截器之前（错误方向先执行）。
/// - [onMetric] 抛出的异常会被吞掉，不影响请求；
/// - [WMetric.uri] 可能带 query，上报前请过滤敏感参数。
class WMetricsInterceptor extends Interceptor {
  /// 创建指标拦截器。
  ///
  /// [sampleRate] 取值 0–1；0 表示关闭，1 表示全量。
  WMetricsInterceptor({
    required this.onMetric,
    this.sampleRate = 1.0,
  }) : assert(
         sampleRate >= 0 && sampleRate <= 1,
         'sampleRate 必须在 0–1 之间',
       );

  /// 指标回调
  final void Function(WMetric metric) onMetric;

  /// 采样率（0–1）
  final double sampleRate;

  static const String _startKey = '_w_tools_metrics_start';
  static const String _sampledKey = '_w_tools_metrics_sampled';
  static const String _networkRetryKey = '_w_tools_network_retry_count';
  static const String _authRetryKey = '_w_tools_auth_retry_count';

  final Random _random = Random();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    options.extra[_startKey] = Stopwatch()..start();
    options.extra[_sampledKey] =
        sampleRate >= 1 || (sampleRate > 0 && _random.nextDouble() < sampleRate);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _emit(
      response.requestOptions,
      statusCode: response.statusCode,
      failed: _isFailedStatus(response.statusCode),
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _emit(
      err.requestOptions,
      statusCode: err.response?.statusCode,
      failed: true,
      error: err,
    );
    handler.next(err);
  }

  void _emit(
    RequestOptions options, {
    required int? statusCode,
    required bool failed,
    Object? error,
  }) {
    final sampled = options.extra[_sampledKey] == true;
    final started = options.extra[_startKey];
    options.extra.remove(_startKey);
    options.extra.remove(_sampledKey);
    if (!sampled) return;

    final duration = started is Stopwatch ? started.elapsed : Duration.zero;
    final attempt =
        1 +
        ((options.extra[_networkRetryKey] as int?) ?? 0) +
        ((options.extra[_authRetryKey] as int?) ?? 0);

    try {
      onMetric(
        WMetric(
          method: options.method.toUpperCase(),
          uri: options.uri,
          duration: duration,
          statusCode: statusCode,
          failed: failed,
          error: error,
          attempt: attempt,
        ),
      );
    } catch (_) {
      // 指标回调不能影响请求本身。
    }
  }

  static bool _isFailedStatus(int? status) => status != null && (status < 200 || status >= 300);
}
