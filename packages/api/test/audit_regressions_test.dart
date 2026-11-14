import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_api/w_tools_api.dart';

/// 可配置的 mock adapter：记录请求头 / extra，按次数返回固定状态。
class _MockAdapter implements HttpClientAdapter {
  _MockAdapter({
    this.statusCode = 200,
    this.delay,
    this.unauthorizedUnlessToken,
  });

  final int statusCode;
  final Duration? delay;
  final String? unauthorizedUnlessToken;

  int calls = 0;
  Map<String, dynamic>? lastHeaders;
  Map<String, dynamic>? lastExtra;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    lastHeaders = Map<String, dynamic>.from(options.headers);
    lastExtra = Map<String, dynamic>.from(options.extra);
    if (delay != null) await Future<void>.delayed(delay!);

    final required = unauthorizedUnlessToken;
    if (required != null) {
      final ok = options.headers['Authorization'] == 'Bearer $required';
      if (!ok) {
        return ResponseBody.fromString(
          '{"error":"unauthorized"}',
          401,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      }
    }

    return ResponseBody.fromString(
      '{"ok":true}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _First401ThenOkAdapter implements HttpClientAdapter {
  final List<Map<String, dynamic>> extras = [];
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    extras.add(Map<String, dynamic>.from(options.extra));
    return ResponseBody.fromString(
      '{"ok":true}',
      calls == 1 ? 401 : 200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _SensitiveResponseAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"ok":true,"access_token":"resp-secret"}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _ThrowingToString {
  @override
  String toString() => throw StateError('log formatting should not run');
}

void main() {
  late List<String> logs;

  setUp(() {
    logs = <String>[];
    WApiSettings.logDebugHandler = (dynamic message) => logs.add('$message');
    WApiSettings.logErrorHandler = (dynamic message) => logs.add('ERR:$message');
  });

  tearDown(() {
    WApiSettings.logDebugHandler = null;
    WApiSettings.logErrorHandler = null;
    DioRegistry.clearCache();
  });

  Dio dioWith(HttpClientAdapter adapter, {String baseUrl = 'https://audit.example.com'}) {
    return Dio(BaseOptions(baseUrl: baseUrl))..httpClientAdapter = adapter;
  }

  group('API-002 tokenless 401', () {
    test('无 token 请求的晚到 401 不清掉后来登录的 token', () async {
      var token = <String?>[null];
      var clears = 0;
      final adapter = _MockAdapter(
        unauthorizedUnlessToken: 'fresh-login-token',
        delay: const Duration(milliseconds: 50),
      );
      final dio = dioWith(adapter, baseUrl: 'https://tokenless-race.example.com');
      dio.interceptors.add(
        WTokenInterceptor(
          dio: dio,
          tokenGetter: () => token[0],
          tokenClearer: () async {
            clears++;
            token[0] = null;
          },
        ),
      );

      Future<int> run() async {
        try {
          final response = await dio.get<dynamic>('/x');
          return response.statusCode ?? -1;
        } catch (_) {
          return -1;
        }
      }

      final pending = run();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      token[0] = 'fresh-login-token';
      final status = await pending;

      expect(clears, 0, reason: '不能清掉登录后刚写入的新 token');
      expect(status, 200, reason: '应使用新 token 重试');
      expect(adapter.calls, 2);
    });
  });

  group('API-005 共享拦截器', () {
    test('同一个 WTokenInterceptor 不能绑定两个 registry', () {
      final shared = WTokenInterceptor(tokenGetter: () => 'token');
      final first = DioRegistry.forBaseUrl(
        'https://bind-one.example.com',
        interceptors: [shared],
      );

      expect(
        () => DioRegistry.forBaseUrl(
          'https://bind-two.example.com',
          interceptors: [shared],
        ),
        throwsArgumentError,
      );
      expect(first.dio, isA<Dio>());
    });
  });

  group('API-003 自定义脱敏头', () {
    test('redactedHeaders 大小写不敏感', () async {
      final dio = dioWith(_MockAdapter());
      dio.interceptors.add(
        WLogInterceptor(
          parts: {WLogPart.requestHeader},
          redactedHeaders: {'X-Secret'},
        ),
      );

      await dio.get('/x', options: Options(headers: {'X-Secret': 'topsecret'}));

      expect(logs.join(), contains('X-Secret: ***'));
      expect(logs.join(), isNot(contains('topsecret')));
    });
  });

  group('API-004 parts 门禁', () {
    test('parts 只开 error 时不输出请求/响应行', () async {
      final dio = dioWith(_MockAdapter());
      dio.interceptors.add(WLogInterceptor(parts: {WLogPart.error}));

      await dio.get('/secret?token=abc123');

      expect(logs.join(), isNot(contains('*** Request ***')));
      expect(logs.join(), isNot(contains('*** Response ***')));
      expect(logs.join(), isNot(contains('token=abc123')));
    });

    test('parts 只开 requestBody 时不输出响应行', () async {
      final dio = dioWith(_MockAdapter());
      dio.interceptors.add(WLogInterceptor(parts: {WLogPart.requestBody}));

      await dio.post('/x', data: {'a': 1});

      expect(logs.join(), contains('data:'));
      expect(logs.join(), isNot(contains('*** Response ***')));
    });

    test('query 里的敏感参数默认脱敏', () async {
      final dio = dioWith(_MockAdapter());
      dio.interceptors.add(WLogInterceptor(parts: {WLogPart.requestHeader}));

      await dio.get('/x?token=abc123&page=2');

      expect(logs.join(), contains('token=***'));
      expect(logs.join(), contains('page=2'));
      expect(logs.join(), isNot(contains('abc123')));
    });

    test('sensitiveQueryKeys 默认追加默认敏感参数', () async {
      final dio = dioWith(_MockAdapter());
      dio.interceptors.add(
        WLogInterceptor(
          parts: {WLogPart.requestHeader},
          sensitiveQueryKeys: {'session'},
        ),
      );

      await dio.get('/x?session=abc123&token=keep');

      expect(logs.join(), contains('session=***'));
      expect(logs.join(), contains('token=***'));
      expect(logs.join(), isNot(contains('abc123')));
      expect(logs.join(), isNot(contains('token=keep')));
    });

    test('没有日志 handler 时不格式化 body', () {
      WApiSettings.logDebugHandler = null;
      WApiSettings.logErrorHandler = null;
      final interceptor = WLogInterceptor(parts: {WLogPart.requestBody});
      final handler = RequestInterceptorHandler();
      final options = RequestOptions(path: '/x', data: _ThrowingToString());

      expect(() => interceptor.onRequest(options, handler), returnsNormally);
    });

    test('超大 Map body 先限量再编码', () async {
      final dio = dioWith(_MockAdapter());
      dio.interceptors.add(
        WLogInterceptor(
          parts: {WLogPart.requestBody},
          maxBodyLength: 100,
        ),
      );

      await dio.post(
        '/x',
        data: {for (var i = 0; i < 1000; i++) 'k$i': 'v$i'},
      );

      final log = logs.join();
      expect(log, contains('"..."'));
      expect(log, contains('truncated'));
      expect(log.length, lessThan(1000));
    });

    test('大文本 body 会截断，避免日志体积放大', () async {
      final dio = dioWith(_MockAdapter());
      dio.interceptors.add(WLogInterceptor(parts: {WLogPart.requestBody}));

      await dio.post('/x', data: List<String>.filled(5000, 'x').join());

      expect(logs.join(), contains('truncated'));
      expect(logs.join().length, lessThan(3000));
    });

    test('maxBodyLength 可覆盖默认截断阈值', () async {
      final dio = dioWith(_MockAdapter());
      dio.interceptors.add(
        WLogInterceptor(
          parts: {WLogPart.requestBody},
          maxBodyLength: 10,
        ),
      );

      await dio.post('/x', data: List<String>.filled(50, 'x').join());

      expect(logs.join(), contains('truncated'));
      expect(logs.join(), isNot(contains('x' * 20)));
    });
  });

  group('API-007 默认 body', () {
    test('默认不打印 request/response body', () async {
      final dio = dioWith(_MockAdapter());
      dio.interceptors.add(WLogInterceptor());

      await dio.post('/x', data: {'a': 1});

      expect(logs.join(), isNot(contains('Response Text')));
      expect(logs.join(), isNot(contains('"a": 1')));
    });

    test('显式 parts 仍可打印 body', () async {
      final dio = dioWith(_MockAdapter());
      dio.interceptors.add(
        WLogInterceptor(
          parts: {WLogPart.requestBody, WLogPart.responseBody},
        ),
      );

      await dio.post('/x', data: {'a': 1});

      expect(logs.join(), contains('"a": 1'));
      expect(logs.join(), contains('Response Text'));
    });
  });

  group('API-029 body 脱敏', () {
    test('requestBody 递归脱敏且不修改原对象', () async {
      final body = <String, dynamic>{
        'email': 'a@b.c',
        'password': 'p@ss',
        'profile': {'token': 'nested'},
        'items': [
          {'access_token': 'list-token'},
        ],
        'password_policy': 'keep',
      };
      final dio = dioWith(_MockAdapter());
      dio.interceptors.add(WLogInterceptor(parts: {WLogPart.requestBody}));

      await dio.post('/login', data: body);

      final log = logs.join();
      expect(log, contains('"password": "***"'));
      expect(log, contains('"token": "***"'));
      expect(log, contains('"access_token": "***"'));
      expect(log, contains('"password_policy": "keep"'));
      expect(log, isNot(contains('p@ss')));
      expect(log, isNot(contains('nested')));
      expect(log, isNot(contains('list-token')));
      expect(body['password'], 'p@ss', reason: '不能修改调用方原始 body');
    });

    test('responseBody 也脱敏 access_token', () async {
      final dio = dioWith(_SensitiveResponseAdapter());
      dio.interceptors.add(WLogInterceptor(parts: {WLogPart.responseBody}));

      await dio.get('/login');

      expect(logs.join(), contains('"access_token": "***"'));
      expect(logs.join(), isNot(contains('resp-secret')));
    });

    test('sensitiveBodyKeys 默认追加默认值', () async {
      final dio = dioWith(_MockAdapter());
      dio.interceptors.add(
        WLogInterceptor(
          parts: {WLogPart.requestBody},
          sensitiveBodyKeys: {'session'},
        ),
      );

      await dio.post(
        '/x',
        data: {'session': 'session-secret', 'password': 'keep'},
      );

      expect(logs.join(), contains('"session": "***"'));
      expect(logs.join(), contains('"password": "***"'));
      expect(logs.join(), isNot(contains('session-secret')));
      expect(logs.join(), isNot(contains('"password": "keep"')));
    });

    test('JSON 字符串 body 也会脱敏', () async {
      final dio = dioWith(_MockAdapter());
      dio.interceptors.add(WLogInterceptor(parts: {WLogPart.requestBody}));

      await dio.post('/x', data: '{"password":"str-secret","safe":"ok"}');

      expect(logs.join(), contains('"password": "***"'));
      expect(logs.join(), contains('"safe": "ok"'));
      expect(logs.join(), isNot(contains('str-secret')));
    });

    test('FormData fields 也会脱敏', () async {
      final dio = dioWith(_MockAdapter());
      dio.interceptors.add(WLogInterceptor(parts: {WLogPart.requestBody}));

      await dio.post(
        '/x',
        data: FormData.fromMap({'password': 'form-secret', 'note': 'ok'}),
      );

      expect(logs.join(), contains('"password": "***"'));
      expect(logs.join(), contains('"note": "ok"'));
      expect(logs.join(), isNot(contains('form-secret')));
    });
  });

  group('API-008 用户回调抛异常', () {
    test('tokenClearer 抛异常不替换原始 401', () async {
      final dio = dioWith(_MockAdapter(statusCode: 401));
      dio.interceptors.add(
        WTokenInterceptor(
          dio: dio,
          tokenGetter: () => 'expired',
          tokenClearer: () async => throw StateError('storage down'),
          tokenRefresher: () async => 'new',
        ),
      );

      Object? caught;
      try {
        await dio.get<dynamic>('/x');
      } catch (error) {
        caught = error;
      }

      expect(caught, isA<DioException>());
      expect((caught! as DioException).response?.statusCode, 401);
    });

    test('日志 handler 抛异常不影响请求', () async {
      final dio = dioWith(_MockAdapter());
      dio.interceptors.add(WLogInterceptor(parts: {WLogPart.request}));
      WApiSettings.logDebugHandler = (_) => throw StateError('logger down');

      final response = await dio.get('/x');

      expect(response.statusCode, 200);
    });
  });

  group('API-020 错误响应片段', () {
    test('只开 responseBody 时错误响应 body 仍输出', () async {
      final dio = dioWith(_MockAdapter(statusCode: 500));
      dio.interceptors.add(WLogInterceptor(parts: {WLogPart.responseBody}));

      await expectLater(dio.get('/error'), throwsA(isA<DioException>()));

      expect(logs.join(), contains('"ok": true'));
      expect(logs.join(), isNot(contains('*** DioError ***')));
    });
  });

  group('API-019 内部日志 URI 脱敏', () {
    test('WTokenInterceptor 未绑定 Dio 时日志不泄露 query token', () async {
      final dio = dioWith(
        _MockAdapter(statusCode: 401),
        baseUrl: 'https://token-log.example.com',
      );
      dio.interceptors.add(
        WTokenInterceptor(
          tokenGetter: () => 'old',
          tokenClearer: () async {},
          tokenRefresher: () async => 'new',
        ),
      );

      await expectLater(
        dio.get('/x?token=secret-token'),
        throwsA(isA<DioException>()),
      );

      expect(logs.join(), isNot(contains('secret-token')));
      expect(logs.join(), contains('token=***'));
    });

    test('WRetryInterceptor 未绑定 Dio 时日志不泄露 query token', () async {
      final dio = dioWith(
        _MockAdapter(statusCode: 500),
        baseUrl: 'https://retry-log.example.com',
      );
      dio.interceptors.add(
        WRetryInterceptor(
          maxRetries: 1,
          baseDelay: Duration.zero,
          jitter: false,
        ),
      );

      await expectLater(
        dio.get('/x?access_token=secret-token'),
        throwsA(isA<DioException>()),
      );

      expect(logs.join(), isNot(contains('secret-token')));
      expect(logs.join(), contains('access_token=***'));
    });
  });

  group('API-018 DioRegistry 配置比较', () {
    test('header 大小写不同不算配置冲突', () {
      DioRegistry.forBaseUrl(
        'https://header-case.example.com',
        options: BaseOptions(headers: {'X-A': '1'}),
      );

      expect(
        () => DioRegistry.forBaseUrl(
          'https://header-case.example.com',
          options: BaseOptions(headers: {'x-a': '1'}),
        ),
        returnsNormally,
      );
    });

    test('list 值内容相同不算配置冲突，不同才算', () {
      DioRegistry.forBaseUrl(
        'https://list-value.example.com',
        options: BaseOptions(
          queryParameters: {
            'a': [1, 2],
          },
        ),
      );

      expect(
        () => DioRegistry.forBaseUrl(
          'https://list-value.example.com',
          options: BaseOptions(
            queryParameters: {
              'a': [1, 2],
            },
          ),
        ),
        returnsNormally,
      );
      expect(
        () => DioRegistry.forBaseUrl(
          'https://list-value.example.com',
          options: BaseOptions(
            queryParameters: {
              'a': [1, 3],
            },
          ),
        ),
        throwsArgumentError,
      );
    });
  });

  group('API-022 retry 计数键', () {
    test('不覆盖用户同名 extra 键', () async {
      final adapter = _First401ThenOkAdapter();
      final dio = dioWith(adapter, baseUrl: 'https://retry-key.example.com');
      dio.interceptors.add(
        WTokenInterceptor(
          dio: dio,
          tokenGetter: () => 'old',
          tokenRefresher: () async => 'new',
        ),
      );

      await dio.get<dynamic>(
        '/x',
        options: Options(extra: {'_retryCount': 99, 'user': true}),
      );

      expect(adapter.calls, 2);
      expect(adapter.extras[1]['_retryCount'], 99);
      expect(adapter.extras[1]['user'], true);
      expect(adapter.extras[1]['_w_tools_auth_retry_count'], 1);
    });
  });

  group('API-023 parts 不可变', () {
    test('parts 不能被外部修改', () {
      final interceptor = WLogInterceptor(parts: {WLogPart.request});

      expect(
        () => interceptor.parts!.add(WLogPart.error),
        throwsUnsupportedError,
      );
    });
  });

  group('API-026 token 日志', () {
    test('长 token 不输出前缀', () async {
      final dio = dioWith(_MockAdapter());
      dio.interceptors.add(
        WTokenInterceptor(tokenGetter: () => 'abcdefghij-secret-tail'),
      );

      await dio.get('/x');

      expect(logs.join(), isNot(contains('abcdefghij')));
      expect(logs.join(), contains('***'));
    });
  });

  group('API-028 默认脱敏头', () {
    test('x-auth-token 默认脱敏', () async {
      final dio = dioWith(_MockAdapter());
      dio.interceptors.add(
        WLogInterceptor(parts: {WLogPart.requestHeader}),
      );

      await dio.get(
        '/x',
        options: Options(headers: {'x-auth-token': 'secret-auth-token'}),
      );

      expect(logs.join(), contains('x-auth-token: ***'));
      expect(logs.join(), isNot(contains('secret-auth-token')));
    });
  });
}
