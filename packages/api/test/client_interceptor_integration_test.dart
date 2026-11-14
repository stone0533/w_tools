import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_api/w_tools_api.dart';

void main() {
  late _Harness harness;

  setUp(() {
    harness = _Harness();
  });

  test('401 刷新后由 token 拦截器重试，retry 不重复处理', () async {
    final user = await harness.client.get('/secure', decode: _userFromJson);

    expect(user.name, 'Ada');
    expect(harness.adapter.secureCalls, 2);
    expect(harness.adapter.refreshCalls, 1);
    expect(harness.authFailures, 0);
  });

  test('500 由 retry 重试成功', () async {
    final ok = await harness.client.get(
      '/flaky',
      decode: (json) => (json as Map)['ok'] as bool,
    );

    expect(ok, isTrue);
    expect(harness.adapter.flakyCalls, 2);
  });

  test('刷新失败触发 onAuthFailure，且不会无限重试', () async {
    final failing = _Harness(failRefresh: true);

    await expectLater(
      failing.client.get('/secure'),
      throwsA(
        isA<WApiException>().having(
          (error) => error.kind,
          'kind',
          WApiErrorKind.unauthorized,
        ),
      ),
    );
    expect(failing.adapter.secureCalls, 1);
    expect(failing.adapter.refreshCalls, 1);
    expect(failing.authFailures, 1);
  });

  test('刷新成功后重试请求失败：保留真实错误，不误触发 onAuthFailure', () async {
    var calls = 0;
    var authFailures = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://auth.test'));
    dio.httpClientAdapter = _CallbackAdapter(() {
      calls++;
      if (calls == 1) {
        return _jsonResponse(401, {'error': 'unauthorized'});
      }
      return _jsonResponse(500, {'error': 'boom'});
    });
    dio.interceptors.add(
      WTokenInterceptor(
        dio: dio,
        tokenGetter: () => 'expired',
        tokenClearer: () async {},
        tokenRefresher: () async => 'fresh',
        onAuthFailure: (_) => authFailures++,
      ),
    );

    await expectLater(
      WApiClient(dio).get('/secure'),
      throwsA(
        isA<WApiException>()
            .having((error) => error.kind, 'kind', WApiErrorKind.server)
            .having((error) => error.statusCode, 'statusCode', 500),
      ),
    );

    expect(calls, 2);
    expect(authFailures, 0, reason: '刷新成功，认证已恢复，不应登出');
  });

  test('download 遇到 401 也会刷新并返回 bytes', () async {
    final bytes = (await harness.client.downloadResponse('/file')).data;

    expect(bytes, [1, 2, 3]);
    expect(harness.adapter.fileCalls, 2);
    expect(harness.adapter.refreshCalls, 1);
  });
}

_User _userFromJson(Object? json) => _User.fromJson(json as Map<String, dynamic>);

class _User {
  const _User({required this.id, required this.name});

  factory _User.fromJson(Map<String, dynamic> json) => _User(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
  );

  final int id;
  final String name;
}

/// 组装 token + retry + WApiClient；刷新请求走同一个 dio（拦截器用 zone 防递归）。
class _Harness {
  _Harness({bool failRefresh = false}) : adapter = _AuthAdapter(failRefresh: failRefresh) {
    dio = Dio(BaseOptions(baseUrl: 'https://auth.test'));
    dio.httpClientAdapter = adapter;
    token = 'expired';

    final tokenInterceptor = WTokenInterceptor(
      tokenGetter: () => token,
      tokenClearer: () async => token = '',
      tokenRefresher: () async {
        final response = await dio.post<Map<String, dynamic>>('/auth/refresh');
        token = response.data!['token'] as String;
        return token;
      },
      onAuthFailure: (_) => authFailures++,
    );
    final retryInterceptor = WRetryInterceptor(
      maxRetries: 2,
      baseDelay: Duration.zero,
      jitter: false,
    );

    dio.interceptors.addAll([tokenInterceptor, retryInterceptor]);
    tokenInterceptor.bindDio(dio);
    retryInterceptor.bindDio(dio);
    client = WApiClient(dio);
  }

  final _AuthAdapter adapter;
  late final Dio dio;
  late final WApiClient client;
  late String token;
  int authFailures = 0;
}

class _AuthAdapter implements HttpClientAdapter {
  _AuthAdapter({this.failRefresh = false});

  final bool failRefresh;
  int secureCalls = 0;
  int flakyCalls = 0;
  int fileCalls = 0;
  int refreshCalls = 0;
  static const _validToken = 'fresh';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final auth = options.headers['Authorization'];

    switch (options.path) {
      case '/auth/refresh':
        refreshCalls++;
        if (failRefresh) return _json(401, {'error': 'refresh failed'});
        return _json(200, {'token': _validToken});
      case '/secure':
        secureCalls++;
        if (auth != 'Bearer $_validToken') {
          return _json(401, {'error': 'unauthorized'});
        }
        return _json(200, {'id': 1, 'name': 'Ada'});
      case '/flaky':
        flakyCalls++;
        if (flakyCalls == 1) return _json(500, {'error': 'boom'});
        return _json(200, {'ok': true});
      case '/file':
        fileCalls++;
        if (auth != 'Bearer $_validToken') {
          return _json(401, {'error': 'unauthorized'});
        }
        return ResponseBody.fromBytes(
          Uint8List.fromList([1, 2, 3]),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/octet-stream'],
          },
        );
      default:
        return _json(404, {'error': 'not found'});
    }
  }

  ResponseBody _json(int status, Object? body) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(int status, Object? body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

class _CallbackAdapter implements HttpClientAdapter {
  _CallbackAdapter(this._respond);

  final ResponseBody Function() _respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => _respond();

  @override
  void close({bool force = false}) {}
}
