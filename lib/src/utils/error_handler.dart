import 'logger.dart';

/// 错误处理工具类
class WErrorHandler {
  /// 处理异常
  ///
  /// @param error 异常对象
  /// @param stackTrace 堆栈信息
  /// @param message 自定义错误消息
  /// @return 格式化的错误信息
  static String handleError(dynamic error, StackTrace? stackTrace, {String? message}) {
    String errorMessage = message ?? '发生错误';

    if (error is FormatException) {
      errorMessage = '数据格式错误: ${error.message}';
    } else if (error is RangeError) {
      errorMessage = '数据范围错误: ${error.message}';
    } else if (error is TypeError) {
      errorMessage = '类型错误: ${error.toString()}';
    } else if (error is Exception) {
      errorMessage = '异常: ${error.toString()}';
    } else {
      errorMessage = '未知错误: ${error.toString()}';
    }

    // 记录错误日志
    WLogger.e(errorMessage, stackTrace: stackTrace);

    return errorMessage;
  }

  /// 处理网络错误
  ///
  /// @param error 网络错误对象
  /// @return 格式化的网络错误信息
  static String handleNetworkError(dynamic error) {
    String errorMessage = '网络错误';

    if (error.toString().contains('SocketException')) {
      errorMessage = '网络连接失败，请检查网络设置';
    } else if (error.toString().contains('TimeoutException')) {
      errorMessage = '网络请求超时，请稍后重试';
    } else if (error.toString().contains('404')) {
      errorMessage = '请求的资源不存在';
    } else if (error.toString().contains('500')) {
      errorMessage = '服务器内部错误';
    } else {
      errorMessage = '网络请求失败: ${error.toString()}';
    }

    // 记录错误日志
    WLogger.e(errorMessage);

    return errorMessage;
  }

  /// 处理业务错误
  ///
  /// @param code 错误码
  /// @param message 错误消息
  /// @return 格式化的业务错误信息
  static String handleBusinessError(int code, String message) {
    String errorMessage = message;

    // 根据错误码处理特定的业务错误
    switch (code) {
      case 401:
        errorMessage = '登录过期，请重新登录';
        break;
      case 403:
        errorMessage = '权限不足，无法操作';
        break;
      case 404:
        errorMessage = '请求的资源不存在';
        break;
      case 500:
        errorMessage = '服务器内部错误';
        break;
      default:
        errorMessage = message;
    }

    // 记录错误日志
    WLogger.e('业务错误 [$code]: $errorMessage');

    return errorMessage;
  }
}
