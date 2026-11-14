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

  test('信封成功时把 data 交给 decode', () async {
    adapter.handler = (_) => _json(200, {
      'code': 0,
      'message': 'ok',
      'data': {'id': 1, 'name': 'Ada'},
    });
    final wrapped = WApiClient(dio, envelope: _envelope);

    final user = await wrapped.get('/me', decode: _userFromJson);

    expect(user.name, 'Ada');
  });

  test('业务码失败抛 business，并带 businessCode / message / payload', () async {
    adapter.handler = (_) => _json(200, {
      'code': 42,
      'message': 'quota exceeded',
      'data': null,
    });
    final wrapped = WApiClient(dio, envelope: _envelope);

    await expectLater(
      wrapped.get('/me'),
      throwsA(
        isA<WApiException>()
            .having((error) => error.kind, 'kind', WApiErrorKind.business)
            .having((error) => error.businessCode, 'businessCode', 42)
            .having((error) => error.message, 'message', 'quota exceeded')
            .having((error) => error.payload, 'payload', isA<Map>()),
      ),
    );
  });

  test('信封解析抛错时包装成 decode 错误', () async {
    adapter.handler = (_) => _json(200, {'code': 0});
    final wrapped = WApiClient(dio, envelope: _brokenEnvelope);

    await expectLater(
      wrapped.get('/me'),
      throwsA(
        isA<WApiException>().having(
          (error) => error.kind,
          'kind',
          WApiErrorKind.decode,
        ),
      ),
    );
  });

  test('authFailureCodes 命中时映射成 unauthorized 并回调', () async {
    adapter.handler = (_) => _json(200, {
      'code': 401,
      'message': 'expired',
      'data': null,
    });
    final failures = <WApiException>[];
    final wrapped = WApiClient(
      dio,
      envelope: const WApiEnvelopeParser(
        readCode: _readCode,
        readData: _readData,
        isSuccess: _isSuccess,
        readMessage: _readMessage,
        authFailureCodes: {401},
      ),
      onAuthFailure: failures.add,
    );

    await expectLater(
      wrapped.get('/me'),
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

    expect(failures, hasLength(1));
  });

  test('未配置 authFailureCodes 时业务码 401 仍是 business', () async {
    adapter.handler = (_) => _json(200, {
      'code': 401,
      'message': 'expired',
      'data': null,
    });
    final failures = <WApiException>[];
    final wrapped = WApiClient(
      dio,
      envelope: _envelope,
      onAuthFailure: failures.add,
    );

    await expectLater(
      wrapped.get('/me'),
      throwsA(
        isA<WApiException>().having(
          (error) => error.kind,
          'kind',
          WApiErrorKind.business,
        ),
      ),
    );

    expect(failures, isEmpty);
  });

  test('page 默认解析 JSON 数组并带上 query', () async {
    adapter.handler = (_) => _json(200, [
      {'id': 1, 'name': 'A'},
      {'id': 2, 'name': 'B'},
    ]);

    final page = await client.page(
      '/users',
      query: const WPageQuery(page: 1, pageSize: 2),
      itemDecode: _userFromJson,
    );

    expect(page.items.map((user) => user.name), ['A', 'B']);
    expect(page.hasMore, isTrue);
    expect(adapter.last!.queryParameters, {'page': 1, 'pageSize': 2});
  });

  test('page 支持 Map 结构、自定义 total 与参数名', () async {
    adapter.handler = (_) => _json(200, {
      'items': [
        {'id': 3, 'name': 'C'},
        {'id': 4, 'name': 'D'},
      ],
      'total': 3,
    });

    final page = await client.page(
      '/users',
      query: const WPageQuery(
        page: 2,
        pageSize: 2,
        pageKey: 'pageNo',
        pageSizeKey: 'size',
      ),
      itemDecode: _userFromJson,
      readItems: (json) => (json as Map)['items'] as List<Object?>,
      readTotal: (json) => (json as Map)['total'] as int,
    );

    expect(page.items.length, 2);
    expect(page.total, 3);
    expect(page.hasMore, isFalse);
    expect(adapter.last!.queryParameters, {'pageNo': 2, 'size': 2});
  });

  test('page 遇到非数组且未提供 readItems 时抛 decode 错误', () async {
    adapter.handler = (_) => _json(200, {'items': []});

    await expectLater(
      client.page('/users', itemDecode: _userFromJson),
      throwsA(
        isA<WApiException>().having(
          (error) => error.kind,
          'kind',
          WApiErrorKind.decode,
        ),
      ),
    );
  });

  test('upload 发送 multipart 字段与文件', () async {
    final file = MultipartFile.fromBytes([1, 2], filename: 'a.bin');

    await client.upload<void>(
      '/files',
      fields: {'bucket': 'avatar'},
      files: {'file': file},
      decode: WApiDecoders.none,
    );

    final data = adapter.last!.data;
    expect(data, isA<FormData>());

    final form = data as FormData;
    expect(
      form.fields.any(
        (entry) => entry.key == 'bucket' && entry.value == 'avatar',
      ),
      isTrue,
    );
    expect(form.files.single.key, 'file');
    expect(form.files.single.value.filename, 'a.bin');
  });

  test('download 返回字节并设置 responseType=bytes', () async {
    adapter.handler = (_) => ResponseBody.fromBytes(
      Uint8List.fromList([1, 2, 3]),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/octet-stream'],
      },
    );

    final bytes = await client.download('/files/1');

    expect(bytes, [1, 2, 3]);
    expect(adapter.last!.responseType, ResponseType.bytes);
  });

  test('信封 + 204 空 body 跳过 readCode', () async {
    adapter.handler = (_) => ResponseBody.fromString('', 204);
    final wrapped = WApiClient(dio, envelope: _envelope);

    await wrapped.delete<void>('/x', decode: WApiDecoders.none);
  });

  test('skipEmptyBody=false 时保留旧的 readCode(null) 行为', () async {
    adapter.handler = (_) => ResponseBody.fromString('', 204);
    final wrapped = WApiClient(
      dio,
      envelope: const WApiEnvelopeParser(
        readCode: _readCode,
        readData: _readData,
        isSuccess: _isSuccess,
        skipEmptyBody: false,
      ),
    );

    await expectLater(
      wrapped.delete<void>('/x', decode: WApiDecoders.none),
      throwsA(
        isA<WApiException>().having(
          (error) => error.kind,
          'kind',
          WApiErrorKind.decode,
        ),
      ),
    );
  });

  test('page 可从响应头读 total', () async {
    adapter.handler = (_) => _json(
      200,
      [
        {'id': 1, 'name': 'A'},
        {'id': 2, 'name': 'B'},
      ],
      headers: {
        'x-total-count': ['3'],
      },
    );

    final page = await client.page(
      '/users',
      query: const WPageQuery(page: 1, pageSize: 2),
      itemDecode: _userFromJson,
      readTotalFromResponse: (response) =>
          int.tryParse(response.headers.value('x-total-count') ?? ''),
    );

    expect(page.total, 3);
    expect(page.hasMore, isTrue);
  });

  test('downloadResponse 保留 headers / status', () async {
    adapter.handler = (_) => ResponseBody.fromBytes(
      Uint8List.fromList([1, 2, 3]),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/octet-stream'],
        'content-disposition': ['attachment; filename="a.bin"'],
      },
    );

    final response = await client.downloadResponse('/files/1');

    expect(response.data, [1, 2, 3]);
    expect(response.statusCode, 200);
    expect(
      response.headers.value('content-disposition'),
      contains('a.bin'),
    );
  });

  test('send 可按请求覆盖信封', () async {
    adapter.handler = (_) => _json(200, {
      'code': 0,
      'message': 'ok',
      'data': {'id': 9, 'name': 'Zoe'},
    });

    final user = await client.send(
      'GET',
      '/me',
      envelope: _envelope,
      decode: _userFromJson,
    );

    expect(user.data.name, 'Zoe');
  });

  test('page 可按请求覆盖信封', () async {
    adapter.handler = (_) => _json(200, {
      'code': 0,
      'message': 'ok',
      'data': [
        {'id': 1, 'name': 'A'},
        {'id': 2, 'name': 'B'},
      ],
    });

    final page = await client.page(
      '/users',
      query: const WPageQuery(page: 1, pageSize: 2),
      itemDecode: _userFromJson,
      envelope: _envelope,
    );

    expect(page.items.map((user) => user.name), ['A', 'B']);
  });

  test('onAuthFailure 与日志回调同时抛错时仍保留 unauthorized', () async {
    adapter.handler = (_) => _json(200, {
      'code': 401,
      'message': 'expired',
      'data': null,
    });
    WApiSettings.logErrorHandler = (_) => throw StateError('logger down');
    addTearDown(WApiSettings.reset);

    final wrapped = WApiClient(
      dio,
      envelope: const WApiEnvelopeParser(
        readCode: _readCode,
        readData: _readData,
        isSuccess: _isSuccess,
        authFailureCodes: {401},
      ),
      onAuthFailure: (_) => throw StateError('auth handler down'),
    );

    await expectLater(
      wrapped.get('/me'),
      throwsA(
        isA<WApiException>().having(
          (error) => error.kind,
          'kind',
          WApiErrorKind.unauthorized,
        ),
      ),
    );
  });

  test('page 对非法 page 抛 ArgumentError（release 守护）', () async {
    await expectLater(
      client.page(
        '/users',
        query: const _InvalidPageQuery(),
        itemDecode: _userFromJson,
      ),
      throwsArgumentError,
    );
  });

  test('WApiDecoders 提供常用 helper', () {
    final users = WApiDecoders.listOf(_userFromJson)([
      {'id': 1, 'name': 'A'},
    ]);
    expect(users.single.name, 'A');

    expect(WApiDecoders.jsonMap({'a': 1}), {'a': 1});
    expect(WApiDecoders.nullable(_userFromJson)(null), isNull);
    WApiDecoders.none({'ignored': true});
  });
}

