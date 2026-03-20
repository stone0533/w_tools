// 网络错误处理模块

import 'package:dio/dio.dart';

/// 网络错误类型
enum NetworkErrorType {
  /// 网络连接错误
  connectionError,

  /// 超时错误
  timeoutError,

  /// 服务器错误
  serverError,

  /// 客户端错误
  clientError,

  /// 未知错误
  unknownError,
}

/// 网络错误类
class NetworkError {
  final NetworkErrorType type;
  final String message;
  final int? statusCode;
  final DioException? originalError;

  const NetworkError({
    required this.type,
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() {
    return 'NetworkError(type: $type, message: $message, statusCode: $statusCode)';
  }
}

/// 错误处理器
class ErrorHandler {
  /// 处理 Dio 错误
  static NetworkError handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkError(
          type: NetworkErrorType.timeoutError,
          message: '网络超时，请检查网络连接',
          originalError: error,
        );
      case DioExceptionType.connectionError:
        return NetworkError(
          type: NetworkErrorType.connectionError,
          message: '网络连接失败，请检查网络连接',
          originalError: error,
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode != null) {
          if (statusCode >= 500) {
            return NetworkError(
              type: NetworkErrorType.serverError,
              message: '服务器错误，请稍后重试',
              statusCode: statusCode,
              originalError: error,
            );
          } else if (statusCode >= 400) {
            return NetworkError(
              type: NetworkErrorType.clientError,
              message: '请求错误，请检查请求参数',
              statusCode: statusCode,
              originalError: error,
            );
          }
        }
        return NetworkError(
          type: NetworkErrorType.unknownError,
          message: '未知错误',
          statusCode: statusCode,
          originalError: error,
        );
      default:
        return NetworkError(
          type: NetworkErrorType.unknownError,
          message: error.message ?? '未知错误',
          originalError: error,
        );
    }
  }

  /// 获取错误消息
  static String getErrorMessage(NetworkError error) {
    return error.message;
  }
}
