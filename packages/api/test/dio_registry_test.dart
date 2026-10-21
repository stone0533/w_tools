import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_api/w_tools_api.dart';

void main() {
  tearDown(() {
    DioRegistry.clearCache();
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
