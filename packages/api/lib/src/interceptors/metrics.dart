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

  /// 不含 query 的路径，适合直接上报
  String get path => uri.path;

  @override
  String toString() =>
      'WMetric($method ${uri.path}, status: $statusCode, '
      'duration: ${duration.inMilliseconds}ms, failed: $failed)';
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

  final Random _random = Random();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    options.extra[_startKey] = DateTime.now();
    options.extra[_sampledKey] =
        sampleRate >= 1 || (sampleRate > 0 && _random.nextDouble() < sampleRate);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _emit(
      response.requestOptions,
      statusCode: response.statusCode,
      failed: false,
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

    final duration = started is DateTime ? DateTime.now().difference(started) : Duration.zero;

    try {
      onMetric(
        WMetric(
          method: options.method.toUpperCase(),
          uri: options.uri,
          duration: duration,
          statusCode: statusCode,
          failed: failed,
          error: error,
        ),
      );
    } catch (_) {
      // 指标回调不能影响请求本身。
    }
  }
}
