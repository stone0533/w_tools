import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_api/w_tools_api.dart';

/// 最简单的 mock HttpClientAdapter — 返回固定响应
class _First401ThenOkAdapter implements HttpClientAdapter {
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
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

class _MockAdapter implements HttpClientAdapter {
  final int statusCode;
  final String responseBody = '{"ok": true}';
  final Map<String, List<String>> responseHeaders = const {};

  _MockAdapter({this.statusCode = 200});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // 记录收到的请求头和 contentType
    _lastRequestHeaders = Map<String, String>.from(options.headers);
    _lastContentType = options.contentType;

    return ResponseBody(
      Stream.value(Uint8List.fromList(utf8.encode(responseBody))),
      statusCode,
      headers: responseHeaders,
    );
  }

  @override
  void close({bool force = false}) {}

  Map<String, String>? _lastRequestHeaders;
  String? _lastContentType;
}

void main() {
  tearDown(DioRegistry.clearCache);

  group('WTokenInterceptor', () {
    test('onRequest 添加 Authorization header', () async {
      final adapter = _MockAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(
        WTokenInterceptor(
          dio: dio,
          tokenGetter: () => 'my_token_value',
        ),
      );

      await dio.get('https://example.com/api');

      expect(
        adapter._lastRequestHeaders!['Authorization'],
        'Bearer my_token_value',
      );
    });

    test('onRequest 设置 contentType 为 application/json', () async {
      final adapter = _MockAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(
        WTokenInterceptor(
          dio: dio,
          tokenGetter: () => 'token',
        ),
      );

      await dio.post('https://example.com/api', data: {'a': 1});

      // 拦截器只对 Map/String body 推断 json
      expect(adapter._lastContentType, 'application/json');
    });

    test('tokenGetter 返回 null 时不添加 Authorization', () async {
      final adapter = _MockAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(
        WTokenInterceptor(
          dio: dio,
          tokenGetter: () => null,
        ),
      );

      await dio.get('https://example.com/api');

      expect(adapter._lastRequestHeaders!['Authorization'], isNull);
    });

    test('tokenGetter 返回空串时不添加 Authorization', () async {
      final adapter = _MockAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(
        WTokenInterceptor(
          dio: dio,
          tokenGetter: () => '',
        ),
      );

      await dio.get('https://example.com/api');

      expect(adapter._lastRequestHeaders!['Authorization'], isNull);
    });

    test('显式 Authorization header 不被 tokenGetter 覆盖', () async {
      final adapter = _MockAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(
        WTokenInterceptor(dio: dio, tokenGetter: () => 'auto-token'),
      );

      await dio.get(
        'https://example.com/api',
        options: Options(headers: {'Authorization': 'Custom abc'}),
      );

      expect(adapter._lastRequestHeaders!['Authorization'], 'Custom abc');
    });

    test('onError 401 时触发 tokenClearer', () async {
      int clearCount = 0;

      final adapter = _MockAdapter(statusCode: 401);
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(
        WTokenInterceptor(
          dio: dio,
          tokenGetter: () => 'expired_token',
          tokenClearer: () async {
            clearCount++;
          },
          tokenRefresher: () async => null, // 刷新失败 → 不触发重试（避免真实网络）
        ),
      );

      await expectLater(
        dio.get('https://example.com/api'),
        throwsA(isA<DioException>()),
      );

      expect(clearCount, 1);
    });

    test('tokenRefresher 为 null 时仍清除 token 并结束', () async {
      var clearCount = 0;
      final dio = Dio()..httpClientAdapter = _MockAdapter(statusCode: 401);
      dio.interceptors.add(
        WTokenInterceptor(
          dio: dio,
          tokenGetter: () => 'expired',
          tokenClearer: () async => clearCount++,
        ),
      );

      await expectLater(
        dio.get('https://example.com/api'),
        throwsA(isA<DioException>()),
      );
      expect(clearCount, 1);
    });

    test('maxAuthRetries=0 时清除 token 但不重试', () async {
      var clearCount = 0;
      var refreshCount = 0;
      final dio = Dio()..httpClientAdapter = _MockAdapter(statusCode: 401);
      dio.interceptors.add(
        WTokenInterceptor(
          dio: dio,
          tokenGetter: () => 'expired',
          tokenClearer: () async => clearCount++,
          tokenRefresher: () async {
            refreshCount++;
            return 'new';
          },
          maxAuthRetries: 0,
        ),
      );

      await expectLater(
        dio.get('https://example.com/api'),
        throwsA(isA<DioException>()),
      );
      expect(clearCount, 1);
      expect(refreshCount, 0);
    });

    test('tokenRefresher 抛异常时不逃逸，请求以原错误结束', () async {
      final adapter = _MockAdapter(statusCode: 401);
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(
        WTokenInterceptor(
          dio: dio,
          tokenGetter: () => 'expired_token',
          tokenRefresher: () async => throw StateError('refresh failed'),
        ),
      );

      await expectLater(
        dio.get('https://example.com/api'),
        throwsA(isA<DioException>()),
      );
    });

    test('并发 401 只触发一次 tokenRefresher（single-flight）', () async {
      int authErrorCalled = 0;

      final adapter = _MockAdapter(statusCode: 401);
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(
        WTokenInterceptor(
          dio: dio,
          tokenGetter: () => 'expired_token',
          tokenRefresher: () async {
            authErrorCalled++;
            await Future.delayed(const Duration(milliseconds: 50));
            return null;
          },
        ),
      );

      Future<void> fire() async {
        try {
          await dio.get('https://example.com/api');
        } catch (_) {}
      }

      await Future.wait([fire(), fire(), fire()]);

      expect(authErrorCalled, 1, reason: '并发 401 应共享同一次刷新');
    });

    test('长度正好 10 的 token 不在日志中完整输出', () async {
      final logs = <String>[];
      WApiSettings.logDebugHandler = (m) => logs.add(m.toString());

      final dio = Dio()..httpClientAdapter = _MockAdapter();
      dio.interceptors.add(
        WTokenInterceptor(tokenGetter: () => '1234567890'),
      );

      await dio.get('https://example.com/api');
      await Future.microtask(() {});

      expect(logs.join(), isNot(contains('1234567890')));
      expect(logs.join(), contains('***'));
    });

    test('FormData 请求 401 后能成功重放（不再因 finalize 抛错）', () async {
      // 同一个 Dio：第一次 401，重放时 200
      final adapter = _First401ThenOkAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://retry.example.com'))
        ..httpClientAdapter = adapter;
      dio.interceptors.add(
        WTokenInterceptor(
          dio: dio,
          tokenGetter: () => 'expired_token',
          tokenRefresher: () async => 'new_token',
        ),
      );

      final res = await dio.post(
        '/upload',
        data: FormData.fromMap({'a': 'b'}),
      );

      // 修复前：重放时 FormData 已 finalize → StateError → 请求以 401 失败
      expect(res.statusCode, 200);
      expect(adapter.calls, 2);
    });

    test('registry 创建时自动绑定 WTokenInterceptor，401 重试成功', () async {
      final adapter = _First401ThenOkAdapter();
      final registry = DioRegistry.forBaseUrl(
        'https://auto-bind.example.com',
        interceptors: [
          WTokenInterceptor(
            tokenGetter: () => 'expired',
            tokenRefresher: () async => 'new',
          ),
        ],
      );
      registry.dio.httpClientAdapter = adapter;

      final res = await registry.dio.post('/x', data: {'a': 1});
      expect(res.statusCode, 200);
      expect(adapter.calls, 2);
    });

    test('未绑定 Dio 且未注册 registry 时不再隐式创建实例', () async {
      final logs = <String>[];
      WApiSettings.logErrorHandler = (dynamic message) => logs.add('$message');

      final dio = Dio(BaseOptions(baseUrl: 'https://unbound.example.com'))
        ..httpClientAdapter = _MockAdapter(statusCode: 401);
      dio.interceptors.add(
        WTokenInterceptor(
          tokenGetter: () => 'expired',
          tokenRefresher: () async => 'new',
        ),
      );

      await expectLater(dio.post('/x'), throwsA(isA<DioException>()));
      expect(DioRegistry.maybeForBaseUrl('https://unbound.example.com'), isNull);
      expect(logs.join(), contains('未绑定 Dio'));
    });

    test('body 为 Stream 时放弃重放，按原错误结束', () async {
      final logs = <String>[];
      WApiSettings.logErrorHandler = (m) => logs.add(m.toString());

      final dio = Dio(BaseOptions(baseUrl: 'https://example.com'))
        ..httpClientAdapter = _MockAdapter(statusCode: 401);
      dio.interceptors.add(
        WTokenInterceptor(
          dio: dio,
          tokenGetter: () => 'expired_token',
          tokenRefresher: () async => 'new_token',
        ),
      );

      await expectLater(
        dio.post('/upload', data: Stream<List<int>>.value([1, 2, 3])),
        throwsA(isA<DioException>()),
      );

      expect(logs.join(), contains('cannot be replayed'));
    });
  });
  group('WTokenInterceptor 边界', () {
    test('刷新接口自身 401 不会自等待死锁', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://refresh-loop.example.com'))
        ..httpClientAdapter = _MockAdapter(statusCode: 401);
      var refreshes = 0;
      dio.interceptors.add(
        WTokenInterceptor(
          dio: dio,
          tokenGetter: () => 'old',
          tokenRefresher: () async {
            refreshes++;
            await dio.get('/refresh'); // 401：不应再次触发刷新
            return 'new';
          },
        ),
      );

      await expectLater(
        dio.get('/x').timeout(const Duration(seconds: 3)),
        throwsA(isA<DioException>()),
      );
      expect(refreshes, 1);
    });

    test('二进制 body 不会被强制标成 application/json', () async {
      final adapter = _MockAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(WTokenInterceptor(tokenGetter: () => 't'));

      await dio.post('https://example.com/upload', data: Uint8List.fromList([1, 2, 3]));

      expect(adapter._lastContentType, isNot('application/json'));
    });
  });
}
