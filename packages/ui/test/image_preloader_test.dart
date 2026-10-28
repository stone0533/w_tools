import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

void main() {
  group('WImagePreloader', () {
    setUpAll(() {
      // 构造函数注册 SystemChannels 需要 WidgetsBinding
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      // 重置单例状态
      WImagePreloader().clearCache();
      WImagePreloader().resetCacheStats();
    });

    testWidgets('是单例', (tester) async {
      final a = WImagePreloader();
      final b = WImagePreloader();
      expect(a, same(b));
    });

    testWidgets('初始状态全零', (tester) async {
      final mgr = WImagePreloader();
      expect(mgr.cacheSize, 0);
      expect(mgr.cacheMemorySize, 0);
      expect(mgr.cacheHits, 0);
      expect(mgr.cacheMisses, 0);
      expect(mgr.cacheHitRate, 0.0);
    });

    testWidgets('cacheHitRate 初始为 0.0', (tester) async {
      final mgr = WImagePreloader();
      expect(mgr.cacheHitRate, 0.0);
    });

    testWidgets('clearCache 清空所有', (tester) async {
      final mgr = WImagePreloader();
      mgr.clearCache();
      expect(mgr.cacheSize, 0);
      expect(mgr.cacheMemorySize, 0);
    });

    testWidgets('cacheImage 找不到 asset 时抛出异常', (tester) async {
      final mgr = WImagePreloader();
      await expectLater(
        mgr.cacheImage('assets/nonexistent_test_image_xyz.png'),
        throwsA(isA<FlutterError>()),
      );
    });

    testWidgets('cacheImage 找不到 asset 后缓存 miss 计数增加', (tester) async {
      final mgr = WImagePreloader();
      final missesBefore = mgr.cacheMisses;
      try {
        await mgr.cacheImage('assets/nonexistent_test_image_abc.png');
      } catch (_) {}
      expect(mgr.cacheMisses, missesBefore + 1);
    });

    testWidgets('resetCacheStats 归零命中和未命中计数', (tester) async {
      final mgr = WImagePreloader();
      try {
        await mgr.cacheImage('assets/fail1.png');
        await mgr.cacheImage('assets/fail2.png');
      } catch (_) {}
      expect(mgr.cacheMisses, greaterThan(0));

      mgr.resetCacheStats();
      expect(mgr.cacheHits, 0);
      expect(mgr.cacheMisses, 0);
      expect(mgr.cacheHitRate, 0.0);
    });

    testWidgets('preloadImage 是 cacheImage 的别名', (tester) async {
      final mgr = WImagePreloader();
      await expectLater(
        mgr.preloadImage('assets/nonexistent_preload.png'),
        throwsA(isA<FlutterError>()),
      );
    });

    testWidgets('preloadImages 批量调用', (tester) async {
      final mgr = WImagePreloader();
      await expectLater(
        mgr.preloadImages([
          'assets/a.png',
          'assets/b.png',
          'assets/c.png',
        ]),
        throwsA(isA<FlutterError>()),
      );
    });
  });
}
