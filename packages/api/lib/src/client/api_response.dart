import 'package:dio/dio.dart';

/// 保留响应元数据的调用结果。
///
/// 需要 status / headers（限流、分页 total、请求 ID）时用
/// `WApiClient.send`；普通 `get/post/...` 仍直接返回 `T`。
class WApiResponse<T> {
  /// 创建响应结果。
  const WApiResponse({
    required this.data,
    required this.statusCode,
    required this.headers,
    required this.requestOptions,
  });

  /// 解码后的业务数据
  final T data;

  /// HTTP 状态码
  final int? statusCode;

  /// 响应头
  final Headers headers;

  /// 原始请求信息
  final RequestOptions requestOptions;

  /// 请求 URI
  Uri get uri => requestOptions.uri;
}
