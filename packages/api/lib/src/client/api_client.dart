import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../api_config.dart';
import 'api_exception.dart';

/// 把 JSON 转成业务模型的显式解码函数。
///
/// Dart / Flutter 没有反射，`get<User>()` 不会自动调用 `User.fromJson`；
/// 必须把映射显式传给 `decode`（或用 json_serializable / freezed 生成）。
typedef WApiDecoder<T> = T Function(Object? json);

/// 请求体的编码方式。
enum WApiBodyKind {
  /// `application/json`
  json,

  /// `application/x-www-form-urlencoded`
  form,

  /// `multipart/form-data`
  multipart,

  /// 原始字节
  bytes,
}

/// 请求体描述。
///
/// ```dart
/// WApiBody.json({'name': 'Ada'});
/// WApiBody.form({'name': 'Ada'});
/// WApiBody.multipart(
///   fields: {'bucket': 'avatar'},
///   files: {'file': MultipartFile.fromBytes(bytes)},
/// );
/// WApiBody.bytes(bytes, contentType: 'application/octet-stream');
/// ```
class WApiBody {
  /// JSON body（Map / List / 可 jsonEncode 的值）。
  const WApiBody.json(Object? value)
    : kind = WApiBodyKind.json,
      data = value,
      contentType = Headers.jsonContentType;

  /// 表单 body；`null` 字段会被丢弃。
  WApiBody.form(Map<String, Object?> fields)
    : kind = WApiBodyKind.form,
      data = _withoutNulls(fields),
      contentType = Headers.formUrlEncodedContentType;

  /// multipart body；`null` 字段会被丢弃。
  ///
  /// [files] 的 key 是表单字段名（dio 5 的 `MultipartFile` 不再自带字段名）。
  WApiBody.multipart({
    Map<String, Object?> fields = const {},
    Map<String, MultipartFile> files = const {},
  }) : kind = WApiBodyKind.multipart,
       data = _formData(fields, files),
       contentType = null;

  /// 原始字节 body。
  WApiBody.bytes(List<int> bytes, {this.contentType})
    : kind = WApiBodyKind.bytes,
      data = Uint8List.fromList(bytes);

  /// 编码方式
  final WApiBodyKind kind;

  /// 直接传给 dio 的 `data`
  final Object? data;

  /// `Content-Type`；multipart 时为 null，由 dio 生成 boundary
  final String? contentType;

  static Map<String, Object?> _withoutNulls(Map<String, Object?> fields) => {
    for (final entry in fields.entries)
      if (entry.value != null) entry.key: entry.value,
  };

  static FormData _formData(
    Map<String, Object?> fields,
    Map<String, MultipartFile> files,
  ) {
    final form = FormData();
    for (final entry in _withoutNulls(fields).entries) {
      form.fields.add(MapEntry(entry.key, entry.value.toString()));
    }
    for (final entry in files.entries) {
      form.files.add(MapEntry(entry.key, entry.value));
    }
    return form;
  }
}

/// 业务信封解析器。
///
/// 很多后端返回 `{code, message, data}`；`WApiClient` 默认不假设信封，
/// 传 [WApiEnvelopeParser] 后才启用：
///
/// ```dart
/// final client = WApiClient(
///   registry.dio,
///   envelope: WApiEnvelopeParser(
///     readCode: (json) => (json as Map)['code'],
///     readData: (json) => (json as Map)['data'],
///     readMessage: (json) => (json as Map)['message'] as String?,
///     isSuccess: (code) => code == 0 || code == 200,
///   ),
/// );
/// ```
///
/// 业务码失败会抛 `WApiException(kind: WApiErrorKind.business)`，
/// 带上 [WApiException.businessCode] 和原始 [WApiException.payload]。
class WApiEnvelopeParser {
  /// 创建解析器。
  const WApiEnvelopeParser({
    required this.readCode,
    required this.readData,
    required this.isSuccess,
    this.readMessage,
    this.authFailureCodes = const {},
  });

  /// 读取业务码
  final Object? Function(Object? json) readCode;

  /// 读取业务数据（成功时传给 `decode`）
  final Object? Function(Object? json) readData;

  /// 业务码是否表示成功
  final bool Function(Object? code) isSuccess;

  /// 读取业务提示信息（可选）
  final String? Function(Object? json)? readMessage;

  /// 视为「登录失效」的业务码。
  ///
  /// 命中时 `WApiClient` 抛 `WApiException(kind: unauthorized)` 并调用
  /// `WApiClient.onAuthFailure`，与 HTTP 401 走同一条登出链路。
  final Set<Object?> authFailureCodes;
}

/// 分页请求参数。
///
/// [pageKey] / [pageSizeKey] 用于适配不同后端的参数名（默认 `page` / `pageSize`）。
class WPageQuery {
  /// 创建分页参数；页码从 1 开始。
  const WPageQuery({
    this.page = 1,
    this.pageSize = 20,
    this.pageKey = 'page',
    this.pageSizeKey = 'pageSize',
  }) : assert(page >= 1, 'page 从 1 开始'),
       assert(pageSize >= 1, 'pageSize 必须大于 0');

  /// 页码（从 1 开始）
  final int page;

