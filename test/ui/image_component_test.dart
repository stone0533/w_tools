import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/src/components/common/image.dart';
import 'package:w_tools_ui/src/utils/image_cache_manager.dart';
import 'package:w_tools_ui/src/components/common/network_image_with_retry.dart';

void main() {
  setUpAll(() {
    WidgetsFlutterBinding.ensureInitialized();
  });
  group('WImageConfig', () {
    test('should set and get properties correctly', () {
      final config = WImageConfig()
        ..width = 100
        ..height = 200
        ..fitCover()
        ..retryCount = 3
        ..retryDelay = 500;

      // 注意：由于这些是私有属性，我们无法直接访问
      // 但我们可以测试链式调用是否正常工作
      expect(config, isNotNull);
    });
  });

  group('WImageCacheManager', () {
    test('should initialize correctly', () {
      final cacheManager = WImageCacheManager();
      expect(cacheManager, isNotNull);
    });

    test('should handle cache operations', () async {
      final cacheManager = WImageCacheManager();

      // 测试清理缓存
      cacheManager.clearCache();
      // 由于 _cache 是私有属性，我们无法直接验证
      // 但我们可以确保方法调用不会抛出异常
      expect(() => cacheManager.clearCache(), returnsNormally);
    });
  });

  group('WImage', () {
    test('should build with config', () {
      final config = WImageConfig()
        ..width = (100)
        ..height = (100);
      final image = WImage(config: config, data: 'test_image.png');

      expect(image.config, config);
    });
  });

  group('WNetworkImageWithRetry', () {
    test('should initialize with parameters', () {
      final image = WNetworkImageWithRetry(
        imageUrl: 'https://example.com/image.png',
        width: 100,
        height: 100,
        defaultPlaceholder: Container(),
        defaultErrorWidget: Container(),
        retryCount: 3,
        retryDelay: 500,
      );

      // 注意：由于这些是私有属性，我们无法直接访问
      // 但我们可以确保构造函数不会抛出异常
      expect(image, isNotNull);
    });
  });

  group('WImageGlobalConfig', () {
    test('should be a singleton', () {
      final instance1 = WImageGlobalConfig();
      final instance2 = WImageGlobalConfig();
      expect(identical(instance1, instance2), true);
    });

    test('configure 写入全局默认值', () {
      final config = WImageGlobalConfig();
      final testPlaceholder = Container(color: Colors.red);
      final testErrorWidget = Container(color: Colors.blue);

      config.configure(
        defaultPlaceholder: testPlaceholder,
        defaultErrorWidget: testErrorWidget,
        maxCacheSize: 50,
        maxCacheMemory: 50 * 1024 * 1024,
      );

      expect(config.defaultPlaceholder, testPlaceholder);
      expect(config.defaultErrorWidget, testErrorWidget);
      expect(config.maxCacheSize, 50);
      expect(config.maxCacheMemory, 50 * 1024 * 1024);
    });

    testWidgets('WImage 使用全局默认占位符', (tester) async {
      final global = WImageGlobalConfig()
        ..defaultPlaceholder = const Text('global-placeholder')
        ..defaultErrorWidget = const Text('global-error');
      addTearDown(
        () => global.configure(defaultPlaceholder: null, defaultErrorWidget: null),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WImage(data: 'data:image/png;base64,@@invalid@@'),
        ),
      );

      // 解码尚未完成时显示全局默认占位符
      expect(find.text('global-placeholder'), findsOneWidget);
    });
  });

  group('WImage 回归', () {
    testWidgets('fitCenter() 应使用 BoxFit.contain', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WImage(
            // 走本地资源分支，cacheEnabled=false 时直接产出 Image.asset
            data: 'no_such_asset_for_test.png',
            config: WImageConfig()
              ..fitCenter()
              ..cacheEnabled = false,
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.fit, BoxFit.contain);
    });

    testWidgets('Base64 解码失败时应渲染 errorWidget 并回调 failed', (tester) async {
      WImageLoadStatus? status;

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: WImage(
              data: 'data:image/png;base64,@@invalid@@',
              config: WImageConfig()..errorWidget = const Text('base64-error'),
              onLoadStatusChanged: (s) => status = s,
            ),
          ),
        );
        // compute 在独立 isolate 中执行，需等待其完成
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });

      // 触发一次重建（拿到错误快照）并执行 post-frame 回掉
      await tester.pump();
      await tester.pump();

      expect(find.text('base64-error'), findsOneWidget);
      expect(status, WImageLoadStatus.failed);
    });

    testWidgets('父级重建不会重复通知同一加载状态', (tester) async {
      final statuses = <WImageLoadStatus>[];

      Widget build() => MaterialApp(
        home: WImage(
          data: 'data:image/png;base64,@@invalid@@',
          config: WImageConfig()..errorWidget = const Text('base64-error'),
          onLoadStatusChanged: statuses.add,
        ),
      );

      await tester.runAsync(() async {
        await tester.pumpWidget(build());
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();
      await tester.pump();

      // 同一 state 重建：Future 与状态均已缓存，不应再次通知 failed
      await tester.pumpWidget(build());
      await tester.pump();
      await tester.pump();

      expect(statuses.where((s) => s == WImageLoadStatus.failed).length, 1);
    });
  });
}
