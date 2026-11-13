import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_api/w_tools_api.dart';

void main() {
  tearDown(() {
    DioRegistry.clearCache();
  });

  group('DioRegistry 配置冲突', () {
    test('命中缓存但 BaseOptions 不同时报错', () {
      DioRegistry.forBaseUrl(
        'https://conflict.example.com',
        options: BaseOptions(connectTimeout: const Duration(seconds: 1)),
      );

      expect(
        () => DioRegistry.forBaseUrl(
          'https://conflict.example.com',
          options: BaseOptions(connectTimeout: const Duration(seconds: 2)),
        ),
        throwsArgumentError,
      );
    });

    test('相同 BaseOptions 命中缓存不报错', () {
      final first = DioRegistry.forBaseUrl(
        'https://same.example.com',
        options: BaseOptions(connectTimeout: const Duration(seconds: 1)),
      );
      final second = DioRegistry.forBaseUrl(
        'https://same.example.com',
        options: BaseOptions(connectTimeout: const Duration(seconds: 1)),
      );
      expect(first, same(second));
    });

    test('命中缓存但 interceptors 不同时报错', () {
      final log = WLogInterceptor(enableLog: false);
      DioRegistry.forBaseUrl('https://interceptor-conflict.example.com', interceptors: [log]);

      expect(
        () => DioRegistry.forBaseUrl(
          'https://interceptor-conflict.example.com',
          interceptors: [WLogInterceptor(enableLog: false)],
        ),
        throwsArgumentError,
      );
    });
  });

  group('DioRegistry', () {
    test('同一个 baseUrl 返回同一个实例', () {
      final util1 = DioRegistry.forBaseUrl('https://api.example.com');
      final util2 = DioRegistry.forBaseUrl('https://api.example.com');
      expect(util1, same(util2));
    });

    test('不同 baseUrl 返回不同实例', () {
      final util1 = DioRegistry.forBaseUrl('https://api.example.com');
      final util2 = DioRegistry.forBaseUrl('https://api.other.com');
      expect(util1, isNot(same(util2)));
    });

    test('dio getter 返回 Dio 实例', () {
      final util = DioRegistry.forBaseUrl('https://api.example.com');
      expect(util.dio, isA<Dio>());
    });

    test('自定义 BaseOptions 生效', () {
      final util = DioRegistry.forBaseUrl(
        'https://config.example.com',
        options: BaseOptions(
          connectTimeout: const Duration(milliseconds: 3000),
          receiveTimeout: const Duration(milliseconds: 10000),
        ),
      );
      expect(util.dio.options.baseUrl, 'https://config.example.com');
      expect(util.dio.options.connectTimeout, const Duration(milliseconds: 3000));
    });

    test('传入的 BaseOptions 不被修改，且注入 baseUrl', () {
      final options = BaseOptions(connectTimeout: const Duration(seconds: 1));
      final util = DioRegistry.forBaseUrl(
        'https://copy.example.com',
        options: options,
      );
      // 原实例保持不变（内部 copyWith 注入 baseUrl）
      expect(options.baseUrl, isEmpty);
      expect(util.dio.options.baseUrl, 'https://copy.example.com');
    });

    test('interceptors 被添加到 dio', () {
      final interceptor = WLogInterceptor(enableLog: false);
      final util = DioRegistry.forBaseUrl(
        'https://interceptor.example.com',
        interceptors: [interceptor],
      );
      expect(
        util.dio.interceptors.whereType<WLogInterceptor>(),
        isNotEmpty,
      );
    });

    test('interceptors 按传入顺序挂载', () {
      final logInterceptor = WLogInterceptor(enableLog: false);
      final tokenInterceptor = WTokenInterceptor(tokenGetter: () => 't');
      final util = DioRegistry.forBaseUrl(
        'https://order.example.com',
        interceptors: [logInterceptor, tokenInterceptor],
      );
      final mounted = util.dio.interceptors;
      expect(mounted.indexOf(logInterceptor), lessThan(mounted.indexOf(tokenInterceptor)));
    });

    test('dio.options 正确设置 baseUrl', () {
      final util = DioRegistry.forBaseUrl('https://base.example.com');
      expect(util.dio.options.baseUrl, 'https://base.example.com');
    });

    test('dispose 释放指定 baseUrl 的实例', () {
      DioRegistry.forBaseUrl('https://to-dispose.example.com');
      DioRegistry.dispose('https://to-dispose.example.com');
      // 再次 forBaseUrl 会创建新实例
      final util2 = DioRegistry.forBaseUrl('https://to-dispose.example.com');
      expect(util2, isA<DioRegistry>());
    });

    test('cacheTtl 到期后重新创建实例', () async {
      DioRegistry.cacheTtl = const Duration(milliseconds: 10);
      addTearDown(() => DioRegistry.cacheTtl = null);

      final a = DioRegistry.forBaseUrl('https://ttl.example.com');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final b = DioRegistry.forBaseUrl('https://ttl.example.com');

      expect(b, isNot(same(a)));
      expect(
        DioRegistry.maybeForBaseUrl('https://ttl.example.com'),
        same(b.dio),
      );
    });

    test('maybeForBaseUrl 对过期实例返回 null', () async {
      DioRegistry.cacheTtl = const Duration(milliseconds: 10);
      addTearDown(() => DioRegistry.cacheTtl = null);

      DioRegistry.forBaseUrl('https://ttl-maybe.example.com');
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(DioRegistry.maybeForBaseUrl('https://ttl-maybe.example.com'), isNull);
    });

    test('maxCachedInstances 按最近使用淘汰', () {
      DioRegistry.maxCachedInstances = 2;
      addTearDown(() => DioRegistry.maxCachedInstances = null);

      final a = DioRegistry.forBaseUrl('https://lru-a.example.com');
      DioRegistry.forBaseUrl('https://lru-b.example.com');

      // 命中 a 后，a 变成最近使用；再创建 c 时淘汰 b。
      DioRegistry.forBaseUrl('https://lru-a.example.com');
      final c = DioRegistry.forBaseUrl('https://lru-c.example.com');

      expect(DioRegistry.maybeForBaseUrl('https://lru-a.example.com'), same(a.dio));
      expect(DioRegistry.maybeForBaseUrl('https://lru-b.example.com'), isNull);
      expect(DioRegistry.maybeForBaseUrl('https://lru-c.example.com'), same(c.dio));
    });

    test('maxCachedInstances = 0 不缓存，且返回的实例可用', () async {
      DioRegistry.maxCachedInstances = 0;
      addTearDown(() => DioRegistry.maxCachedInstances = null);

      final registry = DioRegistry.forBaseUrl('https://no-cache.example.com');
      registry.dio.httpClientAdapter = _EchoAdapter();
      addTearDown(() => registry.dio.close(force: true));

      final response = await registry.dio.get<Map<String, dynamic>>('/x');

      expect(response.statusCode, 200);
      expect(DioRegistry.maybeForBaseUrl('https://no-cache.example.com'), isNull);
    });

    test('clearCache 清空所有缓存', () {
      DioRegistry.forBaseUrl('https://a.example.com');
      DioRegistry.forBaseUrl('https://b.example.com');
      DioRegistry.clearCache();
      // 再次访问会创建全新实例
      final util = DioRegistry.forBaseUrl('https://a.example.com');
      expect(util, isA<DioRegistry>());
    });
  });
}

class _EchoAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    '{}',
    200,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );

  @override
  void close({bool force = false}) {}
}