  /// 每页条数
  final int pageSize;

  /// 页码参数名
  final String pageKey;

  /// 每页条数参数名
  final String pageSizeKey;

  /// 转成 query 参数
  Map<String, Object?> toQuery() => {pageKey: page, pageSizeKey: pageSize};
}

/// 一页数据 + 是否还有更多。
class WPage<T> {
  /// 创建分页结果。
  const WPage({
    required this.items,
    required this.page,
    required this.pageSize,
    this.total,
  });

  /// 当前页数据
  final List<T> items;

  /// 当前页码（从 1 开始）
  final int page;

  /// 每页条数
  final int pageSize;

  /// 总条数；服务端不返回时为 null
  final int? total;

  /// 是否还有下一页。
  ///
  /// 有 [total] 时按 `page * pageSize < total` 计算；没有时按「本页是否满页」判断。
  bool get hasMore {
    final total = this.total;
    if (total != null) return page * pageSize < total;
    return items.length >= pageSize;
  }
}

/// 常用 decoder 辅助。
abstract final class WApiDecoders {
  /// 忽略响应体（DELETE / 204 用）。
  static WApiDecoder<void> get none => (json) {};

  /// 直接返回 `Map<String, dynamic>`（不做字段映射）。
  static WApiDecoder<Map<String, dynamic>> get jsonMap =>
      (json) => json as Map<String, dynamic>;

  /// JSON 数组 → `List<T>`。
  static WApiDecoder<List<T>> listOf<T>(WApiDecoder<T> itemDecode) =>
      (json) => (json as List).map(itemDecode).toList();

  /// 允许响应体为 null 的 decoder。
  static WApiDecoder<T?> nullable<T>(WApiDecoder<T> itemDecode) =>
      (json) => json == null ? null : itemDecode(json);
}

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
  Future<WApiResponse<T>> send<T>(
    String method,
    String path, {
    Object? body,
    Map<String, Object?>? query,
    Map<String, String>? pathParameters,
    WApiDecoder<T>? decode,
    CancelToken? cancelToken,
    Map<String, String>? headers,
    void Function(int sent, int total)? onSendProgress,
  }) => _sendResponse<T>(
    method,
    path,
    body: body,
    query: query,
    pathParameters: pathParameters,
    decode: decode,
    cancelToken: cancelToken,
    headers: headers,
    onSendProgress: onSendProgress,
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
  /// ```dart
  /// final page = await client.page(
  ///   '/users',
  ///   query: const WPageQuery(page: 1, pageSize: 20),
  ///   itemDecode: (json) => User.fromJson(json as Map<String, dynamic>),
  /// );
  /// ```
  Future<WPage<T>> page<T>(
    String path, {
    WPageQuery query = const WPageQuery(),
    required WApiDecoder<T> itemDecode,
    List<Object?> Function(Object? json)? readItems,
    int? Function(Object? json)? readTotal,
    Map<String, Object?>? extraQuery,
    Map<String, String>? pathParameters,
    CancelToken? cancelToken,
    Map<String, String>? headers,
  }) async {
    final body = await _send<Object?>(
      'GET',
      path,
      query: {...?extraQuery, ...query.toQuery()},
      pathParameters: pathParameters,
      cancelToken: cancelToken,
      headers: headers,
    );

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
        items: rawItems.map(itemDecode).toList(growable: false),
        page: query.page,
        pageSize: query.pageSize,
        total: readTotal?.call(body),
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
        'upload 只支持 POST / PUT / PATCH',
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
  Future<Uint8List> download(
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
      return data == null ? Uint8List(0) : Uint8List.fromList(data);
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
    CancelToken? cancelToken,
    Map<String, String>? headers,
    void Function(int sent, int total)? onSendProgress,
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
      );

      return WApiResponse<T>(
        data: _decode(response.data, decode),
        statusCode: response.statusCode,
        headers: response.headers,
        requestOptions: response.requestOptions,
      );
    } on DioException catch (error) {
      throw WApiException.from(error);
    }
  }

  T _decode<T>(Object? body, WApiDecoder<T>? decode) {
    Object? json = body;
    try {
      final envelope = _envelope;
      if (envelope != null) {
        final code = envelope.readCode(json);
        if (!envelope.isSuccess(code)) {
          final isAuthFailure = envelope.authFailureCodes.contains(code);
          final exception = WApiException(
            isAuthFailure ? WApiErrorKind.unauthorized : WApiErrorKind.business,
            businessCode: code,
            message: envelope.readMessage?.call(json) ?? 'Business error',
            payload: json,
          );
          if (isAuthFailure) {
            try {
              onAuthFailure?.call(exception);
            } catch (error) {
              WApiConfig.logErrorHandler?.call('onAuthFailure failed: $error');
            }
          }
          throw exception;
        }
        json = envelope.readData(json);
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
  static String _resolvePath(
    String path,
    Map<String, String>? pathParameters,
  ) {
    if (pathParameters == null || pathParameters.isEmpty) return path;

    var resolved = path;
    for (final entry in pathParameters.entries) {
      resolved = resolved.replaceAll(
        '{${entry.key}}',
        Uri.encodeComponent(entry.value),
      );
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
