// 网络响应处理模块

import 'package:dio/dio.dart';

/// 响应数据类
class ResponseData<T> {
  final T? data;
  final int statusCode;
  final String statusMessage;

  const ResponseData({
    this.data,
    required this.statusCode,
    required this.statusMessage,
  });

  /// 从 Dio Response 创建 ResponseData
  factory ResponseData.fromResponse(Response<T> response) {
    return ResponseData(
      data: response.data,
      statusCode: response.statusCode ?? 0,
      statusMessage: response.statusMessage ?? '',
    );
  }

  /// 是否成功
  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

/// 响应处理器
class ResponseHandler {
  /// 处理响应
  static ResponseData<T> handleResponse<T>(Response<T> response) {
    return ResponseData.fromResponse(response);
  }

  /// 处理错误响应
  static ResponseData<T> handleErrorResponse<T>(DioException error) {
    return ResponseData(
      data: null,
      statusCode: error.response?.statusCode ?? 0,
      statusMessage: error.message ?? 'Unknown error',
    );
  }
}