class _InvalidPageQuery extends WPageQuery {
  const _InvalidPageQuery();

  @override
  int get page => 0;
}

class _User {
  const _User({required this.id, required this.name});

  factory _User.fromJson(Map<String, dynamic> json) => _User(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
  );

  final int id;
  final String name;
}

_User _userFromJson(Object? json) => _User.fromJson(json as Map<String, dynamic>);

const _envelope = WApiEnvelopeParser(
  readCode: _readCode,
  readData: _readData,
  isSuccess: _isSuccess,
  readMessage: _readMessage,
);

const _brokenEnvelope = WApiEnvelopeParser(
  readCode: _boom,
  readData: _readData,
  isSuccess: _isSuccess,
);

Object? _readCode(Object? json) => (json as Map)['code'];
Object? _readData(Object? json) => (json as Map)['data'];
String? _readMessage(Object? json) => (json as Map)['message'] as String?;
bool _isSuccess(Object? code) => code == 0 || code == 200;
Object? _boom(Object? json) => throw StateError('bad envelope');

class _RecordingAdapter implements HttpClientAdapter {
  ResponseBody Function(RequestOptions options)? handler;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return handler?.call(options) ?? _json(200, null);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(
  int status,
  Object? body, {
  Map<String, List<String>>? headers,
}) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
    ...?headers,
  },
);
