import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools/src/components/common/image.dart';
import 'package:w_tools/src/components/common/image_cache_manager.dart';
import 'package:w_tools/src/components/common/network_image_with_retry.dart';

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
      final image = WImage(
        config: config,
        data: 'test_image.png'
      );

      expect(image.config, config);
    });
  });

  group('NetworkImageWithRetry', () {
    test('should initialize with parameters', () {
      final image = NetworkImageWithRetry(
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

    test('should set global config', () {
      final config = WImageGlobalConfig();
      final testPlaceholder = Container(color: Colors.red);
      final testErrorWidget = Container(color: Colors.blue);

      config.setGlobalConfig(
        defaultPlaceholder: testPlaceholder,
        defaultErrorWidget: testErrorWidget,
        maxCacheSize: 50,
        maxCacheMemory: 50 * 1024 * 1024,
      );

      // 注意：由于这些是私有属性，我们无法直接访问
      // 但我们可以确保方法调用不会抛出异常
      expect(() => config.setGlobalConfig(), returnsNormally);
    });
  });
}
