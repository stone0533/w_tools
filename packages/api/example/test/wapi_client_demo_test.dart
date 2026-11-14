import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_api/w_tools_api.dart';
import 'package:w_tools_api_example/wapi_client_demo.dart';

void main() {
  late _DemoAdapter adapter;
  late DemoUserApi api;

  setUp(() {
    adapter = _DemoAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.httpClientAdapter = adapter;
    api = DemoUserApi(WApiClient(dio));
  });

  test('GET 带 path / query 并解码模型', () async {
    final user = await api.me(id: 7);

    expect(user.name, 'Ada');
    expect(adapter.last!.path, '/users/7');
    expect(adapter.last!.queryParameters, {'include': 'profile'});
  });

  test('POST 发送 JSON 并解码', () async {
    final user = await api.create('Grace');

    expect(user.name, 'Grace');
    expect(adapter.last!.method, 'POST');
    expect(adapter.last!.data, {'name': 'Grace'});
  });

  test('DELETE 无响应体', () async {
    await api.remove(7);

    expect(adapter.last!.method, 'DELETE');
    expect(adapter.last!.path, '/users/7');
  });

  test('分页请求带 page / pageSize 并解析列表', () async {
    final page = await api.page(page: 1, pageSize: 2);

    expect(page.items.length, 2);
    expect(page.hasMore, isTrue);
    expect(adapter.last!.queryParameters, {'page': 1, 'pageSize': 2});
  });

  test('上传使用 multipart', () async {
    await api.uploadAvatar([1, 2, 3]);

    final data = adapter.last!.data;
    expect(data, isA<FormData>());
    final form = data as FormData;
    expect(form.fields.single.value, 'avatar');
    expect(form.files.single.key, 'file');
  });

  test('send 保留 status / headers', () async {
    final response = await api.meRaw(id: 7);

    expect(response.data.name, 'Ada');
    expect(response.statusCode, 200);
    expect(response.headers.value('x-request-id'), 'req-1');
  });

  test('send 可按请求覆盖信封', () async {
    final user = await api.meWithEnvelope(id: 7);

    expect(user.name, 'Ada');
  });

  test('page 可从响应头读 total', () async {
    final page = await api.pageWithHeaderTotal(page: 1, pageSize: 2);

    expect(page.total, 3);
    expect(page.hasMore, isTrue);
  });

  test('downloadResponse 保留 headers', () async {
    final response = await api.downloadAvatar();

    expect(response.data, [1, 2, 3]);
    expect(response.statusCode, 200);
    expect(response.headers.value('content-disposition'), contains('avatar.png'));
  });
}

class _DemoAdapter implements HttpClientAdapter {
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    if (options.method == 'DELETE') {
      return ResponseBody.fromString('', 204);
    }
    if (options.method == 'GET' && options.path == '/users/me/avatar') {
      return ResponseBody.fromBytes(
        Uint8List.fromList([1, 2, 3]),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/octet-stream'],
          'content-disposition': ['attachment; filename="avatar.png"'],
        },
      );
    }

    if (options.method == 'GET' && options.path.startsWith('/envelope/users/')) {
      return _json({
        'code': 0,
        'message': 'ok',
        'data': {'id': 7, 'name': 'Ada'},
      });
    }

    if (options.method == 'GET' && options.path == '/users') {
      return _json(
        {
          'items': [
            {'id': 1, 'name': 'Ada'},
            {'id': 2, 'name': 'Grace'},
          ],
          'total': 3,
        },
        headers: {
          'x-total-count': ['3'],
        },
      );
    }

    final body = options.path == '/users' ? {'id': 8, 'name': 'Grace'} : {'id': 7, 'name': 'Ada'};
    return _json(
      body,
      headers: {
        'x-request-id': ['req-1'],
      },
    );
  }

  ResponseBody _json(
    Object? body, {
    Map<String, List<String>>? headers,
  }) => ResponseBody.fromString(
    jsonEncode(body),
    200,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
      ...?headers,
    },
  );

  @override
  void close({bool force = false}) {}
}
