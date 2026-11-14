// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package
import 'dart:math';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';
import 'package:w_tools_ui/src/components/common/image/image_retry_policy.dart';

const _url = 'https://example.com/img.png';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('WImage 网络路径', () {
    testWidgets('渲染 Image 并显示占位符', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WImage.source(
            source: WImageSource.network(_url),
            slots: WImageSlots(placeholderBuilder: (context, data) => const Text('LOAD')),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('LOAD'), findsOneWidget);
    });

    testWidgets('httpHeaders / cacheKey / memCache 透传', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WImage.source(
            source: WImageSource.network(
              _url,
              headers: const {'Authorization': 'Bearer token'},
              cacheKey: 'home-hero',
            ),
            options: const WImageLoadOptions(memCacheWidth: 240, memCacheHeight: 120),
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

    testWidgets('loadingBuilder 分支正常构建', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WImage.source(
            source: WImageSource.network(_url),
            slots: WImageSlots(
              placeholderBuilder: (_, __) => const Text('PROG'),
            ),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.loadingBuilder, isNotNull);
      expect(find.text('PROG'), findsOneWidget);
    });

    testWidgets('同一 source 重建复用 provider', (tester) async {
      await tester.pumpWidget(_wrap(WImage.source(source: WImageSource.network(_url))));
      final first = tester.widget<Image>(find.byType(Image)).image;

      await tester.pumpWidget(_wrap(WImage.source(source: WImageSource.network(_url))));
      final second = tester.widget<Image>(find.byType(Image)).image;

      expect(identical(first, second), isTrue);
    });
  });

  group('手动重试', () {
    testWidgets('errorWidgetBuilder 的 onRetry 会换 key 重新加载', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WImage.source(
            source: WImageSource.provider(MemoryImage(Uint8List.fromList([1, 2, 3]))),
            slots: WImageSlots(
              errorWidgetBuilder: (context, data, error, retry) => TextButton(
                onPressed: retry,
                child: const Text('retry'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final first = tester.widget<Image>(find.byType(Image)).key;
      await tester.tap(find.text('retry'));
      await tester.pump();
      final second = tester.widget<Image>(find.byType(Image)).key;

      expect(first, isNot(second));
    });
  });

  group('WImage 构造快捷入口', () {
    test('base64 生成显式 base64 类型', () {
      expect(WImage.source(source: WImageSource.base64('AAAA')).source.type, WImageType.base64);
    });

    test('file 生成显式 file 类型', () {
      expect(WImage.source(source: WImageSource.file('/tmp/a.png')).source.type, WImageType.file);
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
