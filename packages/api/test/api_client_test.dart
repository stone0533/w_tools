import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_api/w_tools_api.dart';

void main() {
  late Dio dio;
  late _RecordingAdapter adapter;
  late WApiClient client;

  setUp(() {
    adapter = _RecordingAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
    dio.httpClientAdapter = adapter;
    client = WApiClient(dio);
  });

  test('GET 解析 path、过滤 null query 并解码模型', () async {
    adapter.handler = (_) => _json(200, {'id': 1, 'name': 'Ada'});

    final user = await client.get(
      '/users/{id}',
      pathParameters: {'id': '42'},
      query: {'include': 'profile', 'missing': null},
      decode: (json) => User.fromJson(json as Map<String, dynamic>),
    );

    expect(user.name, 'Ada');
    expect(adapter.last!.method, 'GET');
    expect(adapter.last!.path, '/users/42');
    expect(adapter.last!.queryParameters, {'include': 'profile'});
  });

  test('path 参数缺失时抛 ArgumentError', () async {
    await expectLater(
      client.get('/users/{id}', pathParameters: {'other': '1'}),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('pathParameters 为空 Map 时仍报告缺失占位符', () async {
    await expectLater(
      client.get('/users/{id}', pathParameters: const {}),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('完全没传 pathParameters 时报告缺失占位符', () async {
    await expectLater(
      client.get('/users/{id}'),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('POST 发送 JSON 并设置 content-type', () async {
    adapter.handler = (_) => _json(200, {'id': 2, 'name': 'Grace'});

    final user = await client.post(
      '/users',
      body: const WApiBody.json({'name': 'Grace'}),
      decode: (json) => User.fromJson(json as Map<String, dynamic>),
    );

    expect(user.id, 2);
    expect(adapter.last!.method, 'POST');
    expect(adapter.last!.data, {'name': 'Grace'});
    expect(
      _headerOf(adapter.last!.headers, 'content-type'),
      Headers.jsonContentType,
    );
  });

  test('PUT 发送 urlencoded form 并丢弃 null 字段', () async {
    await client.put<void>(
      '/users/2',
      body: WApiBody.form({'name': 'Ada', 'skip': null}),
      decode: (json) {},
    );

    expect(adapter.last!.method, 'PUT');
    expect(adapter.last!.data, {'name': 'Ada'});
    expect(
      _headerOf(adapter.last!.headers, 'content-type'),
      Headers.formUrlEncodedContentType,
    );
  });

  test('POST 支持 multipart 字段与文件', () async {
    final file = MultipartFile.fromBytes(
      [1, 2, 3],
      filename: 'a.bin',
    );

    await client.post<void>(
      '/files',
      body: WApiBody.multipart(
        fields: {'bucket': 'avatar', 'skip': null},
        files: {'file': file},
      ),
      decode: (json) {},
    );

    final data = adapter.last!.data;
    expect(data, isA<FormData>());

    final form = data as FormData;
    expect(
      form.fields.any((entry) => entry.key == 'bucket' && entry.value == 'avatar'),
      isTrue,
    );
    expect(form.fields.any((entry) => entry.key == 'skip'), isFalse);
    expect(form.files.single.key, 'file');
    expect(form.files.single.value.filename, 'a.bin');
  });

  test('bytes body 使用显式 content-type', () async {
    await client.put<void>(
      '/blob',
      body: WApiBody.bytes(
        [1, 2, 3],
        contentType: 'application/octet-stream',
      ),
      decode: (json) {},
    );

    expect(adapter.last!.data, isA<Uint8List>());
    expect(
      _headerOf(adapter.last!.headers, 'content-type'),
      'application/octet-stream',
    );
  });

  test('bytes body 省略 content-type 时默认 application/octet-stream', () async {
    await client.put<void>(
      '/blob',
      body: WApiBody.bytes([1, 2, 3]),
      decode: (json) {},
    );

    expect(adapter.last!.data, isA<Uint8List>());
    expect(
      _headerOf(adapter.last!.headers, 'content-type'),
      'application/octet-stream',
    );
  });

  test('bytes body 的显式请求头覆盖默认 content-type', () async {
    await client.put<void>(
      '/blob',
      body: WApiBody.bytes([1, 2, 3]),
      headers: {'Content-Type': 'image/png'},
      decode: (json) {},
    );

    expect(_headerOf(adapter.last!.headers, 'content-type'), 'image/png');
  });

  test('用户请求头优先于 body 默认 content-type', () async {
    await client.post<void>(
      '/x',
      body: const WApiBody.json({'a': 1}),
      headers: {
        'X-Trace': 't1',
        'content-type': 'application/vnd.api+json',
      },
      decode: (json) {},
    );

    expect(_headerOf(adapter.last!.headers, 'x-trace'), 't1');
    expect(
      _headerOf(adapter.last!.headers, 'content-type'),
      'application/vnd.api+json',
    );
  });

  test('decoder 抛错包装成 decode 错误', () async {
    adapter.handler = (_) => _json(200, {'id': 'oops', 'name': 'Ada'});

    await expectLater(
      client.get(
        '/user',
        decode: (json) => User.fromJson(json as Map<String, dynamic>),
      ),
      throwsA(
        isA<WApiException>()
            .having((error) => error.kind, 'kind', WApiErrorKind.decode)
            .having((error) => error.payload, 'payload', isNotNull),
      ),
    );
  });

  test('没有 decode 时类型不匹配也包装成 decode 错误', () async {
    adapter.handler = (_) => _json(200, {'id': 1});

    await expectLater(
      client.get<String>('/x'),
      throwsA(
        isA<WApiException>().having(
          (error) => error.kind,
          'kind',
          WApiErrorKind.decode,
        ),
      ),
    );
  });

  test('401 映射成 unauthorized 且要求登录', () async {
    adapter.handler = (_) => _json(401, {'error': 'unauthorized'});

    await expectLater(
      client.get('/me'),
      throwsA(
        isA<WApiException>()
            .having((error) => error.kind, 'kind', WApiErrorKind.unauthorized)
            .having(
              (error) => error.requiresLogin,
              'requiresLogin',
              isTrue,
            ),
      ),
    );
  });

  test('5xx 映射成 server 并保留 statusCode / payload', () async {
    adapter.handler = (_) => _json(500, {'error': 'boom'});

    await expectLater(
      client.get('/x'),
      throwsA(
        isA<WApiException>()
            .having((error) => error.kind, 'kind', WApiErrorKind.server)
            .having((error) => error.statusCode, 'statusCode', 500)
            .having((error) => error.payload, 'payload', {'error': 'boom'}),
      ),
    );
  });

  test('DELETE 使用正确 method', () async {
    await client.delete('/users/1');

    expect(adapter.last!.method, 'DELETE');
  });

  test('PATCH 使用 PATCH method 并发送 body', () async {
    await client.patch<void>(
      '/users/1',
      body: const WApiBody.json({'name': 'Ada'}),
      decode: WApiDecoders.none,
    );

    expect(adapter.last!.method, 'PATCH');
    expect(adapter.last!.path, '/users/1');
    expect(adapter.last!.data, {'name': 'Ada'});
  });

  test('HEAD / OPTIONS 使用对应 method', () async {
    await client.head('/resource');
    expect(adapter.last!.method, 'HEAD');

    await client.options('/resource');
    expect(adapter.last!.method, 'OPTIONS');
  });

  test('send 保留 status / headers / requestOptions', () async {
    adapter.handler = (_) => _json(200, {'id': 1, 'name': 'Ada'});

    final response = await client.send<User>(
      'get',
      '/users/42',
      decode: (json) => User.fromJson(json as Map<String, dynamic>),
    );

    expect(response.data.name, 'Ada');
    expect(response.statusCode, 200);
    expect(
      response.headers.value(Headers.contentTypeHeader),
      contains('application/json'),
    );
    expect(response.requestOptions.method, 'GET');
    expect(response.uri.path, '/users/42');
  });

  test('send HEAD 保留响应头', () async {
    adapter.handler = (_) => ResponseBody.fromString(
      '',
      200,
      headers: {
        'x-total-count': ['3'],
      },
    );

    final response = await client.send<void>(
      'HEAD',
      '/users',
      decode: WApiDecoders.none,
    );

    expect(response.statusCode, 200);
    expect(response.headers.value('x-total-count'), '3');
  });

  test('upload 支持 PUT，并拒绝非法 method', () async {
    await client.upload<void>(
      '/files',
      method: 'PUT',
      files: {
        'file': MultipartFile.fromBytes([1]),
      },
      decode: WApiDecoders.none,
    );
    expect(adapter.last!.method, 'PUT');

    await expectLater(
      client.upload<void>(
        '/files',
        method: 'GET',
        decode: WApiDecoders.none,
      ),
      throwsArgumentError,
    );
  });

  test('dio 超时异常映射成 timeout', () {
    final error = WApiException.from(
      DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionTimeout,
      ),
    );

    expect(error.kind, WApiErrorKind.timeout);
  });

  test('403 / 404 映射成 forbidden / notFound', () {
    for (final status in [403, 404]) {
      final options = RequestOptions(path: '/x');
      final error = WApiException.from(
        DioException(
          requestOptions: options,
          response: Response(requestOptions: options, statusCode: status),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        error.kind,
        status == 403 ? WApiErrorKind.forbidden : WApiErrorKind.notFound,
      );
      expect(error.statusCode, status);
    }
  });

  test('form body 实际编码为 urlencoded', () async {
    final capture = _BodyCaptureAdapter();
    final formDio = Dio(BaseOptions(baseUrl: 'https://api.test'));
    formDio.httpClientAdapter = capture;

    await WApiClient(formDio).post<void>(
      '/form',
      body: WApiBody.form({'name': 'Ada'}),
      decode: (json) {},
    );

    expect(capture.body, contains('name=Ada'));
  });

  test('barrel 补全上传 / adapter 类型重导出', () {
    expect(FormData(), isA<FormData>());
    expect(MultipartFile.fromBytes([1]), isA<MultipartFile>());
    expect(HttpClientAdapter, isNotNull);
    expect(ResponseBody, isNotNull);
    expect(ListFormat.multi, isNotNull);
    expect(ProgressCallback, isNotNull);
  });

  test('barrel 重导出 InterceptorsWrapper / QueuedInterceptor', () {
    expect(InterceptorsWrapper(), isA<Interceptor>());
    expect(QueuedInterceptor(), isA<Interceptor>());
  });

  group('options', () {
    test('options.extra 透传给请求（单条关闭重试 / 埋点）', () async {
      await client.get<void>(
        '/x',
        options: Options(
          extra: {WRetryInterceptor.disableRetryExtraKey: true},
        ),
        decode: WApiDecoders.none,
      );

      expect(
        adapter.last!.extra[WRetryInterceptor.disableRetryExtraKey],
        isTrue,
      );
      expect(adapter.last!.method, 'GET');
    });

    test('options.validateStatus 接受 409 时返回 WApiResponse', () async {
      adapter.handler = (_) => _json(409, {'error': 'conflict'});

      final response = await client.send<Map<String, dynamic>>(
        'POST',
        '/items/1',
        options: Options(validateStatus: (status) => status == 409),
      );

      expect(response.statusCode, 409);
      expect(response.data, {'error': 'conflict'});
    });

    test('headers 参数优先于 options.headers，method 由方法名决定', () async {
      await client.post<void>(
        '/x',
        options: Options(
          method: 'GET',
          headers: {'X-Trace': 'from-options', 'X-Only-Options': 'o'},
        ),
        headers: {'X-Trace': 'from-param'},
        decode: WApiDecoders.none,
      );

      expect(adapter.last!.method, 'POST');
      expect(_headerOf(adapter.last!.headers, 'x-trace'), 'from-param');
      expect(_headerOf(adapter.last!.headers, 'x-only-options'), 'o');
    });

    test('options.contentType 只在没有显式 Content-Type 时生效', () async {
      await client.post<void>(
        '/x',
        body: const WApiBody.json({'a': 1}),
        options: Options(contentType: 'application/vnd.api+json'),
        decode: WApiDecoders.none,
      );
      expect(
        _headerOf(adapter.last!.headers, 'content-type'),
        'application/vnd.api+json',
      );

      await client.post<void>(
        '/x',
        body: const WApiBody.json({'a': 1}),
        options: Options(
          contentType: 'application/vnd.api+json',
          headers: {'Content-Type': 'application/problem+json'},
        ),
        decode: WApiDecoders.none,
      );
      expect(
        _headerOf(adapter.last!.headers, 'content-type'),
        'application/problem+json',
      );
    });

    test('headers 参数与 options.headers 大小写不同时 headers 胜出', () async {
      await client.post<void>(
        '/x',
        options: Options(
          headers: {
            'content-type': 'text/plain',
            'x-trace': 'from-options',
          },
        ),
        headers: {
          'Content-Type': 'image/png',
          'X-Trace': 'from-param',
        },
        decode: WApiDecoders.none,
      );

      // 大小写不同的同名 header 不能同时存在，且 headers 参数优先。
      final contentTypes = adapter.last!.headers.keys
          .where((key) => key.toLowerCase() == 'content-type')
          .toList();
      expect(contentTypes, hasLength(1));
      expect(_headerOf(adapter.last!.headers, 'content-type'), 'image/png');
      expect(_headerOf(adapter.last!.headers, 'x-trace'), 'from-param');
    });

    test('get 的 options 也能关闭重试（与 WRetryInterceptor 集成）', () async {
      final retryAdapter = _RecordingAdapter()..handler = (_) => _json(500, {'error': 'boom'});
      final retryDio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = retryAdapter;
      retryDio.interceptors.add(
        WRetryInterceptor(
          dio: retryDio,
          maxRetries: 2,
          baseDelay: Duration.zero,
          jitter: false,
        ),
      );

      await expectLater(
        WApiClient(retryDio).get<void>(
          '/x',
          options: Options(
            extra: {WRetryInterceptor.disableRetryExtraKey: true},
          ),
          decode: WApiDecoders.none,
        ),
        throwsA(isA<WApiException>()),
      );
      expect(retryAdapter.calls, 1);
    });

    test('downloadResponse 透传 options，responseType 仍为 bytes', () async {
      adapter.handler = (_) => ResponseBody.fromString(
        'A',
        200,
        headers: {
          Headers.contentTypeHeader: ['application/octet-stream'],
        },
      );

      final response = await client.downloadResponse(
        '/file',
        options: Options(extra: {'trace': 't1'}),
      );

      expect(response.data, [65]);
      expect(adapter.last!.extra['trace'], 't1');
      expect(adapter.last!.responseType, ResponseType.bytes);
    });
  });

  test('DioException.unknown 带响应时按 HTTP 状态分类', () {
    final request = RequestOptions(path: '/x');
    final error = DioException(
      requestOptions: request,
      type: DioExceptionType.unknown,
      response: Response(requestOptions: request, statusCode: 503),
    );

    final exception = WApiException.from(error);

    expect(exception.kind, WApiErrorKind.server);
    expect(exception.statusCode, 503);
  });
}

/// 测试用模型：只关心 decode 是否被调用以及字段类型。
class User {
  const User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
  );

  final int id;
  final String name;
}

class _RecordingAdapter implements HttpClientAdapter {
  ResponseBody Function(RequestOptions options)? handler;
  RequestOptions? last;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    last = options;
    return handler?.call(options) ?? _json(200, {'ok': true});
  }

  @override
  void close({bool force = false}) {}
}

class _BodyCaptureAdapter implements HttpClientAdapter {
  String? body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (requestStream != null) {
      final bytes = <int>[];
      await for (final chunk in requestStream) {
        bytes.addAll(chunk);
      }
      body = utf8.decode(bytes);
    }
    return _json(200, {'ok': true});
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Object? body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

String? _headerOf(Map<String, dynamic> headers, String name) {
  final lower = name.toLowerCase();
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == lower) return entry.value?.toString();
  }
  return null;
}
