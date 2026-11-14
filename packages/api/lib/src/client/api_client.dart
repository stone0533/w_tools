import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../interceptors/log_support.dart' as log_support;
import 'api_body.dart';
import 'api_decoders.dart';
import 'api_envelope.dart';
import 'api_exception.dart';
import 'api_page.dart';
import 'api_response.dart';

/// 协议层统一入口：收敛 HTTP 方法、参数编码、JSON 解码与错误分类。
///
/// 只负责「怎么调」，不负责 token（`WTokenInterceptor`）、日志、缓存和业务编排。
/// URL 应集中写在 `*_api.dart`，页面 / Repository 不拼路径。
///
/// ```dart
/// final client = WApiClient(registry.dio);
/// final user = await client.get(
///   '/users/{id}',
///   pathParameters: {'id': '42'},
///   decode: (json) => User.fromJson(json as Map<String, dynamic>),
/// );
/// ```
class WApiClient {
  /// 用已创建的 [Dio] 构造；通常来自 `DioRegistry.forBaseUrl(...).dio`。
  ///
  /// [envelope] 默认关闭；传入后才按业务信封解析。
  /// [onAuthFailure] 只在业务码命中 [WApiEnvelopeParser.authFailureCodes] 时调用；
  /// HTTP 401 仍由 `WTokenInterceptor.onAuthFailure` 负责。
  WApiClient(
    this._dio, {
    WApiEnvelopeParser? envelope,
    this.onAuthFailure,
  }) : _envelope = envelope;

  final Dio _dio;
  final WApiEnvelopeParser? _envelope;

  /// 业务码认证失败回调
  final void Function(WApiException error)? onAuthFailure;

  /// 底层 dio（高级场景 / 上传进度 / 自定义 adapter 用）
  Dio get dio => _dio;

  /// 发送任意 HTTP 方法，并保留 status / headers / requestOptions。
  ///
  /// 需要限流头、分页 total 头或请求 ID 时用它；普通请求仍用 `get/post/...`。
  /// [envelope] 只对本次请求生效，不传时使用 client 级信封。
  Future<WApiResponse<T>> send<T>(
    String method,
    String path, {
    Object? body,
    Map<String, Object?>? query,
    Map<String, String>? pathParameters,
    WApiDecoder<T>? decode,
    WApiEnvelopeParser? envelope,
    CancelToken? cancelToken,
    Map<String, String>? headers,
    void Function(int sent, int total)? onSendProgress,
    void Function(int received, int total)? onReceiveProgress,
  }) => _sendResponse<T>(
    method,
    path,
    body: body,
    query: query,
    pathParameters: pathParameters,
    decode: decode,
    envelope: envelope,
    cancelToken: cancelToken,
    headers: headers,
    onSendProgress: onSendProgress,
    onReceiveProgress: onReceiveProgress,
  );

  /// GET 请求。
  Future<T> get<T>(
    String path, {
    Map<String, Object?>? query,
    Map<String, String>? pathParameters,
    WApiDecoder<T>? decode,
    CancelToken? cancelToken,
    Map<String, String>? headers,
  }) => _send<T>(
    'GET',
    path,
    query: query,
    pathParameters: pathParameters,
    decode: decode,
    cancelToken: cancelToken,
    headers: headers,
  );

  /// HEAD 请求。
  Future<T> head<T>(
    String path, {
    Map<String, Object?>? query,
    Map<String, String>? pathParameters,
    WApiDecoder<T>? decode,
    CancelToken? cancelToken,
    Map<String, String>? headers,
  }) => _send<T>(
    'HEAD',
    path,
    query: query,
    pathParameters: pathParameters,
    decode: decode,
    cancelToken: cancelToken,
    headers: headers,
  );

  /// OPTIONS 请求。
  Future<T> options<T>(
    String path, {
    Map<String, Object?>? query,
    Map<String, String>? pathParameters,
    WApiDecoder<T>? decode,
    CancelToken? cancelToken,
    Map<String, String>? headers,
  }) => _send<T>(
    'OPTIONS',
    path,
    query: query,
    pathParameters: pathParameters,
    decode: decode,
    cancelToken: cancelToken,
    headers: headers,
  );

