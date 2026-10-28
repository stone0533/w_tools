import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/src/components/common/image.dart';
import 'package:w_tools_ui/src/components/common/image_retry_policy.dart';

const _url = 'https://example.com/img.png';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('WImage 网络路径', () {
    testWidgets('渲染 Image 并显示占位符', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WImage.network(
            _url,
            config: WImageConfig()..placeholder = const Text('LOAD'),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('LOAD'), findsOneWidget);
    });

    testWidgets('httpHeaders / cacheKey / memCache 透传', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WImage.network(
            _url,
            config: WImageConfig()
              ..httpHeaders = const {'Authorization': 'Bearer token'}
              ..cacheKey = 'home-hero'
              ..memCacheWidth = 240
              ..memCacheHeight = 120,
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image as CachedNetworkImageProvider;
      expect(provider.headers, {'Authorization': 'Bearer token'});
      expect(provider.cacheKey, 'home-hero');
      expect(provider.maxWidth, 240);
      expect(provider.maxHeight, 120);
    });

    testWidgets('进度指示器分支正常构建', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WImage.network(
            _url,
            config: WImageConfig()..progressBuilder = (_, __, ___) => const Text('PROG'),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.loadingBuilder, isNotNull);
    });

    testWidgets('一个 controller 只绑定最后一个 WImage（文档行为）', (tester) async {
      final controller = WImageController();
      await tester.pumpWidget(
        _wrap(
          Column(
            children: <Widget>[
              WImage.network(_url, key: const Key('a'), controller: controller),
              WImage.network(_url, key: const Key('b'), controller: controller),
            ],
          ),
        ),
      );

      List<Key?> keys() => tester.widgetList<Image>(find.byType(Image)).map((w) => w.key).toList();

      final before = keys();
      controller.retry();
      await tester.pump();
      final after = keys();
      expect(after[0], before[0], reason: '第一个 WImage 不应被 retry');
      expect(after[1], isNot(before[1]), reason: '最后一个 WImage 应重建');
    });

    testWidgets('重试计数体现在 ValueKey 上', (tester) async {
      await tester.pumpWidget(_wrap(WImage.network(_url)));

      expect(
        find.byKey(const ValueKey('$_url#attempt=0')),
        findsOneWidget,
      );
    });
  });

  group('WImageController', () {
    testWidgets('retry() 重建并递增 attempt', (tester) async {
      final controller = WImageController();
      await tester.pumpWidget(
        _wrap(WImage.network(_url, controller: controller)),
      );

      expect(controller.isAttached, isTrue);
      expect(find.byKey(const ValueKey('$_url#attempt=0')), findsOneWidget);

      controller.retry();
      await tester.pump();

      expect(find.byKey(const ValueKey('$_url#attempt=1')), findsOneWidget);
    });

    testWidgets('controller.state 暴露加载快照', (tester) async {
      final controller = WImageController();
      await tester.pumpWidget(
        _wrap(WImage.network(_url, controller: controller)),
      );
      expect(controller.state, isNotNull);
      expect(controller.state!.value.attempt, 0);

      controller.retry();
      await tester.pump();
      expect(controller.state!.value.attempt, 1);
    });

    testWidgets('卸载后自动解绑，retry() 不抛异常', (tester) async {
      final controller = WImageController();
      await tester.pumpWidget(
        _wrap(WImage.network(_url, controller: controller)),
      );
      expect(controller.isAttached, isTrue);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      expect(controller.isAttached, isFalse);
      expect(controller.retry, returnsNormally);
    });
  });

  group('重试状态', () {
    testWidgets('retryCount 变化后 attempt 归零', (tester) async {
      final config = WImageConfig()..retryCount = 3;
      final controller = WImageController();

      Widget build() => _wrap(
            WImage.network(_url, config: config, controller: controller),
          );

      await tester.pumpWidget(build());
      controller.retry();
      await tester.pump();
      controller.retry();
      await tester.pump();
      expect(find.byKey(const ValueKey('$_url#attempt=2')), findsOneWidget);

      config.retryCount = 0;
      await tester.pumpWidget(build());
      expect(find.byKey(const ValueKey('$_url#attempt=0')), findsOneWidget);
    });

    testWidgets('retry() 对资产图同样生效（换 key 重建）', (tester) async {
      final controller = WImageController();
      await tester.pumpWidget(
        _wrap(WImage.asset('assets/none.png', controller: controller)),
      );

      expect(
        find.byKey(const ValueKey('assets/none.png#attempt=0')),
        findsOneWidget,
      );

      controller.retry();
      await tester.pump();

      expect(
        find.byKey(const ValueKey('assets/none.png#attempt=1')),
        findsOneWidget,
      );
    });
  });

  group('WImageConfig 构建扩展', () {
    test('buildBase64 生成显式 base64 类型', () {
      final widget = WImageConfig().buildBase64('AAAA');
      expect(widget.type, WImageType.base64);
    });

    test('buildFilePath 生成显式 file 类型', () {
      final widget = WImageConfig().buildFilePath('/tmp/a.png');
      expect(widget.type, WImageType.file);
    });
  });

  group('重试策略', () {
    test('4xx 不重试，5xx / 408 / 429 重试', () {
      bool retryable(int statusCode) => isRetryableNetworkError(
            NetworkImageLoadException(
              statusCode: statusCode,
              uri: Uri.parse(_url),
            ),
          );

      expect(retryable(400), isFalse);
      expect(retryable(401), isFalse);
      expect(retryable(403), isFalse);
      expect(retryable(404), isFalse);
      expect(retryable(408), isTrue);
      expect(retryable(429), isTrue);
      expect(retryable(500), isTrue);
      expect(retryable(503), isTrue);
    });

    test('带 statusCode 字段的其他异常也按状态码判定', () {
      expect(isRetryableNetworkError(const _StatusError(404)), isFalse);
      expect(isRetryableNetworkError(const _StatusError(500)), isTrue);
    });

    test('拿不到状态码时按可重试处理（连接级失败）', () {
      expect(isRetryableNetworkError(Exception('connection reset')), isTrue);
      expect(isRetryableNetworkError(StateError('boom')), isTrue);
    });

    test('退避随 attempt 指数增长并封顶', () {
      Duration delay(int attempt) => retryDelayFor(
            attempt,
            base: const Duration(milliseconds: 100),
            random: Random(1),
          );

      // 一次重试：80–100ms
      expect(delay(0).inMilliseconds, inInclusiveRange(80, 100));
      // 二次重试：160–200ms
      expect(delay(1).inMilliseconds, inInclusiveRange(160, 200));
      // 三次重试：320–400ms
      expect(delay(2).inMilliseconds, inInclusiveRange(320, 400));
      // 大幅指数后封顶在 30s 以内
      expect(
        retryDelayFor(
          20,
          base: const Duration(seconds: 1),
          random: Random(1),
        ).inMilliseconds,
        lessThanOrEqualTo(30000),
      );
    });
  });
}

class _StatusError implements Exception {
  const _StatusError(this.statusCode);

  final int statusCode;
}
