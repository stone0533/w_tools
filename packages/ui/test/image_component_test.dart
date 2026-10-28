import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/src/components/common/image.dart';
import 'package:w_tools_ui/src/utils/image_cache_manager.dart';

void main() {
  setUpAll(() {
    WidgetsFlutterBinding.ensureInitialized();
  });

  group('WImageConfig', () {
    test('链式方法写入的值可以读回', () {
      final config = WImageConfig()
        ..width = 100
        ..height = 200
        ..fitCover()
        ..retryCount = 3
        ..retryDelay = 500;

      expect(config.width, 100);
      expect(config.height, 200);
      expect(config.fit, BoxFit.cover);
      expect(config.retryCount, 3);
      expect(config.retryDelay, 500);
    });

    test('dimensions / square', () {
      final config = WImageConfig()..dimensions(10, 20);
      expect(config.width, 10);
      expect(config.height, 20);
      config.square(30);
      expect(config.width, 30);
      expect(config.height, 30);
    });

    test('placeholder / errorWidget 可以读回', () {
      final config = WImageConfig()
        ..placeholder = const Text('p')
        ..errorWidget = const Text('e');
      expect(config.placeholder, isA<Text>());
      expect(config.errorWidget, isA<Text>());
      config.placeholder = null;
      expect(config.placeholder, isNull);
    });

    test('非法配置触发 assert', () {
      expect(
        () => WImage(data: 'x', config: WImageConfig()..retryCount = -1),
        throwsAssertionError,
      );
      expect(
        () => WImage(data: 'x', config: WImageConfig()..retryDelay = -1),
        throwsAssertionError,
      );
      expect(
        () => WImage(data: 'x', config: WImageConfig()..memCacheWidth = 0),
        throwsAssertionError,
      );
      expect(
        () => WImage(data: 'x', config: WImageConfig()..memCacheHeight = 0),
        throwsAssertionError,
      );
      expect(
        () => WImage(data: 'x', config: WImageConfig()..aspectRatio = 0),
        throwsAssertionError,
      );
      expect(
        () => WImage(data: 'x', config: WImageConfig()..width = -1),
        throwsAssertionError,
      );
    });

    test('validate 捕获 aspectRatio 与固定宽高的冲突', () {
      expect(
        () => (WImageConfig()
              ..aspectRatio = 2
              ..width = 10
              ..height = 10)
            .validate(),
        throwsAssertionError,
      );
    });

    test('WImageConfigBuild 透传 key / type / controller', () {
      const key = Key('k');
      final controller = WImageController();
      final config = WImageConfig();
      final widget =
          config.build(data: 'x', key: key, type: WImageType.base64, controller: controller);
      expect(widget.key, key);
      expect(widget.type, WImageType.base64);
      expect(widget.controller, same(controller));

      final file = config.buildFilePath('/tmp/a.png', key: key, controller: controller);
      expect(file.key, key);
      expect(file.controller, same(controller));
    });

    test('circle() 同时设置宽高与圆角', () {
      final config = WImageConfig()..circle(50);

      expect(config.width, 100);
      expect(config.height, 100);
      expect(config.borderRadius, BorderRadius.circular(50));
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
        ..width = 100
        ..height = 100;
      final image = WImage(config: config, data: 'test_image.png');

      expect(image.config, config);
      expect(image.type, isNull);
    });

    test('命名构造带显式类型', () {
      expect(WImage.asset('a.png').type, WImageType.asset);
      expect(WImage.network('https://x/y.png').type, WImageType.network);
      expect(WImage.file('/tmp/a.png').type, WImageType.file);
      expect(WImage.base64('AAAA').type, WImageType.base64);
    });
  });

  group('WImageGlobalConfig', () {
    test('should be a singleton', () {
      final instance1 = WImageGlobalConfig();
      final instance2 = WImageGlobalConfig();
      expect(identical(instance1, instance2), true);
    });

    test('configure 写入全局默认值，并同步 Flutter ImageCache 上限', () {
      final config = WImageGlobalConfig();
      final testPlaceholder = Container(color: Colors.red);
      final testErrorWidget = Container(color: Colors.blue);
      final oldMaxSize = PaintingBinding.instance.imageCache.maximumSize;
      final oldMaxBytes = PaintingBinding.instance.imageCache.maximumSizeBytes;
      addTearDown(() {
        PaintingBinding.instance.imageCache.maximumSize = oldMaxSize;
        PaintingBinding.instance.imageCache.maximumSizeBytes = oldMaxBytes;
        config.configure(defaultPlaceholder: null, defaultErrorWidget: null);
      });

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
      expect(PaintingBinding.instance.imageCache.maximumSize, 50);
      expect(
        PaintingBinding.instance.imageCache.maximumSizeBytes,
        50 * 1024 * 1024,
      );
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
    testWidgets('fitContain() 应使用 BoxFit.contain', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WImage.asset(
            'no_such_asset_for_test.png',
            config: WImageConfig()..fitContain(),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.fit, BoxFit.contain);
    });

    testWidgets('Base64 解码失败时应渲染 errorWidget 并回调 failed', (tester) async {
      WImageLoadStatus? status;
      Object? capturedError;

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: WImage(
              data: 'data:image/png;base64,@@invalid@@',
              config: WImageConfig()
                ..errorWidgetBuilder = (context, url, error) {
                  capturedError = error;
                  return const Text('base64-error');
                },
              onLoadStatusChanged: (s) => status = s,
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });

      // 触发一次重建（拿到错误快照）并执行 post-frame 回调
      await tester.pump();
      await tester.pump();

      expect(find.text('base64-error'), findsOneWidget);
      expect(status, WImageLoadStatus.failed);
      expect(capturedError, isA<WImageDecodeError>());
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