  /// POST 请求。
  Future<T> post<T>(
    String path, {
    Object? body,
    Map<String, Object?>? query,
    Map<String, String>? pathParameters,
    WApiDecoder<T>? decode,
    CancelToken? cancelToken,
    Map<String, String>? headers,
  }) => _send<T>(
    'POST',
    path,
    body: body,
    query: query,
    pathParameters: pathParameters,
    decode: decode,
    cancelToken: cancelToken,
    headers: headers,
  );

  /// PUT 请求。
  Future<T> put<T>(
    String path, {
    Object? body,
    Map<String, Object?>? query,
    Map<String, String>? pathParameters,
    WApiDecoder<T>? decode,
    CancelToken? cancelToken,
    Map<String, String>? headers,
  }) => _send<T>(
    'PUT',
    path,
    body: body,
    query: query,
    pathParameters: pathParameters,
    decode: decode,
    cancelToken: cancelToken,
    headers: headers,
  );

  /// PATCH 请求。
  Future<T> patch<T>(
    String path, {
    Object? body,
    Map<String, Object?>? query,
    Map<String, String>? pathParameters,
    WApiDecoder<T>? decode,
    CancelToken? cancelToken,
    Map<String, String>? headers,
  }) => _send<T>(
    'PATCH',
    path,
    body: body,
    query: query,
    pathParameters: pathParameters,
    decode: decode,
    cancelToken: cancelToken,
    headers: headers,
  );

  /// DELETE 请求。
  ///
  /// 无响应体时可以省略 `decode`；需要解析响应时显式传。
  Future<T> delete<T>(
    String path, {
    Map<String, Object?>? query,
    Map<String, String>? pathParameters,
    WApiDecoder<T>? decode,
    CancelToken? cancelToken,
    Map<String, String>? headers,
  }) => _send<T>(
    'DELETE',
    path,
    query: query,
    pathParameters: pathParameters,
    decode: decode,
    cancelToken: cancelToken,
    headers: headers,
  );

  /// GET 分页请求。
  ///
  /// 默认只接受 JSON 数组作为 items；后端返回 `{list: [], total: 0}` 时，
  /// 用 [readItems] / [readTotal] 显式读取。
  ///
  /// total 在响应头（如 `X-Total-Count`）时，用 [readTotalFromResponse]；
  /// 它与 [readTotal] 同时提供时优先使用 [readTotalFromResponse]。
  /// [envelope] 只对本次请求生效，不传时使用 client 级信封。
  ///
  /// 只支持 1-based 页码分页；offset / cursor 后端请用 [send] 手工请求并
  /// 自行构造 `WPage`。
  ///
  /// ```dart
  /// final page = await client.page(
  ///   '/users',
  ///   query: const WPageQuery(page: 1, pageSize: 20),
  ///   itemDecode: (json) => User.fromJson(json as Map<String, dynamic>),
  ///   readTotalFromResponse: (response) =>
  ///       int.tryParse(response.headers.value('x-total-count') ?? ''),
  /// );
  /// ```
  Future<WPage<T>> page<T>(
    String path, {
    WPageQuery query = const WPageQuery(),
    required WApiDecoder<T> itemDecode,
    List<Object?> Function(Object? json)? readItems,
    int? Function(Object? json)? readTotal,
    int? Function(WApiResponse<Object?> response)? readTotalFromResponse,
    WApiEnvelopeParser? envelope,
    Map<String, Object?>? extraQuery,
    Map<String, String>? pathParameters,
    CancelToken? cancelToken,
    Map<String, String>? headers,
  }) async {
    if (query.page < 1 || query.pageSize < 1) {
      throw ArgumentError.value(
        query,
        'query',
        'page / pageSize 必须大于 0',
      );
    }
    final response = await _sendResponse<Object?>(
      'GET',
      path,
      query: {...?extraQuery, ...query.toQuery()},
      pathParameters: pathParameters,
      envelope: envelope,
      cancelToken: cancelToken,
      headers: headers,
    );
    final body = response.data;

    try {
      final List<Object?> rawItems;
      if (readItems != null) {
        rawItems = readItems(body);
      } else if (body is List) {
        rawItems = body;
      } else {
        throw WApiException(
          WApiErrorKind.decode,
          message: 'Page items must be a JSON array',
          payload: body,
        );
      }

      return WPage<T>(
        items: List<T>.unmodifiable(rawItems.map(itemDecode)),
        page: query.page,
        pageSize: query.pageSize,
        total: readTotalFromResponse?.call(response) ?? readTotal?.call(body),
      );
    } on WApiException {
      rethrow;
    } catch (error) {
      throw WApiException(
        WApiErrorKind.decode,
        message: 'Page decoding failed',
        cause: error,
        payload: body,
      );
    }
  }

