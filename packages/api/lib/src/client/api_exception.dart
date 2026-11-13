import 'package:dio/dio.dart';

/// 网络错误的业务可识别类型。
///
/// UI 按 [WApiException.kind] 决定提示文案 / 是否重试 / 是否跳登录；
/// 库本身不写死用户文案。
enum WApiErrorKind {
  /// 连接 / 发送 / 接收 / 转换超时
  timeout,

  /// 连不上网络、证书校验失败
  network,

  /// 401，登录态失效
  unauthorized,

  /// 403，已登录但无权限
  forbidden,

  /// 404，资源不存在
  notFound,

  /// 其他 4xx，请求本身有问题
  client,

  /// 5xx，服务端错误
  server,

  /// 请求被 `CancelToken` 取消
  canceled,

  /// 响应体无法被 decoder 解析
  decode,

  /// 其他未知错误
  unknown,

  /// 业务码失败（需要 `WApiEnvelopeParser` 才可能出现）
  business,
}

/// 调用层统一异常。
///
/// [message] 是技术描述（英文），不是用户文案；UI 用 [kind] 映射。
/// [cause] 保留原始 [DioException]（或 decoder 抛出的异常），便于日志排查；
/// [payload] 保留原始响应体（HTTP 错误时是 `response.data`）。
class WApiException implements Exception {
  /// 创建异常。
  const WApiException(
    this.kind, {
    this.statusCode,
    this.businessCode,
    this.message,
    this.cause,
    this.payload,
  });

  /// 从 dio 异常映射；不修改原始异常。
  factory WApiException.from(DioException error) {
    final statusCode = error.response?.statusCode;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return WApiException(
          WApiErrorKind.timeout,
          message: 'Connection timeout',
          cause: error,
        );
      case DioExceptionType.transformTimeout:
        return WApiException(
          WApiErrorKind.timeout,
          message: 'Response transform timeout',
          cause: error,
        );
      case DioExceptionType.connectionError:
        return WApiException(
          WApiErrorKind.network,
          message: 'Connection failed',
          cause: error,
        );
      case DioExceptionType.badCertificate:
        return WApiException(
          WApiErrorKind.network,
          message: 'Bad certificate',
          cause: error,
        );
      case DioExceptionType.cancel:
        return WApiException(
          WApiErrorKind.canceled,
          message: 'Request canceled',
          cause: error,
        );
      case DioExceptionType.badResponse:
        return WApiException(
          _kindOfStatus(statusCode),
          statusCode: statusCode,
          message: 'HTTP ${statusCode ?? 'unknown'}',
          cause: error,
          payload: error.response?.data,
        );
      case DioExceptionType.unknown:
        return WApiException(
          WApiErrorKind.unknown,
          message: error.message ?? 'Request failed',
          cause: error,
        );
    }
  }

  /// 错误类型
  final WApiErrorKind kind;

  /// HTTP 状态码（非 HTTP 错误时为 null）
  final int? statusCode;

  /// 业务码（仅 `WApiErrorKind.business` 时非空）
  final Object? businessCode;

  /// 技术描述，不是用户文案
  final String? message;

  /// 原始异常
  final Object? cause;

  /// 原始响应体
  final Object? payload;

  /// 是否需要跳登录
  bool get requiresLogin => kind == WApiErrorKind.unauthorized;

  static WApiErrorKind _kindOfStatus(int? status) {
    if (status == 401) return WApiErrorKind.unauthorized;
    if (status == 403) return WApiErrorKind.forbidden;
    if (status == 404) return WApiErrorKind.notFound;
    if (status != null && status >= 500) return WApiErrorKind.server;
    if (status != null && status >= 400) return WApiErrorKind.client;
    return WApiErrorKind.unknown;
  }

  @override
  String toString() => 'WApiException(${kind.name}, status: $statusCode)';
}
