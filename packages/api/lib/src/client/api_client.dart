// ignore_for_file: deprecated_member_use_from_same_package

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
/// 除已弃用的 `page` / `download` 外，每个请求方法都接受 `options:`
/// （dio 的 [Options]），用于单条请求的 `extra`（如
/// `WRetryInterceptor.disableRetryExtraKey`）、`validateStatus`（接受 304 / 409）、
/// `responseType` 等；与 client 自己的 method / headers 合并规则见 [send]。
///
/// ```dart
/// final client = WApiClient(registry.dio);
/// final user = await client.get(
///   '/users/{id}',
///   pathParameters: {'id': '42'},
///   decode: (json) => User.fromJson(json as Map<String, dynamic>),
/// );
/// // 单条请求关闭重试 / 接受 409
/// await client.get<void>(
///   '/items/1',
///   options: Options(extra: {WRetryInterceptor.disableRetryExtraKey: true}),
///   decode: WApiDecoders.none,
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
  /// `options:` 透传 dio 的 [Options]（`extra` / `validateStatus` / `responseType`
  /// / `listFormat` 等），并按以下优先级与 client 自己的配置合并：
  /// `method` 永远取本方法的 HTTP 方法；`headers` 参数优先于
  /// `options.headers`；显式 `Content-Type` 头优先于 `options.contentType`，
  /// 两者都没有时才用 [WApiBody] 的默认类型。其他请求方法的 `options:`
  /// 语义相同。
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
    Options? options,
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
    options: options,
  );

  /// GET 请求。
  Future<T> get<T>(
    String path, {
    Map<String, Object?>? query,
    Map<String, String>? pathParameters,
    WApiDecoder<T>? decode,
    CancelToken? cancelToken,
    Map<String, String>? headers,
    Options? options,
  }) => _send<T>(
    'GET',
    path,
    query: query,
    pathParameters: pathParameters,
    decode: decode,
    cancelToken: cancelToken,
    headers: headers,
    options: options,
  );

  /// HEAD 请求。
  Future<T> head<T>(
    String path, {
    Map<String, Object?>? query,
    Map<String, String>? pathParameters,
    WApiDecoder<T>? decode,
    CancelToken? cancelToken,
    Map<String, String>? headers,
    Options? options,
  }) => _send<T>(
    'HEAD',
    path,
    query: query,
    pathParameters: pathParameters,
    decode: decode,
    cancelToken: cancelToken,
    headers: headers,
    options: options,
  );

  /// OPTIONS 请求。
  Future<T> options<T>(
    String path, {
    Map<String, Object?>? query,
    Map<String, String>? pathParameters,
    WApiDecoder<T>? decode,
    CancelToken? cancelToken,
    Map<String, String>? headers,
    Options? options,
  }) => _send<T>(
    'OPTIONS',
    path,
    query: query,
    pathParameters: pathParameters,
    decode: decode,
    cancelToken: cancelToken,
    headers: headers,
    options: options,
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
    Options? options,
  }) => _send<T>(
    'POST',
    path,
    body: body,
    query: query,
    pathParameters: pathParameters,
    decode: decode,
    cancelToken: cancelToken,
    headers: headers,
    options: options,
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
    Options? options,
  }) => _send<T>(
    'PUT',
    path,
    body: body,
    query: query,
    pathParameters: pathParameters,
    decode: decode,
    cancelToken: cancelToken,
    headers: headers,
    options: options,
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
    Options? options,
  }) => _send<T>(
    'PATCH',
    path,
    body: body,
    query: query,
    pathParameters: pathParameters,
    decode: decode,
    cancelToken: cancelToken,
    headers: headers,
    options: options,
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
    Options? options,
  }) => _send<T>(
    'DELETE',
    path,
    query: query,
    pathParameters: pathParameters,
    decode: decode,
    cancelToken: cancelToken,
    headers: headers,
    options: options,
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
  ///
  /// remove-in: 7.0.0
  @Deprecated('Use WApiClient.get/send + WAsyncPage in the repository')
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
    Options? options,
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
      options: options,
    );
  }

  /// 下载文件，返回原始字节。
  ///
  /// 写文件 / 保存到相册由业务层决定；Web 与移动端都可用。
  /// 需要文件名 / Content-Type / status 时用 [downloadResponse]。
  ///
  /// remove-in: 7.0.0
  @Deprecated('Use downloadResponse().data instead')
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
  /// [options] 只影响 `extra` / `headers` / `validateStatus` 等字段：
  /// `responseType` 固定为 `bytes`，方法固定为 GET。
  Future<WApiResponse<Uint8List>> downloadResponse(
    String path, {
    Map<String, Object?>? query,
    Map<String, String>? pathParameters,
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
    Map<String, String>? headers,
    Options? options,
  }) async {
    final resolvedPath = _resolvePath(path, pathParameters);
    try {
      final response = await _dio.get<List<int>>(
        resolvedPath,
        queryParameters: _cleanQuery(query),
        cancelToken: cancelToken,
        options: _mergeOptions(
          method: 'GET',
          headers: headers,
          bodyContentType: null,
          requestBody: null,
          options: options,
        ).copyWith(responseType: ResponseType.bytes),
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
    Options? options,
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
    options: options,
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
    Options? options,
  }) async {
    final resolvedPath = _resolvePath(path, pathParameters);
    final requestBody = body is WApiBody ? body.data : body;
    final bodyContentType = body is WApiBody ? body.contentType : null;

    try {
      final response = await _dio.request<Object?>(
        resolvedPath,
        data: requestBody,
        queryParameters: _cleanQuery(query),
        cancelToken: cancelToken,
        options: _mergeOptions(
          method: method,
          headers: headers,
          bodyContentType: bodyContentType,
          requestBody: requestBody,
          options: options,
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

  /// 把调用方 [Options] 与 client 自己的 method / headers / contentType 合并。
  ///
  /// 优先级：`headers` 参数 > `options.headers`；显式 `Content-Type` 头 >
  /// `options.contentType` > `bodyContentType` > 字节 body 的
  /// `application/octet-stream` 兜底；`method` 永远取调用方法。
  /// 其余字段（`extra` / `validateStatus` / `responseType` / `listFormat` /
  /// 超时等）原样保留，未传 [options] 时相当于 `Options()`。
  static Options _mergeOptions({
    required String method,
    required Map<String, String>? headers,
    required String? bodyContentType,
    required Object? requestBody,
    required Options? options,
  }) {
    // 大小写不敏感地合并：headers 参数优先，同名不同大小写的键只保留一个
    // （否则 _headerOf 会取到 options 里先插入的那个，违反 headers 优先级）。
    final mergedHeaders = <String, dynamic>{};
    for (final entry in (options?.headers ?? const <String, dynamic>{}).entries) {
      mergedHeaders[entry.key] = entry.value;
    }
    for (final entry in (headers ?? const <String, String>{}).entries) {
      mergedHeaders.removeWhere(
        (key, _) => key.toLowerCase() == entry.key.toLowerCase(),
      );
      mergedHeaders[entry.key] = entry.value;
    }
    // 先把 Content-Type 头取出来再从 headers 里移除：dio 的 Options.copyWith
    // 不允许同时传 contentType 和 content-type 头（会触发断言）。
    final headerContentType = _headerOf(
      mergedHeaders,
      Headers.contentTypeHeader,
    );
    mergedHeaders.removeWhere(
      (key, _) => key.toLowerCase() == Headers.contentTypeHeader,
    );
    final contentType =
        headerContentType ??
        options?.contentType ??
        bodyContentType ??
        // 只有 Uint8List 会被 dio 当成原始字节（普通 List<int> 会走
        // transformer 变成字符串），省略 Content-Type 时按未知二进制兜底；
        // multipart 的 FormData 由 dio 自己写 boundary。
        (requestBody is Uint8List ? 'application/octet-stream' : null);
    return (options ?? Options()).copyWith(
      method: method.toUpperCase(),
      headers: mergedHeaders,
      contentType: contentType,
    );
  }
}