  /// 上传文件（`multipart/form-data`）。
  ///
  /// [files] 的 key 是表单字段名；[fields] 是普通表单字段。
  /// [method] 只允许 `POST` / `PUT` / `PATCH`，默认 `POST`。
  Future<T> upload<T>(
    String path, {
    String method = 'POST',
    Map<String, Object?> fields = const {},
    Map<String, MultipartFile> files = const {},
    Map<String, Object?>? query,
    Map<String, String>? pathParameters,
    WApiDecoder<T>? decode,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
    Map<String, String>? headers,
  }) async {
    final normalized = method.toUpperCase();
    if (!const {'POST', 'PUT', 'PATCH'}.contains(normalized)) {
      throw ArgumentError.value(
        method,
        'method',
        'upload only supports POST / PUT / PATCH',
      );
    }

    return _send<T>(
      normalized,
      path,
      body: WApiBody.multipart(fields: fields, files: files),
      query: query,
      pathParameters: pathParameters,
      decode: decode,
      cancelToken: cancelToken,
      headers: headers,
      onSendProgress: onProgress,
    );
  }

  /// 下载文件，返回原始字节。
  ///
  /// 写文件 / 保存到相册由业务层决定；Web 与移动端都可用。
  /// 需要文件名 / Content-Type / status 时用 [downloadResponse]。
  Future<Uint8List> download(
    String path, {
    Map<String, Object?>? query,
    Map<String, String>? pathParameters,
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
    Map<String, String>? headers,
  }) async => (await downloadResponse(
    path,
    query: query,
    pathParameters: pathParameters,
    onProgress: onProgress,
    cancelToken: cancelToken,
    headers: headers,
  )).data;

  /// 下载文件，并保留 status / headers / requestOptions。
  ///
  /// 文件名通常从 `content-disposition` 读取；写文件仍由业务层决定。
  Future<WApiResponse<Uint8List>> downloadResponse(
    String path, {
    Map<String, Object?>? query,
    Map<String, String>? pathParameters,
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
    Map<String, String>? headers,
  }) async {
    final resolvedPath = _resolvePath(path, pathParameters);
    try {
      final response = await _dio.get<List<int>>(
        resolvedPath,
        queryParameters: _cleanQuery(query),
        cancelToken: cancelToken,
        options: Options(
          headers: headers,
          responseType: ResponseType.bytes,
        ),
        onReceiveProgress: onProgress,
      );
      final data = response.data;
      return WApiResponse<Uint8List>(
        data: data == null ? Uint8List(0) : Uint8List.fromList(data),
        statusCode: response.statusCode,
        headers: response.headers,
        requestOptions: response.requestOptions,
      );
    } on DioException catch (error) {
      throw WApiException.from(error);
    }
  }

  Future<T> _send<T>(
    String method,
    String path, {
    Object? body,
    Map<String, Object?>? query,
    Map<String, String>? pathParameters,
    WApiDecoder<T>? decode,
    CancelToken? cancelToken,
    Map<String, String>? headers,
    void Function(int sent, int total)? onSendProgress,
  }) async => (await _sendResponse<T>(
    method,
    path,
    body: body,
    query: query,
    pathParameters: pathParameters,
    decode: decode,
    cancelToken: cancelToken,
    headers: headers,
    onSendProgress: onSendProgress,
  )).data;

