import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_api/w_tools_api.dart';

/// 最简单的 mock HttpClientAdapter — 返回固定响应
class _MockAdapter implements HttpClientAdapter {
  final int statusCode;
  final String responseBody;
  final Map<String, List<String>> responseHeaders;

  _MockAdapter({
    this.statusCode = 200,
    this.responseBody = '{"ok": true}',
    this.responseHeaders = const {},
  });

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
  // === 测试后清理 DioRegistry 缓存 ===
  tearDown(() {
    WApiConfig.logDebugHandler = null;
    WApiConfig.logErrorHandler = null;
    DioRegistry.clearCache();
  });

  group('WLogInterceptor', () {
    test('enableLog=false 时不输出日志', () async {
      List<String> logs = [];
      WApiConfig.logDebugHandler = (m) => logs.add(m.toString());
      WApiConfig.logErrorHandler = (m) => logs.add('E:${m.toString()}');

      final adapter = _MockAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(WLogInterceptor(enableLog: false));

      await dio.get('https://example.com/api');
      await Future.microtask(() {}); // 让异步 handler 跑完

      expect(logs, isEmpty);
    });

    test('enableLog=true 时输出请求日志', () async {
      List<String> logs = [];
      WApiConfig.logDebugHandler = (m) => logs.add(m.toString());

      final adapter = _MockAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(WLogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
      ));

      await dio.get('https://example.com/api');
      await Future.microtask(() {});

      expect(logs, isNotEmpty);
      expect(logs.any((l) => l.contains('*** Request ***')), true);
    });

    test('request=false 时不打印请求详情', () async {
      List<String> logs = [];
      WApiConfig.logDebugHandler = (m) => logs.add(m.toString());

      final adapter = _MockAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(WLogInterceptor(
        request: false,
        requestHeader: false,
        requestBody: false,
      ));

      await dio.get('https://example.com/api');
      await Future.microtask(() {});

      // 没有 request 详情 — 只含 uri
      for (final log in logs) {
        if (log.contains('Request')) {
          expect(log, isNot(contains('method')));
        }
      }
    });

    test('onError 时输出错误日志', () async {
      List<String> logs = [];
      WApiConfig.logErrorHandler = (m) => logs.add(m.toString());

      // 用真实 Dio 发一个无效 URL 触发连接错误（不经过 adapter）
      // 但为了不发真网络请求，我们让 adapter 抛异常
      final adapter = _ErrorAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(WLogInterceptor(error: true));

      try {
        await dio.get('https://example.com/api');
      } catch (_) {}
      await Future.microtask(() {});

      expect(logs, isNotEmpty);
    });

    test('error=false 时不输出原始错误 dump，但仍输出友好提示', () async {
      List<String> logs = [];
      WApiConfig.logErrorHandler = (m) => logs.add(m.toString());

      final adapter = _ErrorAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(WLogInterceptor(error: false));

      try {
        await dio.get('https://example.com/api');
      } catch (_) {}
      await Future.microtask(() {});

      // error=false 时不输出 *** DioError *** 原始 dump
      expect(
        logs.any((l) => l.contains('*** DioError ***')),
        false,
      );
      // 但 _handleError 仍无条件调用
      expect(logs, isNotEmpty);
    });

    test('response.data 为 List<String> 时不抛异常，且输出合法 JSON', () async {
      final logs = <String>[];
      WApiConfig.logDebugHandler = (m) => logs.add(m.toString());

      final adapter = _MockAdapter(
        responseBody: '["a","b"]',
        responseHeaders: {
          'content-type': ['application/json'],
        },
      );
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(WLogInterceptor());

      // 回归：此前 response.toString() → [a, b] 会被 jsonDecode 抛 FormatException
      final res = await dio.get('https://example.com/api');

      expect(res.data, isA<List<dynamic>>());
      // List 元素带引号，说明输出的是合法 JSON
      expect(logs.join(), contains('"a"'));
    });

    test('response.data 为 List<Map> 时不抛异常', () async {
      final logs = <String>[];
      WApiConfig.logDebugHandler = (m) => logs.add(m.toString());

      final adapter = _MockAdapter(
        responseBody: '[{"id":1}]',
        responseHeaders: {
          'content-type': ['application/json'],
        },
      );
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(WLogInterceptor());

      final res = await dio.get('https://example.com/api');

      expect(res.data, isA<List<dynamic>>());
      expect(logs.join(), contains('"id"'));
    });

    test('响应体为非法 JSON 文本时不抛异常，按原文输出', () async {
      final logs = <String>[];
      WApiConfig.logDebugHandler = (m) => logs.add(m.toString());

      final adapter = _MockAdapter(
        responseBody: '{oops}',
        responseHeaders: {
          'content-type': ['text/plain'],
        },
      );
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(WLogInterceptor());

      final res = await dio.get('https://example.com/api');

      expect(res.data, '{oops}');
      expect(logs.join(), contains('{oops}'));
    });
  });

  group('WTokenInterceptor', () {
    test('onRequest 添加 Authorization header', () async {
      final adapter = _MockAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(WTokenInterceptor(
        tokenGetter: () => 'my_token_value',
      ));

      await dio.get('https://example.com/api');

      expect(
        adapter._lastRequestHeaders!['Authorization'],
        'Bearer my_token_value',
      );
    });

    test('onRequest 设置 contentType 为 application/json', () async {
      final adapter = _MockAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(WTokenInterceptor(
        tokenGetter: () => 'token',
      ));

      await dio.get('https://example.com/api');

      // 拦截器在请求级 options.contentType 上设置
      expect(adapter._lastContentType, 'application/json');
    });

    test('tokenGetter 返回 null 时不添加 Authorization', () async {
      final adapter = _MockAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(WTokenInterceptor(
        tokenGetter: () => null,
      ));

      await dio.get('https://example.com/api');

      expect(adapter._lastRequestHeaders!['Authorization'], isNull);
    });

    test('tokenGetter 返回空串时不添加 Authorization', () async {
      final adapter = _MockAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(WTokenInterceptor(
        tokenGetter: () => '',
      ));

      await dio.get('https://example.com/api');

      expect(adapter._lastRequestHeaders!['Authorization'], isNull);
    });

    test('configureRequest 回调被调用', () async {
      RequestOptions? captured;
      final adapter = _MockAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(WTokenInterceptor(
        tokenGetter: () => 'token',
        configureRequest: (opts) {
          captured = opts;
          opts.headers['X-Custom'] = 'injected';
        },
      ));

      await dio.get('https://example.com/api');

      expect(captured, isNotNull);
      expect(adapter._lastRequestHeaders!['X-Custom'], 'injected');
    });

    test('onError 401 时触发 tokenClearer', () async {
      int clearCount = 0;

      final adapter = _MockAdapter(statusCode: 401);
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(WTokenInterceptor(
        tokenGetter: () => 'expired_token',
        tokenClearer: () async {
          clearCount++;
        },
        tokenRefresher: () async => null, // 刷新失败 → 不触发重试（避免真实网络）
      ));

      await expectLater(
        dio.get('https://example.com/api'),
        throwsA(isA<DioException>()),
      );

      expect(clearCount, 1);
    });

    test('同时提供 observeError 与 tokenRefresher 时，401 仍会刷新（不再互斥）', () async {
      int errorHandlerCalled = 0;
      int authErrorCalled = 0;

      final adapter = _MockAdapter(statusCode: 401);
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(WTokenInterceptor(
        tokenGetter: () => 'expired_token',
        observeError: (err) => errorHandlerCalled++,
        tokenRefresher: () async {
          authErrorCalled++;
          return null; // 刷新失败 → 不触发重试（避免真实网络）
        },
      ));

      await expectLater(
        dio.get('https://example.com/api'),
        throwsA(isA<DioException>()),
      );

      expect(errorHandlerCalled, 1, reason: '错误观测回调应被调用');
      expect(authErrorCalled, 1, reason: '401 仍应触发刷新，二者不再互斥');
    });

    test('tokenRefresher 抛异常时不逃逸，请求以原错误结束', () async {
      final adapter = _MockAdapter(statusCode: 401);
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(WTokenInterceptor(
        tokenGetter: () => 'expired_token',
        tokenRefresher: () async => throw StateError('refresh failed'),
      ));

      await expectLater(
        dio.get('https://example.com/api'),
        throwsA(isA<DioException>()),
      );
    });

    test('并发 401 只触发一次 tokenRefresher（single-flight）', () async {
      int authErrorCalled = 0;

      final adapter = _MockAdapter(statusCode: 401);
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(WTokenInterceptor(
        tokenGetter: () => 'expired_token',
        tokenRefresher: () async {
          authErrorCalled++;
          await Future.delayed(const Duration(milliseconds: 50));
          return null;
        },
      ));

      Future<void> fire() async {
        try {
          await dio.get('https://example.com/api');
        } catch (_) {}
      }

      await Future.wait([fire(), fire(), fire()]);

      expect(authErrorCalled, 1, reason: '并发 401 应共享同一次刷新');
    });

    test('FormData 请求 401 后能成功重放（不再因 finalize 抛错）', () async {
      // 重放目标：DioRegistry 缓存的实例，adapter 返回 200
      final retryTarget = DioRegistry.forBaseUrl('https://retry.example.com');
      retryTarget.dio.httpClientAdapter = _MockAdapter();

      // 首个 Dio：返回 401
      final dio = Dio(BaseOptions(baseUrl: 'https://retry.example.com'))
        ..httpClientAdapter = _MockAdapter(statusCode: 401);
      dio.interceptors.add(WTokenInterceptor(
        tokenGetter: () => 'expired_token',
        tokenRefresher: () async => 'new_token',
      ));

      final res = await dio.post(
        '/upload',
        data: FormData.fromMap({'a': 'b'}),
      );

      // 修复前：重放时 FormData 已 finalize → StateError → 请求以 401 失败
      expect(res.statusCode, 200);
    });

    test('body 为 Stream 时放弃重放，按原错误结束', () async {
      final logs = <String>[];
      WApiConfig.logErrorHandler = (m) => logs.add(m.toString());

      final dio = Dio(BaseOptions(baseUrl: 'https://example.com'))
        ..httpClientAdapter = _MockAdapter(statusCode: 401);
      dio.interceptors.add(WTokenInterceptor(
        tokenGetter: () => 'expired_token',
        tokenRefresher: () async => 'new_token',
      ));

      await expectLater(
        dio.post('/upload', data: Stream<List<int>>.value([1, 2, 3])),
        throwsA(isA<DioException>()),
      );

      expect(logs.join(), contains('cannot be replayed'));
    });
  });
}

/// 抛 DioException 的 mock adapter
class _ErrorAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException.connectionError(
      requestOptions: options,
      reason: 'Mock connection error',
    );
  }

  @override
  void close({bool force = false}) {}
}
