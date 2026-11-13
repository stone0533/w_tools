import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_api/w_tools_api.dart';
import 'package:w_tools_api_example/real_world/api_exception.dart';
import 'package:w_tools_api_example/real_world/app_api.dart';
import 'package:w_tools_api_example/real_world/token_store.dart';
import 'package:w_tools_api_example/real_world/user_repository.dart';

void main() {
  const baseUrl = 'https://api.example.com';
  late _MockApi adapter;
  late MemoryTokenStore store;
  late AppApi api;
  var authFailures = 0;

  setUp(() async {
    adapter = _MockApi();
    store = MemoryTokenStore();
    authFailures = 0;
    api = await AppApi.init(
      baseUrl: baseUrl,
      tokenStore: store,
      adapter: adapter,
      enableLog: false,
      onAuthFailure: () => authFailures++,
    );
  });

  tearDown(() {
    AppApi.dispose(baseUrl);
    WApiSettings.reset();
  });

  UserRepository newRepository() => UserRepository(
    localDataSource: UserLocalDataSource(),
    remoteDataSource: UserRemoteDataSource(api.dio),
  );

  test('登录成功后凭证写入 TokenStore', () async {
    final session = await api.login(username: 'ada', password: 'secret');

    expect(session.accessToken, 'access-1');
    expect(session.refreshToken, 'refresh-1');
    expect(session.expiry, isNotNull);
    expect(store.accessToken, 'access-1');
    expect(store.refreshToken, 'refresh-1');
    expect(store.expiry, isNotNull);
  });

  test('首个业务请求 401：自动刷新并重试，只刷新一次', () async {
    await api.login(username: 'ada', password: 'secret');
    final users = newRepository();

    final user = await users.me();

    expect(user.name, 'Ada');
    expect(adapter.meRequests, 2);
    expect(adapter.refreshRequests, 1);
    expect(store.accessToken, 'access-2');
    expect(store.refreshToken, 'refresh-2');
    expect(authFailures, 0);
  });

  test('并发 401 共享同一次刷新（single-flight）', () async {
    await api.login(username: 'ada', password: 'secret');
    final users = newRepository();

    final result = await Future.wait([users.me(), users.me()]);

    expect(result.every((user) => user.name == 'Ada'), isTrue);
    expect(adapter.refreshRequests, 1);
    expect(authFailures, 0);
  });

  test('刷新失败：触发 onAuthFailure，并把错误映射成 unauthorized', () async {
    adapter.refreshShouldFail = true;
    await api.login(username: 'ada', password: 'secret');
    final users = newRepository();

    await expectLater(
      users.me(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.kind,
          'kind',
          ApiErrorKind.unauthorized,
        ),
      ),
    );
    expect(authFailures, 1);
  });

  test('Repository 命中本地缓存后不再发请求', () async {
    await api.login(username: 'ada', password: 'secret');
    final users = newRepository();

    await users.me();
    final requestsAfterFirst = adapter.meRequests;
    final cached = await users.me();

    expect(cached.name, 'Ada');
    expect(adapter.meRequests, requestsAfterFirst);
    expect(users.localDataSource?.cached?.name, 'Ada');
  });
}

/// 模拟服务端：
/// - `/auth/login` 签发 access-1 / refresh-1；
/// - 业务接口只认 access-2，所以第一次 `/me` 必然 401；
/// - `/auth/refresh` 用 refresh-1 换 access-2 / refresh-2。
class _MockApi implements HttpClientAdapter {
  int meRequests = 0;
  int refreshRequests = 0;
  bool refreshShouldFail = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    switch (options.path) {
      case '/auth/login':
        return _json(200, {
          'accessToken': 'access-1',
          'refreshToken': 'refresh-1',
          'expiresIn': 3600,
        });
      case '/auth/refresh':
        refreshRequests++;
        final body = _decodeBody(options.data);
        final refreshToken = body is Map ? body['refreshToken'] : null;
        if (refreshShouldFail || refreshToken != 'refresh-1') {
          return _json(401, {'error': 'invalid refresh token'});
        }
        return _json(200, {
          'accessToken': 'access-2',
          'refreshToken': 'refresh-2',
          'expiresIn': 3600,
        });
      case '/me':
        meRequests++;
        if (options.headers['Authorization'] != 'Bearer access-2') {
          return _json(401, {'error': 'unauthorized'});
        }
        return _json(200, {
          'id': 1,
          'name': 'Ada',
          'email': 'ada@example.com',
        });
      default:
        return _json(404, {'error': 'not found'});
    }
  }

  Object? _decodeBody(Object? data) {
    if (data is! String) return data;
    try {
      return jsonDecode(data);
    } on FormatException {
      return data;
    }
  }

  ResponseBody _json(int status, Map<String, Object?> body) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );

  @override
  void close({bool force = false}) {}
}