  Future<WApiResponse<T>> _sendResponse<T>(
    String method,
    String path, {
    Object? body,
    Map<String, Object?>? query,
    Map<String, String>? pathParameters,
    WApiDecoder<T>? decode,
    WApiEnvelopeParser? envelope,
    CancelToken? cancelToken,
    Map<String, String>? headers,
    void Function(int sent, int total)? onSendProgress,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    final resolvedPath = _resolvePath(path, pathParameters);
    final requestBody = body is WApiBody ? body.data : body;
    final bodyContentType = body is WApiBody ? body.contentType : null;
    final mergedHeaders = <String, dynamic>{...?headers};
    final contentType = _headerOf(mergedHeaders, Headers.contentTypeHeader) ?? bodyContentType;

    try {
      final response = await _dio.request<Object?>(
        resolvedPath,
        data: requestBody,
        queryParameters: _cleanQuery(query),
        cancelToken: cancelToken,
        options: Options(
          method: method.toUpperCase(),
          headers: mergedHeaders,
          contentType: contentType,
        ),
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      return WApiResponse<T>(
        data: _decode(response.data, decode, envelope: envelope),
        statusCode: response.statusCode,
        headers: response.headers,
        requestOptions: response.requestOptions,
      );
    } on DioException catch (error) {
      throw WApiException.from(error);
    }
  }

  T _decode<T>(
    Object? body,
    WApiDecoder<T>? decode, {
    WApiEnvelopeParser? envelope,
  }) {
    Object? json = body;
    try {
      final activeEnvelope = envelope ?? _envelope;
      // 204 / 空 body 没有可读的 code；不要在 readCode(null) 上把成功请求
      // 变成 decode 错误。需要旧行为时把 skipEmptyBody 设为 false。
      if (activeEnvelope != null && activeEnvelope.skipEmptyBody && _isEmptyBody(json)) {
        if (decode != null) return decode(null);
        return null as T;
      }
      if (activeEnvelope != null) {
        final code = activeEnvelope.readCode(json);
        if (!activeEnvelope.isSuccess(code)) {
          final isAuthFailure = activeEnvelope.authFailureCodes.contains(code);
          final exception = WApiException(
            isAuthFailure ? WApiErrorKind.unauthorized : WApiErrorKind.business,
            businessCode: code,
            message: activeEnvelope.readMessage?.call(json) ?? 'Business error',
            payload: json,
          );
          if (isAuthFailure) {
            try {
              onAuthFailure?.call(exception);
            } catch (error) {
              log_support.logError('onAuthFailure failed: $error');
            }
          }
          throw exception;
        }
        json = activeEnvelope.readData(json);
      }

      if (decode != null) return decode(json);
      return json as T;
    } on WApiException {
      rethrow;
    } catch (error) {
      // decoder 里的 TypeError / FormatException、以及没有 decode 时的
      // `json as T` 失败，都不能漏成普通异常。
      throw WApiException(
        WApiErrorKind.decode,
        message: 'Response decoding failed',
        cause: error,
        payload: json,
      );
    }
  }

  /// 把 `'/users/{id}'` + `{'id': '42'}` 解析成 `'/users/42'`。
  ///
  /// 路径里仍留有 `{name}` 占位符（包括没传 `pathParameters`）时抛
  /// [ArgumentError]，避免把编码后的 `%7Bname%7D` 发给服务端。
  static String _resolvePath(
    String path,
    Map<String, String>? pathParameters,
  ) {
    var resolved = path;
    if (pathParameters != null) {
      for (final entry in pathParameters.entries) {
        resolved = resolved.replaceAll(
          '{${entry.key}}',
          Uri.encodeComponent(entry.value),
        );
      }
    }

    final missing = RegExp(r'\{[^}]+\}').firstMatch(resolved);
    if (missing != null) {
      throw ArgumentError.value(
        path,
        'path',
        'Missing path parameter ${missing.group(0)}',
      );
    }
    return resolved;
  }

  /// 204 / 无 body：dio 通常给 null，部分 adapter 会给空字符串。
  static bool _isEmptyBody(Object? body) => body == null || (body is String && body.isEmpty);

  /// 去掉值为 null 的 query，避免 dio 序列化出 `key=null`。
  static Map<String, Object?>? _cleanQuery(Map<String, Object?>? query) {
    if (query == null) return null;
    return {
      for (final entry in query.entries)
        if (entry.value != null) entry.key: entry.value,
    };
  }

  /// 大小写不敏感地读取 header。
  static String? _headerOf(Map<String, dynamic> headers, String name) {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == name.toLowerCase()) {
        return entry.value?.toString();
      }
    }
    return null;
  }
}
