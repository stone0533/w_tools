import 'package:w_tools_api/w_tools_api.dart';

/// 业务可识别的错误类型；UI 按它决定文案 / 是否重试 / 是否跳登录。
enum ApiErrorKind {
  /// 连接 / 发送 / 接收超时
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

  /// 请求被 CancelToken 取消
  canceled,

  /// 其他未知错误
  unknown,
}

/// 网络层对外抛出的统一异常。
///
/// `w_tools_api` 6.x 已提供 `WApiException` 做通用分类；本示例保留 [ApiException]
/// 作为业务层自定义错误（重点是可直接展示的用户文案），在 Repository 边界把
/// [DioException] 翻译成它，UI 层就不依赖 dio。不需要自定义文案时直接用
/// `WApiException` 即可，不必重复维护这套映射。
class ApiException implements Exception {
  const ApiException(
    this.kind,
    this.message, {
    this.statusCode,
    this.cause,
  });

  /// 从 dio 异常映射；保留 [cause] 便于日志排查
  factory ApiException.from(DioException error) {
    final statusCode = error.response?.statusCode;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return ApiException(
          ApiErrorKind.timeout,
          '网络超时，请稍后重试',
          cause: error,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          ApiErrorKind.network,
          '网络连接失败，请检查网络',
          cause: error,
        );
      case DioExceptionType.badCertificate:
        return ApiException(
          ApiErrorKind.network,
          '服务器证书校验失败',
          cause: error,
        );
      case DioExceptionType.cancel:
        return ApiException(
          ApiErrorKind.canceled,
          '请求已取消',
          cause: error,
        );
      case DioExceptionType.badResponse:
        return ApiException(
          _kindOfStatus(statusCode),
          _messageOfStatus(statusCode),
          statusCode: statusCode,
          cause: error,
        );
      case DioExceptionType.unknown:
        return ApiException(
          ApiErrorKind.unknown,
          error.message ?? '请求失败，请稍后重试',
          cause: error,
        );
    }
  }

  /// 错误类型
  final ApiErrorKind kind;

  /// 可直接展示给用户的文案
  final String message;

  /// HTTP 状态码（非 HTTP 错误时为 null）
  final int? statusCode;

  /// 原始 dio 异常，便于日志 / 上报
  final DioException? cause;

  /// 是否需要跳登录
  bool get requiresLogin => kind == ApiErrorKind.unauthorized;

  static ApiErrorKind _kindOfStatus(int? status) {
    if (status == 401) return ApiErrorKind.unauthorized;
    if (status == 403) return ApiErrorKind.forbidden;
    if (status == 404) return ApiErrorKind.notFound;
    if (status != null && status >= 500) return ApiErrorKind.server;
    if (status != null && status >= 400) return ApiErrorKind.client;
    return ApiErrorKind.unknown;
  }

  static String _messageOfStatus(int? status) {
    if (status == 401) return '登录已失效，请重新登录';
    if (status == 403) return '没有权限执行该操作';
    if (status == 404) return '请求的资源不存在';
    if (status != null && status >= 500) return '服务器开小差了，请稍后重试';
    return '请求失败（HTTP ${status ?? '未知'}）';
  }

  @override
  String toString() => 'ApiException($kind, status: $statusCode, message: $message)';
}
